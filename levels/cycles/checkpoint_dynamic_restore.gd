extends RefCounted

const RESTORABLE_GROUPS: Array[StringName] = [&"enemies"]
const RESTORABLE_SCRIPT_PREFIXES: Array[String] = ["res://enemies/"]

func capture_restore_data(scene: Node, node: Node) -> Dictionary:
	if scene == null or node == null:
		return {}
	if not is_restorable_runtime_node(node):
		return {}
	var scene_file_path := String(node.scene_file_path)
	if scene_file_path == "":
		return {}
	var parent := node.get_parent()
	if parent == null:
		return {}
	var parent_path := CheckpointStateUtils.get_scene_relative_path(scene, parent)
	if parent_path == "":
		return {}
	return {
		"scene_path": scene_file_path,
		"parent_path": parent_path,
		"node_name": String(node.name),
	}

func restore_node(scene: Node, entry: Dictionary) -> Node:
	if scene == null:
		return null
	var restore_raw: Variant = entry.get("dynamic_restore", {})
	if not (restore_raw is Dictionary):
		return null
	var restore_data := restore_raw as Dictionary
	var scene_path := str(restore_data.get("scene_path", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return null
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var parent := resolve_parent(scene, str(restore_data.get("parent_path", ".")))
	if parent == null:
		return null
	var restored := packed.instantiate()
	if restored == null:
		return null
	if not is_restorable_scene_instance(restored):
		restored.free()
		return null
	var node_name := str(restore_data.get("node_name", ""))
	if node_name != "":
		restored.name = node_name
	parent.add_child(restored)
	if not is_restorable_runtime_node(restored):
		restored.queue_free()
		return null
	return restored

func is_restorable_runtime_node(node: Node) -> bool:
	if node == null:
		return false
	if node.owner != null:
		return false
	for group_name in RESTORABLE_GROUPS:
		if node.is_in_group(group_name):
			return true
	return false

func is_restorable_scene_instance(node: Node) -> bool:
	if node == null:
		return false
	if is_restorable_runtime_node(node):
		return true
	return _has_restorable_script(node)

func resolve_parent(scene: Node, parent_path: String) -> Node:
	if scene == null:
		return null
	if parent_path == "" or parent_path == ".":
		return scene
	var parent := scene.get_node_or_null(NodePath(parent_path))
	if parent != null:
		return parent
	return scene

func _has_restorable_script(node: Node) -> bool:
	var script_raw: Variant = node.get_script()
	while script_raw is Script:
		var script := script_raw as Script
		if _is_restorable_script_path(String(script.resource_path)):
			return true
		script_raw = script.get_base_script()
	return false

func _is_restorable_script_path(script_path: String) -> bool:
	for prefix in RESTORABLE_SCRIPT_PREFIXES:
		if script_path.begins_with(prefix):
			return true
	return false
