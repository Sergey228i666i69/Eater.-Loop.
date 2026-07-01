extends "res://tests/test_case.gd"

const DistortionGate = preload("res://levels/game_director_distortion_gate.gd")

func run() -> Array[String]:
	_test_blocking_minigame_defers_and_releases_pending_activation()
	_test_allowed_minigame_does_not_defer_distortion()
	_test_scene_reset_and_checkpoint_state()
	return get_failures()

func _test_blocking_minigame_defers_and_releases_pending_activation() -> void:
	var gate: RefCounted = DistortionGate.new()

	gate.on_minigame_started(false)
	assert_true(gate.is_minigame_active(), "Blocking minigame must mark minigame state active")
	assert_true(not gate.is_distortion_allowed(true), "Blocking minigame must hide distortion overlays")
	assert_true(gate.should_defer_activation(false), "Blocking minigame must defer distortion activation")
	assert_true(not gate.should_defer_activation(true), "Death sequence must not defer distortion activation")

	gate.mark_pending_activation()
	assert_true(gate.has_pending_activation(), "Gate must remember a deferred distortion activation")
	assert_true(gate.on_minigame_finished(), "Finishing a blocking minigame with pending activation must request activation")
	assert_true(not gate.has_pending_activation(), "Pending activation must be consumed once released")
	assert_true(not gate.is_minigame_active(), "Finished minigame must clear minigame state")

func _test_allowed_minigame_does_not_defer_distortion() -> void:
	var gate: RefCounted = DistortionGate.new()

	gate.on_minigame_started(true)

	assert_true(gate.is_minigame_active(), "Allowed minigame still counts as active for overlay layering")
	assert_true(gate.is_distortion_allowed(true), "Allowed minigame must keep distortion overlays visible")
	assert_true(not gate.should_defer_activation(false), "Allowed minigame must not defer distortion activation")
	assert_true(not gate.on_minigame_finished(), "Finishing without a pending activation must not trigger distortion")

func _test_scene_reset_and_checkpoint_state() -> void:
	var gate: RefCounted = DistortionGate.new()
	gate.on_minigame_started(false)
	gate.mark_pending_activation()

	var checkpoint: Dictionary = gate.capture_checkpoint_state()
	gate.reset_for_scene()

	assert_true(gate.is_distortion_allowed(true), "Scene reset must clear minigame blocking state")
	assert_true(not gate.has_pending_activation(), "Scene reset must clear pending activation")

	gate.apply_checkpoint_state(checkpoint)
	assert_true(gate.has_pending_activation(), "Checkpoint apply must restore pending activation")
