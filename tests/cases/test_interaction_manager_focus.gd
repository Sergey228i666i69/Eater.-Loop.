extends "res://tests/test_case.gd"

class ProbeInteractive:
	extends InteractiveObject

	var interactions: int = 0

	func _on_interact() -> void:
		interactions += 1

func run() -> Array[String]:
	await _test_only_focused_interactive_consumes_input()
	await _test_active_minigame_blocks_world_interactions()
	return get_failures()

func _test_only_focused_interactive_consumes_input() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	assert_true(InteractionManager != null, "InteractionManager autoload is missing")
	if tree == null or InteractionManager == null:
		return

	InteractionManager.clear_candidates()
	var root := Node2D.new()
	tree.root.add_child(root)

	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)

	var low := ProbeInteractive.new()
	low.name = "LowPriority"
	low.interaction_priority = 0
	root.add_child(low)

	var high := ProbeInteractive.new()
	high.name = "HighPriority"
	high.interaction_priority = 10
	root.add_child(high)
	await tree.process_frame

	low.call("_on_interact_area_body_entered", player)
	high.call("_on_interact_area_body_entered", player)

	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	InteractionManager.call("_unhandled_input", event)

	assert_eq(low.interactions, 0, "Lower-priority overlapping interactive must not receive the shared input")
	assert_eq(high.interactions, 1, "Highest-priority interactive must receive the shared input")

	high.call("_on_interact_area_body_exited", player)
	InteractionManager.call("_unhandled_input", event)
	assert_eq(low.interactions, 1, "Remaining interactive should become focused after higher-priority object exits")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_active_minigame_blocks_world_interactions() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	assert_true(InteractionManager != null, "InteractionManager autoload is missing")
	assert_true(MinigameController != null, "MinigameController autoload is missing")
	if tree == null or InteractionManager == null or MinigameController == null:
		return

	InteractionManager.clear_candidates()
	var root := Node2D.new()
	tree.root.add_child(root)

	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)

	var interactive := ProbeInteractive.new()
	interactive.name = "WorldInteractive"
	root.add_child(interactive)
	await tree.process_frame

	interactive.call("_on_interact_area_body_entered", player)

	var minigame := Node.new()
	minigame.name = "ActiveMinigame"
	root.add_child(minigame)
	MinigameController.start_minigame(minigame, {"pause_game": false})

	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	InteractionManager.call("_unhandled_input", event)

	assert_eq(interactive.interactions, 0, "Active minigame must consume world interaction input before focused objects run")

	MinigameController.finish_minigame(minigame, false)
	InteractionManager.call("_unhandled_input", event)
	assert_eq(interactive.interactions, 1, "World interaction should resume after the active minigame finishes")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame
