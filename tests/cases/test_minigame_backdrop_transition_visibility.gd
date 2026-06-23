extends "res://tests/test_case.gd"

func run() -> Array[String]:
	assert_true(MinigameController != null, "MinigameController autoload is missing")
	if MinigameController == null:
		return get_failures()

	await _test_backdrop_becomes_visible_when_transition_disabled()
	await _test_timeout_signal_emits_once_without_auto_finish()
	return get_failures()

func _test_backdrop_becomes_visible_when_transition_disabled() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var host := Node.new()
	tree.root.add_child(host)
	await tree.process_frame

	var minigame := Control.new()
	minigame.name = "BackdropVisibilityProbe"
	MinigameController.attach_minigame(minigame, -1, host)
	await tree.process_frame

	var backdrop := _get_backdrop(minigame)
	assert_true(backdrop != null, "Shared mini-game backdrop must be created for plain controls")
	if backdrop != null:
		assert_true(not backdrop.visible, "Backdrop must stay hidden until the transition fade reaches black")

	var previous_transition_enabled := bool(MinigameController.get("minigame_transition_enabled"))
	MinigameController.set("minigame_transition_enabled", false)

	var settings := MinigameSettings.new()
	settings.pause_game = false
	settings.show_mouse_cursor = false
	settings.block_player_movement = false
	MinigameController.start_minigame(minigame, settings)
	await tree.process_frame

	backdrop = _get_backdrop(minigame)
	assert_true(backdrop != null and backdrop.visible, "Backdrop must become visible immediately when transition fades are disabled")

	MinigameController.finish_minigame(minigame, false)
	MinigameController.set("minigame_transition_enabled", previous_transition_enabled)
	minigame.queue_free()
	await tree.process_frame

	host.queue_free()
	await tree.process_frame

func _test_timeout_signal_emits_once_without_auto_finish() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var host := Node.new()
	tree.root.add_child(host)
	var minigame := Node.new()
	minigame.name = "TimeoutProbe"
	host.add_child(minigame)
	await tree.process_frame

	var expired := {"count": 0}
	var on_expired := func(active_minigame: Node) -> void:
		if active_minigame == minigame:
			expired["count"] = int(expired["count"]) + 1
	MinigameController.minigame_time_expired.connect(on_expired)

	var settings := MinigameSettings.new()
	settings.pause_game = false
	settings.show_mouse_cursor = false
	settings.block_player_movement = false
	settings.time_limit = 0.01
	settings.auto_finish_on_timeout = false
	MinigameController.start_minigame(minigame, settings)

	MinigameController.call("_update_timer", 0.02)
	MinigameController.call("_update_timer", 0.02)

	assert_eq(int(expired["count"]), 1, "Minigame timeout must emit exactly once while auto-finish is disabled")
	assert_true(MinigameController.has_active_minigame(), "Minigame should remain active after timeout when auto-finish is disabled")

	if MinigameController.minigame_time_expired.is_connected(on_expired):
		MinigameController.minigame_time_expired.disconnect(on_expired)
	MinigameController.finish_minigame(minigame, false)
	host.queue_free()
	await tree.process_frame

func _get_backdrop(minigame: Node) -> CanvasLayer:
	if MinigameController.has_method("_get_minigame_backdrop"):
		return MinigameController.call("_get_minigame_backdrop", minigame) as CanvasLayer
	return null
