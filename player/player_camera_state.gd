extends RefCounted
class_name PlayerCameraState

var smoothing_enabled: bool = true
var smoothing_speed: float = 6.0
var look_ahead_distance: float = 65.0
var look_ahead_run_multiplier: float = 1.35
var look_ahead_speed: float = 3.5

var _camera: Camera2D = null
var _base_position: Vector2 = Vector2.ZERO
var _base_offset: Vector2 = Vector2.ZERO
var _current_look_ahead: Vector2 = Vector2.ZERO
var _target_look_ahead: Vector2 = Vector2.ZERO

func configure(
	p_smoothing_enabled: bool,
	p_smoothing_speed: float,
	p_look_ahead_distance: float,
	p_look_ahead_run_multiplier: float,
	p_look_ahead_speed: float
) -> void:
	smoothing_enabled = p_smoothing_enabled
	smoothing_speed = maxf(0.1, p_smoothing_speed)
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
	_camera.position_smoothing_enabled = smoothing_enabled
	_camera.position_smoothing_speed = smoothing_speed

func update(
	delta: float,
	facing_dir: float,
	is_moving: bool,
	is_running: bool,
	is_blocked: bool
) -> void:
	if not has_camera():
		return
	
	if not smoothing_enabled or look_ahead_distance <= 0.0 or is_blocked:
		_target_look_ahead = Vector2.ZERO
	elif is_moving and absf(facing_dir) > 0.01:
		var dist := look_ahead_distance * (look_ahead_run_multiplier if is_running else 1.0)
		_target_look_ahead = Vector2(signf(facing_dir) * dist, 0.0)
	else:
		_target_look_ahead = Vector2.ZERO

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
