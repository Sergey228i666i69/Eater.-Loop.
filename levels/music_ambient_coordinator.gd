class_name MusicAmbientCoordinator
extends RefCounted

const DEFAULT_PENDING_VOLUME_DB := 999.0
const DEFAULT_PENDING_FADE_TIME := -1.0

var _suppression_state: MusicAmbientSuppressionState
var _pending_stream: AudioStream
var _pending_volume_db: float = DEFAULT_PENDING_VOLUME_DB
var _pending_fade_time: float = DEFAULT_PENDING_FADE_TIME


func _init(suppression_sources: Dictionary = {}) -> void:
	_suppression_state = MusicAmbientSuppressionState.new(suppression_sources)


func set_suppressed(source: Object, suppressed: bool, exit_owner: Object = null, exit_method: StringName = &"") -> bool:
	return _suppression_state.set_suppressed(source, suppressed, exit_owner, exit_method)


func unregister_id(source_id: int) -> bool:
	return _suppression_state.unregister_id(source_id)


func is_suppressed() -> bool:
	return _suppression_state.is_active()


func clear_suppression() -> void:
	_suppression_state.clear()


func set_pending(stream: AudioStream, mixed_volume_db: float, fade_time: float) -> void:
	_pending_stream = stream
	_pending_volume_db = mixed_volume_db
	_pending_fade_time = fade_time


func clear_pending() -> void:
	_pending_stream = null
	_pending_volume_db = DEFAULT_PENDING_VOLUME_DB
	_pending_fade_time = DEFAULT_PENDING_FADE_TIME


func has_pending() -> bool:
	return _pending_stream != null


func pending_stream() -> AudioStream:
	return _pending_stream


func pending_volume_db() -> float:
	return _pending_volume_db


func pending_fade_time() -> float:
	return _pending_fade_time


func consume_pending() -> Dictionary:
	if _pending_stream == null:
		return {}
	var request := {
		"stream": _pending_stream,
		"volume_db": _pending_volume_db,
		"fade_time": _pending_fade_time,
	}
	clear_pending()
	return request
