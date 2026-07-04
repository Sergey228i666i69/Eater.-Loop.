extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const BED_SCRIPT := "res://objects/interactable/bed/bed.gd"
const LEVEL_MUSIC_SCRIPT := "res://levels/cycles/level_music.gd"
const PLAYER_SCRIPT := "res://player/player.gd"
const SceneContextScript = preload("res://global/scene_context.gd")
const NON_LEVEL_SCENE_ALLOWLIST := {
	"TextureDistortionManager.tscn": true,
}
const OPTIONAL_ROOT_NODEPATH_PROPERTIES := {
	"fridge_interacted_spawn_marker_path": true,
	"primary_fridge_path": true,
}

func run() -> Array[String]:
	_test_cycle_scene_directory_has_explicit_level_contracts()
	_test_cycle_level_metadata_is_sane()
	_test_cycle_levels_have_single_player()
	_test_cycle_level_bed_transitions_are_loadable()
	_test_cycle_level_exported_paths_are_valid()
	_test_level_music_nodes_have_streams_when_active()
	return get_failures()

func _test_cycle_scene_directory_has_explicit_level_contracts() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		var file_name := path.get_file()
		if file_name.begins_with("level_"):
			assert_true(_is_cycle_level(root), "Playable level scenes must expose cycle/timer contract: %s" % path)
		else:
			assert_true(NON_LEVEL_SCENE_ALLOWLIST.has(file_name), "Non-level scenes in %s must be explicitly allowlisted: %s" % [LEVEL_DIR, path])
			assert_true(not _is_cycle_level(root), "Allowlisted utility scenes must not masquerade as cycle levels: %s" % path)
		root.free()

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
			_assert_player_authoring_config(path, root, player)
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
		_assert_root_exported_nodepaths_resolve(path, root)
		_assert_enabled_text_is_non_empty(path, root, "show_start_hint", "start_hint_text")
		_assert_enabled_text_is_non_empty(path, root, "show_start_subtitle", "start_subtitle_text")
		root.free()

func _test_level_music_nodes_have_streams_when_active() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		if not _is_cycle_level(root):
			root.free()
			continue
		for node in _find_nodes_with_script(root, LEVEL_MUSIC_SCRIPT):
			_assert_level_music_config(path, root, node)
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

func _assert_root_exported_nodepaths_resolve(path: String, root: Node) -> void:
	for property_info in root.get_property_list():
		if int(property_info.get("type", TYPE_NIL)) != TYPE_NODE_PATH:
			continue
		var property_name := String(property_info.get("name", ""))
		if not property_name.ends_with("_path"):
			continue
		var node_path: NodePath = root.get(property_name)
		if node_path.is_empty():
			assert_true(_is_optional_root_nodepath(property_name), "%s must be set when exported: %s" % [property_name, path])
			continue
		var target := root.get_node_or_null(node_path)
		assert_true(target != null, "%s must resolve from root: %s -> %s" % [property_name, path, node_path])
		if target != null:
			_assert_root_exported_nodepath_type(path, root, property_name, node_path, target)

func _is_optional_root_nodepath(property_name: String) -> bool:
	return OPTIONAL_ROOT_NODEPATH_PROPERTIES.has(property_name)

func _assert_root_exported_nodepath_type(path: String, root: Node, property_name: String, node_path: NodePath, target: Node) -> void:
	var lower_name := property_name.to_lower()
	if property_name == "fridge_interacted_spawn_marker_path":
		assert_true(target is Node2D, "%s must resolve to Node2D: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("fridge") != -1:
		assert_true(target is Fridge, "%s must resolve to Fridge: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("door") != -1:
		assert_true(target is Door, "%s must resolve to Door: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("laptop") != -1:
		assert_true(target is Laptop, "%s must resolve to Laptop: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("bed") != -1:
		assert_true(_script_path(target) == BED_SCRIPT, "%s must resolve to Bed: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("player") != -1:
		assert_true(_script_path(target) == PLAYER_SCRIPT, "%s must resolve to Player: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("generator") != -1:
		assert_true(target is InteractiveObject, "%s must resolve to InteractiveObject: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("darkness") != -1:
		assert_true(target is CanvasModulate, "%s must resolve to CanvasModulate: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("basement") != -1:
		assert_true(target is Node2D, "%s must resolve to Node2D: %s -> %s" % [property_name, path, node_path])
	elif lower_name.find("note") != -1:
		assert_true(target is InteractiveObject, "%s must resolve to InteractiveObject: %s -> %s" % [property_name, path, node_path])

func _assert_enabled_text_is_non_empty(path: String, node: Node, enabled_property: String, text_property: String) -> void:
	if not _has_property(node, enabled_property) or not _has_property(node, text_property):
		return
	if not bool(node.get(enabled_property)):
		return
	var text := str(node.get(text_property)).strip_edges()
	assert_true(text != "", "%s must be non-empty when %s is enabled: %s" % [text_property, enabled_property, path])

func _assert_player_authoring_config(path: String, root: Node, player: Node) -> void:
	_assert_float_at_least(path, root, player, "speed", 0.01)
	_assert_float_at_least(path, root, player, "run_speed_multiplier", 1.0)
	_assert_float_at_least(path, root, player, "stamina_max", 0.0)
	_assert_float_at_least(path, root, player, "stamina_drain_rate", 0.0)
	_assert_float_at_least(path, root, player, "stamina_recovery_rate", 0.0)
	_assert_float_at_least(path, root, player, "stamina_recovery_delay", 0.0)
	_assert_float_at_least(path, root, player, "stamina_min_to_run", 0.0)
	if _has_property(player, "stamina_max") and _has_property(player, "stamina_min_to_run"):
		var stamina_max := float(player.get("stamina_max"))
		var stamina_min_to_run := float(player.get("stamina_min_to_run"))
		if stamina_max > 0.0:
			assert_true(stamina_min_to_run < stamina_max, "Player stamina_min_to_run must be below stamina_max: %s:%s" % [path, root.get_path_to(player)])
	_assert_float_at_least(path, root, player, "flashlight_use_duration", 0.0)
	_assert_float_at_least(path, root, player, "flashlight_recharge_duration", 0.0)
	_assert_float_at_least(path, root, player, "flashlight_recharge_delay", 0.0)
	_assert_float_at_least(path, root, player, "walk_frame_time", 0.001)
	_assert_int_at_least(path, root, player, "walk_loop_start_index", 1)
	if _has_property(player, "walk_loop_start_index") and _has_property(player, "walk_loop_end_index"):
		var walk_loop_start := int(player.get("walk_loop_start_index"))
		var walk_loop_end := int(player.get("walk_loop_end_index"))
		assert_true(walk_loop_end == -1 or walk_loop_end >= walk_loop_start, "Player walk_loop_end_index must be -1 or >= walk_loop_start_index: %s:%s" % [path, root.get_path_to(player)])
	_assert_positive_int_array(path, root, player, "step_frame_indices")
	_assert_float_at_least(path, root, player, "skeleton_animation_blend_time", 0.0)
	_assert_sorted_non_negative_float_array(path, root, player, "skeleton_walk_step_times")
	_assert_sorted_non_negative_float_array(path, root, player, "skeleton_light_walk_step_times")
	_assert_sorted_non_negative_float_array(path, root, player, "skeleton_run_step_times")
	_assert_sorted_non_negative_float_array(path, root, player, "skeleton_light_run_step_times")

func _assert_level_music_config(path: String, root: Node, level_music: Node) -> void:
	var play_on_ready := bool(level_music.get("play_on_ready")) if _has_property(level_music, "play_on_ready") else true
	var continue_on_level_change := bool(level_music.get("continue_on_level_change")) if _has_property(level_music, "continue_on_level_change") else true
	if play_on_ready or not continue_on_level_change:
		assert_true(
			level_music.get("stream") is AudioStream,
			"LevelMusic stream must be set when play_on_ready is enabled or stop-on-exit is configured: %s:%s" % [path, root.get_path_to(level_music)]
		)
	if _has_property(level_music, "fade_time"):
		var fade_time := float(level_music.get("fade_time"))
		assert_true(fade_time >= 0.0, "LevelMusic fade_time must be non-negative: %s:%s" % [path, root.get_path_to(level_music)])

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

func _assert_float_at_least(path: String, root: Node, node: Node, property_name: String, minimum: float) -> void:
	if not _has_property(node, property_name):
		return
	var value := float(node.get(property_name))
	assert_true(value >= minimum, "%s must be >= %s: %s:%s" % [property_name, str(minimum), path, root.get_path_to(node)])

func _assert_int_at_least(path: String, root: Node, node: Node, property_name: String, minimum: int) -> void:
	if not _has_property(node, property_name):
		return
	var value := int(node.get(property_name))
	assert_true(value >= minimum, "%s must be >= %d: %s:%s" % [property_name, minimum, path, root.get_path_to(node)])

func _assert_positive_int_array(path: String, root: Node, node: Node, property_name: String) -> void:
	if not _has_property(node, property_name):
		return
	var values: Array = node.get(property_name)
	for index in range(values.size()):
		assert_true(int(values[index]) > 0, "%s entries must be positive frame indices: %s:%s[%d]" % [property_name, path, root.get_path_to(node), index])

func _assert_sorted_non_negative_float_array(path: String, root: Node, node: Node, property_name: String) -> void:
	if not _has_property(node, property_name):
		return
	var values: PackedFloat32Array = node.get(property_name)
	var previous := -INF
	for index in range(values.size()):
		var value := float(values[index])
		assert_true(value >= 0.0, "%s entries must be non-negative: %s:%s[%d]" % [property_name, path, root.get_path_to(node), index])
		assert_true(value >= previous, "%s entries must be sorted ascending: %s:%s[%d]" % [property_name, path, root.get_path_to(node), index])
		previous = value

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
