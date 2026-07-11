extends "res://tests/test_case.gd"

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")
const ADDON_ROOT := "res://addons/painted_shadow_canvas"
const RUNTIME_SCENE_PATH := ADDON_ROOT + "/runtime/painted_shadow_canvas_2d.tscn"
const PLUGIN_CONFIG_PATH := ADDON_ROOT + "/plugin.cfg"
const PLUGIN_SCRIPT_PATH := ADDON_ROOT + "/plugin.gd"

func run() -> Array[String]:
	_test_addon_resources_load()
	_test_editor_dock_contract()
	_test_runtime_light_contract()
	_test_mask_instances_and_snapshot_roundtrip()
	_test_scene_serialization()
	return get_failures()

func _test_addon_resources_load() -> void:
	assert_true(FileAccess.file_exists(PLUGIN_CONFIG_PATH), "Painted shadow plugin.cfg must exist")
	var config := ConfigFile.new()
	assert_eq(config.load(PLUGIN_CONFIG_PATH), OK, "Painted shadow plugin.cfg must be readable")
	var plugin_script_setting := String(config.get_value("plugin", "script", ""))
	assert_eq(plugin_script_setting, "plugin.gd", "plugin.cfg must keep a path relative to its addon directory")
	var plugin_script_path := PLUGIN_CONFIG_PATH.get_base_dir().path_join(plugin_script_setting)
	assert_eq(plugin_script_path, ADDON_ROOT + "/plugin.gd", "plugin.cfg must resolve to the editor plugin")

	var required_resources := [
		ADDON_ROOT + "/icon.svg",
		plugin_script_path,
		ADDON_ROOT + "/editor/painted_shadow_dock.gd",
		ADDON_ROOT + "/runtime/painted_shadow_brush_engine.gd",
		ADDON_ROOT + "/runtime/painted_shadow_stroke_sampler.gd",
		ADDON_ROOT + "/runtime/painted_shadow_canvas_2d.gd",
		RUNTIME_SCENE_PATH,
		ADDON_ROOT + "/tests/painted_shadow_render_probe.gd",
	]
	for path in required_resources:
		var resource := load(path)
		assert_true(resource != null, "Painted shadow addon resource must load: %s" % path)
		if path.ends_with(".gd"):
			var uid_path: String = String(path) + ".uid"
			assert_true(FileAccess.file_exists(uid_path), "Painted shadow addon script must keep its UID sidecar: %s" % uid_path)
			if FileAccess.file_exists(uid_path):
				assert_true(FileAccess.get_file_as_string(uid_path).strip_edges().begins_with("uid://"), "Addon UID sidecar must contain a uid:// value: %s" % uid_path)
	assert_true(FileAccess.file_exists(ADDON_ROOT + "/icon.svg.import"), "Painted shadow editor icon must keep its tracked import metadata")

	var scene := assert_loads(RUNTIME_SCENE_PATH) as PackedScene
	assert_true(scene != null, "Painted shadow runtime scene must load")
	if scene != null:
		var instance := scene.instantiate()
		assert_true(instance != null and instance.get_script() == CanvasScript, "Runtime scene must instantiate the painted shadow canvas script")
		instance.free()

func _test_editor_dock_contract() -> void:
	var source := FileAccess.get_file_as_string(PLUGIN_SCRIPT_PATH)
	assert_true(
		source.find("_editor_dock.layout_key = \"painted_shadow_canvas_painter\"") != -1,
		"Painted shadow dock must not restore the legacy hidden Inspector-tab layout"
	)
	assert_true(
		source.find("_editor_dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM") != -1,
		"Painted shadow controls must default to the bottom panel instead of hiding behind Inspector"
	)
	assert_true(
		source.find("_editor_dock.available_layouts = EditorDock.DOCK_LAYOUT_ALL") != -1,
		"Painted shadow dock must remain movable between bottom, side, and floating layouts"
	)
	assert_true(
		source.find("_editor_dock.make_visible()") != -1,
		"Selecting a painted shadow canvas must focus and expand its painter dock"
	)
	assert_true(
		source.find("\t\t_editor_dock.open()") == -1,
		"Painted shadow visibility must not regress to open(), which leaves the dock hidden behind another tab"
	)

func _test_runtime_light_contract() -> void:
	var canvas := CanvasScript.new()
	canvas.canvas_size = Vector2(800.0, 320.0)
	canvas.mask_resolution = Vector2i(400, 160)
	canvas.darkness_strength = 0.55
	canvas.affected_item_cull_mask = 3
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree must be available for the runtime light contract")
	if tree != null:
		tree.root.add_child(canvas)
	var shadow_light: PointLight2D = canvas.get_shadow_light()

	assert_true(shadow_light != null, "Canvas must create an internal PointLight2D")
	if shadow_light != null:
		assert_eq(shadow_light.blend_mode, Light2D.BLEND_MODE_SUB, "Painted darkness must use native subtractive light blending")
		assert_eq(shadow_light.range_item_cull_mask, 3, "Internal light must inherit the configured receiver mask")
		assert_true(absf(shadow_light.energy - 0.55) <= 0.0001, "Internal light must inherit the configured darkness strength")
		assert_true(not shadow_light.editor_only, "Painted darkness must remain visible in exported games")
		assert_true(not shadow_light.shadow_enabled, "Occluders must not block the painted darkness itself")
		assert_eq(shadow_light.position, Vector2(400.0, 160.0), "Internal light must stay centered in top-left-origin canvas bounds")
		assert_eq(shadow_light.scale, Vector2(2.0, 2.0), "Internal light texture must cover the exact physical canvas size")
		assert_true(shadow_light.owner == null, "Internal light must stay transient instead of being serialized into authored scenes")
		assert_true(shadow_light.texture != null, "Internal light must receive the generated mask texture")
		if shadow_light.texture != null:
			assert_eq(shadow_light.texture.get_size(), Vector2(400.0, 160.0), "Internal light texture must match mask resolution")
			assert_eq(shadow_light.texture.get_image().get_format(), Image.FORMAT_RGBA8, "GL Compatibility light atlas must receive an RGBA8 texture")

	assert_eq(canvas.get_canvas_rect(), Rect2(Vector2.ZERO, Vector2(800.0, 320.0)), "Canvas bounds must use the node origin as top-left")
	assert_eq(canvas.get_mask_image_copy().get_format(), Image.FORMAT_L8, "Authoritative saved mask must remain compact L8 data")
	canvas.free()

func _test_mask_instances_and_snapshot_roundtrip() -> void:
	var first := CanvasScript.new()
	var second := CanvasScript.new()
	first.canvas_size = Vector2(128.0, 64.0)
	second.canvas_size = first.canvas_size
	first.mask_resolution = Vector2i(64, 32)
	second.mask_resolution = first.mask_resolution

	assert_true(
		first.paint_segment(Vector2(64.0, 32.0), Vector2(64.0, 32.0), 12.0, 1.0, 0.0, 0.2),
		"Canvas paint API must change a blank mask"
	)
	assert_true(first.get_mask_value(Vector2i(32, 16)) > 0.9, "Painted canvas must store darkness at the brush center")
	assert_true(second.get_mask_value(Vector2i(32, 16)) < 0.01, "Canvas instances must not share mutable mask data")

	var snapshot: PackedByteArray = first.capture_mask_snapshot()
	assert_true(not snapshot.is_empty(), "Canvas must serialize its working mask into a PNG snapshot")
	second.apply_mask_snapshot(snapshot)
	assert_true(second.get_mask_value(Vector2i(32, 16)) > 0.9, "Applying a snapshot must restore painted darkness")
	assert_eq(second.get_mask_size(), Vector2i(64, 32), "Snapshot restore must preserve mask dimensions")

	second.paint_segment(Vector2(64.0, 32.0), Vector2(64.0, 32.0), 12.0, 1.0, 0.0, 0.2, true)
	assert_true(second.get_mask_value(Vector2i(32, 16)) < 0.05, "Erase mode must remove painted darkness through the canvas API")

	first.free()
	second.free()

func _test_scene_serialization() -> void:
	var canvas := CanvasScript.new()
	canvas.canvas_size = Vector2(200.0, 100.0)
	canvas.mask_resolution = Vector2i(100, 50)
	canvas.paint_segment(Vector2(100.0, 50.0), Vector2(100.0, 50.0), 20.0, 1.0, 0.3, 0.2)
	canvas.apply_mask_snapshot(canvas.capture_mask_snapshot())

	var packed := PackedScene.new()
	assert_eq(packed.pack(canvas), OK, "Painted shadow canvas must pack into a scene")
	var temp_path := "user://painted_shadow_canvas_contract.tscn"
	assert_eq(ResourceSaver.save(packed, temp_path), OK, "Packed painted shadow scene must save")
	canvas.free()

	var loaded := ResourceLoader.load(temp_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(loaded != null, "Saved painted shadow scene must load")
	if loaded != null:
		var restored := loaded.instantiate()
		assert_true(restored != null, "Saved painted shadow scene must instantiate")
		if restored != null:
			assert_true(restored.get_mask_value(Vector2i(50, 25)) > 0.5, "Painted mask must survive save and reload")
			assert_eq(restored.get_shadow_light().blend_mode, Light2D.BLEND_MODE_SUB, "Restored scene must rebuild its subtractive light")
			restored.free()

	var absolute_path := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(absolute_path)
