extends RefCounted

enum InputKind {
	UNKNOWN = -1,
	KEYBOARD = 0,
	GAMEPAD = 1,
	GAMEPAD_SONY = 2,
	GAMEPAD_OTHER = 3,
}

const DEFAULT_JOYPAD_MOTION_DEADZONE := 0.45
const DEFAULT_NAVIGATION_DEADZONE := 0.5
const SONY_JOYPAD_GUID_VENDOR_HINT := "054c"
const SONY_JOYPAD_NAME_HINTS := [
	"sony",
	"dualsense",
	"dualshock",
	"playstation",
	"wireless controller",
	"ps3",
	"ps4",
	"ps5",
]

static func resolve_input_kind(event: InputEvent, distinguish_sony: bool = false, joypad_motion_deadzone: float = DEFAULT_JOYPAD_MOTION_DEADZONE) -> int:
	if event == null or event.is_echo():
		return InputKind.UNKNOWN
	if event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		if not joy_button.pressed:
			return InputKind.UNKNOWN
		return _resolve_gamepad_kind(joy_button.device, distinguish_sony)
	if event is InputEventJoypadMotion:
		var joy_motion := event as InputEventJoypadMotion
		if absf(joy_motion.axis_value) < joypad_motion_deadzone:
			return InputKind.UNKNOWN
		return _resolve_gamepad_kind(joy_motion.device, distinguish_sony)
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return InputKind.KEYBOARD if key_event.pressed else InputKind.UNKNOWN
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return InputKind.KEYBOARD if mouse_button.pressed else InputKind.UNKNOWN
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		return InputKind.KEYBOARD if mouse_motion.relative.length_squared() > 0.0 else InputKind.UNKNOWN
	return InputKind.UNKNOWN

static func is_navigation_activation_event(event: InputEvent, joypad_motion_deadzone: float = DEFAULT_NAVIGATION_DEADZONE) -> bool:
	if event == null or event.is_echo():
		return false
	if event is InputEventKey:
		return event.is_action_pressed("ui_up") \
			or event.is_action_pressed("ui_down") \
			or event.is_action_pressed("ui_left") \
			or event.is_action_pressed("ui_right")
	if event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		return joy_button.pressed
	if event is InputEventJoypadMotion:
		var joy_motion := event as InputEventJoypadMotion
		return absf(joy_motion.axis_value) >= joypad_motion_deadzone
	return false

static func is_pointer_event(event: InputEvent) -> bool:
	return event is InputEventMouseButton or event is InputEventMouseMotion

static func is_sony_gamepad(device_id: int) -> bool:
	if device_id < 0:
		return false
	var joy_name := Input.get_joy_name(device_id).to_lower()
	for hint in SONY_JOYPAD_NAME_HINTS:
		if joy_name.find(hint) >= 0:
			return true
	var joy_guid := Input.get_joy_guid(device_id).to_lower()
	return joy_guid.find(SONY_JOYPAD_GUID_VENDOR_HINT) >= 0

static func _resolve_gamepad_kind(device_id: int, distinguish_sony: bool) -> int:
	if not distinguish_sony:
		return InputKind.GAMEPAD
	return InputKind.GAMEPAD_SONY if is_sony_gamepad(device_id) else InputKind.GAMEPAD_OTHER
