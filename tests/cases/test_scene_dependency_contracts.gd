extends "res://tests/test_case.gd"

const LEVEL04_SCENE_PATH := "res://levels/cycles/level_04_findkey.tscn"

func run() -> Array[String]:
	_test_key_search_spots_do_not_depend_on_the_door_they_unlock()
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

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
