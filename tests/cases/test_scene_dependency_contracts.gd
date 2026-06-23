extends "res://tests/test_case.gd"

const LEVEL04_SCENE_PATH := "res://levels/cycles/level_04_findkey.tscn"
const SCENE_DIRS := [
	"res://levels",
	"res://objects"
]

func run() -> Array[String]:
	_test_key_search_spots_do_not_depend_on_the_door_they_unlock()
	_test_scene_dependencies_declare_typed_conditions()
	_test_laptop_attempt_dependencies_use_requested_condition()
	_test_self_target_doors_are_locked()
	_test_level_scripts_set_dependency_condition_with_dependency_object()
	_test_target_monster_spawners_declare_spawn_condition()
	_test_reversible_triggers_are_not_one_shot()
	return get_failures()

func _test_key_search_spots_do_not_depend_on_the_door_they_unlock() -> void:
	var level_scene := assert_loads(LEVEL04_SCENE_PATH) as PackedScene
	assert_true(level_scene != null, "Level 04 scene failed to load")
	if level_scene == null:
		return
	var level := level_scene.instantiate()
	assert_true(level != null, "Level 04 scene failed to instantiate")
	if level == null:
		return

	for node in level.find_children("*", "", true, false):
		if not _has_property(node, "key_id"):
			continue
		var key_id := str(node.get("key_id"))
		if key_id.strip_edges() == "":
			continue
		var dependency := node.get("dependency_object") as Node
		if dependency == null or not _has_property(dependency, "required_key_id"):
			continue
		assert_true(
			str(dependency.get("required_key_id")) != key_id,
			"Key search spot must not depend on a door that requires the same key: %s -> %s" % [node.get_path(), dependency.get_path()]
		)

	level.free()

func _test_scene_dependencies_declare_typed_conditions() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("dependency_object = NodePath") == -1:
				continue
			assert_true(
				block.find("dependency_condition =") != -1,
				"Scene dependency_object must declare dependency_condition explicitly: %s" % path
			)

func _test_laptop_attempt_dependencies_use_requested_condition() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("unlock_on_dependency_interaction = true") == -1:
				continue
			assert_true(
				block.find("dependency_condition = 1") != -1,
				"Laptop legacy attempt-unlock flag must use INTERACTION_REQUESTED dependency_condition: %s" % path
			)

func _test_self_target_doors_are_locked() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("target_marker = NodePath(\".\")") == -1:
				continue
			assert_true(
				block.find("is_locked = true") != -1,
				"Self-target scene doors must be locked so players cannot trigger fade-to-self transitions: %s" % path
			)

func _test_level_scripts_set_dependency_condition_with_dependency_object() -> void:
	var scripts := utils.list_files("res://levels", ".gd", ["tests", ".godot", "addons"], ["archive", "trash"])
	scripts.sort()

	for path in scripts:
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read level script: %s" % path)
		if content == "":
			continue
		var lines := content.split("\n")
		for index in range(lines.size()):
			var line := String(lines[index]).strip_edges()
			if line.begins_with("#") or line.find("set_dependency_object") == -1:
				continue
			assert_true(
				_has_nearby_dependency_condition(lines, index),
				"Level script set_dependency_object must set_dependency_condition nearby: %s:%d" % [path, index + 1]
			)

func _test_target_monster_spawners_declare_spawn_condition() -> void:
	for path in _list_active_scenes():
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read scene: %s" % path)
		if content == "":
			continue
		var from := 0
		while true:
			var node_start := content.find("[node ", from)
			if node_start == -1:
				break
			var next_node := content.find("\n[node ", node_start + 1)
			if next_node == -1:
				next_node = content.length()
			var block := content.substr(node_start, next_node - node_start)
			if block.find("TargetMonsterSpawner") != -1 and block.find("enemy_scene =") != -1:
				assert_true(
					block.find("condition_configured = true") != -1,
					"TargetMonsterSpawner with enemy_scene must explicitly confirm its spawn condition: %s" % path
				)
			from = next_node

func _test_reversible_triggers_are_not_one_shot() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("affect_on_exit = true") != -1:
				assert_true(
					block.find("one_shot = false") != -1,
					"Trigger with affect_on_exit=true must set one_shot=false so exit behavior can run: %s" % path
				)

func _list_active_scenes() -> Array[String]:
	var scenes: Array[String] = []
	for dir_path in SCENE_DIRS:
		scenes.append_array(utils.list_files(dir_path, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"]))
	scenes.sort()
	return scenes

func _scene_node_blocks(path: String) -> Array[String]:
	var blocks: Array[String] = []
	var content := FileAccess.get_file_as_string(path)
	assert_true(content != "", "Failed to read scene: %s" % path)
	if content == "":
		return blocks
	var from := 0
	while true:
		var node_start := content.find("[node ", from)
		if node_start == -1:
			break
		var next_node := content.find("\n[node ", node_start + 1)
		if next_node == -1:
			next_node = content.length()
		blocks.append(content.substr(node_start, next_node - node_start))
		from = next_node
	return blocks

func _has_nearby_dependency_condition(lines: PackedStringArray, index: int) -> bool:
	var end_index = mini(lines.size(), index + 6)
	for next_index in range(index + 1, end_index):
		var line := String(lines[next_index]).strip_edges()
		if line.begins_with("#"):
			continue
		if line.find("set_dependency_condition") != -1:
			return true
	return false

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
