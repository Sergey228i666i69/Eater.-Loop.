extends Area2D
class_name InteractiveObject

signal player_entered(player: Node)
signal player_exited(player: Node)
signal interaction_requested(player: Node)
signal interaction_result(result: Dictionary)
signal interaction_succeeded(result: Dictionary)
signal interaction_failed(result: Dictionary)
signal interaction_cancelled(result: Dictionary)
signal interaction_finished

enum InteractionOutcome {
	SUCCEEDED,
	FAILED,
	CANCELLED,
}

enum DependencyCondition {
	COMPLETED,
	INTERACTION_REQUESTED,
}

const RESULT_OUTCOME := "outcome"
const RESULT_SUCCESS := "success"
const RESULT_SOURCE := "source"
const RESULT_REASON := "reason"
const RESULT_PLAYER := "player"
const RESULT_PAYLOAD := "payload"
const FAIL_REASON_DISABLED := "disabled"
const FAIL_REASON_DEPENDENCY := "dependency"
const FAIL_REASON_UNAVAILABLE := "unavailable"
const FAIL_REASON_CANCELLED := "cancelled"

@export_group("Interaction")
## Узел Area2D для зоны взаимодействия (пусто — использовать сам объект).
@export var interact_area_node: NodePath = NodePath("")
## Текст подсказки взаимодействия.
@export var prompt_text: String = ""
## Показывать подсказку автоматически при входе в зону.
@export var auto_prompt: bool = true
## Обрабатывать ввод автоматически.
@export var handle_input: bool = true
## Приоритет выбора, если игрок стоит в нескольких интерактивах.
@export var interaction_priority: int = 0

@export_group("Prompt Indicator")
## Смещение спрайта подсказки относительно центра объекта.
@export var prompt_offset: Vector2 = Vector2.ZERO

@export_group("Dependency System")
## Если true, объект помечается выполненным после первого использования
@export var one_shot: bool = false
## Объект, который должен быть выполнен перед использованием этого
@export var dependency_object: InteractiveObject 
## Как именно dependency_object должен разблокировать этот объект.
@export_enum("Completed", "Interaction Requested") var dependency_condition: int = DependencyCondition.COMPLETED
## Сообщение при блокировке (если показывать вручную)
@export var locked_message: String = "Сначала нужно сделать что-то другое..."

var _interact_area: Area2D = null
var _player_in_range: Node = null
var _prompts_enabled: bool = true
var _interaction_focused: bool = false
var _dependency_request_satisfied: bool = false
var _last_interaction_result: Dictionary = {}
var is_completed: bool = false

func _ready() -> void:
	if not is_in_group("checkpoint_stateful"):
		add_to_group("checkpoint_stateful")
	input_pickable = false
	_setup_interaction_area()
	set_dependency_object(dependency_object)

func _exit_tree() -> void:
	_disconnect_dependency_listener()
	if _uses_interaction_manager():
		InteractionManager.unregister_candidate(self)
	_player_in_range = null
	_interaction_focused = false
	_hide_prompt()

func capture_checkpoint_state() -> Dictionary:
	return {
		"is_completed": is_completed,
		"handle_input": handle_input,
		"auto_prompt": auto_prompt,
		"prompts_enabled": _prompts_enabled,
		"dependency_request_satisfied": _dependency_request_satisfied,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	is_completed = bool(state.get("is_completed", is_completed))
	handle_input = bool(state.get("handle_input", handle_input))
	auto_prompt = bool(state.get("auto_prompt", auto_prompt))
	_prompts_enabled = bool(state.get("prompts_enabled", _prompts_enabled))
	_dependency_request_satisfied = bool(state.get("dependency_request_satisfied", _dependency_request_satisfied))
	_refresh_prompt_state()

func request_interact() -> void:
	if not _can_interact():
		fail_interaction(FAIL_REASON_DISABLED)
		return
	if not _is_dependency_satisfied():
		_show_locked_message()
		fail_interaction(FAIL_REASON_DEPENDENCY)
		return

	interaction_requested.emit(_player_in_range)
	_on_interact()
	
	if _should_auto_complete_after_interact():
		complete_interaction()

func complete_interaction(result_data: Dictionary = {}) -> Dictionary:
	is_completed = true
	var result := _emit_interaction_result(InteractionOutcome.SUCCEEDED, result_data)
	interaction_finished.emit()
	return result

func fail_interaction(reason: String = "", result_data: Dictionary = {}) -> Dictionary:
	var next_result := result_data.duplicate(true)
	var normalized_reason := reason.strip_edges()
	if normalized_reason != "" and not next_result.has(RESULT_REASON):
		next_result[RESULT_REASON] = normalized_reason
	return _emit_interaction_result(InteractionOutcome.FAILED, next_result)

func cancel_interaction(reason: String = FAIL_REASON_CANCELLED, result_data: Dictionary = {}) -> Dictionary:
	var next_result := result_data.duplicate(true)
	var normalized_reason := reason.strip_edges()
	if normalized_reason != "" and not next_result.has(RESULT_REASON):
		next_result[RESULT_REASON] = normalized_reason
	return _emit_interaction_result(InteractionOutcome.CANCELLED, next_result)

func get_last_interaction_result() -> Dictionary:
	return _last_interaction_result.duplicate(true)

func _on_interact() -> void:
	pass

func _should_auto_complete_after_interact() -> bool:
	return one_shot

func _show_locked_message() -> void:
	var localized_message := tr(locked_message)
	if UIMessage:
		UIMessage.show_notification(localized_message)
	else:
		print_verbose("LOCKED: " + localized_message)

func _setup_interaction_area() -> void:
	_interact_area = get_node_or_null(interact_area_node) as Area2D
	if _interact_area == null:
		_interact_area = self
	if _interact_area:
		if not _interact_area.body_entered.is_connected(_on_interact_area_body_entered):
			_interact_area.body_entered.connect(_on_interact_area_body_entered)
		if not _interact_area.body_exited.is_connected(_on_interact_area_body_exited):
			_interact_area.body_exited.connect(_on_interact_area_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _uses_interaction_manager():
		return
	if not handle_input:
		return
	if _player_in_range == null:
		return
	if event.is_action_pressed(_get_interact_action()):
		request_interact()

func _can_interact() -> bool:
	return true

func _get_interact_action() -> String:
	return "interact"

func get_interact_action_name() -> String:
	return _get_interact_action()

func is_manager_candidate() -> bool:
	return handle_input and is_player_in_range() and _can_interact()

func can_show_manager_prompt() -> bool:
	return auto_prompt and _allow_prompt_display()

func show_manager_prompt() -> void:
	_interaction_focused = true
	_refresh_prompt_state()

func hide_manager_prompt() -> void:
	_interaction_focused = false
	_hide_prompt()

func set_manager_focus(focused: bool) -> void:
	if _interaction_focused == focused:
		_refresh_prompt_state()
		return
	if focused:
		show_manager_prompt()
	else:
		hide_manager_prompt()

func get_interaction_sort_position() -> Vector2:
	return global_position

func _on_interact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = body
	if _uses_interaction_manager():
		InteractionManager.register_candidate(self, body)
	_on_player_entered(body)

func _on_interact_area_body_exited(body: Node) -> void:
	if body != _player_in_range:
		return
	if _uses_interaction_manager():
		InteractionManager.unregister_candidate(self)
	_player_in_range = null
	_on_player_exited(body)

func _on_player_entered(_player: Node) -> void:
	player_entered.emit(_player)
	_refresh_prompt_state()

func _on_player_exited(_player: Node) -> void:
	player_exited.emit(_player)
	_hide_prompt()

func _show_prompt() -> void:
	if not _allow_prompt_display():
		_hide_prompt()
		return
	if UIMessage:
		UIMessage.show_interact_prompt(self, _get_prompt_text())
	elif InteractionPrompts:
		InteractionPrompts.show_interact(self, _get_prompt_text())

func _hide_prompt() -> void:
	if UIMessage:
		UIMessage.hide_interact_prompt(self)
	elif InteractionPrompts:
		InteractionPrompts.hide_interact(self)

func _get_prompt_text() -> String:
	return tr(prompt_text)

func get_prompt_world_position() -> Vector2:
	var anchor := _interact_area
	if anchor == null:
		return to_global(prompt_offset)
	return anchor.to_global(prompt_offset)

func get_interacting_player() -> Node:
	return _player_in_range

func is_player_in_range() -> bool:
	return _player_in_range != null

func set_prompts_enabled(enabled: bool) -> void:
	_prompts_enabled = enabled
	_refresh_prompt_state()

func set_interaction_enabled(enabled: bool) -> void:
	handle_input = enabled
	set_prompts_enabled(enabled)
	_notify_interaction_manager_changed()

func refresh_interaction_state() -> void:
	_notify_interaction_manager_changed()
	_refresh_prompt_state()

func set_dependency_object(new_dependency: InteractiveObject) -> void:
	if dependency_object == new_dependency:
		_setup_dependency_listener()
		_refresh_prompt_state()
		_notify_interaction_manager_changed()
		return
	_disconnect_dependency_listener()
	dependency_object = new_dependency
	_dependency_request_satisfied = false
	_setup_dependency_listener()
	_refresh_prompt_state()
	_notify_interaction_manager_changed()

func set_dependency_condition(condition: int) -> void:
	var next_condition := _normalize_dependency_condition(condition)
	if dependency_condition == next_condition:
		_refresh_prompt_state()
		return
	dependency_condition = next_condition
	_dependency_request_satisfied = false
	_refresh_prompt_state()
	_notify_interaction_manager_changed()

func get_dependency_condition() -> int:
	return dependency_condition

func mark_dependency_request_satisfied() -> void:
	_dependency_request_satisfied = true
	_refresh_prompt_state()
	_notify_interaction_manager_changed()

func attach_minigame(minigame: Node, layer_override: int = -1, parent_override: Node = null) -> Node:
	if minigame == null:
		return null
	if MinigameController and MinigameController.has_method("attach_minigame"):
		MinigameController.attach_minigame(minigame, layer_override, parent_override)
		return minigame
	var parent := parent_override
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	if parent != null:
		parent.add_child(minigame)
	return minigame

func start_managed_minigame(minigame: Node, settings: Variant = null, layer_override: int = -1, parent_override: Node = null) -> Node:
	if minigame == null:
		return null
	attach_minigame(minigame, layer_override, parent_override)
	if settings != null and MinigameController and not MinigameController.is_active(minigame):
		MinigameController.start_minigame(minigame, settings)
	return minigame

func _setup_dependency_listener() -> void:
	if dependency_object == null:
		return
	if not is_instance_valid(dependency_object):
		return
	if not dependency_object.interaction_succeeded.is_connected(_on_dependency_succeeded):
		dependency_object.interaction_succeeded.connect(_on_dependency_succeeded)
	if not dependency_object.interaction_requested.is_connected(_on_dependency_interaction_requested):
		dependency_object.interaction_requested.connect(_on_dependency_interaction_requested)

func _disconnect_dependency_listener() -> void:
	if dependency_object == null:
		return
	if not is_instance_valid(dependency_object):
		return
	if dependency_object.interaction_succeeded.is_connected(_on_dependency_succeeded):
		dependency_object.interaction_succeeded.disconnect(_on_dependency_succeeded)
	if dependency_object.interaction_requested.is_connected(_on_dependency_interaction_requested):
		dependency_object.interaction_requested.disconnect(_on_dependency_interaction_requested)

func _on_dependency_succeeded(_result: Dictionary = {}) -> void:
	_on_dependency_finished()

func _on_dependency_finished() -> void:
	_refresh_prompt_state()
	_notify_interaction_manager_changed()

func _on_dependency_interaction_requested(_player: Node = null) -> void:
	if dependency_condition != DependencyCondition.INTERACTION_REQUESTED:
		return
	mark_dependency_request_satisfied()

func _is_dependency_satisfied() -> bool:
	if dependency_object == null:
		return true
	if dependency_object.is_completed:
		return true
	if dependency_condition == DependencyCondition.INTERACTION_REQUESTED:
		return _dependency_request_satisfied
	return false

func _normalize_dependency_condition(condition: int) -> int:
	match condition:
		DependencyCondition.INTERACTION_REQUESTED:
			return DependencyCondition.INTERACTION_REQUESTED
		_:
			return DependencyCondition.COMPLETED

func _emit_interaction_result(outcome: int, result_data: Dictionary = {}) -> Dictionary:
	var result := InteractionResultBuilder.build(
		outcome,
		outcome == InteractionOutcome.SUCCEEDED,
		self,
		_player_in_range,
		result_data
	)
	_last_interaction_result = result.duplicate(true)
	interaction_result.emit(result)
	match outcome:
		InteractionOutcome.SUCCEEDED:
			interaction_succeeded.emit(result)
		InteractionOutcome.CANCELLED:
			interaction_cancelled.emit(result)
		_:
			interaction_failed.emit(result)
	return result

func _is_interaction_available() -> bool:
	if not _can_interact():
		return false
	if not _is_dependency_satisfied():
		return false
	return true

func _allow_prompt_display() -> bool:
	if not _prompts_enabled:
		return false
	return _is_interaction_available()

func _refresh_prompt_state() -> void:
	if _player_in_range == null:
		_hide_prompt()
		return
	if _uses_interaction_manager() and not _interaction_focused:
		_hide_prompt()
		return
	if auto_prompt and _allow_prompt_display():
		_show_prompt()
	else:
		_hide_prompt()

func _uses_interaction_manager() -> bool:
	return InteractionManager != null and InteractionManager.has_method("register_candidate")

func _notify_interaction_manager_changed() -> void:
	if _uses_interaction_manager():
		InteractionManager.refresh_candidate(self)
