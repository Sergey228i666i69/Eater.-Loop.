extends RefCounted

const CONFIRM_ACTIONS: Array[StringName] = [&"mg_confirm", &"ui_accept"]

var _blocking_confirm: bool = false

func arm(confirm_pressed_at_start: bool) -> void:
	_blocking_confirm = confirm_pressed_at_start

func clear() -> void:
	_blocking_confirm = false

func update(event: InputEvent, confirm_pressed_now: bool) -> void:
	if not _blocking_confirm:
		return
	if _event_released_confirm(event):
		_blocking_confirm = false
		return
	if confirm_pressed_now:
		return
	_blocking_confirm = false

func accepts_confirm(event: InputEvent) -> bool:
	if not _event_pressed_confirm(event):
		return false
	return not _blocking_confirm

func is_blocking_confirm() -> bool:
	return _blocking_confirm

func _event_pressed_confirm(event: InputEvent) -> bool:
	if event == null:
		return false
	for action in CONFIRM_ACTIONS:
		if event.is_action_pressed(action):
			return true
	return false

func _event_released_confirm(event: InputEvent) -> bool:
	if event == null:
		return false
	for action in CONFIRM_ACTIONS:
		if event.is_action_released(action):
			return true
	return false
