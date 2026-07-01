extends RefCounted

var _camera: Camera2D = null
var _base_rotation: float = 0.0
var _base_zoom: Vector2 = Vector2.ONE
var _base_offset: Vector2 = Vector2.ZERO

func capture(camera: Camera2D) -> void:
	_camera = null
	_base_rotation = 0.0
	_base_zoom = Vector2.ONE
	_base_offset = Vector2.ZERO
	if camera == null or not is_instance_valid(camera):
		return
	_camera = camera
	_base_rotation = camera.rotation
	_base_zoom = camera.zoom
	_base_offset = camera.offset

func has_camera() -> bool:
	return _camera != null and is_instance_valid(_camera)

func build_death_targets(tilt_deg: float, zoom_mult: float, tilt_sign: float) -> Dictionary:
	return {
		"rotation": _base_rotation + deg_to_rad(tilt_deg) * tilt_sign,
		"zoom": _base_zoom * zoom_mult,
	}

func tween_to_death_pose(tween: Tween, fade_time: float, tilt_deg: float, zoom_mult: float, tilt_sign: float) -> void:
	if tween == null or not has_camera():
		return
	var targets := build_death_targets(tilt_deg, zoom_mult, tilt_sign)
	tween.tween_property(_camera, "rotation", float(targets["rotation"]), fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_camera, "zoom", targets["zoom"], fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func restore() -> void:
	if has_camera():
		_camera.rotation = _base_rotation
		_camera.zoom = _base_zoom
		_camera.offset = _base_offset
	_camera = null
