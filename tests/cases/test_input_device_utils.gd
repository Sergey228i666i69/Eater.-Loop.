extends "res://tests/test_case.gd"

const InputDeviceUtilsClass := preload("res://global/input_device_utils.gd")

func run() -> Array[String]:
	_test_resolve_keyboard_pointer_and_gamepad_kind()
	_test_navigation_activation()
	return get_failures()

func _test_resolve_keyboard_pointer_and_gamepad_kind() -> void:
	var key := InputEventKey.new()
	key.pressed = true
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(key), InputDeviceUtilsClass.InputKind.KEYBOARD, "Pressed key must resolve as keyboard")
	key.pressed = false
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(key), InputDeviceUtilsClass.InputKind.UNKNOWN, "Released key must be ignored")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(3.0, 0.0)
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(mouse_motion), InputDeviceUtilsClass.InputKind.KEYBOARD, "Mouse motion must resolve as keyboard/pointer input")
	mouse_motion.relative = Vector2.ZERO
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(mouse_motion), InputDeviceUtilsClass.InputKind.UNKNOWN, "Zero mouse motion must be ignored")

	var joy_button := InputEventJoypadButton.new()
	joy_button.pressed = true
	joy_button.device = -1
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(joy_button), InputDeviceUtilsClass.InputKind.GAMEPAD, "GameDirector-style detection must resolve any pressed joypad button as gamepad")
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(joy_button, true), InputDeviceUtilsClass.InputKind.GAMEPAD_OTHER, "Prompt-style detection must classify unknown joypad devices as non-Sony gamepad")

	var joy_motion := InputEventJoypadMotion.new()
	joy_motion.axis_value = 0.2
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(joy_motion), InputDeviceUtilsClass.InputKind.UNKNOWN, "Small joypad motion must stay below the default deadzone")
	joy_motion.axis_value = 0.8
	assert_eq(InputDeviceUtilsClass.resolve_input_kind(joy_motion), InputDeviceUtilsClass.InputKind.GAMEPAD, "Large joypad motion must resolve as gamepad")

func _test_navigation_activation() -> void:
	var joy_motion := InputEventJoypadMotion.new()
	joy_motion.axis_value = 0.49
	assert_true(not InputDeviceUtilsClass.is_navigation_activation_event(joy_motion), "Navigation helper must ignore motion below navigation deadzone")
	joy_motion.axis_value = 0.5
	assert_true(InputDeviceUtilsClass.is_navigation_activation_event(joy_motion), "Navigation helper must accept motion at navigation deadzone")

	var joy_button := InputEventJoypadButton.new()
	joy_button.pressed = true
	assert_true(InputDeviceUtilsClass.is_navigation_activation_event(joy_button), "Pressed joypad buttons must activate navigation")
	joy_button.pressed = false
	assert_true(not InputDeviceUtilsClass.is_navigation_activation_event(joy_button), "Released joypad buttons must not activate navigation")

	var mouse_button := InputEventMouseButton.new()
	mouse_button.pressed = true
	assert_true(InputDeviceUtilsClass.is_pointer_event(mouse_button), "Mouse buttons must be pointer events")
	assert_true(not InputDeviceUtilsClass.is_navigation_activation_event(mouse_button), "Pointer events must not activate keyboard/gamepad navigation")
