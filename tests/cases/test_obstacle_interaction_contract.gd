extends "res://tests/test_case.gd"

const OBSTACLE_SCENE_PATH := "res://objects/interactable/obstacle/obstacle.tscn"

func run() -> Array[String]:
	await _test_obstacle_interact_area_contract_and_press_clear()
	return get_failures()

func _test_obstacle_interact_area_contract_and_press_clear() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var obstacle_scene := assert_loads(OBSTACLE_SCENE_PATH) as PackedScene
	assert_true(obstacle_scene != null, "Obstacle scene failed to load")
	if obstacle_scene == null:
		return

	var root := Node2D.new()
	tree.root.add_child(root)

	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)

	var obstacle := obstacle_scene.instantiate()
	obstacle.set("clear_mode", 1)
	obstacle.set("press_count", 2)
	obstacle.set("show_progress_in_prompt", false)
	root.add_child(obstacle)
	await tree.process_frame

	var interact_area := obstacle.get_node_or_null("InteractArea")
	assert_true(interact_area is InteractiveObject, "Obstacle InteractArea must keep the InteractiveObject contract")
	if interact_area is InteractiveObject:
		assert_true(not bool(interact_area.get("handle_input")), "Obstacle InteractArea must not register as a normal focused interaction candidate")
		interact_area.call("_on_interact_area_body_entered", player)
		await tree.process_frame

		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		obstacle.call("_unhandled_input", event)
		assert_true(is_instance_valid(obstacle), "Obstacle must not clear before the required press count")

		obstacle.call("_unhandled_input", event)
		await tree.process_frame
		assert_true(not is_instance_valid(obstacle), "Obstacle must clear itself after the required press count")

	root.queue_free()
	await tree.process_frame
