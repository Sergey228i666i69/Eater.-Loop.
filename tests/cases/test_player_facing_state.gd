extends "res://tests/test_case.gd"

const PlayerFacingState = preload("res://player/player_facing_state.gd")

func run() -> Array[String]:
	_test_direction_input_updates_only_on_nonzero_direction()
	_test_checkpoint_state_round_trips_normalized_facing()
	_test_checkpoint_restore_ignores_invalid_or_zero_facing()
	return get_failures()

func _test_direction_input_updates_only_on_nonzero_direction() -> void:
	var state: RefCounted = PlayerFacingState.new()

	assert_eq(state.get_direction(), 1.0, "Player facing must default to right")
	assert_true(state.set_from_direction(-0.2), "Negative input must flip facing left")
	assert_eq(state.get_direction(), -1.0, "Negative input must normalize to left")
	assert_true(not state.set_from_direction(-1.0), "Same-direction input must not report a visual update")
	assert_true(not state.set_from_direction(0.0), "Zero input must keep the last facing")
	assert_eq(state.get_direction(), -1.0, "Zero input must not erase previous facing")
	assert_true(state.set_from_direction(3.0), "Positive input must flip facing right")
	assert_eq(state.get_direction(), 1.0, "Positive input must normalize to right")

func _test_checkpoint_state_round_trips_normalized_facing() -> void:
	var state: RefCounted = PlayerFacingState.new()
	state.apply_checkpoint_state({"facing_dir": -99.0})

	assert_eq(state.capture_checkpoint_state(), {"facing_dir": -1.0}, "Checkpoint capture must store normalized left-facing state")

	var restored: RefCounted = PlayerFacingState.new()
	restored.apply_checkpoint_state(state.capture_checkpoint_state())

	assert_eq(restored.get_direction(), -1.0, "Checkpoint restore must preserve normalized left-facing state")

func _test_checkpoint_restore_ignores_invalid_or_zero_facing() -> void:
	var state: RefCounted = PlayerFacingState.new()
	state.set_from_direction(-1.0)

	state.apply_checkpoint_state({"facing_dir": 0.0})
	assert_eq(state.get_direction(), -1.0, "Zero checkpoint facing must keep the previous nonzero facing")

	state.apply_checkpoint_state({"facing_dir": "left"})
	assert_eq(state.get_direction(), -1.0, "Non-numeric checkpoint facing must keep the previous nonzero facing")

	state.apply_checkpoint_state({"facing_dir": 4.0})
	assert_eq(state.get_direction(), 1.0, "Positive checkpoint facing must normalize to right")
