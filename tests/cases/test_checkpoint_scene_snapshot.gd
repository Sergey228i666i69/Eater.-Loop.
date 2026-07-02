extends "res://tests/test_case.gd"

const CheckpointSceneSnapshot = preload("res://levels/cycles/checkpoint_scene_snapshot.gd")
const DYNAMIC_ENEMY_SCENE_PATH := "res://tests/fixtures/dynamic_checkpoint_enemy.tscn"

func run() -> Array[String]:
	await _test_dynamic_participant_restore_and_removed_participant_state()
	return get_failures()

func _test_dynamic_participant_restore_and_removed_participant_state() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var enemy_scene := assert_loads(DYNAMIC_ENEMY_SCENE_PATH) as PackedScene
	assert_true(tree != null, "SceneTree is not available")
	if tree == null or enemy_scene == null:
		return

	var snapshot: RefCounted = CheckpointSceneSnapshot.new()
	var scene_a := Node2D.new()
	scene_a.name = "SceneCheckpointSource"
	tree.root.add_child(scene_a)
	await tree.process_frame

	var enemy := enemy_scene.instantiate() as CharacterBody2D
	assert_true(enemy != null, "Dynamic enemy fixture must instantiate as CharacterBody2D")
	if enemy == null:
		scene_a.queue_free()
		await tree.process_frame
		return
	enemy.name = "RuntimeEnemy"
	enemy.global_position = Vector2(24.0, 48.0)
	enemy.velocity = Vector2(7.0, -3.0)
	enemy.set("state_value", 17)
	scene_a.add_child(enemy)
	await tree.process_frame

	var previous_paths := PackedStringArray(["RemovedPickup"])
	var paths: Array[String] = snapshot.collect_participant_paths(scene_a, tree, previous_paths)
	assert_true(paths.has("RuntimeEnemy"), "Scene snapshot must collect runtime checkpoint participants")
	assert_true(paths.has("RemovedPickup"), "Scene snapshot must preserve previous participant paths to record removals")

	var scene_state: Dictionary = snapshot.capture_scene_state(scene_a, PackedStringArray(paths))
	var enemy_entry: Dictionary = scene_state.get("RuntimeEnemy", {})
	assert_true(bool(enemy_entry.get("exists", false)), "Existing participant must be captured as present")
	assert_true(enemy_entry.has("dynamic_restore"), "Ownerless runtime enemy must include dynamic restore metadata")
	var removed_entry: Dictionary = scene_state.get("RemovedPickup", {})
	assert_true(not bool(removed_entry.get("exists", true)), "Missing previous participant must be captured as removed")

	scene_a.queue_free()
	await tree.process_frame

	var scene_b := Node2D.new()
	scene_b.name = "SceneCheckpointTarget"
	var removed_pickup := Node2D.new()
	removed_pickup.name = "RemovedPickup"
	scene_b.add_child(removed_pickup)
	tree.root.add_child(scene_b)
	await tree.process_frame

	snapshot.apply_scene_state(scene_b, PackedStringArray(paths), scene_state)
	var restored := scene_b.get_node_or_null("RuntimeEnemy") as CharacterBody2D
	assert_true(restored != null, "Scene snapshot must recreate dynamic runtime participants")
	if restored != null:
		assert_eq(restored.global_position, Vector2(24.0, 48.0), "Restored dynamic participant must keep captured position")
		assert_eq(restored.velocity, Vector2(7.0, -3.0), "Restored dynamic participant must keep captured velocity")
		assert_eq(int(restored.get("state_value")), 17, "Restored dynamic participant must keep custom checkpoint state")
	await tree.process_frame
	assert_true(scene_b.get_node_or_null("RemovedPickup") == null, "Removed participant must be deleted on checkpoint apply")

	scene_b.queue_free()
	await tree.process_frame
