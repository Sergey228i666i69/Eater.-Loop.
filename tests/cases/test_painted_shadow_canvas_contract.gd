extends "res://tests/test_case.gd"

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")
const LayerScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_layer.gd")
const PluginScript = preload("res://addons/painted_shadow_canvas/plugin.gd")
const ADDON_ROOT := "res://addons/painted_shadow_canvas"
const RUNTIME_SCENE_PATH := ADDON_ROOT + "/runtime/painted_shadow_canvas_2d.tscn"
const PLUGIN_CONFIG_PATH := ADDON_ROOT + "/plugin.cfg"
const PLUGIN_SCRIPT_PATH := ADDON_ROOT + "/plugin.gd"

func run() -> Array[String]:
	_test_addon_resources_load()
	_test_editor_dock_contract()
	_test_editor_viewport_transform_contract()
	_test_editor_input_capture_contract()
	_test_runtime_light_contract()
	_test_layer_masks_and_lights()
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
		ADDON_ROOT + "/runtime/painted_shadow_layer.gd",
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
	assert_true(
		source.find("return capture_left_drag") != -1,
		"Paint mode must consume left-button motion even when the pointer is outside the canvas bounds"
	)
	assert_true(
		source.find("_stroke_layer_id") != -1 and source.find("apply_layer_mask_snapshot") != -1,
		"Painted shadow Undo/Redo must keep strokes bound to a stable layer ID"
	)

func _test_editor_viewport_transform_contract() -> void:
	var viewport_transform := Transform2D(
		Vector2(0.35, 0.0),
		Vector2(0.0, 0.35),
		Vector2(-800.0, 250.0)
	)
	var item_transform := Transform2D(
		Vector2(1.1, 0.2),
		Vector2(-0.1, 0.9),
		Vector2(6057.0, -293.0)
	)
	var local_position := Vector2(1000.0, 360.0)
	var local_to_viewport: Transform2D = PluginScript.compose_local_to_viewport_transform(
		viewport_transform,
		item_transform
	)
	var viewport_position := local_to_viewport * local_position
	var restored_local: Vector2 = PluginScript.viewport_position_to_local(
		viewport_position,
		viewport_transform,
		item_transform
	)
	assert_true(
		restored_local.is_equal_approx(local_position),
		"Editor brush coordinates must round-trip through viewport zoom/pan and item transforms"
	)

func _test_editor_input_capture_contract() -> void:
	var left_press := InputEventMouseButton.new()
	left_press.button_index = MOUSE_BUTTON_LEFT
	left_press.pressed = true
	assert_true(
		PluginScript.should_capture_paint_pointer_event(left_press, false),
		"Paint mode must consume left-button presses before CanvasItem transform tools"
	)

	var left_release := InputEventMouseButton.new()
	left_release.button_index = MOUSE_BUTTON_LEFT
	left_release.pressed = false
	assert_true(
		PluginScript.should_capture_paint_pointer_event(left_release, false),
		"Paint mode must consume left-button releases before CanvasItem transform tools"
	)

	var left_drag := InputEventMouseMotion.new()
	left_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	assert_true(
		PluginScript.should_capture_paint_pointer_event(left_drag, false),
		"Paint mode must consume left-button motion outside the canvas bounds"
	)
	assert_true(
		not PluginScript.should_capture_paint_pointer_event(left_drag, true),
		"Space or middle-button navigation must remain available during Paint mode"
	)

	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	assert_true(
		not PluginScript.should_capture_paint_pointer_event(wheel, false),
		"Paint mode must leave wheel zoom events to the 2D editor"
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

func _test_layer_masks_and_lights() -> void:
	var canvas := CanvasScript.new()
	canvas.canvas_size = Vector2(128.0, 64.0)
	canvas.mask_resolution = Vector2i(64, 32)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(canvas)

	var layer := canvas.create_shadow_layer("Behind table", -5, 6) as Resource
	assert_true(layer != null and layer.get_script() == LayerScript, "Canvas must create typed painted-shadow layer resources")
	assert_true(layer.resource_local_to_scene, "Painted-shadow layers must be local to each scene instance")
	var layer_id := String(layer.get("layer_id"))
	canvas.insert_shadow_layer(layer, 1)
	assert_eq(canvas.get_layer_count(), 2, "Adding a layer must preserve Base and append one independent layer")
	assert_eq(canvas.get_layer_index(layer_id), 1, "Additional layer must keep a stable ID and index")
	canvas.set_layer_z_range(CanvasScript.BASE_LAYER_ID, 2048, 2048)
	assert_eq(
		canvas.get_layer_z_range(CanvasScript.BASE_LAYER_ID),
		Vector2i(2048, 2048),
		"Moving the complete Base Z range above its previous maximum must not clamp against stale state"
	)
	canvas.set_layer_z_range(CanvasScript.BASE_LAYER_ID, -1024, 1024)
	canvas.set_layer_z_range(layer_id, 5000, 6000)
	assert_eq(
		canvas.get_layer_z_range(layer_id),
		Vector2i(RenderingServer.CANVAS_ITEM_Z_MAX, RenderingServer.CANVAS_ITEM_Z_MAX),
		"Additional layer Z ranges must stay inside CanvasItem renderer limits"
	)
	canvas.set_layer_z_range(layer_id, -5, 6)

	var points := PackedVector2Array([Vector2(64.0, 32.0)])
	assert_true(
		canvas.paint_points_on_layer(layer_id, points, 12.0, 1.0, 0.0),
		"Painting the selected layer must change its independent mask"
	)
	assert_true(canvas.get_layer_mask_value(layer_id, Vector2i(32, 16)) > 0.9, "Additional layer must store its own painted pixels")
	assert_true(canvas.get_mask_value(Vector2i(32, 16)) < 0.01, "Painting an additional layer must not change the Base mask")
	canvas.apply_layer_mask_snapshot(layer_id, canvas.capture_layer_mask_snapshot(layer_id))

	var layer_light: PointLight2D = canvas.get_shadow_light_for_layer(layer_id)
	assert_true(layer_light != null, "Every painted layer must own one internal PointLight2D")
	if layer_light != null:
		assert_eq(layer_light.blend_mode, Light2D.BLEND_MODE_SUB, "Layer lights must use subtractive blending")
		assert_eq(layer_light.range_z_min, -5, "Layer light must keep its receiver Z minimum")
		assert_eq(layer_light.range_z_max, 6, "Layer light must keep its receiver Z maximum")
		assert_true(layer_light.owner == null, "Layer lights must remain transient and absent from authored scenes")
		assert_true(layer_light.texture != null, "Layer light must receive its independent GPU mask")
		if layer_light.texture != null:
			assert_eq(layer_light.texture.get_image().get_format(), Image.FORMAT_RGBA8, "Layer GPU masks must be RGBA8 for GL Compatibility")

	canvas.set_layer_enabled(layer_id, false)
	assert_true(not layer_light.enabled, "Hidden painted layers must disable their subtractive light")
	canvas.set_layer_enabled(layer_id, true)
	var removed := canvas.remove_shadow_layer(layer_id)
	assert_true(removed == layer, "Removing a layer must return the same resource for Undo reinsertion")
	assert_eq(canvas.get_shadow_lights().size(), 1, "Removing a layer must remove only its transient light")
	canvas.insert_shadow_layer(removed, 1)
	assert_true(canvas.get_layer_mask_value(layer_id, Vector2i(32, 16)) > 0.9, "Reinserting a removed layer must restore its mask by stable ID")
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
	var extra_layer := canvas.create_shadow_layer("Behind props", -5, 6) as Resource
	var extra_layer_id := String(extra_layer.get("layer_id"))
	canvas.insert_shadow_layer(extra_layer, 1)
	canvas.paint_points_on_layer(extra_layer_id, PackedVector2Array([Vector2(40.0, 25.0)]), 16.0, 1.0, 0.0)
	canvas.apply_layer_mask_snapshot(extra_layer_id, canvas.capture_layer_mask_snapshot(extra_layer_id))

	var packed := PackedScene.new()
	assert_eq(packed.pack(canvas), OK, "Painted shadow canvas must pack into a scene")
	var temp_path := "user://painted_shadow_canvas_contract.tscn"
	assert_eq(ResourceSaver.save(packed, temp_path), OK, "Packed painted shadow scene must save")
	canvas.free()

	var loaded := ResourceLoader.load(temp_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_true(loaded != null, "Saved painted shadow scene must load")
	if loaded != null:
		var restored := loaded.instantiate()
		var second_instance := loaded.instantiate()
		assert_true(restored != null, "Saved painted shadow scene must instantiate")
		if restored != null:
			assert_true(restored.get_mask_value(Vector2i(50, 25)) > 0.5, "Painted mask must survive save and reload")
			assert_eq(restored.get_shadow_light().blend_mode, Light2D.BLEND_MODE_SUB, "Restored scene must rebuild its subtractive light")
			assert_eq(restored.get_layer_count(), 2, "Saved additional painted layers must survive scene reload")
			assert_eq(restored.get_layer_name(extra_layer_id), "Behind props", "Saved layer names must survive scene reload")
			assert_eq(restored.get_layer_z_range(extra_layer_id), Vector2i(-5, 6), "Saved receiver Z ranges must survive scene reload")
			assert_true(restored.get_layer_mask_value(extra_layer_id, Vector2i(20, 12)) > 0.5, "Saved additional masks must survive scene reload")
			if second_instance != null:
				var first_resource := restored.get_shadow_layer_resource(extra_layer_id) as Resource
				var second_resource := second_instance.get_shadow_layer_resource(extra_layer_id) as Resource
				assert_true(first_resource != second_resource, "Scene instances must not share mutable painted-layer resources")
				restored.set_layer_name(extra_layer_id, "Changed in first instance")
				assert_eq(second_instance.get_layer_name(extra_layer_id), "Behind props", "Changing one instance must not rename another instance's layer")
			restored.free()
		if second_instance != null:
			second_instance.free()

	var absolute_path := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(absolute_path)
