extends RefCounted

func collect_participant_paths(scene: Node, tree: SceneTree, previous_paths: PackedStringArray) -> Array[String]:
	var paths: Array[String] = []
	var seen: Dictionary = {}
	if scene == null or tree == null:
		return paths
	for node in tree.get_nodes_in_group(CheckpointStateUtils.CHECKPOINT_STATEFUL_GROUP):
		if node == null or not is_instance_valid(node):
			continue
		if node != scene and not scene.is_ancestor_of(node):
			continue
		var path := CheckpointStateUtils.get_scene_relative_path(scene, node)
		if path == "" or seen.has(path):
			continue
		seen[path] = true
		paths.append(path)
	for path_value in previous_paths:
		var existing_path := str(path_value)
		if existing_path == "" or seen.has(existing_path):
			continue
		seen[existing_path] = true
		paths.append(existing_path)
	paths.sort()
	return paths

func capture_scene_state(scene: Node, participant_paths: PackedStringArray) -> Dictionary:
	var scene_state: Dictionary = {}
	if scene == null:
		return scene_state
	for path_value in participant_paths:
		var path_text := str(path_value)
		if path_text == "":
			continue
		var node := scene.get_node_or_null(NodePath(path_text))
		if node == null:
			scene_state[path_text] = {"exists": false}
			continue
		var entry: Dictionary = {
			"exists": true,
			"snapshot": CheckpointStateUtils.capture_node_snapshot(node),
		}
		var dynamic_restore_data := _capture_dynamic_restore_data(scene, node)
		if not dynamic_restore_data.is_empty():
			entry["dynamic_restore"] = dynamic_restore_data
		scene_state[path_text] = entry
	return scene_state

func apply_scene_state(scene: Node, participant_paths: PackedStringArray, scene_state: Dictionary) -> void:
	if scene == null:
		return
	for path_value in participant_paths:
		var path_text := str(path_value)
		if path_text == "":
			continue
		var entry_raw: Variant = scene_state.get(path_text, {})
		if not (entry_raw is Dictionary):
			continue
		var entry := entry_raw as Dictionary
		var node := scene.get_node_or_null(NodePath(path_text))
		if not bool(entry.get("exists", true)):
			if node == null:
				continue
			CheckpointStateUtils.remove_absent_node(node)
			continue
		if node == null:
			node = _restore_dynamic_checkpoint_node(scene, entry)
			if node == null:
				continue
		var snapshot_raw: Variant = entry.get("snapshot", {})
		if snapshot_raw is Dictionary:
			CheckpointStateUtils.apply_node_snapshot(node, snapshot_raw)

func _capture_dynamic_restore_data(scene: Node, node: Node) -> Dictionary:
	if scene == null or node == null:
		return {}
	if not node.is_in_group("enemies"):
		return {}
	if node.owner != null:
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

func _restore_dynamic_checkpoint_node(scene: Node, entry: Dictionary) -> Node:
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
	var parent := _resolve_dynamic_restore_parent(scene, str(restore_data.get("parent_path", ".")))
	if parent == null:
		return null
	var restored := packed.instantiate()
	if restored == null:
		return null
	var node_name := str(restore_data.get("node_name", ""))
	if node_name != "":
		restored.name = node_name
	parent.add_child(restored)
	return restored

func _resolve_dynamic_restore_parent(scene: Node, parent_path: String) -> Node:
	if scene == null:
		return null
	if parent_path == "" or parent_path == ".":
		return scene
	var parent := scene.get_node_or_null(NodePath(parent_path))
	if parent != null:
		return parent
	return scene
