extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const FRIDGE_SCRIPT := "res://objects/interactable/fridge/fridge.gd"
const FINAL_FRIDGE_SCRIPT := "res://objects/interactable/fridge/final_ending_fridge.gd"

func run() -> Array[String]:
	_test_feeding_fridges_have_complete_configs()
	_test_code_locked_fridges_have_lock_contracts()
	_test_final_fridges_have_final_feeding_contracts()
	return get_failures()

func _test_feeding_fridges_have_complete_configs() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for fridge in _collect_fridges(root):
			if not _is_feeding_configured(fridge):
				continue
			_assert_feeding_config(path, root, fridge)
		root.free()

func _test_code_locked_fridges_have_lock_contracts() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for fridge in _collect_fridges(root):
			if not _has_property(fridge, "require_access_code") or not bool(fridge.get("require_access_code")):
				continue
			var access_code := str(fridge.get("access_code")).strip_edges() if _has_property(fridge, "access_code") else ""
			assert_true(access_code != "", "Code-locked fridge access_code must not be empty: %s:%s" % [path, root.get_path_to(fridge)])
			var code_lock_scene := _get_packed_scene(fridge, "code_lock_scene")
			assert_true(code_lock_scene != null, "Code-locked fridge must set code_lock_scene: %s:%s" % [path, root.get_path_to(fridge)])
			_assert_scene_instance_contract(path, root, fridge, code_lock_scene, "code_lock_scene", ["unlocked"], [])
		root.free()

func _test_final_fridges_have_final_feeding_contracts() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for fridge in _collect_fridges(root):
			if _script_path(fridge) != FINAL_FRIDGE_SCRIPT:
				continue
			var final_scene := _get_packed_scene(fridge, "final_minigame_scene")
			assert_true(final_scene != null, "Final ending fridge must set final_minigame_scene: %s:%s" % [path, root.get_path_to(fridge)])
			_assert_scene_instance_contract(path, root, fridge, final_scene, "final_minigame_scene", ["minigame_finished"], ["setup_final_stages", "setup_game"])
		root.free()

func _assert_feeding_config(path: String, root: Node, fridge: Node) -> void:
	var minigame_scene := _get_packed_scene(fridge, "minigame_scene")
	assert_true(minigame_scene != null, "Feeding fridge must set minigame_scene: %s:%s" % [path, root.get_path_to(fridge)])
	_assert_scene_instance_contract(path, root, fridge, minigame_scene, "minigame_scene", ["minigame_finished"], ["setup_game"])

	var food_scenes := _get_packed_scene_array(fridge, "food_scenes")
	assert_true(not food_scenes.is_empty(), "Feeding fridge must set at least one food_scenes entry: %s:%s" % [path, root.get_path_to(fridge)])
	for index in range(food_scenes.size()):
		assert_true(food_scenes[index] != null, "Feeding fridge food_scenes[%d] must not be null: %s:%s" % [index, path, root.get_path_to(fridge)])

	var food_count := int(fridge.get("food_count")) if _has_property(fridge, "food_count") else 0
	assert_true(food_count > 0, "Feeding fridge food_count must be positive: %s:%s" % [path, root.get_path_to(fridge)])
	assert_true(fridge.get("andrey_face") is Texture2D, "Feeding fridge must set andrey_face: %s:%s" % [path, root.get_path_to(fridge)])
	assert_true(fridge.get("background_texture") is Texture2D, "Feeding fridge must set background_texture: %s:%s" % [path, root.get_path_to(fridge)])

func _assert_scene_instance_contract(path: String, root: Node, fridge: Node, scene: PackedScene, property_name: String, required_signals: Array[String], accepted_setup_methods: Array[String]) -> void:
	if scene == null:
		return
	var instance := scene.instantiate()
	assert_true(instance != null, "%s must instantiate: %s:%s" % [property_name, path, root.get_path_to(fridge)])
	if instance == null:
		return
	for signal_name in required_signals:
		assert_true(instance.has_signal(signal_name), "%s must expose signal %s: %s:%s" % [property_name, signal_name, path, root.get_path_to(fridge)])
	if not accepted_setup_methods.is_empty():
		var has_setup_method := false
		for method_name in accepted_setup_methods:
			if instance.has_method(method_name):
				has_setup_method = true
				break
		assert_true(has_setup_method, "%s must expose one setup method from %s: %s:%s" % [property_name, str(accepted_setup_methods), path, root.get_path_to(fridge)])
	instance.free()

func _is_feeding_configured(fridge: Node) -> bool:
	if _get_packed_scene(fridge, "minigame_scene") != null:
		return true
	return not _get_packed_scene_array(fridge, "food_scenes").is_empty()

func _collect_fridges(root: Node) -> Array[Node]:
	var fridges: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if [FRIDGE_SCRIPT, FINAL_FRIDGE_SCRIPT].has(_script_path(node)):
			fridges.append(node)
	return fridges

func _get_packed_scene(node: Node, property_name: String) -> PackedScene:
	if not _has_property(node, property_name):
		return null
	return node.get(property_name) as PackedScene

func _get_packed_scene_array(node: Node, property_name: String) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	if not _has_property(node, property_name):
		return scenes
	var raw_scenes: Array = node.get(property_name)
	for scene in raw_scenes:
		scenes.append(scene as PackedScene)
	return scenes

func _list_level_scenes() -> Array[String]:
	return utils.list_files(LEVEL_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"])

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for fridge authoring validation: %s" % path)
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
