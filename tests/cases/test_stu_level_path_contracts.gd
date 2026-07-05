extends "res://tests/test_case.gd"

const LEVEL07_SCENE := "res://levels/cycles/level_07_doors.tscn"
const LEVEL11_SCENE := "res://levels/cycles/level_11_STU_1.tscn"
const LEVEL12_SCENE := "res://levels/cycles/level_12_STU_2.tscn"
const LEVEL13_SCENE := "res://levels/cycles/level_13_STU_3.tscn"

func run() -> Array[String]:
	await _test_level07_exported_paths_and_post_fridge_layout()
	_test_level11_exported_paths_and_dynamic_targets_resolve()
	_test_level12_hardcoded_paths_and_dynamic_targets_resolve()
	_test_level13_exported_paths_and_dynamic_targets_resolve()
	return get_failures()

func _test_level07_exported_paths_and_post_fridge_layout() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return
	if CycleState != null:
		CycleState.reset_cycle_state()
		CycleState.mark_fridge_interacted()

	var level := _instantiate_scene(LEVEL07_SCENE)
	if level == null:
		if CycleState != null:
			CycleState.reset_cycle_state()
		return
	tree.root.add_child(level)
	await tree.process_frame
	await tree.process_frame

	var fridge := _assert_root_path(level, LEVEL07_SCENE, "fridge_path")
	var left_door := _assert_root_path(level, LEVEL07_SCENE, "hall2_left_door_path")
	var right_door := _assert_root_path(level, LEVEL07_SCENE, "hall2_right_door_path")
	assert_true(fridge is Fridge, "Level 07 fridge_path must resolve to Fridge")
	assert_true(left_door is Door, "Level 07 hall2_left_door_path must resolve to Door")
	assert_true(right_door is Door, "Level 07 hall2_right_door_path must resolve to Door")
	if left_door is Door:
		assert_true((left_door as Door).is_locked, "Level 07 left Hall2 door must lock after fridge interaction")
	if right_door is Door:
		assert_true(not (right_door as Door).is_locked, "Level 07 right Hall2 door must stay open after fridge interaction")

	level.queue_free()
	await tree.process_frame
	if CycleState != null:
		CycleState.reset_cycle_state()

func _test_level11_exported_paths_and_dynamic_targets_resolve() -> void:
	var level := _instantiate_scene(LEVEL11_SCENE)
	if level == null:
		return
	var fridge := _assert_root_path(level, LEVEL11_SCENE, "fridge_path")
	_assert_root_path(level, LEVEL11_SCENE, "door_in604_path")
	var door_to701 := _assert_root_path(level, LEVEL11_SCENE, "door_to701_path")
	_assert_root_path(level, LEVEL11_SCENE, "note_story_path")
	assert_true(fridge is Fridge, "Level 11 fridge_path must resolve to Fridge")
	assert_true(door_to701 is Door, "Level 11 door_to701_path must resolve to Door")
	if door_to701 != null:
		_assert_relative_path(door_to701, LEVEL11_SCENE, "door_to701_target_before_fridge", level.get("door_to701_target_before_fridge"))
		_assert_relative_path(door_to701, LEVEL11_SCENE, "door_to701_target_after_fridge", level.get("door_to701_target_after_fridge"))
	level.free()

func _test_level12_hardcoded_paths_and_dynamic_targets_resolve() -> void:
	var level := _instantiate_scene(LEVEL12_SCENE)
	if level == null:
		return
	var generator := _assert_root_path(level, LEVEL12_SCENE, "generator_path")
	var darkness := _assert_root_path(level, LEVEL12_SCENE, "darkness_path")
	var basement := _assert_root_path(level, LEVEL12_SCENE, "basement_path")
	var player := _assert_root_path(level, LEVEL12_SCENE, "player_path")
	var fridge := _assert_root_path(level, LEVEL12_SCENE, "fridge_path")
	var door_to202 := _assert_root_path(level, LEVEL12_SCENE, "door_to202_path")
	assert_true(generator is InteractiveObject, "Level 12 generator_path must resolve to InteractiveObject")
	assert_true(darkness is CanvasModulate, "Level 12 darkness_path must resolve to CanvasModulate")
	assert_true(basement is Node2D, "Level 12 basement_path must resolve to Node2D")
	assert_true(player is Node2D, "Level 12 player_path must resolve to Node2D")
	assert_true(fridge is Fridge, "Level 12 fridge_path must resolve to Fridge")
	assert_true(door_to202 is Door, "Level 12 door_to202_path must resolve to Door")
	if door_to202 != null:
		_assert_relative_path(door_to202, LEVEL12_SCENE, "door_to202_default_target", level.get("door_to202_default_target"))
		_assert_relative_path(door_to202, LEVEL12_SCENE, "door_to202_bedroom_target", level.get("door_to202_bedroom_target"))
	level.free()

func _test_level13_exported_paths_and_dynamic_targets_resolve() -> void:
	var level := _instantiate_scene(LEVEL13_SCENE)
	if level == null:
		return
	var door_to_bathroom := _assert_root_path(level, LEVEL13_SCENE, "door_to_bathroom_path")
	var primary_fridge := _assert_optional_root_path(level, LEVEL13_SCENE, "primary_fridge_path")
	var secondary_fridge := _assert_root_path(level, LEVEL13_SCENE, "secondary_fridge_path")
	if primary_fridge != null:
		assert_true(primary_fridge is Fridge, "Level 13 primary_fridge_path must resolve to Fridge when configured")
	assert_true(secondary_fridge is Fridge, "Level 13 secondary_fridge_path must resolve to Fridge")
	if door_to_bathroom != null:
		assert_true(door_to_bathroom is Door, "Level 13 door_to_bathroom_path must resolve to Door")
		_assert_relative_path(door_to_bathroom, LEVEL13_SCENE, "door_to_bathroom_default_target", level.get("door_to_bathroom_default_target"))
		_assert_relative_path(door_to_bathroom, LEVEL13_SCENE, "door_to_bedroom_target", level.get("door_to_bedroom_target"))
	level.free()

func _assert_root_path(level: Node, scene_path: String, property_name: String) -> Node:
	var path: NodePath = level.get(property_name)
	assert_true(not path.is_empty(), "%s must not be empty in %s" % [property_name, scene_path])
	if path.is_empty():
		return null
	return _assert_node(level, scene_path, path, property_name)

func _assert_optional_root_path(level: Node, scene_path: String, property_name: String) -> Node:
	var path: NodePath = level.get(property_name)
	if path.is_empty():
		return null
	return _assert_node(level, scene_path, path, property_name)

func _assert_relative_path(origin: Node, scene_path: String, label: String, path: NodePath) -> Node:
	assert_true(not path.is_empty(), "%s must not be empty in %s" % [label, scene_path])
	if path.is_empty():
		return null
	var target := origin.get_node_or_null(path)
	assert_true(target != null, "%s must resolve in %s from %s -> %s" % [label, scene_path, origin.name, path])
	return target

func _assert_node(root: Node, scene_path: String, path: NodePath, label: String) -> Node:
	var node := root.get_node_or_null(path)
	assert_true(node != null, "%s must resolve in %s -> %s" % [label, scene_path, path])
	return node

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for STU contract validation: %s" % path)
	return root
