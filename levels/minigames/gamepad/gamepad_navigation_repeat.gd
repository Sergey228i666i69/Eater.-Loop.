extends RefCounted

const MIN_REPEAT_TIME := 0.05

var _held_dir := Vector2.ZERO
var _held_elapsed := 0.0
var _repeat_accumulator := 0.0
var _repeat_delay: float = 0.28
var _repeat_interval: float = 0.12


func configure(delay: float, interval: float) -> void:
	_repeat_delay = maxf(MIN_REPEAT_TIME, delay)
	_repeat_interval = maxf(MIN_REPEAT_TIME, interval)


func clear() -> void:
	_held_dir = Vector2.ZERO
	_held_elapsed = 0.0
	_repeat_accumulator = 0.0


func prime(direction: Vector2) -> void:
	_held_dir = direction
	_held_elapsed = 0.0
	_repeat_accumulator = 0.0


func consume_repeats(direction: Vector2, delta: float) -> int:
	if direction == Vector2.ZERO:
		clear()
		return 0
	if direction != _held_dir:
		prime(direction)
		return 0
	_held_elapsed += delta
	if _held_elapsed < _repeat_delay:
		return 0
	_repeat_accumulator += delta
	var repeat_count := 0
	while _repeat_accumulator >= _repeat_interval:
		_repeat_accumulator -= _repeat_interval
		repeat_count += 1
	return repeat_count


func get_held_direction() -> Vector2:
	return _held_dir
