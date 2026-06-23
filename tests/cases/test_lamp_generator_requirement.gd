extends "res://tests/test_case.gd"

const LAMP_SCENE_PATH := "res://objects/interactable/lamp/lamp.tscn"

func run() -> Array[String]:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return get_failures()

	var root := Node.new()
	tree.root.add_child(root)

	var lamp_scene := assert_loads(LAMP_SCENE_PATH) as PackedScene
	assert_true(lamp_scene != null, "Lamp scene failed to load")
	if lamp_scene == null:
		root.queue_free()
		await tree.process_frame
		return get_failures()

	var default_lamp := lamp_scene.instantiate()
	root.add_child(default_lamp)
	await tree.process_frame

	assert_true(not bool(default_lamp.get("requires_generator")), "Default lamp should not require generator")
	assert_true(not _is_lit(default_lamp), "Default lamp should start switched off")

	default_lamp.call("_toggle")
	assert_true(_is_lit(default_lamp), "Default lamp must toggle on without generator")

	default_lamp.call("_toggle")
	assert_true(not _is_lit(default_lamp), "Default lamp must toggle off")
	assert_eq(String(default_lamp.call("_get_lamp_prompt_text")), "E — включить свет", "Lamp prompt must show the real interact key instead of legacy Q")
	if InteractionPrompts != null:
		assert_eq(String(InteractionPrompts.get_default_lamp_text(false)), "E — включить свет", "Default lamp-on prompt must use interact key")
		assert_true(String(InteractionPrompts.get_default_lamp_text(true)).find("Q") == -1, "Default lamp-off prompt must not mention removed Q input")

	var required_lamp := lamp_scene.instantiate()
	required_lamp.set("requires_generator", true)
	root.add_child(required_lamp)
	await tree.process_frame

	required_lamp.call("_toggle")
	assert_true(not _is_lit(required_lamp), "Generator-required lamp must stay off before generator")

	required_lamp.call("turn_on")
	assert_true(_is_lit(required_lamp), "Generator-required lamp must turn on after generator")

	root.queue_free()
	await tree.process_frame
	return get_failures()

func _is_lit(lamp: Node) -> bool:
	var light := lamp.get_node_or_null("PointLight2D") as PointLight2D
	return light != null and light.enabled
