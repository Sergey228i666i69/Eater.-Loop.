extends "res://tests/test_case.gd"

const MusicChaseSourceRegistryScript = preload("res://levels/music_chase_source_registry.gd")


func run() -> Array[String]:
	_test_order_suppression_and_active_metadata()
	_test_mirror_collections_stay_in_sync()
	return get_failures()


func _test_order_suppression_and_active_metadata() -> void:
	var registry = MusicChaseSourceRegistryScript.new()
	var first := Node.new()
	var second := Node.new()
	registry.register_source(first, null, -7.0, 0.4)
	registry.register_source(second, null, -3.0, 0.2)

	assert_eq(registry.next_source_id(), first.get_instance_id(), "First active chase source must win by insertion order")
	var metadata: Dictionary = registry.activate_source(first.get_instance_id())
	assert_eq(float(metadata.get("volume_db", 0.0)), -7.0, "Active source metadata must preserve configured volume")
	assert_eq(registry.active_source_id(), first.get_instance_id(), "Registry must remember the active chase source")
	assert_eq(registry.active_fade_out_time(), 0.4, "Registry must preserve source-specific fade out time")

	registry.set_source_suppressed(first, true)
	assert_eq(registry.next_source_id(), second.get_instance_id(), "Suppressed active source must yield to the next source")
	registry.unregister_source(first)
	assert_eq(registry.active_source_id(), 0, "Removing the active source must clear active source state")
	assert_eq(registry.next_source_id(), second.get_instance_id(), "Removing the first source must keep the second source available")

	first.free()
	second.free()


func _test_mirror_collections_stay_in_sync() -> void:
	var sources := {}
	var order: Array[int] = []
	var suppressed := {}
	var registry = MusicChaseSourceRegistryScript.new(sources, order, suppressed)
	var source := Node.new()
	var source_id := source.get_instance_id()

	registry.register_source(source, null, -5.0, -1.0)
	registry.set_source_suppressed(source, true)
	assert_true(sources.has(source_id), "Mirror sources dictionary must include registered source")
	assert_true(order.has(source_id), "Mirror source order must include registered source")
	assert_true(suppressed.has(source_id), "Mirror suppressed dictionary must include suppressed source")

	registry.unregister_source(source)
	assert_true(not sources.has(source_id), "Mirror sources dictionary must remove unregistered source")
	assert_true(not order.has(source_id), "Mirror source order must remove unregistered source")
	assert_true(not suppressed.has(source_id), "Mirror suppressed dictionary must remove unregistered source")

	source.free()
