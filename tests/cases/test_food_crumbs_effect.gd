extends "res://tests/test_case.gd"

const FoodCrumbsEffectScript := preload("res://levels/minigames/feeding/food/food_crumbs_effect.gd")
const FoodItemScript := preload("res://levels/minigames/feeding/food/food_item.gd")
const TEST_TEXTURE := preload("res://levels/minigames/feeding/food/dumpling/Dumpling.png")

func run() -> Array[String]:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return get_failures()

	await _test_crumbs_effect_spawns_and_falls(tree)
	await _test_food_item_eat_me_triggers_crumbs(tree)
	return get_failures()

func _test_crumbs_effect_spawns_and_falls(tree: SceneTree) -> void:
	var root := Node2D.new()
	tree.root.add_child(root)
	await tree.process_frame

	var source_sprite := Sprite2D.new()
	source_sprite.texture = TEST_TEXTURE
	source_sprite.scale = Vector2(0.5, 0.5)
	root.add_child(source_sprite)

	var spawn_pos := Vector2(100.0, 100.0)
	var effect := FoodCrumbsEffectScript.create_and_spawn(source_sprite, spawn_pos, root)
	assert_true(effect != null, "FoodCrumbsEffect must be instantiated")
	assert_eq(effect.global_position, spawn_pos, "FoodCrumbsEffect position must match spawn position")

	var crumb_sprites: Array[Sprite2D] = []
	for child in effect.get_children():
		if child is Sprite2D:
			crumb_sprites.append(child as Sprite2D)

	assert_true(crumb_sprites.size() >= effect.crumb_count_min and crumb_sprites.size() <= effect.crumb_count_max,
		"FoodCrumbsEffect must spawn between %d and %d crumb sprites, got %d" % [effect.crumb_count_min, effect.crumb_count_max, crumb_sprites.size()])

	for sprite in crumb_sprites:
		assert_eq(sprite.texture, TEST_TEXTURE, "Crumb sprite must use source food texture")
		assert_true(sprite.region_enabled, "Crumb sprite must have region_enabled = true")
		assert_true(sprite.region_rect.size.x > 0.0 and sprite.region_rect.size.y > 0.0, "Crumb region_rect must have positive size")

	var initial_y_positions: Array[float] = []
	for sprite in crumb_sprites:
		initial_y_positions.append(sprite.position.y)

	# Simulate a few frames of physics
	effect._process(0.1)
	effect._process(0.1)

	for i in range(crumb_sprites.size()):
		var sprite := crumb_sprites[i]
		assert_true(sprite.position.y > initial_y_positions[i], "Crumb sprite must fall downwards over time")

	root.queue_free()
	await tree.process_frame

func _test_food_item_eat_me_triggers_crumbs(tree: SceneTree) -> void:
	var container := Node2D.new()
	tree.root.add_child(container)
	await tree.process_frame

	var food := FoodItemScript.new()
	var sprite := Sprite2D.new()
	sprite.texture = TEST_TEXTURE
	food.add_child(sprite)
	container.add_child(food)
	food.global_position = Vector2(200.0, 300.0)

	var status := {"was_eaten": false}
	food.eaten.connect(func(): status["was_eaten"] = true)

	food.eat_me()
	await tree.process_frame

	assert_true(bool(status["was_eaten"]), "food.eaten signal must be emitted upon eat_me")
	
	var found_effect: Node = null
	for child in container.get_children():
		if child.get_script() == FoodCrumbsEffectScript:
			found_effect = child
			break

	assert_true(found_effect != null, "FoodCrumbsEffect must be spawned in the container when food is eaten")

	container.queue_free()
	await tree.process_frame
