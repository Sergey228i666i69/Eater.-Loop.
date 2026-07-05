extends "res://levels/minigames/labs/timed_lab_minigame_base.gd"

# --- Настройки ---
# --- Данные заданий ---
var tasks = [
	{
		"description": "Выбрать всех студентов из таблицы Users",
		"template": ["SELECT", null, "FROM", null],
		"correct": ["*", "Users"],
		"pool": ["SELECT", "*", "FROM", "Users", "WHERE", "DROP"]
	},
	{
		"description": "Найти должников (debt > 0)",
		"template": ["SELECT", "*", "FROM", "Students", "WHERE", null, ">", null],
		"correct": ["debt", "0"],
		"pool": ["debt", "0", "id", "NULL", "100", ">", "Students"]
	},
	{
		"description": "Удалить таблицу Долги (Осторожно!)",
		"template": [null, "TABLE", null],
		"correct": ["DROP", "Debts"],
		"pool": ["DELETE", "DROP", "TABLE", "Debts", "Row", "*"]
	}
]

var current_task_index = 0
var _is_finished: bool = false
var _gamepad_selected_word: String = ""
const COLOR_KEYWORD := Color(0.337255, 0.611765, 0.839216)
const STATUS_TEMPLATE := " SQL | UTF-8 | ВРЕМЯ: %.1f сек | LN 1, COL 1"
const MONO_FONT_NAMES := ["JetBrains Mono", "Menlo", "Consolas", "Courier New", "Courier"]
const SqlDropSlotScript := preload("res://levels/minigames/labs/sql/drag_slot.gd")
const SqlDragWordScript := preload("res://levels/minigames/labs/sql/drag_word.gd")

@onready var drag_layer: Control = $DragLayer
@onready var query_container: HBoxContainer = $Layout/MainContent/EditorArea/QueryEditor/QueryFlow
@onready var pool_container: GridContainer = $Layout/MainContent/EditorArea/WordBank/WordGrid
@onready var task_label: Label = $Layout/MainContent/LeftSidebar/TaskInfo/Description
@onready var timer_label: Label = $Footer/StatusLabel

var _mono_font_bold: SystemFont = null

# Загружаем сцены слотов и слов
var slot_scene = preload("res://levels/minigames/ui/drop_slot.tscn") 
var word_scene = preload("res://levels/minigames/ui/drag_word.tscn")

func _ready():
	_mono_font_bold = _build_mono_font(600)

	start_timed_lab_session(Callable(self, "_on_time_updated"), Callable(self, "_on_time_expired"))
	_update_status_label()
	load_task(0)
	_register_gamepad_scheme()

func _update_status_label() -> void:
	if timer_label:
		timer_label.text = tr(STATUS_TEMPLATE) % max(0.0, current_time)

func load_task(index):
	if index < 0 or index >= tasks.size():
		push_warning("SqlMinigame: неверный индекс задания %d." % index)
		return
	current_task_index = index
	_gamepad_selected_word = ""
	var data = tasks[index]
	
	task_label.text = tr(String(data["description"]))
	
	# Очистка старых элементов
	for child in query_container.get_children(): child.queue_free()
	for child in pool_container.get_children(): child.queue_free()
	
	# Создание слотов запроса
	var correct_index := 0
	for item in data["template"]:
		if item == null:
			# Это слот
			var raw_slot := slot_scene.instantiate()
			var slot := raw_slot as SqlDropSlotScript
			if slot == null:
				push_error("SqlMinigame: slot_scene must instantiate as SqlDropSlot.")
				if raw_slot != null:
					raw_slot.free()
				continue
			# Передаем правильный ответ в слот (важно для вашего drag_slot.gd, так как он проверяет expected_text)
			if correct_index < data["correct"].size():
				slot.expected_text = data["correct"][correct_index]
				correct_index += 1
			
			query_container.add_child(slot)
			# Подписываемся на сигнал падения слова
			slot.word_dropped.connect(check_answer)
		else:
			# Это статический текст
			var keyword = Label.new()
			keyword.text = item
			keyword.add_theme_color_override("font_color", COLOR_KEYWORD)
			if _mono_font_bold:
				keyword.add_theme_font_override("font", _mono_font_bold)
			keyword.add_theme_font_size_override("font_size", 16)
			query_container.add_child(keyword)
			
	# Создание слов для выбора
	for word_text in data["pool"]:
		var raw_word := word_scene.instantiate()
		var word := raw_word as SqlDragWordScript
		if word == null:
			push_error("SqlMinigame: word_scene must instantiate as SqlDragWord.")
			if raw_word != null:
				raw_word.free()
			continue
		word.text_value = word_text
		word.set_drag_context(drag_layer)
		pool_container.add_child(word)
	_register_gamepad_scheme()
		
# Основная функция проверки
func check_answer(_arg = null):
	# Ждем 1 кадр, чтобы переменные в слоте успели обновиться после сигнала
	await get_tree().process_frame
	
	if _is_finished: return

	var data = tasks[current_task_index]
	var slots := _get_all_gamepad_target_slots()
	
	var correct_matches = 0
	var _filled_count = 0
	
	# Проверяем содержимое слотов
	for i in range(slots.size()):
		var slot := slots[i] as SqlDropSlotScript
		if slot == null:
			continue
		var slot_text = ""
		
		if "current_text" in slot:
			slot_text = slot.current_text
		
		if slot_text != "":
			_filled_count += 1
		
		# Сравниваем с правильным ответом
		if i < data["correct"].size():
			if slot_text == data["correct"][i]:
				correct_matches += 1
	
	# Если ВСЕ слоты заполнены И ВСЕ верны — победа
	if correct_matches == slots.size() and slots.size() > 0:
		next_level()

func next_level():
	if current_task_index + 1 < tasks.size():
		load_task(current_task_index + 1)
	else:
		finish_game(true)

func finish_game(success: bool):
	if _is_finished:
		return
	_is_finished = true
	if MinigameController:
		MinigameController.finish_minigame_with_fade(self, success, Callable(self, "_finalize_finish_after_fade").bind(success))
		return
	_finalize_finish_after_fade(success)

func _finalize_finish_after_fade(success: bool) -> void:
	task_completed.emit(success)
	if success:
		print_verbose("Лабораторная выполнена!")
	else:
		print_verbose("Время вышло! Штраф.")
	apply_standard_lab_outcome(success)
	queue_free()

func _on_time_updated(minigame: Node, time_left: float, _time_limit: float) -> void:
	if minigame != self:
		return
	current_time = time_left
	_update_status_label()

func _on_time_expired(minigame: Node) -> void:
	if minigame != self:
		return
	finish_game(false)

func _build_mono_font(weight: int) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(MONO_FONT_NAMES)
	font.font_weight = weight
	return font

func _exit_tree() -> void:
	cleanup_timed_lab(Callable(self, "_on_time_updated"), Callable(self, "_on_time_expired"))

func _register_gamepad_scheme() -> void:
	if MinigameController == null:
		return
	MinigameController.set_gamepad_scheme(self, {
		"mode": "pick_place",
		"source_provider": Callable(self, "_get_gamepad_source_nodes"),
		"target_provider": Callable(self, "_get_gamepad_target_nodes"),
		"on_pick": Callable(self, "_on_gamepad_pick"),
		"on_cancel_pick": Callable(self, "_on_gamepad_cancel_pick"),
		"on_place": Callable(self, "_on_gamepad_place"),
		"on_placed": Callable(self, "_on_gamepad_placed"),
		"on_secondary": Callable(self, "_on_gamepad_secondary"),
		"hints": {
			"confirm": "Выбор / вставка",
			"cancel": "Выход",
			"secondary": "Очистить слот",
			"tab_left": "Секция",
			"tab_right": "Секция"
		}
	})

func _get_gamepad_source_nodes() -> Array[Node]:
	var nodes: Array[Node] = []
	for child in pool_container.get_children():
		if child == null or child.is_queued_for_deletion():
			continue
		if child is Button:
			nodes.append(child)
	return nodes

func _get_gamepad_target_nodes() -> Array[Node]:
	var slots := _get_all_gamepad_target_slots()
	if _gamepad_selected_word == "":
		return slots
	var nodes: Array[Node] = []
	for slot in slots:
		var drop_slot := slot as SqlDropSlotScript
		if drop_slot != null and drop_slot.can_accept_word(_gamepad_selected_word):
			nodes.append(slot)
	return nodes

func _get_all_gamepad_target_slots() -> Array[Node]:
	var nodes: Array[Node] = []
	for child in query_container.get_children():
		if child == null or child.is_queued_for_deletion():
			continue
		var slot := child as SqlDropSlotScript
		if slot != null:
			nodes.append(slot)
	return nodes

func _on_gamepad_pick(source: Node, _context: Dictionary) -> void:
	_gamepad_selected_word = _extract_word_from_source(source)

func _on_gamepad_cancel_pick(_source: Node, _context: Dictionary) -> void:
	_gamepad_selected_word = ""

func _on_gamepad_place(source: Node, target: Node, _context: Dictionary) -> bool:
	if source == null or target == null:
		return false
	var slot := target as SqlDropSlotScript
	if slot == null:
		return false
	var word_text := _extract_word_from_source(source)
	if word_text == "":
		return false
	if not slot.can_accept_word(word_text):
		return false
	slot.set_word(word_text)
	_gamepad_selected_word = ""
	check_answer()
	return true

func _on_gamepad_placed(_source: Node, _target: Node, _context: Dictionary) -> void:
	_gamepad_selected_word = ""

func _on_gamepad_secondary(active: Node, _context: Dictionary) -> bool:
	if active == null:
		return false
	var slot := active as SqlDropSlotScript
	if slot == null:
		return false
	slot.clear_word()
	check_answer()
	return true

func _extract_word_from_source(source: Node) -> String:
	if source == null:
		return ""
	var word := source as SqlDragWordScript
	if word != null:
		return String(word.text_value)
	if source is Button:
		return String((source as Button).text)
	return ""
