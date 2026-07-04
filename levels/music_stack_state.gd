class_name MusicStackState
extends RefCounted

var _entries: Array[Dictionary] = []


func _init(entries: Array[Dictionary] = []) -> void:
	_entries = entries


func push(entry: Dictionary) -> void:
	_entries.append(entry.duplicate(true))


func pop() -> Dictionary:
	if _entries.is_empty():
		return {}
	return _entries.pop_back()


func is_empty() -> bool:
	return _entries.is_empty()


func clear() -> void:
	_entries.clear()


func size() -> int:
	return _entries.size()


func remove_by_stream(stream: AudioStream) -> void:
	if stream == null:
		return
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].get("stream", null) == stream:
			_entries.remove_at(i)


func remove_by_source_id(source_id: int) -> void:
	if source_id == 0:
		return
	for i in range(_entries.size() - 1, -1, -1):
		if int(_entries[i].get("source_id", 0)) == source_id:
			_entries.remove_at(i)


func snapshot() -> Array:
	return _entries.duplicate(true)
