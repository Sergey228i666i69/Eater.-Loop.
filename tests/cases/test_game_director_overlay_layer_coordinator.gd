extends "res://tests/test_case.gd"

const OverlayLayerCoordinator = preload("res://levels/game_director_overlay_layer_coordinator.gd")

func run() -> Array[String]:
	_test_resolve_layer_policy()
	_test_apply_layer_updates_canvas_layer_only_when_needed()
	return get_failures()

func _test_resolve_layer_policy() -> void:
	var coordinator: RefCounted = OverlayLayerCoordinator.new()
	assert_eq(coordinator.resolve_layer(false, false, false), OverlayLayerCoordinator.DEFAULT_OVERLAY_LAYER, "Default overlay layer must stay above gameplay")
	assert_eq(coordinator.resolve_layer(false, true, false), OverlayLayerCoordinator.PAUSED_OVERLAY_LAYER, "Pause menu must lower director overlay below pause UI")
	assert_eq(coordinator.resolve_layer(true, false, false), OverlayLayerCoordinator.PAUSED_OVERLAY_LAYER, "Paused tree outside minigame must lower director overlay")
	assert_eq(coordinator.resolve_layer(true, false, true, 120), 89, "Active minigame must keep overlay below the minigame layer")
	assert_eq(coordinator.resolve_layer(false, false, true, 42), 41, "Active minigame layer should reserve one layer above director overlay")
	assert_eq(coordinator.resolve_layer(false, false, true, -5), 0, "Minigame overlay layer must be clamped at zero")

func _test_apply_layer_updates_canvas_layer_only_when_needed() -> void:
	var coordinator: RefCounted = OverlayLayerCoordinator.new()
	var layer := CanvasLayer.new()
	layer.layer = 12
	coordinator.apply_layer(layer, false, false, false)
	assert_eq(layer.layer, OverlayLayerCoordinator.DEFAULT_OVERLAY_LAYER, "Coordinator must apply default layer")
	coordinator.apply_layer(layer, false, true, false)
	assert_eq(layer.layer, OverlayLayerCoordinator.PAUSED_OVERLAY_LAYER, "Coordinator must apply pause layer")
	layer.free()
