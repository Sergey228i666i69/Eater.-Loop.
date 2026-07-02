extends RefCounted

var _keys: Dictionary = {}

func add_key(key_id: String) -> void:
	var normalized := key_id.strip_edges()
	if normalized == "":
		return
	_keys[normalized] = true

func has_key(key_id: String) -> bool:
	var normalized := key_id.strip_edges()
	if normalized == "":
		return false
	return _keys.has(normalized)

func remove_key(key_id: String) -> void:
	var normalized := key_id.strip_edges()
	if normalized == "":
		return
	_keys.erase(normalized)

func clear() -> void:
	_keys.clear()

func capture_checkpoint_state() -> Dictionary:
	return {"keys": _keys.keys()}

func apply_checkpoint_state(state: Dictionary) -> void:
	clear()
	var key_list: Variant = state.get("keys", [])
	if not (key_list is Array):
		return
	for key_id in key_list:
		add_key(str(key_id))
