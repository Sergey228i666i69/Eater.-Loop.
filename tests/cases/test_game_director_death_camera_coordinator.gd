extends "res://tests/test_case.gd"

const DeathCameraCoordinator = preload("res://levels/game_director_death_camera_coordinator.gd")

func run() -> Array[String]:
	_test_capture_and_restore_camera_pose()
	_test_build_death_targets_uses_captured_pose()
	_test_restore_is_safe_after_camera_is_freed()
	return get_failures()

func _test_capture_and_restore_camera_pose() -> void:
	var coordinator: RefCounted = DeathCameraCoordinator.new()
	var camera := Camera2D.new()
	camera.rotation = 0.4
	camera.zoom = Vector2(1.5, 1.25)
	camera.offset = Vector2(8.0, -3.0)

	coordinator.capture(camera)
	camera.rotation = 1.2
	camera.zoom = Vector2(3.0, 2.0)
	camera.offset = Vector2(-10.0, 5.0)
	coordinator.restore()

	assert_true(absf(camera.rotation - 0.4) < 0.0001, "Death camera restore must recover captured rotation")
	assert_eq(camera.zoom, Vector2(1.5, 1.25), "Death camera restore must recover captured zoom")
	assert_eq(camera.offset, Vector2(8.0, -3.0), "Death camera restore must recover captured offset")
	assert_true(not coordinator.has_camera(), "Death camera restore must release the captured camera reference")
	camera.free()

func _test_build_death_targets_uses_captured_pose() -> void:
	var coordinator: RefCounted = DeathCameraCoordinator.new()
	var camera := Camera2D.new()
	camera.rotation = 0.25
	camera.zoom = Vector2(2.0, 1.5)

	coordinator.capture(camera)
	var targets: Dictionary = coordinator.build_death_targets(10.0, 1.25, -1.0)
	var expected_rotation := 0.25 - deg_to_rad(10.0)

	assert_true(absf(float(targets["rotation"]) - expected_rotation) < 0.0001, "Death camera target rotation must use captured rotation, tilt, and sign")
	assert_eq(targets["zoom"], Vector2(2.5, 1.875), "Death camera target zoom must scale captured zoom")
	camera.free()

func _test_restore_is_safe_after_camera_is_freed() -> void:
	var coordinator: RefCounted = DeathCameraCoordinator.new()
	var camera := Camera2D.new()
	coordinator.capture(camera)
	camera.free()

	coordinator.restore()

	assert_true(not coordinator.has_camera(), "Death camera coordinator must clear freed camera references")
