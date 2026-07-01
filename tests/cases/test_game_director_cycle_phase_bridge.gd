extends "res://tests/test_case.gd"

const CyclePhaseBridge = preload("res://levels/game_director_cycle_phase_bridge.gd")

class FakeCycleState:
	extends RefCounted
	enum Phase { NORMAL, DISTORTED }
	var phase: int = Phase.NORMAL
	var set_calls: Array[int] = []

	func set_phase(new_phase: int) -> void:
		phase = new_phase
		set_calls.append(new_phase)

	func is_normal_phase() -> bool:
		return phase == Phase.NORMAL

	func is_distorted_phase() -> bool:
		return phase == Phase.DISTORTED

func run() -> Array[String]:
	_test_null_cycle_state_keeps_legacy_timer_defaults()
	_test_phase_queries_and_setters_delegate_to_cycle_state()
	_test_missing_phase_methods_are_safe()
	return get_failures()

func _test_null_cycle_state_keeps_legacy_timer_defaults() -> void:
	var bridge: RefCounted = CyclePhaseBridge.new()

	assert_true(bridge.can_run_timer(null), "Missing CycleState must keep the legacy timer-runnable fallback")
	assert_true(not bridge.has_normal_state(null), "Missing CycleState must not count as a normal state for checkpoint restore")
	assert_true(not bridge.is_distorted(null), "Missing CycleState must not count as distorted")
	bridge.set_normal(null)
	bridge.set_distorted(null)

func _test_phase_queries_and_setters_delegate_to_cycle_state() -> void:
	var bridge: RefCounted = CyclePhaseBridge.new()
	var cycle_state := FakeCycleState.new()

	assert_true(bridge.can_run_timer(cycle_state), "Normal phase must allow the timer")
	assert_true(bridge.has_normal_state(cycle_state), "Normal phase must be restorable as normal")
	assert_true(not bridge.is_distorted(cycle_state), "Normal phase must not be distorted")

	bridge.set_distorted(cycle_state)
	assert_eq(cycle_state.phase, FakeCycleState.Phase.DISTORTED, "set_distorted must set the distorted phase")
	assert_eq(cycle_state.set_calls[-1], FakeCycleState.Phase.DISTORTED, "set_distorted must delegate to CycleState")
	assert_true(not bridge.can_run_timer(cycle_state), "Distorted phase must stop timer logic")
	assert_true(not bridge.has_normal_state(cycle_state), "Distorted phase must not restore as normal")
	assert_true(bridge.is_distorted(cycle_state), "Distorted phase must be reported")

	bridge.set_normal(cycle_state)
	assert_eq(cycle_state.phase, FakeCycleState.Phase.NORMAL, "set_normal must set the normal phase")
	assert_eq(cycle_state.set_calls[-1], FakeCycleState.Phase.NORMAL, "set_normal must delegate to CycleState")

func _test_missing_phase_methods_are_safe() -> void:
	var bridge: RefCounted = CyclePhaseBridge.new()
	var plain_object := RefCounted.new()

	assert_true(bridge.can_run_timer(plain_object), "Unknown CycleState-like object must keep the explicit fallback")
	assert_true(not bridge.has_normal_state(plain_object), "Unknown CycleState-like object must not count as normal state")
	assert_true(not bridge.is_distorted(plain_object), "Unknown CycleState-like object must not count as distorted")
	bridge.set_normal(plain_object)
	bridge.set_distorted(plain_object)
