extends "res://tests/test_case.gd"

const PlayerSkeletonStepState = preload("res://player/player_skeleton_step_state.gd")

func run() -> Array[String]:
	_test_first_sample_only_arms_step_tracking()
	_test_crossed_step_times_increment_in_order()
	_test_wrapped_clip_crosses_late_and_early_steps()
	_test_stop_resets_counter_and_previous_position()
	return get_failures()

func _test_first_sample_only_arms_step_tracking() -> void:
	var state: RefCounted = PlayerSkeletonStepState.new()
	var steps: Array = state.advance(true, &"walk", 0.25, PackedFloat32Array([0.2, 0.6]))

	assert_eq(steps, [], "First moving sample must not emit a synthetic step")

func _test_crossed_step_times_increment_in_order() -> void:
	var state: RefCounted = PlayerSkeletonStepState.new()
	state.advance(true, &"walk", 0.1, PackedFloat32Array([0.2, 0.6]))

	assert_eq(state.advance(true, &"walk", 0.3, PackedFloat32Array([0.2, 0.6])), [1], "Crossing one step time must emit step counter 1")
	assert_eq(state.advance(true, &"walk", 0.7, PackedFloat32Array([0.2, 0.6])), [2], "Crossing the next step time must emit step counter 2")

func _test_wrapped_clip_crosses_late_and_early_steps() -> void:
	var state: RefCounted = PlayerSkeletonStepState.new()
	state.advance(true, &"walk", 0.8, PackedFloat32Array([0.2, 0.6]))

	assert_eq(state.advance(true, &"walk", 0.25, PackedFloat32Array([0.2, 0.6])), [1], "Wrapped playback must catch early clip step times")

func _test_stop_resets_counter_and_previous_position() -> void:
	var state: RefCounted = PlayerSkeletonStepState.new()
	state.advance(true, &"walk", 0.1, PackedFloat32Array([0.2, 0.6]))
	state.advance(true, &"walk", 0.3, PackedFloat32Array([0.2, 0.6]))

	assert_eq(state.advance(false, &"walk", 0.4, PackedFloat32Array([0.2, 0.6])), [], "Stopping must not emit steps")
	assert_eq(state.advance(true, &"walk", 0.7, PackedFloat32Array([0.2, 0.6])), [], "First moving sample after stop must re-arm tracking")
	assert_eq(state.advance(true, &"walk", 0.9, PackedFloat32Array([0.2, 0.6])), [], "Counter must stay reset when no step time is crossed")
	assert_eq(state.advance(true, &"walk", 0.25, PackedFloat32Array([0.2, 0.6])), [1], "Counter must restart from 1 after stop and wrap")
