extends RefCounted

var _schemes: Dictionary = {}


func set_scheme(minigame: Node, scheme: Dictionary) -> void:
	if minigame == null:
		return
	_schemes[minigame.get_instance_id()] = {
		"ref": weakref(minigame),
		"scheme": scheme.duplicate(true)
	}
	cleanup_stale()


func clear_scheme(minigame: Node) -> void:
	if minigame == null:
		return
	_schemes.erase(minigame.get_instance_id())


func get_scheme(minigame: Node) -> Dictionary:
	if minigame == null:
		return {}
	var id := minigame.get_instance_id()
	if not _schemes.has(id):
		return {}
	var entry: Dictionary = _schemes[id]
	var ref: WeakRef = entry.get("ref", null)
	if ref == null or ref.get_ref() != minigame:
		_schemes.erase(id)
		return {}
	var scheme: Variant = entry.get("scheme", {})
	if scheme is Dictionary:
		return (scheme as Dictionary).duplicate(true)
	return {}


func cleanup_stale() -> void:
	var stale_ids: Array[int] = []
	for id in _schemes.keys():
		var entry: Dictionary = _schemes[id]
		var ref: WeakRef = entry.get("ref", null)
		if ref == null or ref.get_ref() == null:
			stale_ids.append(id)
	for id in stale_ids:
		_schemes.erase(id)


func get_registered_count() -> int:
	cleanup_stale()
	return _schemes.size()
