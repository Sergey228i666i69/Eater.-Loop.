extends "res://tests/test_case.gd"

func run() -> Array[String]:
	await _test_endings_are_pause_blocked_scene_type()
	return get_failures()

func _test_endings_are_pause_blocked_scene_type() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	assert_true(SceneContext != null, "SceneContext autoload is missing")
	assert_true(PauseManager != null, "PauseManager autoload is missing")
	if tree == null or SceneContext == null or PauseManager == null:
		return

	assert_true(SceneContext.is_ending_scene_path("res://levels/endings/good_ending_screen.tscn"), "SceneContext must classify ending scene paths")
	assert_true(not SceneContext.is_menu_scene_path("res://levels/endings/good_ending_screen.tscn"), "Ending scenes must not be folded into menu paths")

	var original_scene := tree.current_scene
	var ending_scene := Control.new()
	ending_scene.name = "EndingSceneProbe"
	tree.root.add_child(ending_scene)
	SceneContext.mark_ending_scene(ending_scene)
	tree.current_scene = ending_scene
	await tree.process_frame

	assert_true(bool(PauseManager.call("_is_scene_pause_blocked")), "PauseManager must block pause menu over ending scenes")

	tree.current_scene = original_scene
	ending_scene.queue_free()
	await tree.process_frame
