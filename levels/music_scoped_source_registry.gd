class_name MusicScopedSourceRegistry
extends RefCounted

var _sources: Dictionary = {}


func _init(sources: Dictionary = {}) -> void:
	_sources = sources


func register(source: Object, metadata: Dictionary = {}, exit_owner: Object = null, exit_method: StringName = &"") -> bool:
	if source == null:
		return false
	var source_id := source.get_instance_id()
	var is_new := not _sources.has(source_id)
	_sources[source_id] = metadata.duplicate(true)
	if is_new:
		_connect_tree_exit(source, exit_owner, exit_method, source_id)
	return is_new


func unregister_source(source: Object) -> int:
	if source == null:
		return 0
	var source_id := source.get_instance_id()
	unregister_id(source_id)
	return source_id


func unregister_id(source_id: int) -> void:
	_sources.erase(source_id)


func has_source(source: Object) -> bool:
	if source == null:
		return false
	return has_id(source.get_instance_id())


func has_id(source_id: int) -> bool:
	return _sources.has(source_id)


func get_metadata(source_id: int) -> Dictionary:
	var metadata: Variant = _sources.get(source_id, {})
	if metadata is Dictionary:
		return (metadata as Dictionary).duplicate(true)
	return {}


func clear() -> void:
	_sources.clear()


func snapshot() -> Dictionary:
	return _sources.duplicate(true)


func _connect_tree_exit(source: Object, exit_owner: Object, exit_method: StringName, source_id: int) -> void:
	if exit_owner == null or exit_method == &"":
		return
	if not source is Node:
		return
	var source_node := source as Node
	var on_exited := Callable(exit_owner, exit_method).bind(source_id)
	if not source_node.tree_exited.is_connected(on_exited):
		source_node.tree_exited.connect(on_exited, Object.CONNECT_ONE_SHOT)
