extends "res://tests/test_case.gd"

const LEVEL04_SCENE_PATH := "res://levels/cycles/level_04_findkey.tscn"
const DOOR_SCRIPT := "res://objects/interactable/door/door.gd"
const SEARCH_KEY_MANAGER_SCRIPT := "res://levels/minigames/search_key/search_key_manager.gd"
const SearchSpotScript := preload("res://objects/interactable/search_spot/search_spot.gd")
const SCENE_DIRS := [
	"res://levels",
	"res://objects"
]
const SCRIPT_DIRS := [
	"res://levels",
	"res://objects",
	"res://player",
	"res://enemies"
]
const GROUP_METHOD_CONTRACTS := [
	{
		"group": ReactiveLightContracts.REACTIVE_LIGHT_SOURCE_GROUP,
		"methods": [ReactiveLightContracts.METHOD_IS_POINT_LIT],
		"helper": "ReactiveLightContracts.register_reactive_light_source"
	},
	{
		"group": ReactiveLightContracts.GENERATOR_REQUIRED_LIGHT_GROUP,
		"methods": [ReactiveLightContracts.METHOD_TURN_ON],
		"helper": "ReactiveLightContracts.register_generator_required_light"
	},
	{
		"group": ReactiveLightContracts.GENERATOR_REQUIRED_LAMP_GROUP,
		"methods": [ReactiveLightContracts.METHOD_TURN_ON],
		"helper": "ReactiveLightContracts.register_generator_required_lamp"
	}
]
const FORBIDDEN_NULL_SCENE_OVERRIDES := [
	"is_locked",
	"required_key_id",
	"required_key_name",
	"consume_key_on_unlock",
	"interact_area_node",
	"one_shot",
	"target_marker",
]

class GeneratorLightProbe:
	extends Node

	var turned_on: bool = false

	func turn_on() -> void:
		turned_on = true

func run() -> Array[String]:
	_test_key_search_spots_do_not_depend_on_the_door_they_unlock()
	_test_required_door_keys_have_scene_sources()
	_test_search_key_managers_have_resolving_spots()
	_test_scene_dependencies_declare_typed_conditions()
	_test_laptop_attempt_dependencies_use_requested_condition()
	_test_self_target_doors_are_locked()
	_test_level_scripts_set_dependency_condition_with_dependency_object()
	_test_target_monster_spawners_declare_spawn_condition()
	_test_reversible_triggers_are_not_one_shot()
	_test_reactive_light_contracts_register_and_deduplicate_groups()
	_test_reactive_light_contract_turn_on_helper()
	_test_scripts_that_join_runtime_groups_expose_required_methods()
	_test_checkpoint_custom_methods_are_declared_in_pairs()
	_test_checkpoint_participants_have_stable_scene_paths()
	_test_typed_scene_config_overrides_do_not_use_null()
	return get_failures()

func _test_key_search_spots_do_not_depend_on_the_door_they_unlock() -> void:
	var level_scene := assert_loads(LEVEL04_SCENE_PATH) as PackedScene
	assert_true(level_scene != null, "Level 04 scene failed to load")
	if level_scene == null:
		return
	var level := level_scene.instantiate()
	assert_true(level != null, "Level 04 scene failed to instantiate")
	if level == null:
		return

	for node in level.find_children("*", "", true, false):
		if not _has_property(node, "key_id"):
			continue
		var key_id := str(node.get("key_id"))
		if key_id.strip_edges() == "":
			continue
		var dependency := node.get("dependency_object") as Node
		if dependency == null or not _has_property(dependency, "required_key_id"):
			continue
		assert_true(
			str(dependency.get("required_key_id")) != key_id,
			"Key search spot must not depend on a door that requires the same key: %s -> %s" % [node.get_path(), dependency.get_path()]
		)

	level.free()

func _test_required_door_keys_have_scene_sources() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		var provided_keys := _collect_scene_key_sources(root)
		for node in root.find_children("*", "", true, false):
			if _script_path(node) != DOOR_SCRIPT:
				continue
			var required_key_id := str(node.get("required_key_id")).strip_edges()
			if required_key_id == "":
				continue
			assert_true(
				provided_keys.has(required_key_id),
				"Door required_key_id must have a key source in the same scene: %s:%s -> %s" % [path, root.get_path_to(node), required_key_id]
			)
		root.free()

func _test_search_key_managers_have_resolving_spots() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			if _script_path(node) != SEARCH_KEY_MANAGER_SCRIPT:
				continue
			var search_spots: Array = node.get("search_spots")
			assert_true(not search_spots.is_empty(), "SearchKeyManager must declare search_spots: %s:%s" % [path, root.get_path_to(node)])
			for index in range(search_spots.size()):
				var spot_path: NodePath = search_spots[index]
				assert_true(not spot_path.is_empty(), "SearchKeyManager search_spots entry must not be empty: %s:%s[%d]" % [path, root.get_path_to(node), index])
				if spot_path.is_empty():
					continue
				var spot := node.get_node_or_null(spot_path)
				assert_true(spot != null, "SearchKeyManager search spot must resolve: %s:%s[%d] -> %s" % [path, root.get_path_to(node), index, spot_path])
				if spot != null:
					assert_true(spot is SearchSpotScript, "SearchKeyManager search spot must be SearchSpot: %s:%s[%d] -> %s" % [path, root.get_path_to(node), index, spot_path])
		root.free()

func _test_scene_dependencies_declare_typed_conditions() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("dependency_object = NodePath") == -1:
				continue
			assert_true(
				block.find("dependency_condition =") != -1,
				"Scene dependency_object must declare dependency_condition explicitly: %s" % path
			)

func _test_laptop_attempt_dependencies_use_requested_condition() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("unlock_on_dependency_interaction = true") == -1:
				continue
			assert_true(
				block.find("dependency_condition = 1") != -1,
				"Laptop legacy attempt-unlock flag must use INTERACTION_REQUESTED dependency_condition: %s" % path
			)

func _test_self_target_doors_are_locked() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("target_marker = NodePath(\".\")") == -1:
				continue
			assert_true(
				block.find("is_locked = true") != -1,
				"Self-target scene doors must be locked so players cannot trigger fade-to-self transitions: %s" % path
			)

func _test_level_scripts_set_dependency_condition_with_dependency_object() -> void:
	var scripts := utils.list_files("res://levels", ".gd", ["tests", ".godot", "addons"], ["archive", "trash"])
	scripts.sort()

	for path in scripts:
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read level script: %s" % path)
		if content == "":
			continue
		var lines := content.split("\n")
		for index in range(lines.size()):
			var line := String(lines[index]).strip_edges()
			if line.begins_with("#") or line.find("set_dependency_object") == -1:
				continue
			assert_true(
				_has_nearby_dependency_condition(lines, index),
				"Level script set_dependency_object must set_dependency_condition nearby: %s:%d" % [path, index + 1]
			)

func _test_target_monster_spawners_declare_spawn_condition() -> void:
	for path in _list_active_scenes():
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read scene: %s" % path)
		if content == "":
			continue
		var from := 0
		while true:
			var node_start := content.find("[node ", from)
			if node_start == -1:
				break
			var next_node := content.find("\n[node ", node_start + 1)
			if next_node == -1:
				next_node = content.length()
			var block := content.substr(node_start, next_node - node_start)
			if block.find("TargetMonsterSpawner") != -1 and block.find("enemy_scene =") != -1:
				assert_true(
					block.find("condition_configured = true") != -1,
					"TargetMonsterSpawner with enemy_scene must explicitly confirm its spawn condition: %s" % path
				)
			from = next_node

func _test_reversible_triggers_are_not_one_shot() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			if block.find("affect_on_exit = true") != -1:
				assert_true(
					block.find("one_shot = false") != -1,
					"Trigger with affect_on_exit=true must set one_shot=false so exit behavior can run: %s" % path
				)

func _test_scripts_that_join_runtime_groups_expose_required_methods() -> void:
	for path in _list_active_scripts():
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read script: %s" % path)
		if content == "":
			continue
		for contract in GROUP_METHOD_CONTRACTS:
			var group_name := str(contract.get("group", ""))
			var helper_name := str(contract.get("helper", ""))
			if not _script_adds_group(content, group_name, helper_name):
				continue
			for method_name in contract.get("methods", []):
				assert_true(
					_script_declares_method(content, str(method_name)),
					"Script adding %s group must define %s(): %s" % [group_name, method_name, path]
				)

func _test_reactive_light_contracts_register_and_deduplicate_groups() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var root := Node.new()
	var light := Node.new()
	tree.root.add_child(root)
	root.add_child(light)

	ReactiveLightContracts.register_reactive_light_source(light)
	ReactiveLightContracts.register_generator_required_light(light)
	ReactiveLightContracts.register_generator_required_lamp(light)

	assert_true(light.is_in_group(ReactiveLightContracts.REACTIVE_LIGHT_SOURCE_GROUP), "Reactive light helper must register canonical source group")
	assert_true(ReactiveLightContracts.get_reactive_light_sources(tree).has(light), "Reactive light helper must return registered sources")

	var required_count := 0
	for node in ReactiveLightContracts.get_generator_required_lights(tree):
		if node == light:
			required_count += 1
	assert_eq(required_count, 1, "Generator-required helper must deduplicate nodes registered in both required-light groups")

	root.free()

func _test_reactive_light_contract_turn_on_helper() -> void:
	var light := GeneratorLightProbe.new()
	assert_true(
		ReactiveLightContracts.turn_on_generator_light(light),
		"Generator light helper must accept nodes that expose turn_on()"
	)
	assert_true(light.turned_on, "Generator light helper must invoke turn_on()")
	light.free()

func _test_checkpoint_custom_methods_are_declared_in_pairs() -> void:
	for path in _list_active_scripts():
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read script: %s" % path)
		if content == "" or not _script_is_checkpoint_content_participant(content):
			continue
		var has_capture := _script_declares_method(content, "capture_checkpoint_state")
		var has_apply := _script_declares_method(content, "apply_checkpoint_state")
		if not has_capture and not has_apply:
			continue
		assert_true(
			has_capture and has_apply,
			"Checkpoint content scripts with custom checkpoint API must declare capture/apply as a pair: %s" % path
		)

func _test_checkpoint_participants_have_stable_scene_paths() -> void:
	for path in _list_active_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in _walk_scene_nodes(root):
			if not _node_uses_checkpoint_contract(node):
				continue
			var relative_path := CheckpointStateUtils.get_scene_relative_path(root, node)
			assert_true(
				relative_path != "",
				"Checkpoint participant must have a scene-relative path: %s:%s" % [path, root.get_path_to(node)]
			)
			assert_true(
				_is_stable_checkpoint_path(relative_path),
				"Checkpoint participant path must be stable and explicit: %s:%s" % [path, relative_path]
			)
		root.free()

func _test_typed_scene_config_overrides_do_not_use_null() -> void:
	for path in _list_active_scenes():
		for block in _scene_node_blocks(path):
			for property_name in FORBIDDEN_NULL_SCENE_OVERRIDES:
				assert_true(
					block.find("%s = null" % property_name) == -1,
					"Scene typed config override must use an explicit default instead of null: %s -> %s" % [path, property_name]
				)

func _list_active_scenes() -> Array[String]:
	var scenes: Array[String] = []
	for dir_path in SCENE_DIRS:
		scenes.append_array(utils.list_files(dir_path, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"]))
	scenes.sort()
	return scenes

func _list_level_scenes() -> Array[String]:
	return utils.list_files("res://levels/cycles", ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"])

func _list_active_scripts() -> Array[String]:
	var scripts: Array[String] = []
	for dir_path in SCRIPT_DIRS:
		scripts.append_array(utils.list_files(dir_path, ".gd", ["tests", ".godot", "addons"], ["archive", "trash"]))
	scripts.sort()
	return scripts

func _scene_node_blocks(path: String) -> Array[String]:
	var blocks: Array[String] = []
	var content := FileAccess.get_file_as_string(path)
	assert_true(content != "", "Failed to read scene: %s" % path)
	if content == "":
		return blocks
	var from := 0
	while true:
		var node_start := content.find("[node ", from)
		if node_start == -1:
			break
		var next_node := content.find("\n[node ", node_start + 1)
		if next_node == -1:
			next_node = content.length()
		blocks.append(content.substr(node_start, next_node - node_start))
		from = next_node
	return blocks

func _has_nearby_dependency_condition(lines: PackedStringArray, index: int) -> bool:
	var end_index = mini(lines.size(), index + 6)
	for next_index in range(index + 1, end_index):
		var line := String(lines[next_index]).strip_edges()
		if line.begins_with("#"):
			continue
		if line.find("set_dependency_condition") != -1:
			return true
	return false

func _script_adds_group(content: String, group_name: String, helper_name: String = "") -> bool:
	if content.find("add_to_group(\"%s\"" % group_name) != -1 or content.find("add_to_group(&\"%s\"" % group_name) != -1:
		return true
	return helper_name != "" and content.find(helper_name + "(") != -1

func _script_declares_method(content: String, method_name: String) -> bool:
	return content.find("func %s(" % method_name) != -1 or content.find("func %s (" % method_name) != -1

func _script_is_checkpoint_content_participant(content: String) -> bool:
	return content.find("extends InteractiveObject") != -1 \
		or content.find("interactive_object.gd") != -1 \
		or _script_adds_group(content, CheckpointStateUtils.CHECKPOINT_STATEFUL_GROUP)

func _node_uses_checkpoint_contract(node: Node) -> bool:
	return node != null and (node.has_method("capture_checkpoint_state") or node.has_method("apply_checkpoint_state"))

func _is_stable_checkpoint_path(relative_path: String) -> bool:
	if relative_path == ".":
		return true
	for segment in relative_path.split("/"):
		var text := str(segment)
		if text.strip_edges() == "" or text.find("@") != -1:
			return false
	return true

func _walk_scene_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	if root == null:
		return nodes
	nodes.append(root)
	_append_child_nodes(root, nodes)
	return nodes

func _append_child_nodes(node: Node, nodes: Array[Node]) -> void:
	for child in node.get_children():
		if child == null:
			continue
		nodes.append(child)
		_append_child_nodes(child, nodes)

func _collect_scene_key_sources(root: Node) -> Dictionary:
	var keys := {}
	for node in root.find_children("*", "", true, false):
		if _script_path(node) == DOOR_SCRIPT:
			continue
		if _has_property(node, "key_id"):
			var key_id := str(node.get("key_id")).strip_edges()
			if key_id != "":
				keys[key_id] = true
		if _has_property(node, "reward_key_id"):
			var reward_key_id := str(node.get("reward_key_id")).strip_edges()
			if reward_key_id != "":
				keys[reward_key_id] = true
	return keys

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for dependency contract validation: %s" % path)
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
