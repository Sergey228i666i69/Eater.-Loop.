extends "res://tests/test_case.gd"

const GamepadNavigationRepeat = preload("res://levels/minigames/gamepad/gamepad_navigation_repeat.gd")


func run() -> Array[String]:
	_test_repeats_start_after_delay_and_follow_interval()
	_test_direction_change_and_release_reset_repeat_state()
	_test_repeat_timings_are_clamped()
	return get_failures()


func _test_repeats_start_after_delay_and_follow_interval() -> void:
	var repeat := GamepadNavigationRepeat.new()
	repeat.configure(0.3, 0.1)
	repeat.prime(Vector2.RIGHT)

	assert_eq(repeat.consume_repeats(Vector2.RIGHT, 0.2), 0, "Hold must not repeat before the configured delay")
	assert_eq(repeat.consume_repeats(Vector2.RIGHT, 0.1), 1, "Hold must emit first repeat when delay is reached")
	assert_eq(repeat.consume_repeats(Vector2.RIGHT, 0.25), 2, "Hold must emit one repeat per accumulated interval")
	assert_eq(repeat.consume_repeats(Vector2.RIGHT, 0.06), 1, "Hold must keep remainder after multi-repeat frames")


func _test_direction_change_and_release_reset_repeat_state() -> void:
	var repeat := GamepadNavigationRepeat.new()
	repeat.configure(0.2, 0.1)
	repeat.prime(Vector2.LEFT)

	assert_eq(repeat.consume_repeats(Vector2.LEFT, 0.2), 2, "Initial held direction must use configured repeat timing")
	assert_eq(repeat.consume_repeats(Vector2.RIGHT, 0.5), 0, "Changing direction must re-prime before repeating")
	assert_eq(repeat.get_held_direction(), Vector2.RIGHT, "Changing direction must become the new held direction")
	assert_eq(repeat.consume_repeats(Vector2.ZERO, 1.0), 0, "Releasing navigation must not emit repeats")
	assert_eq(repeat.get_held_direction(), Vector2.ZERO, "Releasing navigation must clear held direction")
	assert_eq(repeat.consume_repeats(Vector2.RIGHT, 0.5), 0, "Pressing after release must prime before repeating")


func _test_repeat_timings_are_clamped() -> void:
	var repeat := GamepadNavigationRepeat.new()
	repeat.configure(0.0, 0.0)
	repeat.prime(Vector2.DOWN)

	assert_eq(repeat.consume_repeats(Vector2.DOWN, 0.04), 0, "Repeat delay must clamp to a small positive minimum")
	assert_eq(repeat.consume_repeats(Vector2.DOWN, 0.05), 1, "Repeat interval must clamp to a small positive minimum")
