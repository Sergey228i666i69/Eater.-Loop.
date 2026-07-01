extends RefCounted

const CHECKPOINT_PENDING_KEY := "pending_distortion_activation"

var _minigame_active: bool = false
var _minigame_blocks_distortion: bool = false
var _pending_activation: bool = false

func reset_for_scene() -> void:
	_minigame_active = false
	_minigame_blocks_distortion = false
	_pending_activation = false

func clear_pending_activation() -> void:
	_pending_activation = false

func mark_pending_activation() -> void:
	_pending_activation = true

func has_pending_activation() -> bool:
	return _pending_activation

func is_minigame_active() -> bool:
	return _minigame_active

func is_distortion_allowed(in_game_scene: bool) -> bool:
	if not in_game_scene:
		return false
	return not (_minigame_active and _minigame_blocks_distortion)

func should_defer_activation(death_sequence_active: bool) -> bool:
	if death_sequence_active:
		return false
	return _minigame_active and _minigame_blocks_distortion

func on_minigame_started(allows_distortion: bool) -> void:
	_minigame_active = true
	_minigame_blocks_distortion = not allows_distortion

func on_minigame_finished() -> bool:
	_minigame_active = false
	_minigame_blocks_distortion = false
	if not _pending_activation:
		return false
	_pending_activation = false
	return true

func capture_checkpoint_state() -> Dictionary:
	return {
		CHECKPOINT_PENDING_KEY: _pending_activation,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	_pending_activation = bool(state.get(CHECKPOINT_PENDING_KEY, false))
