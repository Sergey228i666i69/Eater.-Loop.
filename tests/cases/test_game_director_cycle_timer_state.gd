extends "res://tests/test_case.gd"

const CycleTimerState = preload("res://levels/game_director_cycle_timer_state.gd")

func run() -> Array[String]:
	await _test_start_normal_phase_uses_default_and_supports_disabled_timer()
	await _test_time_left_and_timeout_contracts()
	await _test_checkpoint_restore_respects_cycle_state_gate()
	return get_failures()

func _test_start_normal_phase_uses_default_and_supports_disabled_timer() -> void:
	var timer := await _make_tree_timer()
	var state: RefCounted = CycleTimerState.new()

	var started: Dictionary = state.start_normal_phase(timer, -1.0, 7.0)
	assert_true(bool(started["enabled"]), "Default timer duration must start the timer")
	assert_eq(float(started["duration"]), 7.0, "Default timer duration must be reported")
	assert_eq(state.get_current_max_time(), 7.0, "Current max time must store the resolved default duration")
	assert_true(not timer.is_stopped(), "Started timer must be running")

	var disabled: Dictionary = state.start_normal_phase(timer, 0.0, 7.0)
	assert_true(not bool(disabled["enabled"]), "Zero timer duration must disable the timer")
	assert_eq(state.get_current_max_time(), 0.0, "Disabled timer must clear current max time")
	assert_true(timer.is_stopped(), "Disabled timer must be stopped")
	timer.queue_free()

func _test_time_left_and_timeout_contracts() -> void:
	var timer := await _make_tree_timer()
	var state: RefCounted = CycleTimerState.new()
	state.start_normal_phase(timer, 10.0, 7.0)

	assert_true(state.is_timer_running(timer, true), "Running timer must report active in normal phase")
	assert_true(not state.is_timer_running(timer, false), "Running timer must report inactive outside normal phase")
	assert_true(state.get_time_ratio(timer, true) > 0.0, "Time ratio must be positive while timer runs")
	assert_eq(state.get_time_ratio(timer, false), 0.0, "Time ratio must be zero outside normal phase")

	assert_true(not state.set_time_left(timer, true, 4.0), "Positive time left must not request timeout")
	assert_true(timer.time_left > 0.0 and timer.time_left <= 4.0, "set_time_left must clamp timer to the requested range")
	assert_true(state.set_time_left(timer, true, 0.0), "Zero time left must request distortion timeout")
	assert_true(timer.is_stopped(), "Zero time left must stop the timer")
	assert_eq(state.get_time_left(timer, true), 10.0, "Stopped normal-phase timer must report full current max time")
	assert_eq(state.get_time_left(timer, false), 0.0, "Stopped timer without normal CycleState must report zero")

	assert_true(not state.ensure_timer_running(timer, false, 5.0), "ensure_timer_running must ignore non-normal phases")
	assert_true(timer.is_stopped(), "Non-normal ensure must not start the timer")
	assert_true(state.ensure_timer_running(timer, true, 5.0), "ensure_timer_running must start a stopped normal timer")
	assert_eq(state.get_current_max_time(), 5.0, "ensure_timer_running must update current max time")
	timer.queue_free()

func _test_checkpoint_restore_respects_cycle_state_gate() -> void:
	var timer := await _make_tree_timer()
	var state: RefCounted = CycleTimerState.new()
	state.apply_checkpoint_state(timer, true, {
		"current_max_time": 9.0,
		"current_timer_duration": 6.0,
		"time_left": 4.0,
		"timer_running": true,
	})

	assert_eq(state.get_current_max_time(), 9.0, "Checkpoint restore must keep current max time")
	assert_eq(state.get_current_timer_duration(), 6.0, "Checkpoint restore must keep configured timer duration")
	assert_true(not timer.is_stopped(), "Normal checkpoint restore must restart a running timer")
	assert_true(timer.time_left > 0.0 and timer.time_left <= 4.0, "Checkpoint restore must clamp restored time left")

	state.apply_checkpoint_state(timer, false, {
		"current_max_time": 9.0,
		"current_timer_duration": 6.0,
		"time_left": 4.0,
		"timer_running": true,
	})
	assert_true(timer.is_stopped(), "Checkpoint restore without a normal CycleState must keep the timer stopped")

	state.set_current_timer_duration(11.0)
	state.start_normal_phase(timer, 8.0, 7.0)
	var checkpoint: Dictionary = state.capture_checkpoint_state(timer, true, false)
	assert_eq(float(checkpoint["current_max_time"]), 8.0, "Checkpoint capture must include current max time")
	assert_eq(float(checkpoint["current_timer_duration"]), 11.0, "Checkpoint capture must include configured timer duration")
	assert_true(bool(checkpoint["timer_running"]), "Checkpoint capture must include running state")
	assert_true(float(checkpoint["time_left"]) > 0.0, "Checkpoint capture must include remaining time")
	timer.queue_free()

func _make_tree_timer() -> Timer:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	var timer := Timer.new()
	timer.one_shot = true
	if tree != null:
		tree.root.add_child(timer)
		await tree.process_frame
	return timer
