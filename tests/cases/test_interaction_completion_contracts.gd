extends "res://tests/test_case.gd"

const DoorScript := preload("res://objects/interactable/door/door.gd")
const FridgeScript := preload("res://objects/interactable/fridge/fridge.gd")
const LaptopScript := preload("res://objects/interactable/notebook/laptop.gd")
const BlockpostScript := preload("res://objects/interactable/level12/blockpost/blockpost.gd")
const SearchSpotScript := preload("res://objects/interactable/search_spot/search_spot.gd")
const Level12MoneySystemScript := preload("res://objects/interactable/level12/money/level12_money_system.gd")

class DummyPlayer:
	extends CharacterBody2D

	var keys := {}

	func _ready() -> void:
		add_to_group("player")

	func has_key(key_id: String) -> bool:
		return bool(keys.get(key_id, false))

	func remove_key(key_id: String) -> void:
		keys.erase(key_id)

func _attach_completed_dependent(root: Node, dependency: InteractiveObject) -> InteractiveObject:
	var dependent := InteractiveObject.new()
	root.add_child(dependent)
	dependent.set_dependency_object(dependency)
	dependent.set_dependency_condition(InteractiveObject.DependencyCondition.COMPLETED)
	return dependent

func run() -> Array[String]:
	await _test_locked_door_attempt_does_not_complete_one_shot_contract()
	await _test_broken_door_transition_does_not_complete_one_shot_contract()
	await _test_self_target_door_transition_does_not_complete_one_shot_contract()
	await _test_successful_door_transition_completes_interaction()
	await _test_fridge_locked_gates_do_not_complete_one_shot_contract()
	await _test_laptop_dependency_attempt_unlock_does_not_complete_laptop()
	await _test_blockpost_completes_only_after_successful_payment()
	await _test_search_spot_key_success_completes_interaction()
	return get_failures()

func _test_locked_door_attempt_does_not_complete_one_shot_contract() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var player := DummyPlayer.new()
	var door := DoorScript.new()
	door.one_shot = true
	door.is_locked = true
	door.required_key_id = "door_key"
	root.add_child(door)
	root.add_child(player)
	tree.root.add_child(root)
	await tree.process_frame

	var dependent := _attach_completed_dependent(root, door)
	door.call("_on_interact_area_body_entered", player)
	door.request_interact()

	assert_true(not door.is_completed, "Locked door must not complete after a failed one-shot interaction attempt")
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Failed locked door attempt must not satisfy completed dependencies")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_search_spot_key_success_completes_interaction() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var search_spot := SearchSpotScript.new()
	search_spot.name = "SearchSpot"
	search_spot.one_shot = false
	search_spot.has_key = true
	root.add_child(search_spot)
	tree.root.add_child(root)
	await tree.process_frame

	var dependent := _attach_completed_dependent(root, search_spot)
	search_spot.call("_on_minigame_finished", null, true)

	assert_true(search_spot.is_completed, "SearchSpot must complete after successful key discovery")
	assert_true(search_spot.is_searched_empty, "SearchSpot must become searched-empty after successful key discovery")
	assert_true(not search_spot.has_key, "SearchSpot must consume its key after successful discovery")
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "Successful key discovery must satisfy completed dependencies")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_broken_door_transition_does_not_complete_one_shot_contract() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var player := DummyPlayer.new()
	var door := DoorScript.new()
	door.one_shot = true
	door.is_locked = false
	door.target_marker = NodePath("")
	root.add_child(door)
	root.add_child(player)
	tree.root.add_child(root)
	await tree.process_frame

	door.call("_on_interact_area_body_entered", player)
	door.request_interact()
	await tree.process_frame

	assert_true(not door.is_completed, "Door with missing target marker must not complete after a failed transition")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_self_target_door_transition_does_not_complete_one_shot_contract() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var player := DummyPlayer.new()
	player.global_position = Vector2(10.0, 20.0)
	var door := DoorScript.new()
	door.one_shot = true
	door.is_locked = false
	door.target_marker = NodePath(".")
	root.add_child(door)
	root.add_child(player)
	tree.root.add_child(root)
	await tree.process_frame

	door.call("_on_interact_area_body_entered", player)
	door.request_interact()
	await tree.process_frame

	assert_true(not door.is_completed, "Door with self target marker must not complete after a failed transition")
	assert_eq(player.global_position, Vector2(10.0, 20.0), "Self-target door must not move the player")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_successful_door_transition_completes_interaction() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var player := DummyPlayer.new()
	player.name = "Player"
	var door := DoorScript.new()
	door.name = "Door"
	door.one_shot = true
	door.is_locked = false
	door.target_marker = NodePath("../DoorTarget")
	var target := Marker2D.new()
	target.name = "DoorTarget"
	target.global_position = Vector2(50.0, 60.0)
	root.add_child(door)
	root.add_child(target)
	root.add_child(player)
	tree.root.add_child(root)
	await tree.process_frame

	door.call("_on_interact_area_body_entered", player)
	door.request_interact()
	await _wait_for_condition(tree, func() -> bool:
		return door.is_completed
	)

	assert_true(door.is_completed, "Door must complete only after a successful transition")
	assert_eq(player.global_position, target.global_position, "Successful door transition must move the player to the target marker")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_fridge_locked_gates_do_not_complete_one_shot_contract() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return
	if CycleState != null:
		CycleState.reset_cycle_state()

	var root := Node2D.new()
	var lab_locked_fridge := FridgeScript.new()
	lab_locked_fridge.one_shot = true
	lab_locked_fridge.require_lab_completion = true
	root.add_child(lab_locked_fridge)
	tree.root.add_child(root)
	await tree.process_frame

	var dependent := _attach_completed_dependent(root, lab_locked_fridge)
	lab_locked_fridge.request_interact()
	assert_true(not lab_locked_fridge.is_completed, "Fridge locked by lab completion must not complete after an attempt")
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Failed lab-locked fridge attempt must not satisfy completed dependencies")

	var code_locked_fridge := FridgeScript.new()
	code_locked_fridge.one_shot = true
	code_locked_fridge.require_access_code = true
	root.add_child(code_locked_fridge)
	await tree.process_frame

	dependent = _attach_completed_dependent(root, code_locked_fridge)
	code_locked_fridge.request_interact()
	assert_true(not code_locked_fridge.is_completed, "Fridge locked by missing code minigame must not complete after an attempt")
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Failed code-locked fridge attempt must not satisfy completed dependencies")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame
	if CycleState != null:
		CycleState.reset_cycle_state()

func _test_laptop_dependency_attempt_unlock_does_not_complete_laptop() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var dependency := InteractiveObject.new()
	dependency.name = "Dependency"
	var laptop := LaptopScript.new()
	laptop.name = "Laptop"
	laptop.one_shot = true
	laptop.unlock_on_dependency_interaction = true
	laptop.dependency_object = dependency
	root.add_child(dependency)
	root.add_child(laptop)
	tree.root.add_child(root)
	await tree.process_frame

	dependency.request_interact()

	assert_eq(laptop.get_dependency_condition(), InteractiveObject.DependencyCondition.INTERACTION_REQUESTED, "Legacy laptop attempt flag must set the typed dependency condition")
	assert_true(bool(laptop.call("_is_dependency_satisfied")), "Laptop should still unlock on dependency interaction attempts")
	assert_true(not laptop.is_completed, "Laptop dependency-attempt unlock must not mark the laptop completed")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _test_blockpost_completes_only_after_successful_payment() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var player := DummyPlayer.new()
	var money_system := Level12MoneySystemScript.new()
	money_system.name = "Money"
	money_system.hud_show_duration = 0.5
	var passage_checks: Array[bool] = []
	money_system.passage_check.connect(func(_current_money: int, _required_money: int, can_pass: bool) -> void:
		passage_checks.append(can_pass)
	)
	var blockpost := BlockpostScript.new()
	blockpost.name = "Blockpost"
	blockpost.one_shot = true
	blockpost.money_system_path = NodePath("../Money")
	root.add_child(blockpost)
	root.add_child(money_system)
	root.add_child(player)
	tree.root.add_child(root)
	await tree.process_frame

	var dependent := _attach_completed_dependent(root, blockpost)
	blockpost.call("_on_interact_area_body_entered", player)
	blockpost.request_interact()
	assert_true(not blockpost.is_completed, "Blockpost must not complete after failed payment")
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Failed blockpost payment must not satisfy completed dependencies")

	money_system.add_money(100, "Test")
	blockpost.request_interact()
	assert_true(blockpost.is_completed, "Blockpost must complete after successful payment")
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "Successful blockpost payment must satisfy completed dependencies")
	assert_eq(passage_checks, [false, true], "Blockpost should check the payment system for each active interaction attempt")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame

func _wait_for_condition(tree: SceneTree, predicate: Callable, timeout_seconds: float = 1.5) -> void:
	var timeout := tree.create_timer(timeout_seconds, true)
	var tick := tree.create_timer(0.05, true)
	while not bool(predicate.call()) and timeout.time_left > 0.0:
		await tick.timeout
		tick = tree.create_timer(0.05, true)
