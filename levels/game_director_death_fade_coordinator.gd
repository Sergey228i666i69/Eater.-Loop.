extends RefCounted

const MIN_FADE_TIME := 0.01

func begin_fade(
	tween: Object,
	fade_rect: ColorRect,
	camera_coordinator: Object,
	raw_fade_duration: float,
	tilt_deg: float,
	zoom_mult: float,
	tilt_sign: float,
	completed: Callable
) -> bool:
	if tween == null:
		return false
	var fade_time := maxf(MIN_FADE_TIME, raw_fade_duration)
	_prepare_fade_rect(fade_rect)
	tween.set_parallel(true)
	if fade_rect != null:
		_configure_tweener(tween.tween_property(fade_rect, "color:a", 1.0, fade_time))
	if _camera_has_capture(camera_coordinator):
		camera_coordinator.tween_to_death_pose(tween, fade_time, tilt_deg, zoom_mult, tilt_sign)
	if completed.is_valid() and tween.has_signal("finished"):
		tween.connect("finished", completed)
	return true

func _prepare_fade_rect(fade_rect: ColorRect) -> void:
	if fade_rect == null:
		return
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 0)

func _camera_has_capture(camera_coordinator: Object) -> bool:
	if camera_coordinator == null:
		return false
	if not camera_coordinator.has_method("has_camera"):
		return false
	if not camera_coordinator.has_method("tween_to_death_pose"):
		return false
	return bool(camera_coordinator.has_camera())

func _configure_tweener(tweener: Object) -> void:
	if tweener == null:
		return
	tweener.set_trans(Tween.TRANS_SINE)
	tweener.set_ease(Tween.EASE_OUT)
