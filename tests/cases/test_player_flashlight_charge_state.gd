extends "res://tests/test_case.gd"

const FlashlightChargeState = preload("res://player/player_flashlight_charge_state.gd")

func run() -> Array[String]:
	_test_enabled_flashlight_drains_and_requests_toggle_disable()
	_test_unavailable_flashlight_requests_silent_force_disable()
	_test_recharge_waits_for_delay_and_emits_once_when_full()
	_test_instant_recharge_fills_and_emits_once()
	_test_checkpoint_state_round_trips_and_clamps()
	return get_failures()

func _test_enabled_flashlight_drains_and_requests_toggle_disable() -> void:
	var state: RefCounted = FlashlightChargeState.new()
	state.configure(5.0, 5.0, 1.0)
	state.reset_full()

	var result: Dictionary = state.update(2.0, true, true)
	assert_true(not bool(result[FlashlightChargeState.RESULT_TOGGLE_DISABLE]), "Partially drained flashlight must stay enabled")
	assert_true(_almost_eq(float(state.charge), 3.0), "Enabled flashlight must drain charge")
	assert_true(_almost_eq(float(state.time_since_use), 0.0), "Enabled flashlight must reset recharge delay timer")

	result = state.update(4.0, true, true)
	assert_true(bool(result[FlashlightChargeState.RESULT_TOGGLE_DISABLE]), "Empty flashlight must request normal toggle disable")
	assert_true(_almost_eq(float(state.charge), 0.0), "Flashlight charge must clamp at zero")

func _test_unavailable_flashlight_requests_silent_force_disable() -> void:
	var state: RefCounted = FlashlightChargeState.new()
	state.configure(5.0, 5.0, 1.0)
	state.reset_full()

	var result: Dictionary = state.update(0.25, true, false)

	assert_true(bool(result[FlashlightChargeState.RESULT_FORCE_DISABLE]), "Unavailable flashlight must request silent force disable")
	assert_true(not bool(result[FlashlightChargeState.RESULT_TOGGLE_DISABLE]), "Unavailable flashlight must not use the audible depleted-toggle path")

func _test_recharge_waits_for_delay_and_emits_once_when_full() -> void:
	var state: RefCounted = FlashlightChargeState.new()
	state.configure(4.0, 2.0, 1.0)
	state.apply_checkpoint_state({"flashlight_charge": 1.0, "time_since_flashlight_use": 0.0})

	var result: Dictionary = state.update(0.5, false, true)
	assert_true(not bool(result[FlashlightChargeState.RESULT_RECHARGED]), "Flashlight must not recharge before delay")
	assert_true(_almost_eq(float(state.charge), 1.0), "Charge must stay fixed before recharge delay")

	result = state.update(0.5, false, true)
	assert_true(not bool(result[FlashlightChargeState.RESULT_RECHARGED]), "Partial recharge must not emit full recharge")
	assert_true(_almost_eq(float(state.charge), 2.0), "Charge must begin recovering once delay is met")

	result = state.update(2.0, false, true)
	assert_true(bool(result[FlashlightChargeState.RESULT_RECHARGED]), "Recharge must emit when charge reaches full")
	assert_true(_almost_eq(float(state.charge), 4.0), "Recharge must clamp at full charge")

	result = state.update(1.0, false, true)
	assert_true(not bool(result[FlashlightChargeState.RESULT_RECHARGED]), "Full flashlight must not emit repeated recharge events")

func _test_instant_recharge_fills_and_emits_once() -> void:
	var state: RefCounted = FlashlightChargeState.new()
	state.configure(5.0, 0.0, 0.5)
	state.apply_checkpoint_state({"flashlight_charge": 2.0, "time_since_flashlight_use": 0.5})

	var result: Dictionary = state.update(0.0, false, true)
	assert_true(bool(result[FlashlightChargeState.RESULT_RECHARGED]), "Instant recharge must emit when it fills from below full")
	assert_true(_almost_eq(float(state.charge), 5.0), "Instant recharge must fill charge")

	result = state.update(0.0, false, true)
	assert_true(not bool(result[FlashlightChargeState.RESULT_RECHARGED]), "Instant recharge must not emit when already full")

func _test_checkpoint_state_round_trips_and_clamps() -> void:
	var state: RefCounted = FlashlightChargeState.new()
	state.configure(3.0, 1.0, 1.0)
	state.apply_checkpoint_state({"flashlight_charge": 99.0, "time_since_flashlight_use": 2.5})

	assert_true(_almost_eq(float(state.charge), 3.0), "Checkpoint restore must clamp flashlight charge to max")
	assert_true(_almost_eq(float(state.time_since_use), 2.5), "Checkpoint restore must keep recharge delay timer")
	assert_eq(
		state.capture_checkpoint_state(),
		{"flashlight_charge": 3.0, "time_since_flashlight_use": 2.5},
		"Checkpoint capture must preserve Player-compatible keys"
	)
	assert_true(state.can_enable(), "Restored non-empty flashlight must be enableable")

func _almost_eq(left: float, right: float, epsilon: float = 0.0001) -> bool:
	return absf(left - right) <= epsilon
