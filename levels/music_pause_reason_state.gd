class_name MusicPauseReasonState
extends RefCounted

var _reasons: Dictionary = {}

func request(reason: String) -> bool:
	var key := reason.strip_edges()
	if key == "":
		return false
	var was_active := is_active()
	_reasons[key] = true
	return not was_active

func release(reason: String) -> bool:
	var key := reason.strip_edges()
	if key == "" or not _reasons.has(key):
		return false
	_reasons.erase(key)
	return not is_active()

func clear() -> void:
	_reasons.clear()

func is_active() -> bool:
	return not _reasons.is_empty()

func has_reason(reason: String) -> bool:
	return _reasons.has(reason.strip_edges())

func get_reasons() -> Dictionary:
	return _reasons.duplicate()
