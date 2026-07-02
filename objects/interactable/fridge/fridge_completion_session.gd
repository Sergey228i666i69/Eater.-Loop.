class_name FridgeCompletionSession
extends RefCounted

const PLAYER_GROUP := "player"
const ENEMIES_GROUP := "enemies"
const CHASE_MUSIC_CLEAR_FADE := 0.2

static func mark_cycle_feeding_completed(cycle_state: Object) -> void:
	if cycle_state == null:
		return
	if cycle_state.has_method("mark_ate"):
		cycle_state.mark_ate()
	if cycle_state.has_method("mark_fridge_interacted"):
		cycle_state.mark_fridge_interacted()

static func clear_chase_after_teleport_success(tree: SceneTree, music_manager: Object) -> void:
	if tree != null:
		tree.call_group(ENEMIES_GROUP, "force_stop_chase")
	if music_manager != null and music_manager.has_method("clear_chase_music_sources"):
		music_manager.clear_chase_music_sources(CHASE_MUSIC_CLEAR_FADE)

static func teleport_player_if_needed(owner: Node, enable_teleport: bool, teleport_target: NodePath) -> bool:
	if owner == null or not enable_teleport or teleport_target.is_empty():
		return false
	var marker := owner.get_node_or_null(teleport_target) as Node2D
	if marker == null or not owner.is_inside_tree():
		return false
	var tree := owner.get_tree()
	if tree == null:
		return false
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node2D
	if player == null:
		return false
	player.global_position = marker.global_position
	return true

static func current_scene_from_owner(owner: Node) -> Node:
	if owner == null or not owner.is_inside_tree():
		return null
	var tree := owner.get_tree()
	if tree == null:
		return null
	return tree.current_scene

static func save_after_feeding(game_state: Object, current_scene: Node) -> void:
	if game_state == null:
		return
	if current_scene != null and game_state.has_method("capture_fridge_checkpoint"):
		game_state.capture_fridge_checkpoint(current_scene)
		return
	if game_state.has_method("autosave_run"):
		game_state.autosave_run()
