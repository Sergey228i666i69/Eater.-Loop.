extends Node

signal lab_completed
signal lab_completed_with_id(lab_id: String)
signal ate_this_cycle_changed(is_ate: bool)
signal phone_picked_changed
signal fridge_interacted_changed
signal electricity_changed(is_on: bool)
signal flashlight_collected_this_cycle_changed(is_collected: bool)
signal cycle_state_reset

enum Phase { NORMAL, DISTORTED }

const SAVE_SECTION := "cycle"

var _phase: Phase = Phase.NORMAL
var _ate_this_cycle: bool = false
var _lab_done: bool = false
var _completed_labs: PackedStringArray = PackedStringArray()
var _phone_picked: bool = false
var _fridge_interacted: bool = false
var _pending_sleep_spawn: bool = false
var _pending_respawn_blackout: bool = false
var _flashlight_collected_this_cycle: bool = false
var _electricity_on: bool = true
var electricity_on: bool:
	set(value):
		if _electricity_on == value:
			return
		_electricity_on = value
		electricity_changed.emit(_electricity_on)
	get:
		return _electricity_on

func is_electricity_on() -> bool:
	return _electricity_on

func set_phase(new_phase: Phase) -> void:
	_phase = new_phase

func get_phase() -> Phase:
	return _phase

func is_normal_phase() -> bool:
	return _phase == Phase.NORMAL

func is_distorted_phase() -> bool:
	return _phase == Phase.DISTORTED

func next_cycle() -> void:
	_reset_cycle_state_internal(true)

func reset_cycle_state() -> void:
	_reset_cycle_state_internal(true)

func reset_runtime_state_only() -> void:
	_reset_cycle_state_internal(false)

func mark_ate() -> void:
	if _ate_this_cycle:
		return
	_ate_this_cycle = true
	ate_this_cycle_changed.emit(_ate_this_cycle)
	_autosave_run()

func has_eaten_this_cycle() -> bool:
	return _ate_this_cycle

func mark_phone_picked() -> void:
	if _phone_picked:
		return
	_phone_picked = true
	phone_picked_changed.emit()
	_autosave_run()

func has_phone_picked() -> bool:
	return _phone_picked

func mark_fridge_interacted() -> void:
	if _fridge_interacted:
		return
	_fridge_interacted = true
	fridge_interacted_changed.emit()
	_autosave_run()

func is_fridge_interacted() -> bool:
	return _fridge_interacted

func mark_lab_completed(lab_id: String = "") -> void:
	var normalized_id := lab_id.strip_edges()
	var did_add_specific := false
	if normalized_id != "" and not _completed_labs.has(normalized_id):
		_completed_labs.append(normalized_id)
		did_add_specific = true
		lab_completed_with_id.emit(normalized_id)
	if not _lab_done:
		_lab_done = true
		lab_completed.emit()
	if did_add_specific or normalized_id == "":
		_autosave_run()

func is_lab_completed(lab_id: String = "") -> bool:
	var normalized_id := lab_id.strip_edges()
	if normalized_id == "":
		return _lab_done
	return _completed_labs.has(normalized_id)

func has_completed_any_lab() -> bool:
	return _lab_done

func get_completed_labs() -> PackedStringArray:
	return _completed_labs.duplicate()

func has_completed_all_labs(required_lab_ids: PackedStringArray) -> bool:
	if required_lab_ids.is_empty():
		return has_completed_any_lab()
	for lab_id in required_lab_ids:
		var normalized_id := String(lab_id).strip_edges()
		if normalized_id == "":
			continue
		if not _completed_labs.has(normalized_id):
			return false
	return true

func collect_flashlight_for_cycle() -> void:
	if _flashlight_collected_this_cycle:
		return
	_flashlight_collected_this_cycle = true
	flashlight_collected_this_cycle_changed.emit(true)
	_autosave_run()

func clear_flashlight_for_cycle() -> void:
	if not _flashlight_collected_this_cycle:
		return
	_flashlight_collected_this_cycle = false
	flashlight_collected_this_cycle_changed.emit(false)
	_autosave_run()

func has_flashlight_for_current_cycle() -> bool:
	if _flashlight_collected_this_cycle:
		return true
	if GameState != null and GameState.has_method("is_flashlight_unlocked"):
		return bool(GameState.is_flashlight_unlocked())
	return false

func has_flashlight_collected_this_cycle() -> bool:
	return _flashlight_collected_this_cycle

func queue_sleep_spawn() -> void:
	if _pending_sleep_spawn:
		return
	_pending_sleep_spawn = true
	_autosave_run()

func has_pending_sleep_spawn() -> bool:
	return _pending_sleep_spawn

func consume_pending_sleep_spawn() -> bool:
	if not _pending_sleep_spawn:
		return false
	_pending_sleep_spawn = false
	_autosave_run()
	return true

func queue_respawn_blackout() -> void:
	if _pending_respawn_blackout:
		return
	_pending_respawn_blackout = true
	_autosave_run()

func has_pending_respawn_blackout() -> bool:
	return _pending_respawn_blackout

func consume_pending_respawn_blackout() -> bool:
	if not _pending_respawn_blackout:
		return false
	_pending_respawn_blackout = false
	_autosave_run()
	return true

func write_save_data(config: ConfigFile) -> void:
	if config == null:
		return
	config.set_value(SAVE_SECTION, "phase", int(_phase))
	config.set_value(SAVE_SECTION, "ate_this_cycle", _ate_this_cycle)
	config.set_value(SAVE_SECTION, "lab_done", _lab_done)
	config.set_value(SAVE_SECTION, "completed_labs", _completed_labs)
	config.set_value(SAVE_SECTION, "phone_picked", _phone_picked)
	config.set_value(SAVE_SECTION, "fridge_interacted", _fridge_interacted)
	config.set_value(SAVE_SECTION, "pending_sleep_spawn", _pending_sleep_spawn)
	config.set_value(SAVE_SECTION, "pending_respawn_blackout", _pending_respawn_blackout)
	config.set_value(SAVE_SECTION, "electricity_on", electricity_on)
	config.set_value(SAVE_SECTION, "flashlight_collected_this_cycle", _flashlight_collected_this_cycle)

func export_checkpoint_state() -> Dictionary:
	return {
		"phase": int(_phase),
		"ate_this_cycle": _ate_this_cycle,
		"lab_done": _lab_done,
		"completed_labs": _completed_labs,
		"phone_picked": _phone_picked,
		"fridge_interacted": _fridge_interacted,
		"pending_sleep_spawn": _pending_sleep_spawn,
		"pending_respawn_blackout": _pending_respawn_blackout,
		"electricity_on": electricity_on,
		"flashlight_collected_this_cycle": _flashlight_collected_this_cycle,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	if state.is_empty():
		_reset_cycle_state_internal(false)
		return
	var raw_phase := int(state.get("phase", int(Phase.NORMAL)))
	if raw_phase < int(Phase.NORMAL) or raw_phase > int(Phase.DISTORTED):
		raw_phase = int(Phase.NORMAL)
	_phase = raw_phase as Phase
	_ate_this_cycle = bool(state.get("ate_this_cycle", false))
	_lab_done = bool(state.get("lab_done", false))
	var completed_labs_raw: Variant = state.get("completed_labs", [])
	_completed_labs = PackedStringArray(_coerce_string_array(completed_labs_raw))
	if not _lab_done and not _completed_labs.is_empty():
		_lab_done = true
	_phone_picked = bool(state.get("phone_picked", false))
	_fridge_interacted = bool(state.get("fridge_interacted", false))
	_pending_sleep_spawn = bool(state.get("pending_sleep_spawn", false))
	_pending_respawn_blackout = bool(state.get("pending_respawn_blackout", false))
	electricity_on = bool(state.get("electricity_on", true))
	_flashlight_collected_this_cycle = bool(state.get("flashlight_collected_this_cycle", false))

func load_save_data(config: ConfigFile) -> void:
	if config == null:
		_reset_cycle_state_internal(false)
		return
	_phase = Phase.NORMAL
	if config.has_section_key(SAVE_SECTION, "phase"):
		var raw_phase := int(config.get_value(SAVE_SECTION, "phase", int(Phase.NORMAL)))
		if raw_phase >= int(Phase.NORMAL) and raw_phase <= int(Phase.DISTORTED):
			_phase = raw_phase as Phase
	_ate_this_cycle = bool(config.get_value(SAVE_SECTION, "ate_this_cycle", false))
	_lab_done = bool(config.get_value(SAVE_SECTION, "lab_done", false))
	var completed_labs_raw: Variant = config.get_value(SAVE_SECTION, "completed_labs", [])
	_completed_labs = PackedStringArray(_coerce_string_array(completed_labs_raw))
	if not _lab_done and not _completed_labs.is_empty():
		_lab_done = true
	_phone_picked = bool(config.get_value(SAVE_SECTION, "phone_picked", false))
	_fridge_interacted = bool(config.get_value(SAVE_SECTION, "fridge_interacted", false))
	_pending_sleep_spawn = bool(config.get_value(SAVE_SECTION, "pending_sleep_spawn", false))
	_pending_respawn_blackout = bool(config.get_value(SAVE_SECTION, "pending_respawn_blackout", false))
	electricity_on = bool(config.get_value(SAVE_SECTION, "electricity_on", true))
	_flashlight_collected_this_cycle = bool(config.get_value(SAVE_SECTION, "flashlight_collected_this_cycle", false))

func _reset_cycle_state_internal(autosave_after_reset: bool) -> void:
	_phase = Phase.NORMAL
	_ate_this_cycle = false
	_lab_done = false
	_completed_labs = PackedStringArray()
	_phone_picked = false
	_fridge_interacted = false
	_pending_sleep_spawn = false
	_pending_respawn_blackout = false
	electricity_on = true
	_flashlight_collected_this_cycle = false
	ate_this_cycle_changed.emit(false)
	fridge_interacted_changed.emit()
	phone_picked_changed.emit()
	flashlight_collected_this_cycle_changed.emit(false)
	cycle_state_reset.emit()
	if autosave_after_reset:
		_autosave_run()

func _coerce_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	if value is PackedStringArray:
		for item in value:
			var text := str(item)
			if seen.has(text):
				continue
			seen[text] = true
			result.append(text)
		return result
	if value is Array:
		for item in value:
			var text := str(item)
			if seen.has(text):
				continue
			seen[text] = true
			result.append(text)
	return result

func _autosave_run() -> void:
	if GameState == null:
		return
	if GameState.has_method("autosave_run"):
		GameState.autosave_run()
