extends RefCounted
class_name PlayerCameraState

var look_ahead_enabled: bool = true
var look_ahead_distance: float = 38.0
var look_ahead_run_multiplier: float = 1.25
var look_ahead_speed: float = 2.5

var _camera: Camera2D = null
var _base_position: Vector2 = Vector2.ZERO
var _base_offset: Vector2 = Vector2.ZERO
var _current_look_ahead: Vector2 = Vector2.ZERO
var _target_look_ahead: Vector2 = Vector2.ZERO

func configure(
	p_look_ahead_enabled: bool,
	p_look_ahead_distance: float,
	p_look_ahead_run_multiplier: float,
	p_look_ahead_speed: float
) -> void:
	look_ahead_enabled = p_look_ahead_enabled
	look_ahead_distance = maxf(0.0, p_look_ahead_distance)
	look_ahead_run_multiplier = maxf(1.0, p_look_ahead_run_multiplier)
	look_ahead_speed = maxf(0.1, p_look_ahead_speed)
	_apply_camera_settings()

func bind_camera(camera: Camera2D) -> void:
	_camera = camera
	if _camera == null:
		return
	_base_position = _camera.position
	_base_offset = _camera.offset
	_apply_camera_settings()
	snap_to_target()

func has_camera() -> bool:
	return _camera != null and is_instance_valid(_camera)

func get_camera() -> Camera2D:
	return _camera

func get_look_ahead_offset() -> Vector2:
	return _current_look_ahead

func get_base_position() -> Vector2:
	return _base_position

func _apply_camera_settings() -> void:
	if not has_camera():
		return
	# Keep position smoothing disabled on the Camera2D node to ensure
	# the player character and viewport remain crisp and rock-solid
	# without sub-pixel sprite jitter or rubber-band rebound on stop.
	_camera.position_smoothing_enabled = false

func update(
	delta: float,
	facing_dir: float,
	is_moving: bool,
	is_running: bool,
	is_blocked: bool
) -> void:
	if not has_camera():
		return
	
	if not look_ahead_enabled or look_ahead_distance <= 0.0 or is_blocked:
		_target_look_ahead = Vector2.ZERO
	else:
		var dir := signf(facing_dir) if absf(facing_dir) > 0.01 else 1.0
		var mult := (look_ahead_run_multiplier if (is_moving and is_running) else 1.0)
		_target_look_ahead = Vector2(dir * look_ahead_distance * mult, 0.0)

	var alpha: float = 1.0 - exp(-look_ahead_speed * maxf(0.0001, delta))
	_current_look_ahead = _current_look_ahead.lerp(_target_look_ahead, alpha)
	_camera.position = _base_position + _current_look_ahead

func snap_to_target() -> void:
	if not has_camera():
		return
	_current_look_ahead = _target_look_ahead
	_camera.position = _base_position + _current_look_ahead
	_camera.reset_smoothing()

func teleport_to(player: Node2D, target_global_position: Vector2) -> void:
	if player != null and is_instance_valid(player):
		player.global_position = target_global_position
		if player is CharacterBody2D:
			(player as CharacterBody2D).velocity = Vector2.ZERO
	snap_to_target()
