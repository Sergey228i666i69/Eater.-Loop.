class_name MusicAmbientSuppressionState
extends RefCounted

var _sources: Dictionary = {}


func _init(sources: Dictionary = {}) -> void:
	_sources = sources


func set_suppressed(source: Object, suppressed: bool, exit_owner: Object = null, exit_method: StringName = &"") -> bool:
	if source == null:
		return false
	cleanup_stale()
	var was_active := is_active()
	var source_id := source.get_instance_id()
	if suppressed:
		_sources[source_id] = weakref(source)
		_connect_tree_exit(source, exit_owner, exit_method, source_id)
	else:
		_sources.erase(source_id)
	cleanup_stale()
	return was_active != is_active()


func unregister_id(source_id: int) -> bool:
	if not _sources.has(source_id):
		return false
	_sources.erase(source_id)
	return true


func has_id(source_id: int) -> bool:
	cleanup_stale()
	return _sources.has(source_id)


func is_active() -> bool:
	cleanup_stale()
	return not _sources.is_empty()


func clear() -> void:
	_sources.clear()


func snapshot() -> Dictionary:
	cleanup_stale()
	return _sources.duplicate()


func cleanup_stale() -> void:
	if _sources.is_empty():
		return
	var stale_ids: Array[int] = []
	for id in _sources.keys():
		var ref_value: Variant = _sources[id]
		if ref_value is WeakRef:
			var wref := ref_value as WeakRef
			if wref.get_ref() == null:
				stale_ids.append(id)
	for id in stale_ids:
		_sources.erase(id)


func _connect_tree_exit(source: Object, exit_owner: Object, exit_method: StringName, source_id: int) -> void:
	if exit_owner == null or exit_method == &"":
		return
	if not source is Node:
		return
	var source_node := source as Node
	var on_exited := Callable(exit_owner, exit_method).bind(source_id)
	if not source_node.tree_exited.is_connected(on_exited):
		source_node.tree_exited.connect(on_exited, Object.CONNECT_ONE_SHOT)
