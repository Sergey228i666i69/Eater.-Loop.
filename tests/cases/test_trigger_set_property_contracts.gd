extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const TRIGGER_SCRIPT := "res://objects/interactable/trigger/trigger_set_property.gd"
const MUSIC_ACTION_NONE := 0
const MUSIC_ACTION_REPLACE := 1
const MUSIC_ACTION_EVENT_START := 4

func run() -> Array[String]:
	_test_configured_trigger_targets_resolve()
	return get_failures()

func _test_configured_trigger_targets_resolve() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			if _script_path(node) != TRIGGER_SCRIPT:
				continue
			_assert_trigger_property_targets(path, root, node)
			_assert_trigger_has_configured_effect(path, root, node)
		root.free()

func _assert_trigger_property_targets(scene_path: String, root: Node, trigger: Node) -> void:
	var changes: Array = trigger.get("changes")
	if not changes.is_empty():
		for index in range(changes.size()):
			var change := changes[index] as PropertyChange
			assert_true(change != null, "Trigger change must be a PropertyChange: %s:%s[%d]" % [scene_path, root.get_path_to(trigger), index])
			if change == null:
				continue
			_assert_change_target(scene_path, root, trigger, change, index)
		return

	var property_name := str(trigger.get("property_name")).strip_edges()
	var target_paths: Array = trigger.get("target_paths")
	var has_simple_property_change := property_name != "" or not target_paths.is_empty()
	if not has_simple_property_change:
		return

	assert_true(property_name != "", "Trigger simple property change must declare property_name: %s:%s" % [scene_path, root.get_path_to(trigger)])
	assert_true(not target_paths.is_empty(), "Trigger simple property change must declare target_paths: %s:%s" % [scene_path, root.get_path_to(trigger)])
	if property_name == "":
		return
	for index in range(target_paths.size()):
		var target_path: NodePath = target_paths[index]
		assert_true(not target_path.is_empty(), "Trigger target_paths entry must not be empty: %s:%s[%d]" % [scene_path, root.get_path_to(trigger), index])
		if target_path.is_empty():
			continue
		var target := trigger.get_node_or_null(target_path)
		assert_true(target != null, "Trigger target_path must resolve: %s:%s[%d] -> %s" % [scene_path, root.get_path_to(trigger), index, target_path])
		if target != null:
			assert_true(_has_property(target, property_name), "Trigger target must expose property '%s': %s:%s[%d] -> %s" % [property_name, scene_path, root.get_path_to(trigger), index, target_path])

func _assert_change_target(scene_path: String, root: Node, trigger: Node, change: PropertyChange, index: int) -> void:
	var target_path := change.target
	var property_name := change.property_name.strip_edges()
	assert_true(not target_path.is_empty(), "Trigger PropertyChange target must not be empty: %s:%s[%d]" % [scene_path, root.get_path_to(trigger), index])
	assert_true(property_name != "", "Trigger PropertyChange property_name must not be empty: %s:%s[%d]" % [scene_path, root.get_path_to(trigger), index])
	if target_path.is_empty() or property_name == "":
		return
	var target := trigger.get_node_or_null(target_path)
	assert_true(target != null, "Trigger PropertyChange target must resolve: %s:%s[%d] -> %s" % [scene_path, root.get_path_to(trigger), index, target_path])
	if target != null:
		assert_true(_has_property(target, property_name), "Trigger PropertyChange target must expose property '%s': %s:%s[%d] -> %s" % [property_name, scene_path, root.get_path_to(trigger), index, target_path])

func _assert_trigger_has_configured_effect(scene_path: String, root: Node, trigger: Node) -> void:
	var has_property_effect := _trigger_has_property_effect(trigger)
	var has_sfx_effect := trigger.get("sfx_stream") is AudioStream
	var has_music_effect := _trigger_has_music_effect(trigger)
	assert_true(
		has_property_effect or has_sfx_effect or has_music_effect,
		"TriggerSetProperty must configure at least one property, sfx, or music effect: %s:%s" % [scene_path, root.get_path_to(trigger)]
	)
	if bool(trigger.get("music_enabled")):
		_assert_trigger_music_config(scene_path, root, trigger)

func _trigger_has_property_effect(trigger: Node) -> bool:
	var changes: Array = trigger.get("changes")
	if not changes.is_empty():
		return true
	var property_name := str(trigger.get("property_name")).strip_edges()
	var target_paths: Array = trigger.get("target_paths")
	return property_name != "" or not target_paths.is_empty()

func _trigger_has_music_effect(trigger: Node) -> bool:
	if not bool(trigger.get("music_enabled")):
		return false
	return int(trigger.get("music_on_enter")) != MUSIC_ACTION_NONE or int(trigger.get("music_on_exit")) != MUSIC_ACTION_NONE

func _assert_trigger_music_config(scene_path: String, root: Node, trigger: Node) -> void:
	var enter_action := int(trigger.get("music_on_enter"))
	var exit_action := int(trigger.get("music_on_exit"))
	if [MUSIC_ACTION_REPLACE, MUSIC_ACTION_EVENT_START].has(enter_action) or [MUSIC_ACTION_REPLACE, MUSIC_ACTION_EVENT_START].has(exit_action):
		assert_true(
			trigger.get("music_stream") is AudioStream,
			"TriggerSetProperty music_stream must be set for replace/event-start actions: %s:%s" % [scene_path, root.get_path_to(trigger)]
		)

func _list_level_scenes() -> Array[String]:
	return utils.list_files(LEVEL_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"])

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for trigger contract validation: %s" % path)
	return root

func _script_path(node: Node) -> String:
	var script := node.get_script() as Resource
	if script == null:
		return ""
	return String(script.resource_path)

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for info in node.get_property_list():
		if String(info.name) == property_name:
			return true
	return false
