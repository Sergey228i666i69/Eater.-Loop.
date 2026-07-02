extends RefCounted

var _step_counter: int = 0
var _last_animation: StringName = StringName()
var _last_position: float = -1.0

func reset() -> void:
	_step_counter = 0
	_last_animation = StringName()
	_last_position = -1.0

func advance(is_moving: bool, animation_name: StringName, current_position: float, step_times: PackedFloat32Array) -> Array[int]:
	if not is_moving:
		reset()
		return []
	if step_times.is_empty():
		_last_animation = animation_name
		_last_position = current_position
		return []
	if _last_animation != animation_name or _last_position < 0.0:
		_last_animation = animation_name
		_last_position = current_position
		return []
	var wrapped := current_position < _last_position
	var crossed_steps: Array[int] = []
	for step_time in step_times:
		if _did_cross_step_time(_last_position, current_position, step_time, wrapped):
			_step_counter += 1
			crossed_steps.append(_step_counter)
	_last_position = current_position
	return crossed_steps

func _did_cross_step_time(previous_position: float, current_position: float, step_time: float, wrapped: bool) -> bool:
	if wrapped:
		return step_time > previous_position or step_time <= current_position
	return previous_position < step_time and step_time <= current_position
