extends "res://tests/test_case.gd"

const SCRIPT_DIRS := [
    "res://levels",
    "res://objects",
    "res://player",
    "res://global"
]
const ACTION_METHOD_LITERAL_PATTERN := "is_action_(?:pressed|released|just_pressed|just_released)\\(\\s*&?\"([^\"]+)\""
const NAV_ACTION_WRAPPER_PATTERN := "_is_nav_action_pressed\\(\\s*[^,]+,\\s*&?\"([^\"]+)\"\\s*,\\s*&?\"([^\"]+)\""

func run() -> Array[String]:
    var cfg = utils.load_project_config()
    if cfg == null:
        fail("Failed to load project.godot")
        return get_failures()

    var actions = cfg.get_section_keys("input")
    assert_true(actions.size() > 0, "No input actions defined")

    var required = [
        "move_left",
        "move_right",
        "interact",
        "run",
        "pause_menu",
        "mg_cancel",
        "mg_grab",
        "mg_confirm",
        "mg_secondary",
        "mg_nav_left",
        "mg_nav_right",
        "mg_nav_up",
        "mg_nav_down",
        "mg_tab_left",
        "mg_tab_right",
        "ui_accept",
        "ui_cancel",
        "ui_left",
        "ui_right",
        "ui_up",
        "ui_down"
    ]
    for name in required:
        assert_true(InputMap.has_action(name), "Missing input action: %s" % name)
        if InputMap.has_action(name):
            var events = InputMap.action_get_events(name)
            assert_true(events.size() > 0, "Input action has no events: %s" % name)
    _test_light_interactables_use_existing_action()
    _test_runtime_action_literals_exist()
    return get_failures()

func _test_light_interactables_use_existing_action() -> void:
    var scene_paths := [
        "res://objects/interactable/lamp/lamp.tscn",
        "res://objects/interactable/projector/projector.tscn",
    ]
    for scene_path in scene_paths:
        var scene := assert_loads(scene_path) as PackedScene
        if scene == null:
            continue
        var instance := scene.instantiate()
        var action := str(instance.call("_get_interact_action"))
        assert_true(InputMap.has_action(action), "%s uses missing input action: %s" % [scene_path, action])
        instance.free()

func _test_runtime_action_literals_exist() -> void:
    var scripts: Array[String] = []
    for dir_path in SCRIPT_DIRS:
        scripts.append_array(utils.list_files(dir_path, ".gd", ["tests", ".godot", "addons"], ["archive", "trash"]))
    scripts.sort()

    for path in scripts:
        var content := FileAccess.get_file_as_string(path)
        assert_true(content != "", "Failed to read script: %s" % path)
        if content == "":
            continue
        var action_names := _extract_action_literals(content)
        var sorted_actions := action_names.keys()
        sorted_actions.sort()
        for action in sorted_actions:
            assert_true(InputMap.has_action(StringName(action)), "%s uses missing input action literal: %s" % [path, action])

func _extract_action_literals(content: String) -> Dictionary:
    var actions := {}
    _collect_pattern_actions(content, ACTION_METHOD_LITERAL_PATTERN, actions, [1])
    _collect_pattern_actions(content, NAV_ACTION_WRAPPER_PATTERN, actions, [1, 2])
    return actions

func _collect_pattern_actions(content: String, pattern: String, actions: Dictionary, groups: Array[int]) -> void:
    var regex := RegEx.new()
    var err := regex.compile(pattern)
    assert_eq(err, OK, "Failed to compile input action regex: %s" % pattern)
    if err != OK:
        return
    for match_result in regex.search_all(content):
        for group_index in groups:
            var action := match_result.get_string(group_index).strip_edges()
            if action != "":
                actions[action] = true
