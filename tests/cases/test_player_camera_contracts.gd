extends "res://tests/test_case.gd"

const PlayerCameraState = preload("res://player/player_camera_state.gd")
const PlayerScene = preload("res://player/player.tscn")

func run() -> Array[String]:
	_test_camera_binding_and_configuration()
	_test_look_ahead_tracking_and_direction()
	_test_snap_and_teleport_snaps_camera_instantly()
	_test_player_teleport_api()
	return get_failures()

func _test_camera_binding_and_configuration() -> void:
	var state: RefCounted = PlayerCameraState.new()
	var camera := Camera2D.new()
	camera.position = Vector2(0.0, -26.0)
	camera.offset = Vector2(0.0, -5.0)

	state.configure(true, 7.0, 80.0, 1.5, 4.0)
	state.bind_camera(camera)

	assert_true(state.has_camera(), "Player camera state must report bound camera")
	assert_eq(camera.position_smoothing_enabled, true, "Camera position smoothing must be enabled")
	assert_eq(camera.position_smoothing_speed, 7.0, "Camera position smoothing speed must match configuration")
	assert_eq(state.get_base_position(), Vector2(0.0, -26.0), "Base camera position must be captured")
	camera.free()

func _test_look_ahead_tracking_and_direction() -> void:
	var state: RefCounted = PlayerCameraState.new()
	var camera := Camera2D.new()
	camera.position = Vector2(0.0, -26.0)

	state.configure(true, 6.0, 60.0, 1.5, 10.0)
	state.bind_camera(camera)

	# Moving right (walk)
	state.update(0.5, 1.0, true, false, false)
	var offset_right: Vector2 = state.get_look_ahead_offset()
	assert_true(offset_right.x > 30.0, "Moving right must produce positive X look-ahead offset")

	# Moving right (run)
	state.update(0.5, 1.0, true, true, false)
	var offset_run: Vector2 = state.get_look_ahead_offset()
	assert_true(offset_run.x > offset_right.x, "Running must produce larger look-ahead offset")

	# Moving left (walk)
	state.update(0.5, -1.0, true, false, false)
	var offset_left: Vector2 = state.get_look_ahead_offset()
	assert_true(offset_left.x < 0.0, "Moving left must produce negative X look-ahead offset")

	# Stopped
	for i in range(5):
		state.update(0.2, 0.0, false, false, false)
	var offset_stopped: Vector2 = state.get_look_ahead_offset()
	assert_true(absf(offset_stopped.x) < 5.0, "Stopped state must ease look-ahead back toward center")

	camera.free()

func _test_snap_and_teleport_snaps_camera_instantly() -> void:
	var state: RefCounted = PlayerCameraState.new()
	var camera := Camera2D.new()
	camera.position = Vector2(0.0, -26.0)

	state.configure(true, 6.0, 60.0, 1.5, 10.0)
	state.bind_camera(camera)

	var dummy_player := CharacterBody2D.new()
	dummy_player.global_position = Vector2(100.0, 0.0)
	dummy_player.velocity = Vector2(300.0, 0.0)

	state.teleport_to(dummy_player, Vector2(5000.0, 200.0))

	assert_eq(dummy_player.global_position, Vector2(5000.0, 200.0), "Teleport must update player global position")
	assert_eq(dummy_player.velocity, Vector2.ZERO, "Teleport must zero player velocity")

	dummy_player.free()
	camera.free()

func _test_player_teleport_api() -> void:
	var player = PlayerScene.instantiate()
	get_tree().root.add_child(player)

	assert_true(player.has_method("teleport_to"), "Player must implement teleport_to API")
	assert_true(player.has_method("snap_camera"), "Player must implement snap_camera API")
	assert_true(player.is_camera_smoothing_enabled(), "Player must enable camera smoothing by default")

	player.teleport_to(Vector2(2400.0, -100.0))
	assert_eq(player.global_position, Vector2(2400.0, -100.0), "Player teleport_to must update position")
	assert_eq(player.velocity, Vector2.ZERO, "Player teleport_to must zero velocity")

	player.queue_free()
	await get_tree().process_frame
