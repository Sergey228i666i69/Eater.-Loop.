extends "res://tests/test_case.gd"

const CheckpointDynamicRestore = preload("res://levels/cycles/checkpoint_dynamic_restore.gd")
const DYNAMIC_ENEMY_SCENE_PATH := "res://tests/fixtures/dynamic_checkpoint_enemy.tscn"
const NON_RESTORABLE_SCENE_PATH := "res://objects/interactable/door/door.tscn"

func run() -> Array[String]:
	await _test_ownerless_runtime_enemy_captures_restore_data()
	await _test_non_enemy_runtime_node_is_not_factory_restorable()
	await _test_restore_node_uses_captured_parent_and_name()
	await _test_restore_node_rejects_unallowlisted_scene_path()
	return get_failures()

func _test_ownerless_runtime_enemy_captures_restore_data() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var enemy_scene := assert_loads(DYNAMIC_ENEMY_SCENE_PATH) as PackedScene
	assert_true(tree != null, "SceneTree is not available")
	if tree == null or enemy_scene == null:
		return

	var helper: RefCounted = CheckpointDynamicRestore.new()
	var scene := Node2D.new()
	var parent := Node2D.new()
	parent.name = "SpawnParent"
	scene.add_child(parent)
	tree.root.add_child(scene)
	await tree.process_frame

	var enemy := enemy_scene.instantiate() as CharacterBody2D
	enemy.name = "RuntimeEnemy"
	parent.add_child(enemy)
	await tree.process_frame

	var restore_data: Dictionary = helper.capture_restore_data(scene, enemy)
	assert_eq(restore_data.get("scene_path", ""), DYNAMIC_ENEMY_SCENE_PATH, "Runtime enemy restore must keep scene path")
	assert_eq(restore_data.get("parent_path", ""), "SpawnParent", "Runtime enemy restore must keep scene-relative parent path")
	assert_eq(restore_data.get("node_name", ""), "RuntimeEnemy", "Runtime enemy restore must keep node name")

	scene.queue_free()
	await tree.process_frame

func _test_restore_node_rejects_unallowlisted_scene_path() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var helper: RefCounted = CheckpointDynamicRestore.new()
	var scene := Node2D.new()
	scene.name = "Scene"
	tree.root.add_child(scene)
	await tree.process_frame

	var restored: Node = helper.restore_node(scene, {
		"dynamic_restore": {
			"scene_path": NON_RESTORABLE_SCENE_PATH,
			"parent_path": ".",
			"node_name": "RestoredDoor",
		}
	})

	assert_true(restored == null, "Dynamic restore must reject non-allowlisted scene paths")
	assert_true(scene.get_node_or_null("RestoredDoor") == null, "Rejected dynamic restore must not attach the node")

	scene.queue_free()
	await tree.process_frame

func _test_non_enemy_runtime_node_is_not_factory_restorable() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var enemy_scene := assert_loads(DYNAMIC_ENEMY_SCENE_PATH) as PackedScene
	assert_true(tree != null, "SceneTree is not available")
	if tree == null or enemy_scene == null:
		return

	var helper: RefCounted = CheckpointDynamicRestore.new()
	var scene := Node2D.new()
	tree.root.add_child(scene)
	await tree.process_frame

	var runtime_node := enemy_scene.instantiate() as CharacterBody2D
	scene.add_child(runtime_node)
	await tree.process_frame
	runtime_node.remove_from_group("enemies")

	assert_true(helper.capture_restore_data(scene, runtime_node).is_empty(), "Only allowlisted runtime groups may be factory-restored")

	scene.queue_free()
	await tree.process_frame

func _test_restore_node_uses_captured_parent_and_name() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var helper: RefCounted = CheckpointDynamicRestore.new()
	var scene := Node2D.new()
	var parent := Node2D.new()
	parent.name = "SpawnParent"
	scene.add_child(parent)
	tree.root.add_child(scene)
	await tree.process_frame

	var restored: Node = helper.restore_node(scene, {
		"dynamic_restore": {
			"scene_path": DYNAMIC_ENEMY_SCENE_PATH,
			"parent_path": "SpawnParent",
			"node_name": "RestoredEnemy",
		}
	})

	assert_true(restored != null, "Dynamic restore helper must recreate loadable runtime nodes")
	if restored != null:
		assert_eq(restored.name, "RestoredEnemy", "Dynamic restore helper must apply captured node name")
		assert_eq(restored.get_parent(), parent, "Dynamic restore helper must add restored node under captured parent")

	scene.queue_free()
	await tree.process_frame
