@tool
extends RefCounted

## Keeps a fixed brush-stamp grid across arbitrary mouse-motion event chunks.

const MIN_SPACING := 0.001
const ENDPOINT_EPSILON := 0.25

var _active := false
var _last_input_position := Vector2.ZERO
var _last_stamp_position := Vector2.ZERO
var _spacing := 1.0
var _distance_until_next_stamp := 1.0

func begin(start_position: Vector2, spacing: float) -> PackedVector2Array:
	_active = true
	_last_input_position = start_position
	_last_stamp_position = start_position
	_spacing = maxf(spacing, MIN_SPACING)
	_distance_until_next_stamp = _spacing
	return PackedVector2Array([start_position])

func sample(input_position: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not _active:
		return points
	var segment := input_position - _last_input_position
	var distance := segment.length()
	if distance <= 0.0001:
		_last_input_position = input_position
		return points
	var direction := segment / distance
	var traveled := 0.0
	var distance_to_next := _distance_until_next_stamp
	while traveled + distance_to_next <= distance + 0.0001:
		traveled += distance_to_next
		points.append(_last_input_position + direction * traveled)
		distance_to_next = _spacing
	var leftover := maxf(0.0, distance - traveled)
	_distance_until_next_stamp = maxf(MIN_SPACING, distance_to_next - leftover)
	_last_input_position = input_position
	if not points.is_empty():
		_last_stamp_position = points[points.size() - 1]
	return points

func finish(include_endpoint: bool = true) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not _active:
		return points
	if include_endpoint and _last_stamp_position.distance_to(_last_input_position) > ENDPOINT_EPSILON:
		points.append(_last_input_position)
	_active = false
	return points

func cancel() -> void:
	_active = false

func is_active() -> bool:
	return _active
