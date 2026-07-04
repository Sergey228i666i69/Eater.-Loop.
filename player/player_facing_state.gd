extends RefCounted

const DEFAULT_FACING := 1.0

var facing_dir: float = DEFAULT_FACING

func set_from_direction(direction: float) -> bool:
	if is_zero_approx(direction):
		return false
	var next_facing := _normalize_number(direction, facing_dir)
	if is_equal_approx(next_facing, facing_dir):
		return false
	facing_dir = next_facing
	return true

func get_direction() -> float:
	return facing_dir

func capture_checkpoint_state() -> Dictionary:
	return {"facing_dir": facing_dir}

func apply_checkpoint_state(state: Dictionary) -> void:
	facing_dir = _normalize_variant(state.get("facing_dir", facing_dir), facing_dir)

func _normalize_variant(value: Variant, fallback: float) -> float:
	var value_type := typeof(value)
	if value_type == TYPE_FLOAT or value_type == TYPE_INT:
		return _normalize_number(float(value), fallback)
	return _normalize_number(fallback, DEFAULT_FACING)

func _normalize_number(value: float, fallback: float) -> float:
	if value < 0.0:
		return -1.0
	if value > 0.0:
		return 1.0
	if fallback < 0.0:
		return -1.0
	return 1.0
