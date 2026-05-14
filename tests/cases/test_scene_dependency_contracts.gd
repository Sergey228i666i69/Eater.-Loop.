extends "res://tests/test_case.gd"

const LEVEL04_SCENE_PATH := "res://levels/cycles/level_04_findkey.tscn"
const SCENE_DIRS := [
	"res://levels",
	"res://objects"
]

func run() -> Array[String]:
	_test_key_search_spots_do_not_depend_on_the_door_they_unlock()
	_test_target_monster_spawners_declare_spawn_condition()
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

func _test_target_monster_spawners_declare_spawn_condition() -> void:
	var scenes: Array[String] = []
	for dir_path in SCENE_DIRS:
		scenes.append_array(utils.list_files(dir_path, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"]))
	scenes.sort()

	for path in scenes:
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

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
