extends RefCounted

func reset(
	death_root: CanvasItem,
	glitch_background: CanvasItem,
	fade_rect: ColorRect,
	retry_button: Button,
	restore_camera: Callable,
	release_cursor: Callable,
	release_pause: Callable
) -> void:
	_call_if_valid(restore_camera)
	if death_root != null:
		death_root.visible = false
	if glitch_background != null:
		glitch_background.visible = false
	if fade_rect != null:
		fade_rect.visible = false
		fade_rect.color = Color(0, 0, 0, 0)
	if retry_button != null:
		retry_button.remove_theme_stylebox_override("focus")
	_call_if_valid(release_cursor)
	_call_if_valid(release_pause)

func _call_if_valid(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()
