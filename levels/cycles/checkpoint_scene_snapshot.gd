extends RefCounted

const CheckpointDynamicRestoreClass = preload("res://levels/cycles/checkpoint_dynamic_restore.gd")

var _dynamic_restore = CheckpointDynamicRestoreClass.new()

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
		var dynamic_restore_data: Dictionary = _dynamic_restore.capture_restore_data(scene, node)
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
			node = _dynamic_restore.restore_node(scene, entry)
			if node == null:
				continue
		var snapshot_raw: Variant = entry.get("snapshot", {})
		if snapshot_raw is Dictionary:
			CheckpointStateUtils.apply_node_snapshot(node, snapshot_raw)
