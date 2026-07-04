extends "res://tests/test_case.gd"

const MusicAmbientSuppressionStateScript = preload("res://levels/music_ambient_suppression_state.gd")

var _exited_source_ids: Array[int] = []


func run() -> Array[String]:
	_test_multiple_sources_gate_active_state()
	_test_weakref_cleanup_removes_freed_sources()
	await _test_tree_exit_callback_is_connected_for_nodes()
	return get_failures()


func _test_multiple_sources_gate_active_state() -> void:
	var mirror: Dictionary = {}
	var state = MusicAmbientSuppressionStateScript.new(mirror)
	var source_a := RefCounted.new()
	var source_b := RefCounted.new()

	assert_true(state.set_suppressed(source_a, true), "First suppression source must activate ambient suppression")
	assert_true(not state.set_suppressed(source_b, true), "Second suppression source must keep ambient suppression active without a new activation")
	assert_true(state.is_active(), "Ambient suppression state must stay active while sources exist")
	assert_true(mirror.has(source_a.get_instance_id()), "State must update caller-owned mirror for the first source")
	assert_true(mirror.has(source_b.get_instance_id()), "State must update caller-owned mirror for the second source")

	assert_true(not state.set_suppressed(source_a, false), "Removing one of several sources must not deactivate ambient suppression")
	assert_true(state.is_active(), "Ambient suppression state must remain active while another source exists")
	assert_true(state.set_suppressed(source_b, false), "Removing the final source must deactivate ambient suppression")
	assert_true(not state.is_active(), "Ambient suppression state must be inactive after final source removal")
	assert_true(mirror.is_empty(), "State must clear caller-owned mirror after all sources are removed")


func _test_weakref_cleanup_removes_freed_sources() -> void:
	var state = MusicAmbientSuppressionStateScript.new()
	var source := RefCounted.new()
	var source_id := source.get_instance_id()
	assert_true(state.set_suppressed(source, true), "Freed-source test must start with active suppression")
	assert_true(state.has_id(source_id), "State must contain source before it is freed")

	source = null
	state.cleanup_stale()

	assert_true(not state.has_id(source_id), "State must remove stale weakref source ids")
	assert_true(not state.is_active(), "State must become inactive after stale source cleanup")


func _test_tree_exit_callback_is_connected_for_nodes() -> void:
	_exited_source_ids.clear()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var state = MusicAmbientSuppressionStateScript.new()
	var source := Node.new()
	tree.root.add_child(source)
	await tree.process_frame

	var source_id := source.get_instance_id()
	assert_true(state.set_suppressed(source, true, self, &"_on_source_exited"), "Node suppression source register must activate suppression")
	source.queue_free()
	await tree.process_frame
	await tree.process_frame

	assert_true(_exited_source_ids.has(source_id), "State must connect the requested tree_exited callback for Node sources")


func _on_source_exited(source_id: int) -> void:
	_exited_source_ids.append(source_id)
