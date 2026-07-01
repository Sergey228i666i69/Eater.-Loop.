extends RefCounted

const CycleStateScript = preload("res://levels/cycles/cycle_state.gd")

func set_normal(cycle_state: Object) -> void:
	_set_phase(cycle_state, CycleStateScript.Phase.NORMAL)

func set_distorted(cycle_state: Object) -> void:
	_set_phase(cycle_state, CycleStateScript.Phase.DISTORTED)

func can_run_timer(cycle_state: Object) -> bool:
	return _is_normal(cycle_state, true)

func has_normal_state(cycle_state: Object) -> bool:
	return _is_normal(cycle_state, false)

func is_distorted(cycle_state: Object) -> bool:
	if cycle_state == null:
		return false
	if not cycle_state.has_method("is_distorted_phase"):
		return false
	return bool(cycle_state.call("is_distorted_phase"))

func _is_normal(cycle_state: Object, fallback: bool) -> bool:
	if cycle_state == null:
		return fallback
	if not cycle_state.has_method("is_normal_phase"):
		return fallback
	return bool(cycle_state.call("is_normal_phase"))

func _set_phase(cycle_state: Object, phase_value: int) -> void:
	if cycle_state == null:
		return
	if not cycle_state.has_method("set_phase"):
		return
	cycle_state.call("set_phase", phase_value)
