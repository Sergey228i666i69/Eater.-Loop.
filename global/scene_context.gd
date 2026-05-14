extends Node

const GAMEPLAY_SCENE_GROUP := "gameplay_scene"
const MENU_SCENE_GROUP := "menu_scene"
const GAMEPLAY_SCENE_ROOT := "res://levels/cycles/"
const MENU_SCENE_ROOT := "res://levels/menu/"

func mark_gameplay_scene(scene: Node) -> void:
	if scene != null and not scene.is_in_group(GAMEPLAY_SCENE_GROUP):
		scene.add_to_group(GAMEPLAY_SCENE_GROUP)

func mark_menu_scene(scene: Node) -> void:
	if scene != null and not scene.is_in_group(MENU_SCENE_GROUP):
		scene.add_to_group(MENU_SCENE_GROUP)

func is_gameplay_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.is_in_group(GAMEPLAY_SCENE_GROUP):
		return true
	if scene.has_method("get_cycle_number") and scene.has_method("get_timer_duration"):
		return true
	return is_gameplay_scene_path(scene.scene_file_path)

func is_menu_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.is_in_group(MENU_SCENE_GROUP):
		return true
	return is_menu_scene_path(scene.scene_file_path)

func is_gameplay_scene_path(path: String) -> bool:
	return path.begins_with(GAMEPLAY_SCENE_ROOT)

func is_menu_scene_path(path: String) -> bool:
	return path.begins_with(MENU_SCENE_ROOT)
