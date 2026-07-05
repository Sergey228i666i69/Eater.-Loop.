extends "res://tests/test_case.gd"

const DROP_SLOT_SCENE_PATH := "res://levels/minigames/ui/drop_slot.tscn"
const DRAG_WORD_SCENE_PATH := "res://levels/minigames/ui/drag_word.tscn"
const DRAG_WORD_SCRIPT_PATH := "res://levels/minigames/labs/sql/drag_word.gd"
const SQL_MINIGAME_SCRIPTS := [
	"res://levels/minigames/labs/sql/sql_minigame.gd",
	"res://levels/minigames/labs/sql/sql_minigame_glitch.gd",
]
const SqlDropSlotScript := preload("res://levels/minigames/labs/sql/drag_slot.gd")
const SqlDragWordScript := preload("res://levels/minigames/labs/sql/drag_word.gd")


func run() -> Array[String]:
	_test_widget_scenes_use_typed_scripts()
	_test_sql_minigames_use_typed_widgets()
	return get_failures()


func _test_widget_scenes_use_typed_scripts() -> void:
	var slot_scene := assert_loads(DROP_SLOT_SCENE_PATH) as PackedScene
	var word_scene := assert_loads(DRAG_WORD_SCENE_PATH) as PackedScene
	if slot_scene == null or word_scene == null:
		return

	var slot_instance := slot_scene.instantiate()
	var slot := slot_instance as SqlDropSlotScript
	assert_true(slot != null, "drop_slot.tscn must instantiate as SqlDropSlot")
	if slot != null:
		assert_true(slot.has_signal("word_dropped"), "SqlDropSlot must expose word_dropped")
		slot.free()
	elif slot_instance != null:
		slot_instance.free()

	var word_instance := word_scene.instantiate()
	var word := word_instance as SqlDragWordScript
	assert_true(word != null, "drag_word.tscn must instantiate as SqlDragWord")
	if word != null:
		word.free()
	elif word_instance != null:
		word_instance.free()


func _test_sql_minigames_use_typed_widgets() -> void:
	var forbidden_patterns := [
		"has_signal(\"word_dropped\")",
		"has_method(\"set_drag_context\")",
		"has_method(\"set_word\")",
		"has_method(\"can_accept_word\")",
		".call(\"can_accept_word\"",
		"has_method(\"clear_word\")",
	]
	for script_path in SQL_MINIGAME_SCRIPTS:
		var content := FileAccess.get_file_as_string(script_path)
		assert_true(content != "", "Failed to read SQL minigame script: %s" % script_path)
		for pattern in forbidden_patterns:
			assert_true(content.find(pattern) == -1, "SQL minigames must use typed SqlDropSlot/SqlDragWord API instead of method probes: %s (%s)" % [script_path, pattern])

	var drag_word_content := FileAccess.get_file_as_string(DRAG_WORD_SCRIPT_PATH)
	assert_true(drag_word_content != "", "Failed to read SQL drag word script")
	for pattern in [
		"has_method(\"set_word\")",
		"has_method(\"can_accept_word\")",
	]:
		assert_true(drag_word_content.find(pattern) == -1, "SqlDragWord must find SqlDropSlot by type instead of method probes: %s" % pattern)
