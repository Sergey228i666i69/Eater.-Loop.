extends RefCounted

const KEY_CURRENT_MAX_TIME := "current_max_time"
const KEY_CURRENT_TIMER_DURATION := "current_timer_duration"
const KEY_TIME_LEFT := "time_left"
const KEY_TIMER_RUNNING := "timer_running"

var _current_max_time: float = 1.0
var _current_timer_duration: float = 0.0

func get_current_max_time() -> float:
	return _current_max_time

func set_current_timer_duration(value: float) -> void:
	_current_timer_duration = value

func get_current_timer_duration() -> float:
	return _current_timer_duration

func start_normal_phase(timer: Timer, timer_duration: float, default_time: float) -> Dictionary:
	var time_to_set := timer_duration
	if time_to_set < 0.0:
		time_to_set = default_time
	if time_to_set > 0.0:
		_current_max_time = time_to_set
		if timer != null:
			timer.start(time_to_set)
		return {
			"enabled": true,
			"duration": time_to_set,
		}
	_current_max_time = 0.0
	if timer != null:
		timer.stop()
	return {
		"enabled": false,
		"duration": 0.0,
	}

func get_time_ratio(timer: Timer, timer_can_run: bool) -> float:
	if not timer_can_run:
		return 0.0
	if timer == null or timer.is_stopped() or _current_max_time <= 0.0:
		return 1.0
	return timer.time_left / _current_max_time

func get_time_left(timer: Timer, stopped_counts_as_full_duration: bool) -> float:
	if _current_max_time <= 0.0:
		return 0.0
	if timer == null or timer.is_stopped():
		if stopped_counts_as_full_duration:
			return _current_max_time
		return 0.0
	return timer.time_left

func is_timer_running(timer: Timer, timer_can_run: bool) -> bool:
	if not timer_can_run:
		return false
	return timer != null and _current_max_time > 0.0 and not timer.is_stopped()

func ensure_timer_running(timer: Timer, timer_can_run: bool, fallback_time: float) -> bool:
	if fallback_time <= 0.0:
		return false
	if not timer_can_run:
		return false
	if is_timer_running(timer, timer_can_run):
		return false
	_current_max_time = fallback_time
	if timer != null:
		timer.start(fallback_time)
	return true

func set_time_left(timer: Timer, timer_can_run: bool, new_time: float) -> bool:
	if not timer_can_run:
		return false
	if _current_max_time <= 0.0:
		return false
	var clamped_time := clampf(new_time, 0.0, _current_max_time)
	if clamped_time <= 0.0:
		if timer != null:
			timer.stop()
		return true
	if timer != null:
		timer.start(clamped_time)
	return false

func capture_checkpoint_state(timer: Timer, timer_can_run: bool, stopped_counts_as_full_duration: bool) -> Dictionary:
	return {
		KEY_CURRENT_MAX_TIME: _current_max_time,
		KEY_CURRENT_TIMER_DURATION: _current_timer_duration,
		KEY_TIME_LEFT: get_time_left(timer, stopped_counts_as_full_duration),
		KEY_TIMER_RUNNING: is_timer_running(timer, timer_can_run),
	}

func apply_checkpoint_state(timer: Timer, should_restore_timer: bool, state: Dictionary) -> void:
	_current_timer_duration = float(state.get(KEY_CURRENT_TIMER_DURATION, _current_timer_duration))
	_current_max_time = float(state.get(KEY_CURRENT_MAX_TIME, _current_max_time))
	if timer == null:
		return
	if should_restore_timer and _current_max_time > 0.0:
		var timer_running := bool(state.get(KEY_TIMER_RUNNING, false))
		var time_left := clampf(float(state.get(KEY_TIME_LEFT, _current_max_time)), 0.0, _current_max_time)
		if timer_running and time_left > 0.0:
			timer.start(time_left)
		else:
			timer.stop()
	else:
		timer.stop()
