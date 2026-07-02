extends RefCounted

var _time_limit: float = -1.0
var _time_left: float = 0.0
var _auto_finish_on_timeout: bool = false
var _timeout_emitted: bool = false


func setup(limit: float, auto_finish_on_timeout: bool) -> void:
	_timeout_emitted = false
	_auto_finish_on_timeout = auto_finish_on_timeout
	_time_limit = float(limit)
	if _time_limit > 0.0:
		_time_left = _time_limit
	else:
		_time_left = 0.0


func clear() -> void:
	_time_limit = -1.0
	_time_left = 0.0
	_auto_finish_on_timeout = false
	_timeout_emitted = false


func update(delta: float) -> Dictionary:
	if _time_limit <= 0.0:
		return {}
	_time_left = max(0.0, _time_left - delta)
	var expired := false
	if _time_left <= 0.0 and not _timeout_emitted:
		_timeout_emitted = true
		expired = true
	return {
		"updated": true,
		"expired": expired,
		"time_left": _time_left,
		"time_limit": _time_limit,
		"auto_finish_on_timeout": _auto_finish_on_timeout
	}


func get_time_left() -> float:
	return _time_left


func get_time_limit() -> float:
	return _time_limit
