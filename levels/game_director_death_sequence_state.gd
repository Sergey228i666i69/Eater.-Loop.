extends RefCounted

var _active: bool = false
var _pause_requested: bool = false

func try_begin() -> bool:
	if _active:
		return false
	_active = true
	return true

func reset_sequence() -> void:
	_active = false

func is_active() -> bool:
	return _active

func mark_pause_requested() -> bool:
	if _pause_requested:
		return false
	_pause_requested = true
	return true

func mark_pause_released() -> bool:
	if not _pause_requested:
		return false
	_pause_requested = false
	return true

func has_pause_request() -> bool:
	return _pause_requested
