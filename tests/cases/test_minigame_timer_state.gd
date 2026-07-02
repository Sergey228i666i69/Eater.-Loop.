extends "res://tests/test_case.gd"

const MinigameTimerState = preload("res://levels/minigames/minigame_timer_state.gd")


func run() -> Array[String]:
	_test_inactive_timer_does_not_emit_updates()
	_test_timer_reports_updates_and_single_expiration()
	_test_clear_resets_public_time_values()
	return get_failures()


func _test_inactive_timer_does_not_emit_updates() -> void:
	var state := MinigameTimerState.new()
	state.setup(0.0, true)

	assert_true(state.update(0.5).is_empty(), "Timer with a zero time limit must stay inactive")
	assert_eq(state.get_time_left(), 0.0, "Inactive timer must expose zero time left")
	assert_eq(state.get_time_limit(), 0.0, "Inactive timer must keep the configured zero time limit")


func _test_timer_reports_updates_and_single_expiration() -> void:
	var state := MinigameTimerState.new()
	state.setup(1.0, true)

	var first_tick := state.update(0.4)
	assert_true(bool(first_tick.get("updated", false)), "Active timer must report regular updates")
	assert_true(not bool(first_tick.get("expired", false)), "Timer must not expire before reaching zero")
	assert_true(is_equal_approx(float(first_tick.get("time_left", 0.0)), 0.6), "Timer must subtract delta from time left")
	assert_true(is_equal_approx(float(first_tick.get("time_limit", 0.0)), 1.0), "Timer must report the original time limit")

	var expiration := state.update(0.6)
	assert_true(bool(expiration.get("expired", false)), "Timer must expire when it reaches zero")
	assert_true(bool(expiration.get("auto_finish_on_timeout", false)), "Timer must carry the auto-finish policy")

	var after_expiration := state.update(0.6)
	assert_true(bool(after_expiration.get("updated", false)), "Expired timer must keep reporting update ticks")
	assert_true(not bool(after_expiration.get("expired", false)), "Timer expiration must be emitted once per setup")
	assert_true(is_equal_approx(float(after_expiration.get("time_left", -1.0)), 0.0), "Timer must clamp time left at zero")


func _test_clear_resets_public_time_values() -> void:
	var state := MinigameTimerState.new()
	state.setup(2.0, true)
	state.update(0.5)
	state.clear()

	assert_eq(state.get_time_left(), 0.0, "Cleared timer must expose zero time left")
	assert_eq(state.get_time_limit(), -1.0, "Cleared timer must return the inactive sentinel time limit")
	assert_true(state.update(0.5).is_empty(), "Cleared timer must not report updates")
