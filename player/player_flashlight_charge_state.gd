extends RefCounted

const RESULT_FORCE_DISABLE := "force_disable"
const RESULT_TOGGLE_DISABLE := "toggle_disable"
const RESULT_RECHARGED := "recharged"

var use_duration: float = 5.0
var recharge_duration: float = 5.0
var recharge_delay: float = 1.0

var charge: float = 0.0
var time_since_use: float = 0.0

func configure(p_use_duration: float, p_recharge_duration: float, p_recharge_delay: float) -> void:
	use_duration = p_use_duration
	recharge_duration = p_recharge_duration
	recharge_delay = p_recharge_delay
	var max_charge := _max_charge()
	charge = clampf(charge, 0.0, max_charge)

func reset_full() -> void:
	charge = _max_charge()
	time_since_use = maxf(0.0, recharge_delay)

func update(delta: float, enabled: bool, available: bool) -> Dictionary:
	var result := {
		RESULT_FORCE_DISABLE: false,
		RESULT_TOGGLE_DISABLE: false,
		RESULT_RECHARGED: false,
	}
	var effective_enabled := enabled
	if enabled and not available:
		result[RESULT_FORCE_DISABLE] = true
		effective_enabled = false

	var max_charge := _max_charge()
	charge = clampf(charge, 0.0, max_charge)
	if max_charge <= 0.0:
		return result

	if effective_enabled:
		time_since_use = 0.0
		charge = maxf(0.0, charge - delta)
		if charge <= 0.0:
			result[RESULT_TOGGLE_DISABLE] = true
		return result

	time_since_use += delta
	if time_since_use < maxf(0.0, recharge_delay):
		return result

	if recharge_duration <= 0.0:
		var was_below_full := charge < max_charge
		charge = max_charge
		result[RESULT_RECHARGED] = was_below_full
		return result

	var previous_charge := charge
	var recharge_rate := max_charge / recharge_duration
	charge = minf(max_charge, charge + recharge_rate * delta)
	result[RESULT_RECHARGED] = previous_charge < max_charge and charge >= max_charge
	return result

func can_enable() -> bool:
	if use_duration <= 0.0:
		return true
	return charge > 0.0

func get_ratio() -> float:
	if use_duration <= 0.0:
		return 1.0
	return clampf(charge / use_duration, 0.0, 1.0)

func capture_checkpoint_state() -> Dictionary:
	return {
		"flashlight_charge": charge,
		"time_since_flashlight_use": time_since_use,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	charge = float(state.get("flashlight_charge", charge))
	time_since_use = float(state.get("time_since_flashlight_use", time_since_use))
	charge = clampf(charge, 0.0, _max_charge())

func _max_charge() -> float:
	return maxf(0.0, use_duration)
