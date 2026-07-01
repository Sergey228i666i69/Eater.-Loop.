extends "res://tests/test_case.gd"

func run() -> Array[String]:
    var cfg = utils.load_project_config()
    if cfg == null:
        fail("Failed to load project.godot")
        return get_failures()

    _test_main_scene(cfg)
    _test_enabled_editor_plugins_exist(cfg)
    _test_configured_translations_load(cfg)
    return get_failures()

func _test_main_scene(cfg: ConfigFile) -> void:
    var main_scene = cfg.get_value("application", "run/main_scene", "")
    assert_true(main_scene != "", "application/run/main_scene is empty")
    if main_scene != "":
        var res = assert_loads(main_scene)
        if res != null and not (res is PackedScene):
            fail("Main scene is not a PackedScene: %s" % main_scene)

func _test_enabled_editor_plugins_exist(cfg: ConfigFile) -> void:
    if not cfg.has_section_key("editor_plugins", "enabled"):
        return
    for plugin_cfg_path in _to_string_array(cfg.get_value("editor_plugins", "enabled", PackedStringArray())):
        assert_true(plugin_cfg_path.ends_with("plugin.cfg"), "Enabled editor plugin does not point to plugin.cfg: %s" % plugin_cfg_path)
        assert_true(FileAccess.file_exists(plugin_cfg_path), "Enabled editor plugin is missing: %s" % plugin_cfg_path)

func _test_configured_translations_load(cfg: ConfigFile) -> void:
    for translation_path in _to_string_array(cfg.get_value("locale", "translations", PackedStringArray())):
        var res = assert_loads(translation_path)
        if res != null and not (res is Translation):
            fail("Configured translation is not a Translation resource: %s" % translation_path)

func _to_string_array(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if value is PackedStringArray:
        for item in value:
            result.append(str(item))
    elif value is Array:
        for item in value:
            result.append(str(item))
    elif value is String and value != "":
        result.append(value)
    return result
