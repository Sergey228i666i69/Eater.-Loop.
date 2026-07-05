extends RefCounted

const InputDeviceUtilsClass := preload("res://global/input_device_utils.gd")
const INPUT_KIND_GAMEPAD := InputDeviceUtilsClass.InputKind.GAMEPAD

var _focus_style_hidden: StyleBoxEmpty

func apply_input_mode(retry_button: Button, cursor_manager: Object, owner: Object, input_kind: int) -> void:
	var using_gamepad := input_kind == INPUT_KIND_GAMEPAD
	_apply_retry_button_mode(retry_button, using_gamepad)
	_apply_cursor_mode(cursor_manager, owner, using_gamepad)

func release_cursor_request(cursor_manager: Object, owner: Object) -> void:
	if cursor_manager != null:
		cursor_manager.release_visible(owner)

func _apply_retry_button_mode(retry_button: Button, using_gamepad: bool) -> void:
	if retry_button == null:
		return
	if using_gamepad:
		if _focus_style_hidden == null:
			_focus_style_hidden = StyleBoxEmpty.new()
		retry_button.add_theme_stylebox_override("focus", _focus_style_hidden)
		if retry_button.is_inside_tree():
			retry_button.grab_focus()
		return
	retry_button.remove_theme_stylebox_override("focus")
	if retry_button.has_focus():
		retry_button.release_focus()

func _apply_cursor_mode(cursor_manager: Object, owner: Object, using_gamepad: bool) -> void:
	if cursor_manager == null:
		return
	if using_gamepad:
		release_cursor_request(cursor_manager, owner)
	else:
		cursor_manager.request_visible(owner)
