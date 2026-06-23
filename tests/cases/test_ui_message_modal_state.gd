extends "res://tests/test_case.gd"

func run() -> Array[String]:
	await _test_repeated_pausing_hint_restores_original_pause_state()
	await _test_cancelled_fade_cannot_overwrite_screen_dark_state()
	return get_failures()

func _test_repeated_pausing_hint_restores_original_pause_state() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	var ui := tree.root.get_node_or_null("UIMessage")
	assert_true(ui != null, "UIMessage autoload is missing")
	if ui == null:
		return

	tree.paused = false
	ui.show_hint("first hint", null, true)
	ui.show_hint("second hint", null, true)
	ui.hide_hint()

	assert_true(not tree.paused, "Closing repeated pausing hints must restore the original unpaused state")
	_reset_ui_state(tree, ui)

func _test_cancelled_fade_cannot_overwrite_screen_dark_state() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	var ui := tree.root.get_node_or_null("UIMessage")
	assert_true(ui != null, "UIMessage autoload is missing")
	if ui == null:
		return

	ui.set_screen_dark(false)
	ui.fade_out(0.2)
	await tree.process_frame
	ui.set_screen_dark(false)
	for _i in range(8):
		await tree.process_frame

	assert_true(not bool(ui.call("is_screen_dark", 0.01)), "Cancelled fade_out must not later darken the screen")
	_reset_ui_state(tree, ui)

func _reset_ui_state(tree: SceneTree, ui: Node) -> void:
	if ui.has_method("hide_hint"):
		ui.hide_hint()
	if ui.has_method("set_screen_dark"):
		ui.set_screen_dark(false)
	tree.paused = false
