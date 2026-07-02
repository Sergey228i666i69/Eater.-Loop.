extends "res://tests/test_case.gd"

const GamepadConfirmReleaseGate = preload("res://levels/minigames/gamepad/gamepad_confirm_release_gate.gd")

func run() -> Array[String]:
	_test_confirm_passes_when_not_armed()
	_test_held_confirm_blocks_until_release()
	_test_gate_clears_when_confirm_is_no_longer_pressed()
	return get_failures()

func _test_confirm_passes_when_not_armed() -> void:
	var gate: RefCounted = GamepadConfirmReleaseGate.new()
	gate.arm(false)

	gate.update(_action("mg_confirm", true), true)

	assert_true(gate.accepts_confirm(_action("mg_confirm", true)), "Confirm must pass when the gate was not armed")

func _test_held_confirm_blocks_until_release() -> void:
	var gate: RefCounted = GamepadConfirmReleaseGate.new()
	gate.arm(true)

	gate.update(_action("mg_confirm", true), true)
	assert_true(gate.is_blocking_confirm(), "Held confirm must keep the gate armed")
	assert_true(not gate.accepts_confirm(_action("mg_confirm", true)), "Held confirm must be ignored until release")

	gate.update(_action("mg_confirm", false), true)
	assert_true(not gate.is_blocking_confirm(), "Confirm release must clear the gate")
	assert_true(gate.accepts_confirm(_action("mg_confirm", true)), "Confirm must pass after release clears the gate")

func _test_gate_clears_when_confirm_is_no_longer_pressed() -> void:
	var gate: RefCounted = GamepadConfirmReleaseGate.new()
	gate.arm(true)

	var confirm_event := _action("ui_accept", true)
	gate.update(confirm_event, false)

	assert_true(not gate.is_blocking_confirm(), "Gate must clear if no confirm action is currently pressed")
	assert_true(gate.accepts_confirm(confirm_event), "The same confirm event may pass after stale gate cleanup")

func _action(name: String, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	return event
