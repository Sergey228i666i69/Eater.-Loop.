extends "res://tests/test_case.gd"

const LEVEL_DIR := "res://levels/cycles"
const LEVEL_MINIGAME_DIR := "res://levels/minigames"
const LEVEL_UI_DIR := "res://levels/ui"
const OBJECT_DIR := "res://objects"
const INTERACTABLE_DIR := "res://objects/interactable"
const ENEMY_DIR := "res://enemies"
const BASIC_INTERACTIVE_TEMPLATE_SCENE := "res://objects/interactable/templates/basic_interactive_template.tscn"
const MAIN_MENU_SCENE := "res://levels/menu/main_menu.tscn"
const PAUSE_MENU_SCENE := "res://levels/menu/pause_menu.tscn"
const INTERACTIVE_OBJECT_SCRIPT := "res://objects/interactable/interactive_object.gd"
const PAUSE_MENU_SCRIPT := "res://levels/menu/pause_menu.gd"
const SETTINGS_PANEL_SCRIPT := "res://levels/menu/settings_panel.gd"
const PLAYER_SCENES := [
	"res://player/player.tscn",
]
const LEVEL_MUSIC_SCRIPT := "res://levels/cycles/level_music.gd"
const DOOR_SCRIPT := "res://objects/interactable/door/door.gd"
const BLOCKPOST_SCRIPT := "res://objects/interactable/level12/blockpost/blockpost.gd"
const STUDENT_MONEY_SCRIPT := "res://objects/interactable/level12/student/student_money_npc.gd"
const LAPTOP_SCRIPT := "res://objects/interactable/notebook/laptop.gd"
const FRIDGE_SCRIPT := "res://objects/interactable/fridge/fridge.gd"
const LAMP_SCRIPT := "res://objects/interactable/lamp/lamp.gd"
const PROJECTOR_SCRIPT := "res://objects/interactable/projector/projector.gd"
const PICKUP_FLASHLIGHT_SCRIPT := "res://objects/interactable/flashlight/pickup_flashlight.gd"
const LEBEDKA_SCRIPT := "res://objects/interactable/lebedka/lebedka.gd"
const CORRIDOR_DISTORTION_SCRIPT := "res://levels/cycles/corridor_distortion.gd"
const TARGET_MONSTER_SPAWNER_SCRIPT := "res://objects/environment/smart/target/target.gd"
const SPAWNER_CONDITION_NODE_SIGNAL := 1
const SPAWNER_CONDITION_TRIGGER_ENTER := 2
const SCENE_AUDIO_BUSES := {
	"Music": true,
	"Sounds": true,
}

func run() -> Array[String]:
	_test_basic_interactive_template_contract()
	_test_pause_menu_scene_contract()
	_test_menu_settings_panel_contracts()
	_test_unlocked_level_doors_have_resolving_targets()
	_test_blockpost_child_contracts()
	_test_level_money_interactables_resolve_money_systems()
	_test_content_scene_exported_nodepaths_resolve()
	_test_interactable_exported_nodepaths_resolve()
	_test_scene_audio_players_use_explicit_buses()
	_test_level_utility_nodepaths_resolve()
	return get_failures()

func _test_basic_interactive_template_contract() -> void:
	var root := _instantiate_scene(BASIC_INTERACTIVE_TEMPLATE_SCENE)
	if root == null:
		return
	assert_true(root is Area2D, "Basic interactive template root must be Area2D")
	assert_true(_script_path(root) == INTERACTIVE_OBJECT_SCRIPT, "Basic interactive template root must use InteractiveObject script")
	assert_true(root.get_node_or_null("CollisionShape2D") is CollisionShape2D, "Basic interactive template must keep CollisionShape2D child")
	assert_true(root.get_node_or_null("Sprite2D") is Sprite2D, "Basic interactive template must keep Sprite2D child")
	assert_true(_has_property(root, "prompt_text"), "Basic interactive template must expose prompt_text")
	root.free()

func _test_pause_menu_scene_contract() -> void:
	var root := _instantiate_scene(PAUSE_MENU_SCENE)
	if root == null:
		return
	var pause_menu := root.get_node_or_null("PauseMenu")
	assert_true(pause_menu != null, "Pause menu scene must keep a PauseMenu child for PauseManager")
	if pause_menu != null:
		assert_true(_script_path(pause_menu) == PAUSE_MENU_SCRIPT, "PauseMenu child must use pause_menu.gd for PauseManager typed lifecycle calls")
	root.free()

func _test_menu_settings_panel_contracts() -> void:
	var contracts := [
		{"scene": MAIN_MENU_SCENE, "panel": "SettingsPanelCenter/SettingsPanel"},
		{"scene": PAUSE_MENU_SCENE, "panel": "PauseMenu/SettingsPanelCenter/SettingsPanel"},
	]
	for contract in contracts:
		var scene_path := String(contract["scene"])
		var root := _instantiate_scene(scene_path)
		if root == null:
			continue
		var panel_path := String(contract["panel"])
		var settings_panel := root.get_node_or_null(panel_path)
		assert_true(settings_panel != null, "Menu scene must keep typed SettingsPanel instance: %s -> %s" % [scene_path, panel_path])
		if settings_panel != null:
			assert_true(_script_path(settings_panel) == SETTINGS_PANEL_SCRIPT, "Menu SettingsPanel must use settings_panel.gd for typed focus/closed API: %s -> %s" % [scene_path, panel_path])
		root.free()

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
				_assert_money_system_resolves(path, root, node)
			elif script_path == STUDENT_MONEY_SCRIPT:
				_assert_money_system_resolves(path, root, node)
			elif script_path == LAPTOP_SCRIPT and _has_property(node, "reward_on_work_completion") and bool(node.get("reward_on_work_completion")):
				_assert_money_system_resolves(path, root, node)
		root.free()

func _test_content_scene_exported_nodepaths_resolve() -> void:
	for path in _list_content_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in _nodes_including_root(root):
			_assert_exported_nodepath_properties_resolve(path, root, node)
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

func _test_scene_audio_players_use_explicit_buses() -> void:
	for path in _list_content_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in _nodes_including_root(root):
			if not _is_scene_audio_player(node):
				continue
			_assert_scene_audio_player_bus(path, root, node)
		root.free()

func _test_level_utility_nodepaths_resolve() -> void:
	for path in _list_level_scenes():
		var root := _instantiate_scene(path)
		if root == null:
			continue
		for node in root.find_children("*", "", true, false):
			var script_path := _script_path(node)
			if script_path == LEBEDKA_SCRIPT:
				var fridge := _assert_required_nodepath_resolves(path, root, node, "fridge_path")
				assert_true(fridge is Fridge, "Lebedka fridge_path must resolve to Fridge: %s:%s" % [path, root.get_path_to(node)])
				_assert_optional_nodepath_resolves(path, root, node, "sprite_node", "Sprite2D")
			elif script_path == CORRIDOR_DISTORTION_SCRIPT:
				_assert_required_nodepath_resolves(path, root, node, "trigger_path", "Area2D")
				_assert_required_nodepath_resolves(path, root, node, "new_corridor_path", "Node2D")
				if _has_property(node, "camera_enabled") and bool(node.get("camera_enabled")):
					_assert_required_nodepath_resolves(path, root, node, "camera_path", "Camera2D")
				_assert_nodepath_array_resolves(path, root, node, "kitchen_nodes", "Node2D")
				_assert_nodepath_array_resolves(path, root, node, "back_nodes", "Node2D")
				_assert_nodepath_array_resolves(path, root, node, "disable_nodes")
				_assert_nodepath_array_resolves(path, root, node, "stop_audio_nodes")
			elif script_path == TARGET_MONSTER_SPAWNER_SCRIPT:
				_assert_target_monster_spawner_paths(path, root, node)
		root.free()

func _assert_target_monster_spawner_paths(path: String, root: Node, node: Node) -> void:
	_assert_optional_nodepath_resolves(path, root, node, "spawn_parent_path")
	var enemy_scene: PackedScene = node.get("enemy_scene") if _has_property(node, "enemy_scene") else null
	if enemy_scene == null:
		return
	var condition_configured := bool(node.get("condition_configured")) if _has_property(node, "condition_configured") else false
	if not condition_configured:
		return
	var condition_type := int(node.get("condition_type")) if _has_property(node, "condition_type") else 0
	if condition_type == SPAWNER_CONDITION_NODE_SIGNAL:
		var source := _assert_required_nodepath_resolves(path, root, node, "condition_node_path")
		var signal_name := StringName(node.get("condition_signal_name")) if _has_property(node, "condition_signal_name") else StringName()
		assert_true(signal_name != StringName(), "TargetMonsterSpawner condition_signal_name must not be empty: %s:%s" % [path, root.get_path_to(node)])
		if source != null and signal_name != StringName():
			assert_true(source.has_signal(signal_name), "TargetMonsterSpawner condition node must expose signal '%s': %s:%s" % [String(signal_name), path, root.get_path_to(node)])
		var property_name := StringName(node.get("condition_property_name")) if _has_property(node, "condition_property_name") else StringName()
		if source != null and property_name != StringName():
			assert_true(_has_property(source, String(property_name)), "TargetMonsterSpawner condition node must expose property '%s': %s:%s" % [String(property_name), path, root.get_path_to(node)])
	elif condition_type == SPAWNER_CONDITION_TRIGGER_ENTER:
		_assert_required_nodepath_resolves(path, root, node, "trigger_area_path", "Area2D")

func _assert_money_system_resolves(path: String, root: Node, node: Node) -> void:
	var money_path: NodePath = node.get("money_system_path")
	var money_system := node.get_node_or_null(money_path) if not money_path.is_empty() else node.get_node_or_null("../Level12MoneySystem")
	assert_true(money_system != null, "Money interactable must resolve its money system: %s:%s" % [path, root.get_path_to(node)])
	if money_system != null:
		assert_true(money_system is Level12MoneySystem, "Money interactable must resolve Level12MoneySystem: %s:%s" % [path, root.get_path_to(node)])

func _assert_exported_nodepath_properties_resolve(path: String, root: Node, node: Node) -> void:
	for property_info in node.get_property_list():
		if not _is_exported_script_property(property_info):
			continue
		var property_name := String(property_info.get("name", ""))
		if _is_owner_relative_target_marker_property(property_name):
			continue
		var property_type := int(property_info.get("type", TYPE_NIL))
		if property_type == TYPE_NODE_PATH:
			var node_path: NodePath = node.get(property_name)
			if node_path.is_empty():
				continue
			_assert_path_resolves(path, root, node, property_name, node_path)
		elif property_type == TYPE_ARRAY:
			_assert_exported_nodepath_array_entries_resolve(path, root, node, property_name)

func _assert_exported_nodepath_array_entries_resolve(path: String, root: Node, node: Node, property_name: String) -> void:
	var values: Array = node.get(property_name)
	for index in range(values.size()):
		var value: Variant = values[index]
		if not (value is NodePath):
			continue
		var node_path := value as NodePath
		assert_true(not node_path.is_empty(), "%s entry must not be empty when configured: %s:%s[%d]" % [property_name, path, root.get_path_to(node), index])
		if node_path.is_empty():
			continue
		_assert_path_resolves(path, root, node, "%s[%d]" % [property_name, index], node_path)

func _is_exported_script_property(property_info: Dictionary) -> bool:
	var usage := int(property_info.get("usage", 0))
	return (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_STORAGE) != 0

func _is_owner_relative_target_marker_property(property_name: String) -> bool:
	return property_name.ends_with("_target") or property_name.find("_target_") != -1

func _assert_required_nodepath_resolves(path: String, root: Node, node: Node, property_name: String, expected_type: String = "") -> Node:
	if not _has_property(node, property_name):
		return null
	var node_path: NodePath = node.get(property_name)
	assert_true(not node_path.is_empty(), "%s must be set: %s:%s" % [property_name, path, root.get_path_to(node)])
	if node_path.is_empty():
		return null
	return _assert_path_resolves(path, root, node, property_name, node_path, expected_type)

func _assert_optional_nodepath_resolves(path: String, root: Node, node: Node, property_name: String, expected_type: String = "") -> Node:
	if not _has_property(node, property_name):
		return null
	var node_path: NodePath = node.get(property_name)
	if node_path.is_empty():
		return null
	return _assert_path_resolves(path, root, node, property_name, node_path, expected_type)

func _assert_required_nodepath_resolves_with_method(path: String, root: Node, node: Node, property_name: String, required_method: String) -> Node:
	var target := _assert_required_nodepath_resolves(path, root, node, property_name)
	if target != null:
		assert_true(target.has_method(required_method), "%s must expose %s(): %s:%s" % [property_name, required_method, path, root.get_path_to(node)])
	return target

func _assert_nodepath_array_resolves(path: String, root: Node, node: Node, property_name: String, expected_type: String = "") -> void:
	if not _has_property(node, property_name):
		return
	var node_paths: Array = node.get(property_name)
	for index in range(node_paths.size()):
		var node_path: NodePath = node_paths[index]
		assert_true(not node_path.is_empty(), "%s entry must not be empty: %s:%s[%d]" % [property_name, path, root.get_path_to(node), index])
		if node_path.is_empty():
			continue
		_assert_path_resolves(path, root, node, "%s[%d]" % [property_name, index], node_path, expected_type)

func _assert_path_resolves(path: String, root: Node, node: Node, property_name: String, node_path: NodePath, expected_type: String = "") -> Node:
	var target := node.get_node_or_null(node_path)
	assert_true(target != null, "%s must resolve: %s:%s -> %s" % [property_name, path, root.get_path_to(node), node_path])
	if target != null and expected_type != "":
		assert_true(target.is_class(expected_type), "%s must resolve to %s: %s:%s -> %s" % [property_name, expected_type, path, root.get_path_to(node), node_path])
	return target

func _assert_scene_audio_player_bus(path: String, root: Node, node: Node) -> void:
	if _script_path(node) == LEVEL_MUSIC_SCRIPT:
		return
	var bus_name := String(node.get("bus"))
	assert_true(
		SCENE_AUDIO_BUSES.has(bus_name),
		"Scene audio players must use explicit Music/Sounds bus: %s:%s uses '%s'" % [path, root.get_path_to(node), bus_name]
	)

func _is_scene_audio_player(node: Node) -> bool:
	return node is AudioStreamPlayer or node is AudioStreamPlayer2D

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

func _list_content_scenes() -> Array[String]:
	var scenes: Array[String] = []
	for root_dir in [LEVEL_DIR, LEVEL_MINIGAME_DIR, LEVEL_UI_DIR, OBJECT_DIR, ENEMY_DIR]:
		scenes.append_array(utils.list_files(root_dir, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"]))
	for path in PLAYER_SCENES:
		if ResourceLoader.exists(path):
			scenes.append(path)
	scenes.sort()
	return scenes

func _nodes_including_root(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	return nodes

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
