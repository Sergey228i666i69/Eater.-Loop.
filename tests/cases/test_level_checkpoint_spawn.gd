extends "res://tests/test_case.gd"

class DummyPlayer:
	extends Node2D

class DummyMarker:
	extends Marker2D

func run() -> Array[String]:
	await _test_level_moves_player_to_fridge_checkpoint_spawn()
	_test_next_cycle_preserves_pending_sleep_spawn()
	return get_failures()

func _test_level_moves_player_to_fridge_checkpoint_spawn() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	assert_true(GameState != null, "GameState autoload is missing")
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if CycleState == null or GameState == null or tree == null:
		return

	GameState.reset_run()
	CycleState.reset_cycle_state()
	CycleState.mark_fridge_interacted()

	var level := load("res://levels/cycles/level.gd").new() as Node2D
	var marker := DummyMarker.new()
	marker.name = "CheckpointMarker"
	marker.position = Vector2(840.0, 420.0)
	level.add_child(marker)
	level.set("fridge_interacted_spawn_marker_path", NodePath("CheckpointMarker"))

	var player := DummyPlayer.new()
	player.position = Vector2(-100.0, 50.0)
	player.add_to_group("player")

	tree.root.add_child(level)
	tree.root.add_child(player)
	await tree.process_frame

	level.call("_apply_conditional_respawn_position")

	assert_eq(player.global_position, marker.global_position, "Level must respawn the player at the configured fridge checkpoint marker")

	player.queue_free()
	level.queue_free()
	await tree.process_frame
	GameState.reset_run()
	CycleState.reset_cycle_state()

func _test_next_cycle_preserves_pending_sleep_spawn() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	assert_true(GameState != null, "GameState autoload is missing")
	if CycleState == null or GameState == null:
		return
	GameState.reset_run()
	CycleState.reset_cycle_state()
	CycleState.queue_sleep_spawn()
	GameState.next_cycle()
	assert_true(bool(CycleState.has_pending_sleep_spawn()), "Sleep spawn flag must survive the cycle transition that loads the next bedroom")
	CycleState.consume_pending_sleep_spawn()
	GameState.reset_run()
	CycleState.reset_cycle_state()
