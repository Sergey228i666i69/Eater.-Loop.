extends "res://tests/test_case.gd"

const MusicScopedSourceRegistryScript = preload("res://levels/music_scoped_source_registry.gd")

var _exited_source_ids: Array[int] = []


func run() -> Array[String]:
	_test_register_updates_metadata_and_mirror()
	await _test_tree_exit_callback_is_connected_for_nodes()
	return get_failures()


func _test_register_updates_metadata_and_mirror() -> void:
	var mirror: Dictionary = {}
	var registry = MusicScopedSourceRegistryScript.new(mirror)
	var source := RefCounted.new()
	var source_id := source.get_instance_id()

	assert_true(registry.register(source, {"fade_out_time": 0.25}), "First source register must report a new scoped source")
	assert_true(registry.has_id(source_id), "Registry must store registered source id")
	assert_true(mirror.has(source_id), "Registry must update the caller-owned mirror dictionary")
	assert_eq(float(registry.get_metadata(source_id).get("fade_out_time", -1.0)), 0.25, "Registry must expose registered metadata")

	assert_true(not registry.register(source, {"fade_out_time": 0.75}), "Duplicate source register must not report a new scoped source")
	assert_eq(float(registry.get_metadata(source_id).get("fade_out_time", -1.0)), 0.75, "Duplicate register must refresh source metadata")

	registry.unregister_id(source_id)
	assert_true(not registry.has_id(source_id), "Unregister must remove source id")
	assert_true(not mirror.has(source_id), "Unregister must update the caller-owned mirror dictionary")

	registry.register(source, {"fade_out_time": 1.0})
	registry.clear()
	assert_true(mirror.is_empty(), "Clear must reset the caller-owned mirror dictionary")


func _test_tree_exit_callback_is_connected_for_nodes() -> void:
	_exited_source_ids.clear()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var registry = MusicScopedSourceRegistryScript.new()
	var source := Node.new()
	tree.root.add_child(source)
	await tree.process_frame

	var source_id := source.get_instance_id()
	assert_true(registry.register(source, {}, self, &"_on_source_exited"), "Node source register must succeed")
	source.queue_free()
	await tree.process_frame
	await tree.process_frame

	assert_true(_exited_source_ids.has(source_id), "Registry must connect the requested tree_exited callback for Node sources")


func _on_source_exited(source_id: int) -> void:
	_exited_source_ids.append(source_id)
