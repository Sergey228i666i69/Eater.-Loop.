extends SceneTree

## Real-renderer smoke probe for the addon's central visual contract.
## Run with a non-headless display driver; the dummy headless renderer cannot
## produce meaningful pixel samples.

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")

var _add_light: PointLight2D = null

func _initialize() -> void:
	var scene := Node2D.new()
	root.add_child(scene)

	var background := ColorRect.new()
	background.size = Vector2(320.0, 160.0)
	background.color = Color(0.8, 0.8, 0.8, 1.0)
	scene.add_child(background)
	var layer_two_receiver := ColorRect.new()
	layer_two_receiver.position = Vector2(0.0, 80.0)
	layer_two_receiver.size = Vector2(128.0, 48.0)
	layer_two_receiver.color = background.color
	layer_two_receiver.light_mask = 2
	scene.add_child(layer_two_receiver)

	var ambient := CanvasModulate.new()
	ambient.color = Color(0.5, 0.5, 0.5, 1.0)
	scene.add_child(ambient)

	var shadow: Node2D = CanvasScript.new()
	shadow.canvas_size = Vector2(128.0, 128.0)
	shadow.mask_resolution = Vector2i(64, 64)
	shadow.darkness_strength = 0.2
	shadow.fill_mask(1.0)
	scene.add_child(shadow)

	var light_image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	light_image.fill(Color.WHITE)
	_add_light = PointLight2D.new()
	_add_light.texture = ImageTexture.create_from_image(light_image)
	_add_light.position = Vector2(64.0, 64.0)
	_add_light.scale = Vector2(2.0, 2.0)
	_add_light.energy = 0.5
	_add_light.range_item_cull_mask = 3
	_add_light.enabled = false
	scene.add_child(_add_light)

	_run_probe.call_deferred()

func _run_probe() -> void:
	await _wait_for_render_frames()
	var dark_image := root.get_texture().get_image()
	var render_transform := root.get_stretch_transform() * root.get_canvas_transform()
	var layer_one_pixel := Vector2i(render_transform * Vector2(64.0, 40.0))
	var layer_two_pixel := Vector2i(render_transform * Vector2(64.0, 104.0))
	var ambient_pixel := Vector2i(render_transform * Vector2(200.0, 64.0))
	var layer_one_dark := dark_image.get_pixelv(layer_one_pixel).get_luminance()
	var layer_two_dark := dark_image.get_pixelv(layer_two_pixel).get_luminance()
	var ambient_luminance := dark_image.get_pixelv(ambient_pixel).get_luminance()

	_add_light.enabled = true
	await _wait_for_render_frames()
	var lit_image := root.get_texture().get_image()
	var layer_one_lit := lit_image.get_pixelv(layer_one_pixel).get_luminance()
	var layer_two_lit := lit_image.get_pixelv(layer_two_pixel).get_luminance()

	var layer_one_shadow_delta := ambient_luminance - layer_one_dark
	var layer_two_shadow_delta := ambient_luminance - layer_two_dark
	var layer_one_light_delta := layer_one_lit - layer_one_dark
	var layer_two_light_delta := layer_two_lit - layer_two_dark
	var passed := (
		layer_one_shadow_delta > 0.03
		and layer_two_shadow_delta > 0.03
		and layer_one_light_delta > 0.08
		and layer_two_light_delta > 0.08
	)
	print(
		"PAINTED_SHADOW_RENDER %s ambient=%.4f layer1_dark=%.4f layer1_lit=%.4f layer2_dark=%.4f layer2_lit=%.4f"
		% [
			"PASS" if passed else "FAIL",
			ambient_luminance,
			layer_one_dark,
			layer_one_lit,
			layer_two_dark,
			layer_two_lit,
		]
	)
	quit(0 if passed else 1)

func _wait_for_render_frames() -> void:
	for _index in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
