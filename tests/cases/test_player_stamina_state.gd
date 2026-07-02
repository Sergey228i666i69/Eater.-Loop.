extends "res://tests/test_case.gd"

const PlayerStaminaState = preload("res://player/player_stamina_state.gd")

func run() -> Array[String]:
	_test_running_drains_stamina_and_stops_below_threshold()
	_test_recovery_waits_for_delay()
	_test_unlimited_stamina_runs_without_drain()
	_test_checkpoint_state_round_trips_and_clamps()
	return get_failures()

func _test_running_drains_stamina_and_stops_below_threshold() -> void:
	var state: RefCounted = PlayerStaminaState.new()
	state.configure(true, 1.0, 0.6, 0.5, 2.0, 0.2)
	state.reset_full()

	assert_true(state.resolve_running(1.0, 1.0, true), "Run must start when movement, run input and stamina are available")
	assert_true(_almost_eq(float(state.stamina), 0.4), "Running must drain stamina")
	assert_true(state.resolve_running(1.0, 1.0, true), "Run can continue when stamina was above threshold at frame start")
	assert_true(_almost_eq(float(state.stamina), 0.0), "Stamina drain must clamp at zero")
	assert_true(not state.resolve_running(0.1, 1.0, true), "Run must stop after stamina reaches the threshold floor")

func _test_recovery_waits_for_delay() -> void:
	var state: RefCounted = PlayerStaminaState.new()
	state.configure(true, 5.0, 1.0, 2.0, 2.0, 0.2)
	state.apply_checkpoint_state({"stamina": 1.0, "time_since_run": 0.0})

	assert_true(not state.resolve_running(1.0, 0.0, false), "Standing still must not run")
	assert_true(_almost_eq(float(state.stamina), 1.0), "Stamina must not recover before delay")
	assert_true(not state.resolve_running(1.5, 0.0, false), "Standing still after delay still must not run")
	assert_true(_almost_eq(float(state.stamina), 4.0), "Stamina must recover using the elapsed frame once delay has passed")

func _test_unlimited_stamina_runs_without_drain() -> void:
	var state: RefCounted = PlayerStaminaState.new()
	state.configure(true, 0.0, 100.0, 100.0, 0.0, 0.2)
	state.reset_full()

	assert_true(state.resolve_running(10.0, -1.0, true), "Zero stamina_max means unlimited run while input is held")
	assert_true(_almost_eq(float(state.get_ratio()), 1.0), "Unlimited stamina ratio must stay full")
	assert_true(not state.resolve_running(0.5, -1.0, false), "Unlimited stamina still requires run input")

func _test_checkpoint_state_round_trips_and_clamps() -> void:
	var state: RefCounted = PlayerStaminaState.new()
	state.configure(true, 3.0, 1.0, 1.0, 1.0, 0.2)
	state.apply_checkpoint_state({"stamina": 99.0, "time_since_run": 4.5})

	assert_true(_almost_eq(float(state.stamina), 3.0), "Checkpoint restore must clamp stamina to configured max")
	assert_true(_almost_eq(float(state.time_since_run), 4.5), "Checkpoint restore must keep time_since_run")
	assert_eq(state.capture_checkpoint_state(), {"stamina": 3.0, "time_since_run": 4.5}, "Checkpoint capture must preserve public keys")

func _almost_eq(left: float, right: float, epsilon: float = 0.0001) -> bool:
	return absf(left - right) <= epsilon
