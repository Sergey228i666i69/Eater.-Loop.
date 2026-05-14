extends Node

var _candidates: Dictionary = {}
var _focused_object: InteractiveObject = null
var _enter_sequence: int = 0

func register_candidate(object: InteractiveObject, player: Node) -> void:
	if object == null or not is_instance_valid(object):
		return
	var id := object.get_instance_id()
	var previous: Variant = _candidates.get(id, {})
	var order := int(previous.get("order", 0)) if previous is Dictionary else 0
	if order <= 0:
		_enter_sequence += 1
		order = _enter_sequence
	_candidates[id] = {
		"object": object,
		"player": player,
		"order": order,
	}
	_refresh_focus()

func unregister_candidate(object: InteractiveObject) -> void:
	if object == null:
		return
	_candidates.erase(object.get_instance_id())
	if _focused_object == object:
		_set_object_focus(_focused_object, false)
		_focused_object = null
	_refresh_focus()

func refresh_candidate(object: InteractiveObject) -> void:
	if object == null:
		return
	if not _candidates.has(object.get_instance_id()):
		return
	_refresh_focus()

func clear_candidates() -> void:
	_set_object_focus(_focused_object, false)
	_candidates.clear()
	_focused_object = null

func get_focused_object() -> InteractiveObject:
	_prune_candidates()
	return _focused_object

func _unhandled_input(event: InputEvent) -> void:
	var selected := _select_candidate()
	if selected == null:
		return
	var action := selected.call("_get_interact_action") as String
	if action == "":
		return
	if not event.is_action_pressed(action):
		return
	if _is_minigame_blocking_interactions():
		get_viewport().set_input_as_handled()
		return
	selected.request_interact()
	get_viewport().set_input_as_handled()
	_refresh_focus()

func _refresh_focus() -> void:
	var selected := _select_candidate()
	if selected == _focused_object:
		if _focused_object != null:
			_set_object_focus(_focused_object, true)
		return
	_set_object_focus(_focused_object, false)
	_focused_object = selected
	_set_object_focus(_focused_object, true)

func _select_candidate() -> InteractiveObject:
	_prune_candidates()
	var selected: InteractiveObject = null
	var selected_available := false
	var selected_priority := -2147483648
	var selected_distance := INF
	var selected_order := -1
	for entry in _candidates.values():
		var object := entry.get("object") as InteractiveObject
		if object == null or not _is_candidate_enabled(object):
			continue
		var available := _can_show_prompt(object)
		var priority := int(object.interaction_priority)
		var distance := _distance_to_player(object, entry.get("player"))
		var order := int(entry.get("order", 0))
		if (available and not selected_available) \
				or (available == selected_available and priority > selected_priority) \
				or (available == selected_available and priority == selected_priority and distance < selected_distance) \
				or (available == selected_available and priority == selected_priority and is_equal_approx(distance, selected_distance) and order > selected_order):
			selected = object
			selected_available = available
			selected_priority = priority
			selected_distance = distance
			selected_order = order
	return selected

func _prune_candidates() -> void:
	for id in _candidates.keys():
		var entry: Variant = _candidates[id]
		if not (entry is Dictionary):
			_candidates.erase(id)
			continue
		var object := (entry as Dictionary).get("object") as InteractiveObject
		if object == null or not is_instance_valid(object) or not object.is_inside_tree():
			_candidates.erase(id)
	if _focused_object != null and (not is_instance_valid(_focused_object) or not _candidates.has(_focused_object.get_instance_id())):
		_focused_object = null

func _is_candidate_enabled(object: InteractiveObject) -> bool:
	return object != null and object.is_manager_candidate()

func _distance_to_player(object: InteractiveObject, player: Variant) -> float:
	if object == null:
		return INF
	if player is Node2D and is_instance_valid(player):
		return object.get_interaction_sort_position().distance_squared_to((player as Node2D).global_position)
	return 0.0

func _set_object_focus(object: InteractiveObject, focused: bool) -> void:
	if object == null or not is_instance_valid(object):
		return
	object.call("_set_interaction_focus", focused)

func _can_show_prompt(object: InteractiveObject) -> bool:
	return object != null and object.can_show_manager_prompt()

func _is_minigame_blocking_interactions() -> bool:
	return MinigameController != null \
		and MinigameController.has_method("has_active_minigame") \
		and bool(MinigameController.has_active_minigame())
