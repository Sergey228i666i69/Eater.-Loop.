extends "res://tests/test_case.gd"

const LevelBase := preload("res://levels/cycles/level.gd")

func run() -> Array[String]:
	_test_gameplay_path_classification_follows_playable_level_contract()
	_test_gameplay_scene_classification_uses_contracts_before_paths()
	await _test_endings_are_pause_blocked_scene_type()
	return get_failures()

func _test_gameplay_path_classification_follows_playable_level_contract() -> void:
	assert_true(SceneContext != null, "SceneContext autoload is missing")
	if SceneContext == null:
		return

	assert_true(SceneContext.is_gameplay_scene_path("res://levels/cycles/level_01_start.tscn"), "Playable level_*.tscn paths must be gameplay scene paths")
	assert_true(SceneContext.is_gameplay_scene_path("res://levels/cycles/level_14_end.tscn"), "Ending-cycle level_*.tscn paths must still count as gameplay paths for save tracking")
	assert_true(not SceneContext.is_gameplay_scene_path("res://levels/cycles/TextureDistortionManager.tscn"), "Utility scenes in levels/cycles must not be classified as gameplay by path")
	assert_true(not SceneContext.is_gameplay_scene_path("res://levels/cycles/checkpoint_scene_snapshot.gd"), "Helper scripts in levels/cycles must not be classified as gameplay by path")

func _test_gameplay_scene_classification_uses_contracts_before_paths() -> void:
	assert_true(SceneContext != null, "SceneContext autoload is missing")
	if SceneContext == null:
		return

	var level := LevelBase.new()
	assert_true(SceneContext.is_gameplay_scene(level), "Scenes exposing cycle/timer contract must classify as gameplay even without a level_*.tscn path")
	level.free()

	var grouped_scene := Node.new()
	SceneContext.mark_gameplay_scene(grouped_scene)
	assert_true(SceneContext.is_gameplay_scene(grouped_scene), "Scenes marked with gameplay_scene group must classify as gameplay even outside levels/cycles")
	grouped_scene.free()

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
