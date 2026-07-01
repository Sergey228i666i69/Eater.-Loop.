extends "res://tests/test_case.gd"

const StalkerService = preload("res://levels/game_director_stalker_service.gd")

func run() -> Array[String]:
	await _test_spawn_capture_and_restore_round_trip()
	return get_failures()

func _test_spawn_capture_and_restore_round_trip() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var service: RefCounted = StalkerService.new()
	service.stalker_scene = _make_stalker_scene()
	assert_true(service.stalker_scene != null, "Test stalker scene must pack")
	if service.stalker_scene == null:
		return

	var scene_a := Node2D.new()
	scene_a.name = "StalkerSceneA"
	tree.root.add_child(scene_a)
	var spawn_a := Node2D.new()
	spawn_a.name = "Spawn"
	spawn_a.global_position = Vector2(16.0, 24.0)
	spawn_a.add_to_group(StalkerService.STALKER_SPAWN_GROUP)
	scene_a.add_child(spawn_a)
	await tree.process_frame

	assert_eq(service.find_spawn(tree, scene_a), spawn_a, "Service must find spawn markers inside the active scene")
	var stalker_a: Node = service.create_stalker(scene_a, Vector2(40.0, 50.0), "CustomStalker")
	assert_true(stalker_a != null, "Service must instantiate a stalker")
	await tree.process_frame
	if stalker_a != null:
		assert_eq(stalker_a.name, "CustomStalker", "Service must apply preferred stalker node name")
		assert_eq((stalker_a as Node2D).global_position, Vector2(40.0, 50.0), "Service must place the spawned stalker")
		assert_eq(service.find_active(tree, scene_a), stalker_a, "Service must find active stalkers inside the scene")

	var state: Dictionary = service.capture_checkpoint_state(tree, scene_a, true)
	assert_true(bool(state.get("stalker_spawned", false)), "Checkpoint state must preserve stalker_spawned")
	assert_eq(str(state.get("stalker_node_name", "")), "CustomStalker", "Checkpoint state must preserve stalker node name")
	var snapshot: Dictionary = state.get("stalker_snapshot", {}) as Dictionary
	assert_eq(snapshot.get("global_position"), Vector2(40.0, 50.0), "Checkpoint state must capture stalker position")

	scene_a.queue_free()
	await tree.process_frame

	var scene_b := Node2D.new()
	scene_b.name = "StalkerSceneB"
	tree.root.add_child(scene_b)
	var spawn_b := Node2D.new()
	spawn_b.name = "Spawn"
	spawn_b.global_position = Vector2(80.0, 90.0)
	spawn_b.add_to_group(StalkerService.STALKER_SPAWN_GROUP)
	scene_b.add_child(spawn_b)
	await tree.process_frame

	var restored: Node = service.restore_from_checkpoint(tree, scene_b, state)
	assert_true(restored != null, "Service must recreate stalker from checkpoint state")
	await tree.process_frame
	if restored != null:
		assert_eq(restored.name, "CustomStalker", "Restored stalker must keep checkpoint name")
		assert_eq((restored as Node2D).global_position, Vector2(40.0, 50.0), "Restored stalker must use checkpoint position")
		assert_eq(service.find_active(tree, scene_b), restored, "Restored stalker must be discoverable as active")

	scene_b.queue_free()
	await tree.process_frame

func _make_stalker_scene() -> PackedScene:
	var stalker := Node2D.new()
	stalker.name = "Stalker"
	stalker.add_to_group(StalkerService.STALKER_ENEMY_GROUP, true)
	var packed := PackedScene.new()
	var error := packed.pack(stalker)
	stalker.free()
	return packed if error == OK else null
