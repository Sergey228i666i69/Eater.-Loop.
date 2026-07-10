extends "res://tests/test_case.gd"

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")
const StrokeSampler = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_stroke_sampler.gd")

func run() -> Array[String]:
	var one_event_path := PackedVector2Array([
		Vector2(100.0, 256.0),
		Vector2(900.0, 256.0),
	])
	var many_event_path := PackedVector2Array()
	for x in range(100, 901, 10):
		many_event_path.append(Vector2(float(x), 256.0))

	var one_event_mask := _paint_path(one_event_path)
	var many_event_mask := _paint_path(many_event_path)
	assert_eq(one_event_mask.get_size(), many_event_mask.get_size(), "Compared stroke masks must have equal dimensions")
	assert_eq(
		one_event_mask.get_data(),
		many_event_mask.get_data(),
		"Stroke spacing and intensity must not depend on mouse-motion event frequency"
	)
	return get_failures()

func _paint_path(points: PackedVector2Array) -> Image:
	var canvas := CanvasScript.new()
	canvas.canvas_size = Vector2(1024.0, 512.0)
	canvas.mask_resolution = Vector2i(128, 64)
	var sampler := StrokeSampler.new()
	var stamps := sampler.begin(points[0], 23.04)
	for index in range(1, points.size()):
		stamps.append_array(sampler.sample(points[index]))
	stamps.append_array(sampler.finish(true))
	canvas.paint_points(stamps, 64.0, 0.35, 0.85, false)
	var result := canvas.get_mask_image_copy()
	canvas.free()
	return result
