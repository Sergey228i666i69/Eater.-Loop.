extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const BED_SCRIPT := "res://objects/interactable/bed/bed.gd"
const PLAYER_SCRIPT := "res://player/player.gd"
const SceneContextScript = preload("res://global/scene_context.gd")

func run() -> Array[String]:
	_test_cycle_level_metadata_is_sane()
	_test_cycle_levels_have_single_player()
	_test_cycle_level_bed_transitions_are_loadable()
	_test_cycle_level_exported_paths_are_valid()
	return get_failures()

func _test_cycle_level_metadata_is_sane() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		if not _is_cycle_level(root):
			root.free()
			continue
		var cycle_number := _get_int_property_or_method(root, "cycle_number", "get_cycle_number")
		var timer_duration := _get_float_property_or_method(root, "timer_duration", "get_timer_duration")
		assert_true(cycle_number > 0, "Cycle level must have a positive cycle_number: %s" % path)
		assert_true(timer_duration >= 0.0, "Cycle level timer_duration must be non-negative: %s" % path)
		root.free()

func _test_cycle_levels_have_single_player() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		if not _is_cycle_level(root):
			root.free()
			continue
		var players := _find_nodes_with_script(root, PLAYER_SCRIPT)
		assert_eq(players.size(), 1, "Cycle level must include exactly one Player instance: %s" % path)
		if players.size() == 1:
			var player := players[0] as Node
			assert_true(player is Node2D, "Cycle level Player must be a Node2D: %s:%s" % [path, root.get_path_to(player)])
		root.free()

func _test_cycle_level_bed_transitions_are_loadable() -> void:
	for path in _list_level_scenes():
		var packed_scene := assert_loads(path) as PackedScene
		if packed_scene == null:
			continue
		var root := packed_scene.instantiate()
		if root == null:
			fail("Scene must instantiate for level authoring validation: %s" % path)
			continue
		if not _is_cycle_level(root):
			root.free()
			continue
		var bed_count := 0
		for node in root.find_children("*", "", true, false):
			if _script_path(node) != BED_SCRIPT:
				continue
			bed_count += 1
			_assert_bed_next_level_path(path, root, node, packed_scene)
		assert_true(bed_count > 0, "Cycle level must include at least one bed transition: %s" % path)
		root.free()

func _test_cycle_level_exported_paths_are_valid() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		if not _is_cycle_level(root):
			root.free()
			continue
		_assert_optional_nodepath_resolves(path, root, root, "fridge_interacted_spawn_marker_path", "Node2D")
		_assert_enabled_text_is_non_empty(path, root, "show_start_hint", "start_hint_text")
		_assert_enabled_text_is_non_empty(path, root, "show_start_subtitle", "start_subtitle_text")
		root.free()

func _assert_bed_next_level_path(path: String, root: Node, bed: Node, current_scene: PackedScene) -> void:
	assert_true(_has_property(bed, "next_level_path"), "Bed must expose next_level_path: %s:%s" % [path, root.get_path_to(bed)])
	if not _has_property(bed, "next_level_path"):
		return
	var next_level_path := str(bed.get("next_level_path")).strip_edges()
	assert_true(next_level_path != "", "Bed next_level_path must be set: %s:%s" % [path, root.get_path_to(bed)])
	if next_level_path == "":
		return
	var next_scene := assert_loads(next_level_path) as PackedScene
	if next_scene == null:
		return
	assert_true(next_scene != current_scene, "Bed next_level_path must not point to the same scene: %s:%s -> %s" % [path, root.get_path_to(bed), next_level_path])
	_assert_bed_next_level_scene_type(path, root, bed, next_level_path, next_scene)

func _assert_bed_next_level_scene_type(path: String, root: Node, bed: Node, next_level_path: String, next_scene: PackedScene) -> void:
	var next_root := next_scene.instantiate()
	assert_true(next_root != null, "Bed next_level_path scene must instantiate for type validation: %s:%s -> %s" % [path, root.get_path_to(bed), next_level_path])
	if next_root == null:
		return
	var valid_target := _is_cycle_level(next_root)
	var scene_context := SceneContextScript.new()
	valid_target = valid_target or scene_context.is_ending_scene(next_root)
	scene_context.free()
	assert_true(valid_target, "Bed next_level_path must point to a cycle level or ending scene: %s:%s -> %s" % [path, root.get_path_to(bed), next_level_path])
	next_root.free()

func _assert_optional_nodepath_resolves(path: String, root: Node, node: Node, property_name: String, expected_type: String = "") -> void:
	if not _has_property(node, property_name):
		return
	var node_path: NodePath = node.get(property_name)
	if node_path.is_empty():
		return
	var target := node.get_node_or_null(node_path)
	assert_true(target != null, "%s must resolve: %s:%s -> %s" % [property_name, path, root.get_path_to(node), node_path])
	if target != null and expected_type != "":
		assert_true(target.is_class(expected_type), "%s must resolve to %s: %s:%s -> %s" % [property_name, expected_type, path, root.get_path_to(node), node_path])

func _assert_enabled_text_is_non_empty(path: String, node: Node, enabled_property: String, text_property: String) -> void:
	if not _has_property(node, enabled_property) or not _has_property(node, text_property):
		return
	if not bool(node.get(enabled_property)):
		return
	var text := str(node.get(text_property)).strip_edges()
	assert_true(text != "", "%s must be non-empty when %s is enabled: %s" % [text_property, enabled_property, path])

func _get_int_property_or_method(node: Node, property_name: String, method_name: String) -> int:
	if node.has_method(method_name):
		return int(node.call(method_name))
	if _has_property(node, property_name):
		return int(node.get(property_name))
	return 0

func _get_float_property_or_method(node: Node, property_name: String, method_name: String) -> float:
	if node.has_method(method_name):
		return float(node.call(method_name))
	if _has_property(node, property_name):
		return float(node.get(property_name))
	return 0.0

func _is_cycle_level(node: Node) -> bool:
	return node.has_method("get_cycle_number") and node.has_method("get_timer_duration")

func _list_level_scenes() -> Array[String]:
	return utils.list_files(LEVEL_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"])

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for level authoring validation: %s" % path)
	return root

func _script_path(node: Node) -> String:
	var script := node.get_script() as Resource
	if script == null:
		return ""
	return String(script.resource_path)

func _find_nodes_with_script(root: Node, script_path: String) -> Array[Node]:
	var matches: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if _script_path(node) == script_path:
			matches.append(node)
	return matches

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
