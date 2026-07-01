extends RefCounted

const STALKER_SPAWN_GROUP := "stalker_spawn"
const STALKER_ENEMY_GROUP := "stalker_enemy"
const DEFAULT_STALKER_NODE_NAME := "GameDirectorStalker"

var stalker_scene: PackedScene

func find_spawn(tree: SceneTree, scene: Node) -> Node2D:
	if tree == null or scene == null:
		return null
	for node in tree.get_nodes_in_group(STALKER_SPAWN_GROUP):
		if node is Node2D and scene.is_ancestor_of(node):
			return node
	return null

func create_stalker(scene: Node, spawn_position: Vector2, preferred_name: String = DEFAULT_STALKER_NODE_NAME) -> Node:
	if scene == null or stalker_scene == null:
		return null
	var stalker := stalker_scene.instantiate()
	if stalker == null:
		return null
	if preferred_name.strip_edges() != "":
		stalker.name = preferred_name
	scene.add_child(stalker)
	if stalker is Node2D:
		(stalker as Node2D).global_position = spawn_position
	return stalker

func find_active(tree: SceneTree, scene: Node) -> Node:
	if tree == null or scene == null:
		return null
	for node in tree.get_nodes_in_group(STALKER_ENEMY_GROUP):
		if node != null and is_instance_valid(node) and (node == scene or scene.is_ancestor_of(node)):
			return node
	return null

func capture_checkpoint_state(tree: SceneTree, scene: Node, stalker_spawned: bool) -> Dictionary:
	var state := {"stalker_spawned": stalker_spawned}
	if not stalker_spawned:
		return state
	var stalker := find_active(tree, scene)
	if stalker == null:
		return state
	state["stalker_node_name"] = stalker.name
	state["stalker_snapshot"] = CheckpointStateUtils.capture_node_snapshot(stalker)
	return state

func restore_from_checkpoint(tree: SceneTree, scene: Node, state: Dictionary) -> Node:
	if tree == null or scene == null:
		return null
	var stalker := find_active(tree, scene)
	if stalker == null:
		var spawn_position := _resolve_restore_position(tree, scene, state)
		var preferred_name := str(state.get("stalker_node_name", DEFAULT_STALKER_NODE_NAME))
		stalker = create_stalker(scene, spawn_position, preferred_name)
	if stalker == null:
		return null
	var snapshot_raw: Variant = state.get("stalker_snapshot", {})
	if snapshot_raw is Dictionary:
		CheckpointStateUtils.apply_node_snapshot(stalker, snapshot_raw)
	return stalker

func _resolve_restore_position(tree: SceneTree, scene: Node, state: Dictionary) -> Vector2:
	var snapshot_raw: Variant = state.get("stalker_snapshot", {})
	if snapshot_raw is Dictionary and snapshot_raw.has("global_position"):
		var restored_position: Variant = snapshot_raw.get("global_position")
		if restored_position is Vector2:
			return restored_position
	var spawn := find_spawn(tree, scene)
	if spawn != null:
		return spawn.global_position
	return Vector2.ZERO
