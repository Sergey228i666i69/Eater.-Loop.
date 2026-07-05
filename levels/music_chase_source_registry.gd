class_name MusicChaseSourceRegistry
extends RefCounted

const DEFAULT_VOLUME_DB := 999.0
const DEFAULT_FADE_OUT_TIME := -1.0

var _sources: Dictionary = {}
var _source_order: Array[int] = []
var _suppressed: Dictionary = {}
var _active_source_id: int = 0
var _active_fade_out_time: float = DEFAULT_FADE_OUT_TIME


func _init(sources: Dictionary = {}, source_order: Array[int] = [], suppressed: Dictionary = {}) -> void:
	_sources = sources
	_source_order = source_order
	_suppressed = suppressed


func register_source(
	source: Object,
	stream: AudioStream = null,
	volume_db: float = DEFAULT_VOLUME_DB,
	fade_out_time: float = DEFAULT_FADE_OUT_TIME,
	exit_owner: Object = null,
	exit_method: StringName = &""
) -> bool:
	if source == null:
		return false
	var source_id := source.get_instance_id()
	var is_new := not _sources.has(source_id)
	_sources[source_id] = {
		"stream": stream,
		"volume_db": volume_db,
		"fade_out_time": fade_out_time,
	}
	if not _source_order.has(source_id):
		_source_order.append(source_id)
	if is_new:
		_connect_tree_exit(source, exit_owner, exit_method, source_id)
	return true


func unregister_source(source: Object) -> int:
	if source == null:
		return 0
	var source_id := source.get_instance_id()
	unregister_id(source_id)
	return source_id


func unregister_id(source_id: int) -> void:
	if source_id == 0:
		return
	_sources.erase(source_id)
	_suppressed.erase(source_id)
	_source_order.erase(source_id)
	if _active_source_id == source_id:
		clear_active_source()


func set_source_suppressed(source: Object, suppressed: bool) -> bool:
	if source == null:
		return false
	var source_id := source.get_instance_id()
	if suppressed:
		_suppressed[source_id] = true
	else:
		_suppressed.erase(source_id)
	return true


func next_source_id() -> int:
	for source_id in _source_order:
		if _sources.has(source_id) and not is_source_suppressed(source_id):
			return source_id
	return 0


func activate_source(source_id: int) -> Dictionary:
	if source_id == 0 or not _sources.has(source_id):
		clear_active_source()
		return {}
	_active_source_id = source_id
	var metadata := get_metadata(source_id)
	var fade_out_time := float(metadata.get("fade_out_time", DEFAULT_FADE_OUT_TIME))
	_active_fade_out_time = fade_out_time if fade_out_time >= 0.0 else DEFAULT_FADE_OUT_TIME
	return metadata


func clear_active_source() -> void:
	_active_source_id = 0
	_active_fade_out_time = DEFAULT_FADE_OUT_TIME


func clear() -> void:
	_sources.clear()
	_source_order.clear()
	_suppressed.clear()
	clear_active_source()


func is_empty() -> bool:
	return _sources.is_empty()


func is_source_suppressed(source_id: int) -> bool:
	return bool(_suppressed.get(source_id, false))


func active_source_id() -> int:
	return _active_source_id


func active_fade_out_time() -> float:
	return _active_fade_out_time


func get_metadata(source_id: int) -> Dictionary:
	var metadata: Variant = _sources.get(source_id, {})
	if metadata is Dictionary:
		return (metadata as Dictionary).duplicate(true)
	return {}


func snapshot() -> Dictionary:
	return {
		"sources": _sources.duplicate(true),
		"source_order": _source_order.duplicate(),
		"suppressed": _suppressed.duplicate(true),
		"active_source_id": _active_source_id,
		"active_fade_out_time": _active_fade_out_time,
	}


func _connect_tree_exit(source: Object, exit_owner: Object, exit_method: StringName, source_id: int) -> void:
	if exit_owner == null or exit_method == &"":
		return
	if not source is Node:
		return
	var source_node := source as Node
	var on_exited := Callable(exit_owner, exit_method).bind(source_id)
	if not source_node.tree_exited.is_connected(on_exited):
		source_node.tree_exited.connect(on_exited, Object.CONNECT_ONE_SHOT)
