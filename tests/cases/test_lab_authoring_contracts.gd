extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const LAPTOP_SCRIPT := "res://objects/interactable/notebook/laptop.gd"
const FRIDGE_SCRIPT := "res://objects/interactable/fridge/fridge.gd"
const TIMED_LAB_BASE_SCRIPT := "res://levels/minigames/labs/timed_lab_minigame_base.gd"
const TIMED_LAB_BASE_STRINGLY_UI_PATTERNS := [
	"UIMessage.has_method(\"show_dialogue\")",
	"UIMessage.call(\"show_dialogue\""
]

func run() -> Array[String]:
	_test_timed_lab_base_uses_stable_ui_facade()
	_test_laptop_lab_settings_are_valid()
	_test_laptop_minigame_scenes_match_lab_contract()
	_test_multi_lab_scenes_use_unique_ids()
	_test_required_lab_ids_have_laptop_sources()
	return get_failures()

func _test_timed_lab_base_uses_stable_ui_facade() -> void:
	var content := FileAccess.get_file_as_string(TIMED_LAB_BASE_SCRIPT)
	assert_true(content != "", "Failed to read TimedLabMinigameBase script")
	for pattern in TIMED_LAB_BASE_STRINGLY_UI_PATTERNS:
		assert_true(
			content.find(pattern) == -1,
			"TimedLabMinigameBase must use UIMessage.show_dialogue directly instead of stringly method probes: %s" % pattern
		)

func _test_laptop_lab_settings_are_valid() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for laptop in _collect_lab_laptops(root):
			assert_true(float(laptop.get("time_limit")) > 0.0, "Laptop time_limit must be positive: %s:%s" % [path, root.get_path_to(laptop)])
			assert_true(float(laptop.get("penalty_time")) >= 0.0, "Laptop penalty_time must be non-negative: %s:%s" % [path, root.get_path_to(laptop)])
		root.free()

func _test_laptop_minigame_scenes_match_lab_contract() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for laptop in _collect_lab_laptops(root):
			var minigame_scene := _get_packed_scene(laptop, "minigame_scene")
			var game := minigame_scene.instantiate() if minigame_scene != null else null
			assert_true(game != null, "Laptop minigame_scene must instantiate: %s:%s" % [path, root.get_path_to(laptop)])
			if game == null:
				continue
			assert_true(game is TimedLabMinigameBase, "Laptop minigame_scene must extend TimedLabMinigameBase: %s:%s" % [path, root.get_path_to(laptop)])
			assert_true(game.has_signal("task_completed"), "Laptop minigame_scene must expose task_completed signal: %s:%s" % [path, root.get_path_to(laptop)])
			assert_true(_has_property(game, "time_limit"), "Laptop minigame_scene must expose time_limit: %s:%s" % [path, root.get_path_to(laptop)])
			assert_true(_has_property(game, "penalty_time"), "Laptop minigame_scene must expose penalty_time: %s:%s" % [path, root.get_path_to(laptop)])
			assert_true(_has_property(game, "lab_completion_id"), "Laptop minigame_scene must expose lab_completion_id: %s:%s" % [path, root.get_path_to(laptop)])
			game.free()
		root.free()

func _test_multi_lab_scenes_use_unique_ids() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		var laptops := _collect_lab_laptops(root)
		if not _scene_requires_explicit_lab_ids(root, laptops):
			root.free()
			continue
		var seen_ids := {}
		for laptop in laptops:
			var lab_id := str(laptop.get("lab_completion_id")).strip_edges()
			assert_true(lab_id != "", "Scenes with multiple lab laptops must give each laptop a lab_completion_id: %s:%s" % [path, root.get_path_to(laptop)])
			if lab_id == "":
				continue
			assert_true(not seen_ids.has(lab_id), "Lab laptop IDs must be unique within a scene: %s -> %s" % [path, lab_id])
			seen_ids[lab_id] = true
		root.free()

func _test_required_lab_ids_have_laptop_sources() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		var provided_ids := _collect_scene_lab_ids(root)
		for fridge in _collect_fridges(root):
			if not _has_property(fridge, "required_lab_completion_ids"):
				continue
			var required_ids: PackedStringArray = fridge.get("required_lab_completion_ids")
			for required_id in required_ids:
				var lab_id := str(required_id).strip_edges()
				assert_true(lab_id != "", "Fridge required_lab_completion_ids must not contain empty IDs: %s:%s" % [path, root.get_path_to(fridge)])
				if lab_id == "":
					continue
				assert_true(provided_ids.has(lab_id), "Fridge required_lab_completion_ids must reference a laptop in the same scene: %s:%s -> %s" % [path, root.get_path_to(fridge), lab_id])
		root.free()

func _collect_lab_laptops(root: Node) -> Array[Node]:
	var laptops: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if _script_path(node) != LAPTOP_SCRIPT:
			continue
		if _get_packed_scene(node, "minigame_scene") == null:
			continue
		laptops.append(node)
	return laptops

func _collect_fridges(root: Node) -> Array[Node]:
	var fridges: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if _script_path(node) == FRIDGE_SCRIPT:
			fridges.append(node)
	return fridges

func _collect_scene_lab_ids(root: Node) -> Dictionary:
	var lab_ids := {}
	for laptop in _collect_lab_laptops(root):
		var lab_id := str(laptop.get("lab_completion_id")).strip_edges()
		if lab_id != "":
			lab_ids[lab_id] = true
	return lab_ids

func _scene_requires_explicit_lab_ids(root: Node, laptops: Array[Node]) -> bool:
	if laptops.size() <= 1:
		return false
	if not _collect_required_lab_ids(root).is_empty():
		return true
	return _collect_unique_minigame_scene_paths(laptops).size() > 1

func _collect_required_lab_ids(root: Node) -> Dictionary:
	var required_ids := {}
	for fridge in _collect_fridges(root):
		if not _has_property(fridge, "required_lab_completion_ids"):
			continue
		var ids: PackedStringArray = fridge.get("required_lab_completion_ids")
		for raw_id in ids:
			var lab_id := str(raw_id).strip_edges()
			if lab_id != "":
				required_ids[lab_id] = true
	return required_ids

func _collect_unique_minigame_scene_paths(laptops: Array[Node]) -> Dictionary:
	var paths := {}
	for laptop in laptops:
		var minigame_scene := _get_packed_scene(laptop, "minigame_scene")
		if minigame_scene == null:
			continue
		var scene_path := str(minigame_scene.resource_path).strip_edges()
		if scene_path != "":
			paths[scene_path] = true
	return paths

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
	assert_true(root != null, "Scene must instantiate for lab authoring validation: %s" % path)
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
