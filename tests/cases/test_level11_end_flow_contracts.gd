extends "res://tests/test_case.gd"

const LevelEndScript := preload("res://levels/cycles/level_11_end.gd")

class FakeInteractive:
	extends Node

	signal interaction_requested(player: Node)
	signal interaction_succeeded(result: Dictionary)
	signal interaction_finished
	signal feeding_finished

	var is_enabled: bool = true
	var enabled_history: Array[bool] = []
	var refresh_count: int = 0

	func set_interaction_enabled(enabled: bool) -> void:
		is_enabled = enabled
		enabled_history.append(enabled)

	func refresh_visual_state() -> void:
		refresh_count += 1

func run() -> Array[String]:
	await _test_attempts_do_not_choose_ending_branch()
	await _test_success_signals_choose_ending_branch()
	_test_level_end_checkpoint_state_round_trips_branch_flags()
	await _test_game_state_can_capture_scene_root_checkpoint_participant()
	return get_failures()

func _test_attempts_do_not_choose_ending_branch() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if CycleState != null:
		CycleState.reset_cycle_state()

	var fixture := await _build_level_fixture(tree)
	var level: Node = fixture["level"]
	var laptop: FakeInteractive = fixture["laptop"]
	var fridge: FakeInteractive = fixture["fridge"]

	laptop.interaction_requested.emit(null)
	fridge.interaction_requested.emit(null)

	assert_eq(int(level.get("_branch")), 0, "Final branch must not be selected by raw interaction attempts")
	assert_true(fridge.enabled_history.is_empty(), "Fridge must not be disabled by a laptop attempt")
	assert_true(laptop.enabled_history.is_empty(), "Laptop must not be disabled by a fridge attempt")

	await _free_fixture(tree, fixture)
	if CycleState != null:
		CycleState.reset_cycle_state()

func _test_success_signals_choose_ending_branch() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if CycleState != null:
		CycleState.reset_cycle_state()

	var laptop_fixture := await _build_level_fixture(tree)
	var laptop_level: Node = laptop_fixture["level"]
	var laptop: FakeInteractive = laptop_fixture["laptop"]
	var laptop_fridge: FakeInteractive = laptop_fixture["fridge"]

	laptop.interaction_finished.emit()
	assert_eq(int(laptop_level.get("_branch")), 0, "Legacy laptop finish alone must not choose laptop ending branch when typed success exists")

	laptop.interaction_succeeded.emit({"success": true})
	assert_eq(int(laptop_level.get("_branch")), 1, "Laptop success must choose laptop ending branch")
	assert_true(not laptop_fridge.is_enabled, "Laptop branch must disable fridge after successful laptop outcome")
	await _free_fixture(tree, laptop_fixture)

	var fridge_fixture := await _build_level_fixture(tree)
	var fridge_level: Node = fridge_fixture["level"]
	var fridge_laptop: FakeInteractive = fridge_fixture["laptop"]
	var fridge: FakeInteractive = fridge_fixture["fridge"]
	fridge_level.set("_ending_started", true)

	fridge.feeding_finished.emit()
	assert_eq(int(fridge_level.get("_branch")), 2, "Fridge feeding success must choose fridge ending branch")
	assert_true(not fridge_laptop.is_enabled, "Fridge branch must disable laptop after successful fridge outcome")

	await _free_fixture(tree, fridge_fixture)
	if CycleState != null:
		CycleState.reset_cycle_state()

func _test_level_end_checkpoint_state_round_trips_branch_flags() -> void:
	var original := LevelEndScript.new()
	original.set("_branch", 2)
	original.set("_ending_started", true)
	original.set("_bad_ending_queued", true)

	var state := original.call("capture_checkpoint_state") as Dictionary
	var restored := LevelEndScript.new()
	restored.call("apply_checkpoint_state", state)

	assert_eq(int(restored.get("_branch")), 2, "Level end checkpoint must restore selected branch")
	assert_true(bool(restored.get("_ending_started")), "Level end checkpoint must restore ending_started")
	assert_true(bool(restored.get("_bad_ending_queued")), "Level end checkpoint must restore queued bad ending")

	original.free()
	restored.free()

func _test_game_state_can_capture_scene_root_checkpoint_participant() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if GameState == null:
		fail("GameState autoload is missing")
		return

	var level := LevelEndScript.new()
	tree.root.add_child(level)
	await tree.process_frame

	var paths: Array = GameState.call("_collect_checkpoint_participant_paths", level)
	assert_true(paths.has("."), "GameState must include checkpoint_stateful scene roots using the '.' participant path")

	level.queue_free()
	await tree.process_frame

func _build_level_fixture(tree: SceneTree) -> Dictionary:
	var level := LevelEndScript.new()
	var hall := Node.new()
	hall.name = "Hall"
	var hall_interactables := Node.new()
	hall_interactables.name = "InteractableObjects"
	var laptop := FakeInteractive.new()
	laptop.name = "Laptop"
	var fridge := FakeInteractive.new()
	fridge.name = "Fridge"
	var bedroom := Node.new()
	bedroom.name = "Bedroom"
	var bedroom_interactables := Node.new()
	bedroom_interactables.name = "InteractableObjects"
	var bed := FakeInteractive.new()
	bed.name = "Bed"

	level.add_child(hall)
	hall.add_child(hall_interactables)
	hall_interactables.add_child(laptop)
	hall_interactables.add_child(fridge)
	level.add_child(bedroom)
	bedroom.add_child(bedroom_interactables)
	bedroom_interactables.add_child(bed)

	tree.root.add_child(level)
	await tree.process_frame

	return {
		"level": level,
		"laptop": laptop,
		"fridge": fridge,
		"bed": bed,
	}

func _free_fixture(tree: SceneTree, fixture: Dictionary) -> void:
	var level: Node = fixture["level"]
	if level != null and is_instance_valid(level):
		level.queue_free()
	await tree.process_frame
