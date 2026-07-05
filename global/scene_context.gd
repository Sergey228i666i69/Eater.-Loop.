extends Node

const CycleLevelScript := preload("res://levels/cycles/level.gd")

const GAMEPLAY_SCENE_GROUP := "gameplay_scene"
const MENU_SCENE_GROUP := "menu_scene"
const ENDING_SCENE_GROUP := "ending_scene"
const GAMEPLAY_SCENE_ROOT := "res://levels/cycles/"
const GAMEPLAY_SCENE_FILE_PREFIX := "level_"
const MENU_SCENE_ROOT := "res://levels/menu/"
const ENDING_SCENE_ROOT := "res://levels/endings/"

func mark_gameplay_scene(scene: Node) -> void:
	if scene != null and not scene.is_in_group(GAMEPLAY_SCENE_GROUP):
		scene.add_to_group(GAMEPLAY_SCENE_GROUP)

func mark_menu_scene(scene: Node) -> void:
	if scene != null and not scene.is_in_group(MENU_SCENE_GROUP):
		scene.add_to_group(MENU_SCENE_GROUP)

func mark_ending_scene(scene: Node) -> void:
	if scene != null and not scene.is_in_group(ENDING_SCENE_GROUP):
		scene.add_to_group(ENDING_SCENE_GROUP)

func is_gameplay_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.is_in_group(GAMEPLAY_SCENE_GROUP):
		return true
	if scene is CycleLevelScript:
		return true
	return is_gameplay_scene_path(scene.scene_file_path)

func is_menu_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.is_in_group(MENU_SCENE_GROUP):
		return true
	return is_menu_scene_path(scene.scene_file_path)

func is_ending_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.is_in_group(ENDING_SCENE_GROUP):
		return true
	return is_ending_scene_path(scene.scene_file_path)

func is_gameplay_scene_path(path: String) -> bool:
	if not path.begins_with(GAMEPLAY_SCENE_ROOT):
		return false
	var file_name := path.get_file()
	return file_name.begins_with(GAMEPLAY_SCENE_FILE_PREFIX) and file_name.ends_with(".tscn")

func is_menu_scene_path(path: String) -> bool:
	return path.begins_with(MENU_SCENE_ROOT)

func is_ending_scene_path(path: String) -> bool:
	return path.begins_with(ENDING_SCENE_ROOT)
