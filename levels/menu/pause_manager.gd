extends Node

@export var pause_menu_scene: PackedScene = preload("res://levels/menu/pause_menu.tscn")

var _pause_menu_layer: Node
var _pause_menu: Node
var _is_open: bool = false
var _pause_blockers: Dictionary = {}
var _pause_requests: Dictionary = {}
var _paused_before_requests: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	var pause_requested := event.is_action_pressed("pause_menu")
	var keyboard_escape_requested := event.is_action_pressed("ui_cancel") and _is_keyboard_escape_event(event)
	if not pause_requested and not keyboard_escape_requested:
		return
	if _is_open:
		if _pause_menu and _pause_menu.has_method("request_resume"):
			_pause_menu.call("request_resume")
		else:
			_request_resume()
		get_viewport().set_input_as_handled()
		return
	if is_pause_blocked():
		return
	if keyboard_escape_requested and _should_defer_to_minigame_cancel(event):
		return
	if _is_scene_pause_blocked():
		return
	if _is_minigame_pause_blocked():
		return
	if get_tree().paused and not _is_minigame_active():
		return
	_open_menu()
	get_viewport().set_input_as_handled()

func _open_menu() -> void:
	if pause_menu_scene == null:
		return
	_ensure_menu_instance()
	if _pause_menu and _pause_menu.has_method("open_menu"):
		_pause_menu.call("open_menu")
	request_pause(self, "pause_menu")
	_is_open = true
	if MinigameController != null:
		MinigameController.set_pause_menu_open(true)

func _request_resume() -> void:
	if _pause_menu and _pause_menu.has_method("close_menu"):
		_pause_menu.call("close_menu")
	release_pause(self, "pause_menu")
	_is_open = false
	if MinigameController != null:
		MinigameController.set_pause_menu_open(false)

func _ensure_menu_instance() -> void:
	if is_instance_valid(_pause_menu_layer):
		return
	_pause_menu_layer = pause_menu_scene.instantiate()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(_pause_menu_layer)
	_pause_menu = _pause_menu_layer.get_node_or_null("PauseMenu")
	if _pause_menu and _pause_menu.has_signal("resume_requested"):
		_pause_menu.connect("resume_requested", _request_resume)
	_pause_menu_layer.tree_exiting.connect(func():
		_pause_menu_layer = null
		_pause_menu = null
		_is_open = false
		release_pause(self, "pause_menu")
		if MinigameController != null:
			MinigameController.set_pause_menu_open(false)
	)

func _is_menu_scene() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return true
	return SceneContext != null and SceneContext.is_menu_scene(current)

func _is_scene_pause_blocked() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return true
	if SceneContext == null:
		return false
	return SceneContext.is_menu_scene(current) or SceneContext.is_ending_scene(current)

func _is_minigame_active() -> bool:
	var nodes := get_tree().get_nodes_in_group("minigame_ui")
	for node in nodes:
		if node is CanvasItem and node.visible:
			return true
		if node.is_inside_tree():
			return true
	return false

func _is_minigame_pause_blocked() -> bool:
	if MinigameController != null:
		return not MinigameController.is_pause_menu_allowed()
	return false

func _is_minigame_cancel_allowed() -> bool:
	if MinigameController != null:
		return MinigameController.is_cancel_action_allowed()
	return false

func _is_keyboard_escape_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	return key_event.physical_keycode == KEY_ESCAPE or key_event.keycode == KEY_ESCAPE

func _should_defer_to_minigame_cancel(event: InputEvent) -> bool:
	if not _is_keyboard_escape_event(event):
		return false
	if not _is_minigame_active():
		return false
	return _is_minigame_cancel_allowed()

func is_pause_menu_open() -> bool:
	return _is_open

func request_pause(owner: Object, reason: String = "") -> String:
	if owner == null:
		return ""
	_cleanup_pause_requests()
	if _pause_requests.is_empty():
		_paused_before_requests = get_tree().paused
	var key := _build_pause_key(owner, reason)
	_pause_requests[key] = {
		"ref": weakref(owner),
		"reason": reason,
	}
	if owner is Node:
		var owner_node := owner as Node
		var exit_cleanup := Callable(self, "_on_pause_owner_tree_exiting").bind(key)
		if not owner_node.tree_exiting.is_connected(exit_cleanup):
			owner_node.tree_exiting.connect(exit_cleanup, Object.CONNECT_ONE_SHOT)
	_apply_pause_requests()
	return key

func release_pause(owner: Object, reason: String = "") -> void:
	if owner == null:
		return
	_pause_requests.erase(_build_pause_key(owner, reason))
	_cleanup_pause_requests()
	_apply_pause_requests()

func release_all_pauses_for(owner: Object) -> void:
	if owner == null:
		return
	var owner_prefix := "%s:" % owner.get_instance_id()
	for key in _pause_requests.keys():
		if str(key).begins_with(owner_prefix):
			_pause_requests.erase(key)
	_cleanup_pause_requests()
	_apply_pause_requests()

func clear_all_pause_requests() -> void:
	_pause_requests.clear()
	_paused_before_requests = false
	_apply_pause_requests()

func has_pause_requests() -> bool:
	_cleanup_pause_requests()
	return not _pause_requests.is_empty()

func get_pause_request_count() -> int:
	_cleanup_pause_requests()
	return _pause_requests.size()

func set_pause_blocked(source: Object, blocked: bool = true) -> void:
	if source == null:
		return
	var source_id := source.get_instance_id()
	if blocked:
		_pause_blockers[source_id] = weakref(source)
	else:
		_pause_blockers.erase(source_id)
	_cleanup_pause_blockers()

func is_pause_blocked() -> bool:
	_cleanup_pause_blockers()
	return not _pause_blockers.is_empty()

func _cleanup_pause_blockers() -> void:
	var stale: Array[int] = []
	for source_id in _pause_blockers.keys():
		var ref := _pause_blockers[source_id] as WeakRef
		if ref == null or ref.get_ref() == null:
			stale.append(source_id)
	for source_id in stale:
		_pause_blockers.erase(source_id)

func _build_pause_key(owner: Object, reason: String = "") -> String:
	return "%s:%s" % [owner.get_instance_id(), reason.strip_edges()]

func _cleanup_pause_requests() -> void:
	var stale: Array[String] = []
	for key in _pause_requests.keys():
		var data := _pause_requests[key] as Dictionary
		var ref := data.get("ref", null) as WeakRef
		if ref == null or ref.get_ref() == null:
			stale.append(str(key))
	for key in stale:
		_pause_requests.erase(key)

func _on_pause_owner_tree_exiting(key: String) -> void:
	_pause_requests.erase(key)
	_cleanup_pause_requests()
	_apply_pause_requests()

func _apply_pause_requests() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if _pause_requests.is_empty():
		tree.paused = _paused_before_requests
		_paused_before_requests = false
	else:
		tree.paused = true
