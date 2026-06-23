extends "res://tests/test_case.gd"

func run() -> Array[String]:
	await _test_pause_tokens_keep_tree_paused_until_all_owners_release()
	await _test_hint_release_preserves_external_pause_owner()
	await _test_minigame_finish_preserves_external_pause_owner()
	return get_failures()

func _test_pause_tokens_keep_tree_paused_until_all_owners_release() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if PauseManager == null:
		fail("PauseManager autoload is missing")
		return
	_reset_pause_state(tree)

	var owner_a := Node.new()
	var owner_b := Node.new()
	tree.root.add_child(owner_a)
	tree.root.add_child(owner_b)

	PauseManager.request_pause(owner_a, "a")
	assert_true(tree.paused, "First pause token must pause the tree")
	PauseManager.request_pause(owner_b, "b")
	assert_eq(PauseManager.get_pause_request_count(), 2, "PauseManager must track independent pause owners")

	PauseManager.release_pause(owner_a, "a")
	assert_true(tree.paused, "Releasing one of two pause owners must keep the tree paused")
	assert_eq(PauseManager.get_pause_request_count(), 1, "Releasing one owner must leave the other owner registered")

	PauseManager.release_pause(owner_b, "b")
	assert_true(not tree.paused, "Tree must unpause after the final pause owner releases")
	assert_eq(PauseManager.get_pause_request_count(), 0, "PauseManager must clear the final owner")

	var owner_c := Node.new()
	tree.root.add_child(owner_c)
	PauseManager.request_pause(owner_c, "auto_cleanup")
	assert_true(tree.paused, "Auto-cleanup fixture must pause the tree before owner exits")
	owner_c.queue_free()
	await tree.process_frame
	assert_true(not tree.paused, "PauseManager must release a Node owner's token when that owner exits the tree")

	owner_a.queue_free()
	owner_b.queue_free()
	await tree.process_frame
	_reset_pause_state(tree)

func _test_hint_release_preserves_external_pause_owner() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	var ui := tree.root.get_node_or_null("UIMessage")
	if ui == null or PauseManager == null:
		fail("UIMessage or PauseManager autoload is missing")
		return
	_reset_pause_state(tree)

	var external_owner := Node.new()
	tree.root.add_child(external_owner)
	PauseManager.request_pause(external_owner, "external")
	ui.show_hint("pause overlap", null, true)
	ui.hide_hint()

	assert_true(tree.paused, "Closing a pausing hint must not unpause while another owner still holds a token")
	PauseManager.release_pause(external_owner, "external")
	assert_true(not tree.paused, "Tree must unpause after the external owner releases")

	external_owner.queue_free()
	await tree.process_frame
	_reset_pause_state(tree)

func _test_minigame_finish_preserves_external_pause_owner() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if MinigameController == null or PauseManager == null:
		fail("MinigameController or PauseManager autoload is missing")
		return
	_reset_pause_state(tree)

	var minigame := Node.new()
	minigame.name = "PauseTokenMinigame"
	minigame.add_to_group("minigame_ui")
	tree.root.add_child(minigame)

	var settings := MinigameSettings.new()
	settings.pause_game = true
	settings.show_mouse_cursor = false
	settings.block_player_movement = false
	settings.suspend_music = false
	MinigameController.start_minigame(minigame, settings)
	assert_true(tree.paused, "Pause-game minigame must pause through PauseManager")

	PauseManager.request_pause(PauseManager, "test_pause_menu")
	MinigameController.finish_minigame(minigame, true)
	assert_true(tree.paused, "Finishing minigame must not unpause while another owner is active")

	PauseManager.release_pause(PauseManager, "test_pause_menu")
	assert_true(not tree.paused, "Tree must unpause after the remaining owner releases")

	minigame.queue_free()
	await tree.process_frame
	_reset_pause_state(tree)

func _reset_pause_state(tree: SceneTree) -> void:
	if PauseManager != null and PauseManager.has_method("clear_all_pause_requests"):
		PauseManager.clear_all_pause_requests()
	tree.paused = false
