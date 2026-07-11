extends SceneTree

## Real-renderer smoke probe for the addon's central visual contract.
## Run with a non-headless display driver; the dummy headless renderer cannot
## produce meaningful pixel samples.

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")

var _add_light: PointLight2D = null

func _initialize() -> void:
	var scene := Node2D.new()
	root.add_child(scene)

	var base_receiver := ColorRect.new()
	base_receiver.size = Vector2(128.0, 64.0)
	base_receiver.color = Color(0.8, 0.8, 0.8, 1.0)
	base_receiver.z_index = -5
	scene.add_child(base_receiver)

	var foreground_receiver := ColorRect.new()
	foreground_receiver.position = Vector2(0.0, 64.0)
	foreground_receiver.size = Vector2(128.0, 64.0)
	foreground_receiver.color = base_receiver.color
	foreground_receiver.z_index = 7
	scene.add_child(foreground_receiver)

	var ambient_reference := ColorRect.new()
	ambient_reference.position = Vector2(192.0, 32.0)
	ambient_reference.size = Vector2(64.0, 64.0)
	ambient_reference.color = base_receiver.color
	ambient_reference.z_index = -5
	scene.add_child(ambient_reference)

	var ambient := CanvasModulate.new()
	ambient.color = Color(0.5, 0.5, 0.5, 1.0)
	scene.add_child(ambient)

	var shadow: Node2D = CanvasScript.new()
	shadow.canvas_size = Vector2(128.0, 128.0)
	shadow.mask_resolution = Vector2i(64, 64)
	shadow.darkness_strength = 0.2
	shadow.z_index_min = -5
	shadow.z_index_max = 6
	var base_mask := Image.create(64, 64, false, Image.FORMAT_L8)
	base_mask.fill(Color.BLACK)
	base_mask.fill_rect(Rect2i(0, 0, 32, 64), Color.WHITE)
	shadow.import_mask_image(base_mask)
	var foreground_layer := shadow.create_shadow_layer("Foreground Z 7", 7, 7) as Resource
	var foreground_layer_id := String(foreground_layer.get("layer_id"))
	shadow.insert_shadow_layer(foreground_layer, 1)
	var foreground_mask := Image.create(64, 64, false, Image.FORMAT_L8)
	foreground_mask.fill(Color.BLACK)
	foreground_mask.fill_rect(Rect2i(32, 0, 32, 64), Color.WHITE)
	shadow.import_layer_mask_image(foreground_layer_id, foreground_mask)
	scene.add_child(shadow)

	var light_image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	light_image.fill(Color.WHITE)
	_add_light = PointLight2D.new()
	_add_light.texture = ImageTexture.create_from_image(light_image)
	_add_light.position = Vector2(64.0, 64.0)
	_add_light.scale = Vector2(2.0, 2.0)
	_add_light.energy = 0.5
	_add_light.range_item_cull_mask = 1
	_add_light.enabled = false
	scene.add_child(_add_light)

	_run_probe.call_deferred()

func _run_probe() -> void:
	await _wait_for_render_frames()
	var dark_image := root.get_texture().get_image()
	var render_transform := root.get_stretch_transform() * root.get_canvas_transform()
	var base_dark_pixel := Vector2i(render_transform * Vector2(32.0, 32.0))
	var base_clear_pixel := Vector2i(render_transform * Vector2(96.0, 32.0))
	var foreground_clear_pixel := Vector2i(render_transform * Vector2(32.0, 96.0))
	var foreground_dark_pixel := Vector2i(render_transform * Vector2(96.0, 96.0))
	var ambient_pixel := Vector2i(render_transform * Vector2(224.0, 48.0))
	var base_dark := dark_image.get_pixelv(base_dark_pixel).get_luminance()
	var base_clear := dark_image.get_pixelv(base_clear_pixel).get_luminance()
	var foreground_clear := dark_image.get_pixelv(foreground_clear_pixel).get_luminance()
	var foreground_dark := dark_image.get_pixelv(foreground_dark_pixel).get_luminance()
	var ambient_luminance := dark_image.get_pixelv(ambient_pixel).get_luminance()

	_add_light.enabled = true
	await _wait_for_render_frames()
	var lit_image := root.get_texture().get_image()
	var base_lit := lit_image.get_pixelv(base_dark_pixel).get_luminance()
	var foreground_lit := lit_image.get_pixelv(foreground_dark_pixel).get_luminance()

	var base_shadow_delta := ambient_luminance - base_dark
	var foreground_shadow_delta := ambient_luminance - foreground_dark
	var base_light_delta := base_lit - base_dark
	var foreground_light_delta := foreground_lit - foreground_dark
	var passed := (
		base_shadow_delta > 0.03
		and foreground_shadow_delta > 0.03
		and absf(base_clear - ambient_luminance) < 0.02
		and absf(foreground_clear - ambient_luminance) < 0.02
		and base_light_delta > 0.08
		and foreground_light_delta > 0.08
	)
	print(
		"PAINTED_SHADOW_RENDER %s ambient=%.4f base_dark=%.4f base_clear=%.4f foreground_clear=%.4f foreground_dark=%.4f base_lit=%.4f foreground_lit=%.4f"
		% [
			"PASS" if passed else "FAIL",
			ambient_luminance,
			base_dark,
			base_clear,
			foreground_clear,
			foreground_dark,
			base_lit,
			foreground_lit,
		]
	)
	quit(0 if passed else 1)

func _wait_for_render_frames() -> void:
	for _index in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
