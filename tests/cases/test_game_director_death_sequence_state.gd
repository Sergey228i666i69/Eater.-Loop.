extends "res://tests/test_case.gd"

const DeathSequenceState = preload("res://levels/game_director_death_sequence_state.gd")

func run() -> Array[String]:
	_test_begin_is_idempotent_until_reset()
	_test_pause_request_lifecycle_is_idempotent()
	_test_sequence_reset_keeps_pause_owner_for_explicit_release()
	return get_failures()

func _test_begin_is_idempotent_until_reset() -> void:
	var state: RefCounted = DeathSequenceState.new()

	assert_true(state.try_begin(), "Death sequence must start from an inactive state")
	assert_true(state.is_active(), "Death sequence must expose active state after start")
	assert_true(not state.try_begin(), "Death sequence must reject duplicate starts")

	state.reset_sequence()

	assert_true(not state.is_active(), "Death sequence reset must clear active state")
	assert_true(state.try_begin(), "Death sequence must be startable after reset")

func _test_pause_request_lifecycle_is_idempotent() -> void:
	var state: RefCounted = DeathSequenceState.new()

	assert_true(state.mark_pause_requested(), "First death pause request must be accepted")
	assert_true(state.has_pause_request(), "Death pause request state must be visible")
	assert_true(not state.mark_pause_requested(), "Duplicate death pause request must be ignored")
	assert_true(state.mark_pause_released(), "First death pause release must be accepted")
	assert_true(not state.has_pause_request(), "Death pause release must clear request state")
	assert_true(not state.mark_pause_released(), "Duplicate death pause release must be ignored")

func _test_sequence_reset_keeps_pause_owner_for_explicit_release() -> void:
	var state: RefCounted = DeathSequenceState.new()

	state.try_begin()
	state.mark_pause_requested()
	state.reset_sequence()

	assert_true(not state.is_active(), "Death sequence reset must clear active state")
	assert_true(state.has_pause_request(), "Death sequence reset must not silently drop a pending pause owner")
	assert_true(state.mark_pause_released(), "Pending pause owner must remain releasable after sequence reset")
