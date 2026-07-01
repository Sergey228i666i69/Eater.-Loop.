extends RefCounted

const DistortionProgress = preload("res://levels/game_director_distortion_progress.gd")
const KEY_DISTORTION_ACTIVE := "distortion_active"
const KEY_DISTORTION_PROGRESS := "distortion_progress"
const KEY_TRANSITION_ACTIVE := "transition_active"
const KEY_TRANSITION_PROGRESS := "transition_progress"

var _distortion_active: bool = false
var _distortion_progress: float = 0.0
var _transition_active: bool = false
var _transition_progress: float = 0.0
var _flash_active: bool = false
var _damage_flash_active: bool = false
var _light_only_jump_active: bool = false
var _progress_helper: RefCounted = DistortionProgress.new()

func reset_for_normal_phase() -> void:
	_distortion_active = false
	_distortion_progress = 0.0
	_transition_active = false
	_transition_progress = 0.0
	_flash_active = false
	_damage_flash_active = false
	_light_only_jump_active = false

func activate_distortion_phase() -> void:
	_distortion_active = true
	_distortion_progress = 0.0
	_transition_active = true
	_transition_progress = 0.0
	_flash_active = false
	_damage_flash_active = false

func is_distortion_active() -> bool:
	return _distortion_active

func is_transition_active() -> bool:
	return _transition_active

func is_flash_active() -> bool:
	return _flash_active

func is_damage_flash_active() -> bool:
	return _damage_flash_active

func is_light_only_jump_active() -> bool:
	return _light_only_jump_active

func set_flash_active(value: bool) -> void:
	_flash_active = value

func set_damage_flash_active(value: bool) -> void:
	_damage_flash_active = value

func set_light_only_jump_active(value: bool) -> void:
	_light_only_jump_active = value

func has_active_visual_effects() -> bool:
	return _distortion_active or _transition_active or _damage_flash_active or _light_only_jump_active

func has_distortion_or_transition() -> bool:
	return _distortion_active or _transition_active

func advance_distortion(delta: float, duration: float) -> float:
	_distortion_progress = _progress_helper.advance_progress(_distortion_progress, delta, duration)
	return _progress_helper.ease_out(_distortion_progress)

func advance_transition(delta: float, duration: float) -> Dictionary:
	_transition_progress = _progress_helper.advance_progress(_transition_progress, delta, duration)
	var strength: float = _progress_helper.transition_strength(_transition_progress)
	var completed := _transition_progress >= 1.0
	if completed:
		_transition_active = false
	return {
		"strength": strength,
		"completed": completed,
	}

func capture_checkpoint_state() -> Dictionary:
	return {
		KEY_DISTORTION_ACTIVE: _distortion_active,
		KEY_DISTORTION_PROGRESS: _distortion_progress,
		KEY_TRANSITION_ACTIVE: _transition_active,
		KEY_TRANSITION_PROGRESS: _transition_progress,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	_distortion_active = bool(state.get(KEY_DISTORTION_ACTIVE, false))
	_distortion_progress = float(state.get(KEY_DISTORTION_PROGRESS, 0.0))
	_transition_active = bool(state.get(KEY_TRANSITION_ACTIVE, false))
	_transition_progress = float(state.get(KEY_TRANSITION_PROGRESS, 0.0))
	_flash_active = false
	_damage_flash_active = false
	_light_only_jump_active = false
