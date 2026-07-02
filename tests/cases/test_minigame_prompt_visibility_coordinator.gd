extends "res://tests/test_case.gd"

const PromptVisibilityCoordinator = preload("res://levels/minigames/minigame_prompt_visibility_coordinator.gd")


class FakePrompts:
	extends RefCounted

	var enabled: bool = true
	var set_values: Array[bool] = []

	func are_prompts_enabled() -> bool:
		return enabled

	func set_prompts_enabled(value: bool) -> void:
		enabled = value
		set_values.append(value)


func run() -> Array[String]:
	await _test_preserves_previous_prompt_state()
	await _test_restore_request_waits_for_target_exit()
	await _test_controller_restores_prompts_after_minigame_node_exits()
	return get_failures()


func _test_preserves_previous_prompt_state() -> void:
	var prompts := FakePrompts.new()
	prompts.enabled = false
	var coordinator := PromptVisibilityCoordinator.new()

	coordinator.suspend(prompts)
	assert_true(not prompts.enabled, "Suspending prompts must keep an already disabled prompt layer disabled")

	coordinator.restore(prompts)
	assert_true(not prompts.enabled, "Restoring prompts must preserve the disabled pre-minigame state")
	assert_eq(prompts.set_values, [false, false], "Coordinator must write suspend and restore values in order")


func _test_restore_request_waits_for_target_exit() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var prompts := FakePrompts.new()
	var coordinator := PromptVisibilityCoordinator.new()
	var restore_requests := {"count": 0}
	coordinator.connect("restore_requested", func() -> void:
		restore_requests["count"] = int(restore_requests["count"]) + 1
	)

	var minigame := Node.new()
	tree.root.add_child(minigame)
	await tree.process_frame

	coordinator.suspend(prompts)
	assert_true(coordinator.schedule_restore_target(minigame), "Coordinator must wait for an in-tree minigame node before restoring prompts")
	assert_true(coordinator.has_restore_target(), "Coordinator must remember the minigame restore target")

	minigame.queue_free()
	await tree.process_frame

	assert_eq(int(restore_requests["count"]), 1, "Coordinator must request prompt restore exactly once when the minigame exits")
	assert_true(not coordinator.has_restore_target(), "Coordinator must clear the restore target after tree exit")


func _test_controller_restores_prompts_after_minigame_node_exits() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if MinigameController == null or InteractionPrompts == null:
		fail("MinigameController or InteractionPrompts autoload is missing")
		return

	if MinigameController.has_method("_force_clear_active_state"):
		MinigameController.call("_force_clear_active_state")

	var previous_prompts_enabled := bool(InteractionPrompts.are_prompts_enabled())
	var previous_transition_enabled := bool(MinigameController.get("minigame_transition_enabled"))
	InteractionPrompts.set_prompts_enabled(true)
	MinigameController.set("minigame_transition_enabled", false)

	var host := Node.new()
	tree.root.add_child(host)
	var minigame := Node.new()
	minigame.name = "PromptVisibilityMinigame"
	host.add_child(minigame)
	await tree.process_frame

	var settings := MinigameSettings.new()
	settings.pause_game = false
	settings.show_mouse_cursor = false
	settings.block_player_movement = false
	settings.suspend_music = false

	MinigameController.start_minigame(minigame, settings)
	assert_true(not InteractionPrompts.are_prompts_enabled(), "Starting a minigame must suspend interaction prompts")

	MinigameController.finish_minigame(minigame, true)
	assert_true(not InteractionPrompts.are_prompts_enabled(), "Finishing must keep prompts hidden until the minigame node exits")

	minigame.queue_free()
	await tree.process_frame

	assert_true(InteractionPrompts.are_prompts_enabled(), "Prompts must restore after the finished minigame exits the tree")

	host.queue_free()
	await tree.process_frame
	InteractionPrompts.set_prompts_enabled(previous_prompts_enabled)
	MinigameController.set("minigame_transition_enabled", previous_transition_enabled)
	if MinigameController.has_method("_force_clear_active_state"):
		MinigameController.call("_force_clear_active_state")
