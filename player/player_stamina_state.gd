extends RefCounted

var allow_running: bool = true
var stamina_max: float = 5.0
var stamina_drain_rate: float = 1.0
var stamina_recovery_rate: float = 0.6
var stamina_recovery_delay: float = 2.0
var stamina_min_to_run: float = 0.2

var stamina: float = 0.0
var time_since_run: float = 0.0

func configure(
	p_allow_running: bool,
	p_stamina_max: float,
	p_stamina_drain_rate: float,
	p_stamina_recovery_rate: float,
	p_stamina_recovery_delay: float,
	p_stamina_min_to_run: float
) -> void:
	allow_running = p_allow_running
	stamina_max = p_stamina_max
	stamina_drain_rate = p_stamina_drain_rate
	stamina_recovery_rate = p_stamina_recovery_rate
	stamina_recovery_delay = p_stamina_recovery_delay
	stamina_min_to_run = p_stamina_min_to_run
	if stamina_max > 0.0:
		stamina = clampf(stamina, 0.0, stamina_max)
	else:
		stamina = 0.0

func reset_full() -> void:
	stamina = maxf(0.0, stamina_max)
	time_since_run = 0.0

func resolve_running(delta: float, direction: float, run_pressed: bool) -> bool:
	if not allow_running:
		time_since_run += delta
		_try_restore_stamina(delta)
		return false

	if direction == 0.0:
		time_since_run += delta
		_try_restore_stamina(delta)
		return false

	if stamina_max <= 0.0:
		if run_pressed:
			time_since_run = 0.0
		else:
			time_since_run += delta
		return run_pressed

	if run_pressed and stamina > stamina_min_to_run:
		time_since_run = 0.0
		_drain_stamina(delta)
		return true

	time_since_run += delta
	_try_restore_stamina(delta)
	return false

func get_ratio() -> float:
	if stamina_max <= 0.0:
		return 1.0
	return clampf(stamina / stamina_max, 0.0, 1.0)

func capture_checkpoint_state() -> Dictionary:
	return {
		"stamina": stamina,
		"time_since_run": time_since_run,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	stamina = float(state.get("stamina", stamina))
	time_since_run = float(state.get("time_since_run", time_since_run))
	if stamina_max > 0.0:
		stamina = clampf(stamina, 0.0, stamina_max)
	else:
		stamina = 0.0

func _drain_stamina(delta: float) -> void:
	if stamina_drain_rate <= 0.0:
		return
	stamina = maxf(0.0, stamina - stamina_drain_rate * delta)

func _restore_stamina(delta: float) -> void:
	if stamina_recovery_rate <= 0.0:
		return
	if stamina_max <= 0.0:
		return
	stamina = minf(stamina_max, stamina + stamina_recovery_rate * delta)

func _try_restore_stamina(delta: float) -> void:
	if time_since_run < stamina_recovery_delay:
		return
	_restore_stamina(delta)
