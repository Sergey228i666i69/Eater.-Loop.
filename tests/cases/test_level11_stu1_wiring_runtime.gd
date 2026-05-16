extends "res://tests/test_case.gd"

const LEVEL_SCENE_PATH := "res://levels/cycles/level_11_STU_1.tscn"

func run() -> Array[String]:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return get_failures()
	if CycleState != null and CycleState.has_method("reset_cycle_state"):
		CycleState.reset_cycle_state()

	var level_scene := assert_loads(LEVEL_SCENE_PATH) as PackedScene
	assert_true(level_scene != null, "Level 11 scene failed to load")
	if level_scene == null:
		return get_failures()

	var level := level_scene.instantiate()
	level.set("show_start_subtitle", false)
	tree.root.add_child(level)
	await tree.process_frame
	await tree.process_frame

	var fridge := level.get_node_or_null("6thLevel/604/InteractableObjects/Fridge") as InteractiveObject
	var note_story := level.get_node_or_null("NoteStory") as InteractiveObject
	assert_true(fridge != null, "Level 11 fridge node is missing")
	assert_true(note_story != null, "Level 11 NoteStory node is missing")

	if fridge != null and note_story != null:
		assert_true(note_story.get("dependency_object") == fridge, "NoteStory must depend on the level 11 fridge")
		assert_eq(note_story.get_dependency_condition(), InteractiveObject.DependencyCondition.COMPLETED, "NoteStory must use completed dependency condition")
		assert_true(not bool(note_story.call("_is_dependency_satisfied")), "NoteStory must stay locked before fridge completion")

		fridge.complete_interaction()
		await tree.process_frame
		assert_true(bool(note_story.call("_is_dependency_satisfied")), "NoteStory must unlock only after fridge completion")

	level.queue_free()
	await tree.process_frame
	if CycleState != null and CycleState.has_method("reset_cycle_state"):
		CycleState.reset_cycle_state()
	return get_failures()
