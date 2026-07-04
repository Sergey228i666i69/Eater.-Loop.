extends "res://objects/interactable/interactive_object.gd"

const SearchKeyMinigameScript := preload("res://levels/minigames/search_key/search_minigame.gd")

@export_group("Search Settings")
@export var minigame_scene: PackedScene
@export var key_id: String = "door_key"
@export var key_texture: Texture2D
@export var trash_textures: Array[Texture2D] = []
@export var trash_min: int = 5
@export var trash_max: int = 15
@export var searched_empty_message: String = "Теперь не нечего тут искать"

@export_group("Minigame Session")
@export var show_mouse_cursor: bool = true

var has_key: bool = false
var is_searched_empty: bool = false

var _current_minigame: SearchKeyMinigameScript = null
var _layout_state: Dictionary = {}

func set_has_key(value: bool) -> void:
	has_key = value
	if value:
		is_searched_empty = false

func set_searched_empty(value: bool) -> void:
	is_searched_empty = value
	if value:
		has_key = false

func _on_interact() -> void:
	if _current_minigame != null:
		return
	if is_searched_empty:
		if UIMessage:
			UIMessage.show_notification(searched_empty_message)
		return
	if minigame_scene == null:
		push_warning("SearchSpot: minigame_scene не задан.")
		return

	var raw_minigame := minigame_scene.instantiate()
	var minigame := raw_minigame as SearchKeyMinigameScript
	if minigame == null:
		push_warning("SearchSpot: minigame_scene must use SearchKeyMinigame.")
		if raw_minigame != null:
			raw_minigame.free()
		return
	_current_minigame = minigame

	var layout_payload: Dictionary = {}
	if not _layout_state.is_empty():
		layout_payload = _layout_state.duplicate(true)
	minigame.setup({
		"has_key": has_key,
		"key_id": key_id,
		"key_texture": key_texture,
		"trash_range": Vector2i(trash_min, trash_max),
		"trash_textures": trash_textures,
		"layout_state": layout_payload
	})

	set_prompts_enabled(false)
	if MinigameController and MinigameController.has_signal("minigame_finished"):
		MinigameController.minigame_finished.connect(_on_minigame_finished)
		var settings := MinigameSettings.new()
		settings.pause_game = false
		settings.show_mouse_cursor = show_mouse_cursor
		settings.block_player_movement = true
		settings.allow_pause_menu = false
		settings.allow_cancel_action = true
		start_managed_minigame(minigame, settings)
	else:
		attach_minigame(minigame)

func _on_minigame_finished(minigame: Node, success: bool) -> void:
	if minigame != _current_minigame:
		return
	if MinigameController and MinigameController.minigame_finished.is_connected(_on_minigame_finished):
		MinigameController.minigame_finished.disconnect(_on_minigame_finished)
	set_prompts_enabled(true)

	var finished_minigame := minigame as SearchKeyMinigameScript
	if is_instance_valid(finished_minigame):
		_layout_state = finished_minigame.get_layout_state()
	_current_minigame = null

	if success and has_key:
		var found_key_id := key_id
		has_key = false
		is_searched_empty = true
		complete_interaction(InteractionResultBuilder.key_reward(found_key_id))

func capture_checkpoint_state() -> Dictionary:
	var state := super.capture_checkpoint_state()
	state["has_key"] = has_key
	state["is_searched_empty"] = is_searched_empty
	state["layout_state"] = _layout_state.duplicate(true)
	return state

func apply_checkpoint_state(state: Dictionary) -> void:
	super.apply_checkpoint_state(state)
	has_key = bool(state.get("has_key", has_key))
	is_searched_empty = bool(state.get("is_searched_empty", is_searched_empty))
	var layout_state: Variant = state.get("layout_state", {})
	_layout_state = layout_state.duplicate(true) if layout_state is Dictionary else {}
	_current_minigame = null
