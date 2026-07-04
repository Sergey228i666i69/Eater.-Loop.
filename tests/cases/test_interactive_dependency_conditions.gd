extends "res://tests/test_case.gd"

class ProbeInteractive:
	extends InteractiveObject

	var interactions: int = 0

	func _on_interact() -> void:
		interactions += 1

func run() -> Array[String]:
	await _test_interaction_result_signals_separate_success_failure_and_legacy_finish()
	await _test_default_condition_behaves_like_legacy_completion()
	await _test_completed_condition_ignores_attempts()
	await _test_interaction_requested_condition_unlocks_on_attempt()
	await _test_interaction_requested_checkpoint_state_restores_unlock()
	await _test_rebinding_dependency_disconnects_old_signals()
	await _test_prompt_and_availability_follow_typed_condition()
	return get_failures()

func _test_interaction_result_signals_separate_success_failure_and_legacy_finish() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var object := ProbeInteractive.new()
	var dependent := ProbeInteractive.new()
	var results: Array[Dictionary] = []
	var successes: Array[Dictionary] = []
	var failures: Array[Dictionary] = []
	var legacy_finish_count: Array[int] = [0]
	root.add_child(object)
	root.add_child(dependent)
	tree.root.add_child(root)
	await tree.process_frame

	dependent.set_dependency_object(object)
	dependent.set_dependency_condition(InteractiveObject.DependencyCondition.COMPLETED)
	object.interaction_result.connect(func(result: Dictionary) -> void:
		results.append(result)
	)
	object.interaction_succeeded.connect(func(result: Dictionary) -> void:
		successes.append(result)
	)
	object.interaction_failed.connect(func(result: Dictionary) -> void:
		failures.append(result)
	)
	object.interaction_finished.connect(func() -> void:
		legacy_finish_count[0] += 1
	)

	object.fail_interaction("probe_failure")
	assert_true(not object.is_completed, "Failed interaction result must not mark object completed")
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Failed result must not satisfy completed dependency")
	assert_eq(failures.size(), 1, "Failed interaction must emit typed failure signal")
	assert_eq(int(failures[0].get(InteractiveObject.RESULT_OUTCOME)), InteractiveObject.InteractionOutcome.FAILED, "Failure result must expose failed outcome")
	assert_eq(str(failures[0].get(InteractiveObject.RESULT_REASON)), "probe_failure", "Failure result must preserve reason")
	assert_true(failures[0].get(InteractiveObject.RESULT_PAYLOAD) is Dictionary, "Failure result must expose typed payload dictionary")
	assert_eq(legacy_finish_count[0], 0, "Failed result must not emit legacy interaction_finished")

	object.complete_interaction(InteractionResultBuilder.with_payload({
		"reward_type": "probe",
		"item_id": "ok"
	}, {
		"legacy_payload": "ok"
	}))
	assert_true(object.is_completed, "Successful interaction result must mark object completed")
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "Successful result must satisfy completed dependency")
	assert_eq(successes.size(), 1, "Successful interaction must emit typed success signal")
	assert_eq(int(successes[0].get(InteractiveObject.RESULT_OUTCOME)), InteractiveObject.InteractionOutcome.SUCCEEDED, "Success result must expose succeeded outcome")
	assert_eq(str(successes[0].get("legacy_payload")), "ok", "Success result must preserve custom top-level keys")
	var success_payload: Dictionary = successes[0].get(InteractiveObject.RESULT_PAYLOAD, {})
	assert_eq(str(success_payload.get("item_id")), "ok", "Success result must preserve typed payload data")
	assert_eq(legacy_finish_count[0], 1, "Successful completion must keep legacy interaction_finished compatibility")
	assert_eq(results.size(), 2, "Typed result stream must include failure and success outcomes")

	root.queue_free()
	await tree.process_frame

func _test_default_condition_behaves_like_legacy_completion() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var dependency := ProbeInteractive.new()
	var dependent := ProbeInteractive.new()
	root.add_child(dependency)
	root.add_child(dependent)
	tree.root.add_child(root)
	await tree.process_frame

	dependent.set_dependency_object(dependency)

	dependency.request_interact()
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Default dependency condition must ignore mere interaction attempts")

	dependency.complete_interaction()
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "Default dependency condition must unlock after completion")

	root.queue_free()
	await tree.process_frame

func _test_completed_condition_ignores_attempts() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var dependency := ProbeInteractive.new()
	var dependent := ProbeInteractive.new()
	root.add_child(dependency)
	root.add_child(dependent)
	tree.root.add_child(root)
	await tree.process_frame

	dependent.set_dependency_object(dependency)
	dependent.set_dependency_condition(InteractiveObject.DependencyCondition.COMPLETED)

	dependency.request_interact()
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "COMPLETED dependency condition must not unlock on interaction_requested")

	dependency.complete_interaction()
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "COMPLETED dependency condition must unlock after interaction_finished")

	root.queue_free()
	await tree.process_frame

func _test_interaction_requested_condition_unlocks_on_attempt() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var dependency := ProbeInteractive.new()
	var dependent := ProbeInteractive.new()
	root.add_child(dependency)
	root.add_child(dependent)
	tree.root.add_child(root)
	await tree.process_frame

	dependent.set_dependency_object(dependency)
	dependent.set_dependency_condition(InteractiveObject.DependencyCondition.INTERACTION_REQUESTED)

	dependency.request_interact()
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "INTERACTION_REQUESTED dependency condition must unlock on interaction_requested")
	assert_true(not dependent.is_completed, "Dependency-attempt unlock must not mark the dependent object completed")

	root.queue_free()
	await tree.process_frame

func _test_interaction_requested_checkpoint_state_restores_unlock() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var dependency := ProbeInteractive.new()
	var original := ProbeInteractive.new()
	var restored := ProbeInteractive.new()
	root.add_child(dependency)
	root.add_child(original)
	root.add_child(restored)
	tree.root.add_child(root)
	await tree.process_frame

	original.set_dependency_object(dependency)
	original.set_dependency_condition(InteractiveObject.DependencyCondition.INTERACTION_REQUESTED)
	restored.set_dependency_object(dependency)
	restored.set_dependency_condition(InteractiveObject.DependencyCondition.INTERACTION_REQUESTED)

	dependency.request_interact()
	var state := original.capture_checkpoint_state()
	assert_true(bool(state.get("dependency_request_satisfied", false)), "Checkpoint state must store requested dependency unlocks")

	restored.apply_checkpoint_state(state)
	assert_true(bool(restored.call("_is_dependency_satisfied")), "Checkpoint restore must preserve requested dependency unlocks")

	root.queue_free()
	await tree.process_frame

func _test_rebinding_dependency_disconnects_old_signals() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var first_dependency := ProbeInteractive.new()
	var second_dependency := ProbeInteractive.new()
	var dependent := ProbeInteractive.new()
	root.add_child(first_dependency)
	root.add_child(second_dependency)
	root.add_child(dependent)
	tree.root.add_child(root)
	await tree.process_frame

	dependent.set_dependency_object(first_dependency)
	dependent.set_dependency_condition(InteractiveObject.DependencyCondition.INTERACTION_REQUESTED)
	first_dependency.request_interact()
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "First dependency should satisfy the requested condition")

	dependent.set_dependency_object(second_dependency)
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Rebinding dependency must reset the requested unlock state")

	first_dependency.request_interact()
	assert_true(not bool(dependent.call("_is_dependency_satisfied")), "Old dependency signal must be disconnected after rebinding")

	second_dependency.request_interact()
	assert_true(bool(dependent.call("_is_dependency_satisfied")), "New dependency signal must unlock after rebinding")

	root.queue_free()
	await tree.process_frame

func _test_prompt_and_availability_follow_typed_condition() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var root := Node2D.new()
	var player := Node2D.new()
	player.add_to_group("player")
	var dependency := ProbeInteractive.new()
	var dependent := ProbeInteractive.new()
	dependent.prompt_text = "Use"
	root.add_child(player)
	root.add_child(dependency)
	root.add_child(dependent)
	tree.root.add_child(root)
	await tree.process_frame

	dependent.set_dependency_object(dependency)
	dependent.set_dependency_condition(InteractiveObject.DependencyCondition.INTERACTION_REQUESTED)
	dependent.call("_on_interact_area_body_entered", player)

	assert_true(not dependent.can_show_manager_prompt(), "Prompt availability must stay false before requested dependency")
	assert_true(not bool(dependent.call("_is_interaction_available")), "Interaction availability must stay false before requested dependency")

	dependency.request_interact()
	assert_true(dependent.can_show_manager_prompt(), "Prompt availability must become true after requested dependency")
	assert_true(bool(dependent.call("_is_interaction_available")), "Interaction availability must become true after requested dependency")

	InteractionManager.clear_candidates()
	root.queue_free()
	await tree.process_frame
