extends RefCounted

var _owner: Node
var _fade_rect: ColorRect
var _fade_tween: Tween
var _fade_token: int = 0


func _init(owner: Node, fade_rect: ColorRect) -> void:
	_owner = owner
	_fade_rect = fade_rect


func fade_out(duration: float = 0.5) -> void:
	if _fade_rect == null or _owner == null:
		return
	var token := _begin_fade_tween()
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_tween.tween_property(_fade_rect, "color:a", 1.0, maxf(0.0, duration))
	await _wait_for_fade_token(token)


func fade_in(duration: float = 0.5) -> void:
	if _fade_rect == null or _owner == null:
		return
	var token := _begin_fade_tween()
	_fade_tween.tween_property(_fade_rect, "color:a", 0.0, maxf(0.0, duration))
	await _wait_for_fade_token(token)
	if token == _fade_token:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_screen_dark(dark: bool) -> void:
	if _fade_rect == null:
		return
	_cancel_fade_tween()
	_fade_rect.color.a = 1.0 if dark else 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP if dark else Control.MOUSE_FILTER_IGNORE


func play_fade_sequence(fade_out_duration: float, fade_in_duration: float, on_black: Callable = Callable(), on_finished: Callable = Callable()) -> void:
	if _fade_rect == null or _owner == null:
		_call_if_valid(on_black)
		_call_if_valid(on_finished)
		return
	var token := _begin_fade_tween()
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var out_time: float = max(0.0, float(fade_out_duration))
	var in_time: float = max(0.0, float(fade_in_duration))
	_fade_tween.tween_property(_fade_rect, "color:a", 1.0, out_time)
	_fade_tween.tween_callback(Callable(self, "_invoke_callback_if_current").bind(token, on_black))
	_fade_tween.tween_property(_fade_rect, "color:a", 0.0, in_time)
	_fade_tween.tween_callback(Callable(self, "_finish_fade_sequence").bind(token, on_finished))


func is_screen_dark(threshold: float = 0.01) -> bool:
	if _fade_rect == null:
		return false
	return _fade_rect.color.a > threshold


func _invoke_callback_if_current(token: int, callback: Callable) -> void:
	if token != _fade_token:
		return
	_call_if_valid(callback)


func _finish_fade_sequence(token: int, callback: Callable) -> void:
	if token != _fade_token:
		return
	if _fade_rect != null:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_call_if_valid(callback)


func _begin_fade_tween() -> int:
	_cancel_fade_tween()
	_fade_token += 1
	_fade_tween = _owner.create_tween()
	return _fade_token


func _cancel_fade_tween() -> void:
	_fade_token += 1
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = null


func _wait_for_fade_token(token: int) -> void:
	while token == _fade_token and _fade_tween != null and _fade_tween.is_running():
		await _owner.get_tree().process_frame


func _call_if_valid(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()
