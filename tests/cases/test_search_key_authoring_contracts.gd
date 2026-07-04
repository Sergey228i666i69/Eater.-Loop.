extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const SEARCH_KEY_MANAGER_SCRIPT := "res://levels/minigames/search_key/search_key_manager.gd"
const SEARCH_SPOT_SCRIPT := "res://objects/interactable/search_spot/search_spot.gd"

func run() -> Array[String]:
	_test_managed_search_spots_have_complete_configs()
	return get_failures()

func _test_managed_search_spots_have_complete_configs() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for manager in _collect_search_key_managers(root):
			_assert_managed_search_spots(path, root, manager)
		root.free()

func _assert_managed_search_spots(path: String, root: Node, manager: Node) -> void:
	var search_spots: Array = manager.get("search_spots")
	for index in range(search_spots.size()):
		var spot_path: NodePath = search_spots[index]
		if spot_path.is_empty():
			continue
		var spot := manager.get_node_or_null(spot_path)
		if spot == null:
			continue
		assert_true(_script_path(spot) == SEARCH_SPOT_SCRIPT, "SearchKeyManager search_spots must point to SearchSpot: %s:%s[%d] -> %s" % [path, root.get_path_to(manager), index, spot_path])
		if _script_path(spot) != SEARCH_SPOT_SCRIPT:
			continue
		_assert_search_spot_config(path, root, spot)

func _assert_search_spot_config(path: String, root: Node, spot: Node) -> void:
	var minigame_scene := _get_packed_scene(spot, "minigame_scene")
	assert_true(minigame_scene != null, "SearchSpot must set minigame_scene: %s:%s" % [path, root.get_path_to(spot)])
	_assert_search_minigame_contract(path, root, spot, minigame_scene)

	var key_id := str(spot.get("key_id")).strip_edges()
	assert_true(key_id != "", "SearchSpot key_id must not be empty: %s:%s" % [path, root.get_path_to(spot)])
	assert_true(spot.get("key_texture") is Texture2D, "SearchSpot must set key_texture: %s:%s" % [path, root.get_path_to(spot)])

	var trash_textures: Array = spot.get("trash_textures")
	assert_true(not trash_textures.is_empty(), "SearchSpot must set trash_textures: %s:%s" % [path, root.get_path_to(spot)])
	for index in range(trash_textures.size()):
		assert_true(trash_textures[index] is Texture2D, "SearchSpot trash_textures[%d] must be Texture2D: %s:%s" % [index, path, root.get_path_to(spot)])

	var trash_min := int(spot.get("trash_min"))
	var trash_max := int(spot.get("trash_max"))
	assert_true(trash_min >= 0, "SearchSpot trash_min must be non-negative: %s:%s" % [path, root.get_path_to(spot)])
	assert_true(trash_max >= trash_min, "SearchSpot trash_max must be >= trash_min: %s:%s" % [path, root.get_path_to(spot)])
	assert_true(trash_max > 0, "SearchSpot trash_max must allow visible trash: %s:%s" % [path, root.get_path_to(spot)])

func _assert_search_minigame_contract(path: String, root: Node, spot: Node, scene: PackedScene) -> void:
	if scene == null:
		return
	var instance := scene.instantiate()
	assert_true(instance != null, "SearchSpot minigame_scene must instantiate: %s:%s" % [path, root.get_path_to(spot)])
	if instance == null:
		return
	assert_true(instance.has_method("setup"), "SearchSpot minigame_scene must expose setup(config): %s:%s" % [path, root.get_path_to(spot)])
	assert_true(instance.has_method("get_layout_state"), "SearchSpot minigame_scene must expose get_layout_state(): %s:%s" % [path, root.get_path_to(spot)])
	assert_true(instance.has_node("SearchArea/KeyButton"), "SearchSpot minigame_scene must keep SearchArea/KeyButton: %s:%s" % [path, root.get_path_to(spot)])
	assert_true(instance.has_node("SearchArea/TrashContainer"), "SearchSpot minigame_scene must keep SearchArea/TrashContainer: %s:%s" % [path, root.get_path_to(spot)])
	instance.free()

func _collect_search_key_managers(root: Node) -> Array[Node]:
	var managers: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if _script_path(node) == SEARCH_KEY_MANAGER_SCRIPT:
			managers.append(node)
	return managers

func _get_packed_scene(node: Node, property_name: String) -> PackedScene:
	if not _has_property(node, property_name):
		return null
	return node.get(property_name) as PackedScene

func _list_level_scenes() -> Array[String]:
	return utils.list_files(LEVEL_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"])

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for search-key authoring validation: %s" % path)
	return root

func _script_path(node: Node) -> String:
	var script := node.get_script() as Resource
	if script == null:
		return ""
	return String(script.resource_path)

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
