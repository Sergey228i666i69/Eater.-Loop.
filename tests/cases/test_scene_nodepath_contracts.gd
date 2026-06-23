extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const INTERACTABLE_DIR := "res://objects/interactable"
const DOOR_SCRIPT := "res://objects/interactable/door/door.gd"
const BLOCKPOST_SCRIPT := "res://objects/interactable/level12/blockpost/blockpost.gd"
const STUDENT_MONEY_SCRIPT := "res://objects/interactable/level12/student/student_money_npc.gd"
const LAPTOP_SCRIPT := "res://objects/interactable/notebook/laptop.gd"
const FRIDGE_SCRIPT := "res://objects/interactable/fridge/fridge.gd"
const LAMP_SCRIPT := "res://objects/interactable/lamp/lamp.gd"
const PROJECTOR_SCRIPT := "res://objects/interactable/projector/projector.gd"
const PICKUP_FLASHLIGHT_SCRIPT := "res://objects/interactable/flashlight/pickup_flashlight.gd"

func run() -> Array[String]:
	_test_unlocked_level_doors_have_resolving_targets()
	_test_blockpost_child_contracts()
	_test_level_money_interactables_resolve_money_systems()
	_test_interactable_exported_nodepaths_resolve()
	return get_failures()

func _test_unlocked_level_doors_have_resolving_targets() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			if not _is_script(node, DOOR_SCRIPT):
				continue
			if _is_door_allowed_to_have_inert_target(node):
				continue
			var marker: NodePath = node.get("target_marker")
			assert_true(not marker.is_empty(), "Unlocked/key door target_marker must be non-empty: %s:%s" % [path, root.get_path_to(node)])
			if marker.is_empty():
				continue
			var target := node.get_node_or_null(marker)
			assert_true(target != null, "Door target_marker must resolve: %s:%s -> %s" % [path, root.get_path_to(node), marker])
			assert_true(target != node, "Door target_marker must not point to self unless the door is inert/locked: %s:%s" % [path, root.get_path_to(node)])
		root.free()

func _test_blockpost_child_contracts() -> void:
	for path in _list_contract_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			if not _is_script(node, BLOCKPOST_SCRIPT):
				continue
			assert_true(node.get_node_or_null("TouchArea") is Area2D, "Blockpost must keep TouchArea Area2D child: %s:%s" % [path, root.get_path_to(node)])
			assert_true(node.get_node_or_null("PassageBlocker/CollisionShape2D") is CollisionShape2D, "Blockpost must keep PassageBlocker/CollisionShape2D child: %s:%s" % [path, root.get_path_to(node)])
			var marker: NodePath = node.get("target_marker")
			assert_true(not marker.is_empty(), "Blockpost target_marker must be set: %s:%s" % [path, root.get_path_to(node)])
			if not marker.is_empty():
				assert_true(node.get_node_or_null(marker) != null, "Blockpost target_marker must resolve: %s:%s -> %s" % [path, root.get_path_to(node), marker])
		root.free()

func _test_level_money_interactables_resolve_money_systems() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			var script_path := _script_path(node)
			if script_path == BLOCKPOST_SCRIPT:
				_assert_money_system_resolves(path, root, node, "try_open_blockpost")
			elif script_path == STUDENT_MONEY_SCRIPT:
				_assert_money_system_resolves(path, root, node, "add_money")
			elif script_path == LAPTOP_SCRIPT and _has_property(node, "reward_on_work_completion") and bool(node.get("reward_on_work_completion")):
				_assert_money_system_resolves(path, root, node, "add_money")
		root.free()

func _test_interactable_exported_nodepaths_resolve() -> void:
	for path in _list_contract_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			var script_path := _script_path(node)
			if [LAMP_SCRIPT, PROJECTOR_SCRIPT, PICKUP_FLASHLIGHT_SCRIPT].has(script_path):
				_assert_required_nodepath_resolves(path, root, node, "light_node", "PointLight2D")
			if [FRIDGE_SCRIPT, LAPTOP_SCRIPT, LAMP_SCRIPT, PROJECTOR_SCRIPT].has(script_path):
				_assert_optional_nodepath_resolves(path, root, node, "sprite_node")
			if [FRIDGE_SCRIPT, LAPTOP_SCRIPT].has(script_path):
				_assert_optional_nodepath_resolves(path, root, node, "available_light_node")
				_assert_optional_nodepath_resolves(path, root, node, "available_light_node_secondary")
			if script_path == FRIDGE_SCRIPT:
				_assert_optional_nodepath_resolves(path, root, node, "noise_player_node", "AudioStreamPlayer2D")
				if _has_property(node, "enable_teleport") and bool(node.get("enable_teleport")):
					_assert_required_nodepath_resolves(path, root, node, "teleport_target")
		root.free()

func _assert_money_system_resolves(path: String, root: Node, node: Node, required_method: String) -> void:
	var money_path: NodePath = node.get("money_system_path")
	var money_system := node.get_node_or_null(money_path) if not money_path.is_empty() else node.get_node_or_null("../Level12MoneySystem")
	assert_true(money_system != null, "Money interactable must resolve its money system: %s:%s" % [path, root.get_path_to(node)])
	if money_system != null:
		assert_true(money_system.has_method(required_method), "Money system must expose %s for %s:%s" % [required_method, path, root.get_path_to(node)])

func _assert_required_nodepath_resolves(path: String, root: Node, node: Node, property_name: String, expected_type: String = "") -> void:
	if not _has_property(node, property_name):
		return
	var node_path: NodePath = node.get(property_name)
	assert_true(not node_path.is_empty(), "%s must be set: %s:%s" % [property_name, path, root.get_path_to(node)])
	if node_path.is_empty():
		return
	_assert_path_resolves(path, root, node, property_name, node_path, expected_type)

func _assert_optional_nodepath_resolves(path: String, root: Node, node: Node, property_name: String, expected_type: String = "") -> void:
	if not _has_property(node, property_name):
		return
	var node_path: NodePath = node.get(property_name)
	if node_path.is_empty():
		return
	_assert_path_resolves(path, root, node, property_name, node_path, expected_type)

func _assert_path_resolves(path: String, root: Node, node: Node, property_name: String, node_path: NodePath, expected_type: String = "") -> void:
	var target := node.get_node_or_null(node_path)
	assert_true(target != null, "%s must resolve: %s:%s -> %s" % [property_name, path, root.get_path_to(node), node_path])
	if target != null and expected_type != "":
		assert_true(target.is_class(expected_type), "%s must resolve to %s: %s:%s -> %s" % [property_name, expected_type, path, root.get_path_to(node), node_path])

func _is_door_allowed_to_have_inert_target(node: Node) -> bool:
	var locked := bool(node.get("is_locked")) if _has_property(node, "is_locked") else false
	var required_key := str(node.get("required_key_id")).strip_edges() if _has_property(node, "required_key_id") else ""
	return locked and required_key == ""

func _list_level_scenes() -> Array[String]:
	return utils.list_files(LEVEL_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"])

func _list_contract_scenes() -> Array[String]:
	var scenes := _list_level_scenes()
	scenes.append_array(utils.list_files(INTERACTABLE_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"]))
	scenes.sort()
	return scenes

func _instantiate_scene(path: String) -> Node:
	var packed_scene := assert_loads(path) as PackedScene
	if packed_scene == null:
		return null
	var root := packed_scene.instantiate()
	assert_true(root != null, "Scene must instantiate for contract validation: %s" % path)
	return root

func _is_script(node: Node, script_path: String) -> bool:
	return _script_path(node) == script_path

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
