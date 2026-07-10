extends "res://tests/test_case.gd"

const BrushEngine = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_brush_engine.gd")

func run() -> Array[String]:
	_test_hard_and_soft_falloff()
	_test_intensity_accumulation_and_erase()
	_test_segment_interpolation()
	_test_edge_clipping_and_coordinate_mapping()
	return get_failures()

func _test_hard_and_soft_falloff() -> void:
	var hard_image := _blank_image(Vector2i(64, 64))
	BrushEngine.paint_stamp(
		hard_image,
		Vector2(32.0, 32.0),
		Vector2(12.0, 12.0),
		1.0,
		0.0,
		BrushEngine.BrushMode.PAINT
	)
	assert_true(hard_image.get_pixel(32, 32).r > 0.99, "Hard brush must fully paint its center")
	assert_true(hard_image.get_pixel(42, 32).r > 0.99, "Hard brush must stay opaque inside its radius")
	assert_true(hard_image.get_pixel(46, 32).r < 0.01, "Hard brush must not paint outside its radius")

	var soft_image := _blank_image(Vector2i(64, 64))
	BrushEngine.paint_stamp(
		soft_image,
		Vector2(32.0, 32.0),
		Vector2(20.0, 20.0),
		1.0,
		1.0,
		BrushEngine.BrushMode.PAINT
	)
	var center := soft_image.get_pixel(32, 32).r
	var middle := soft_image.get_pixel(42, 32).r
	var edge := soft_image.get_pixel(50, 32).r
	assert_true(center > middle and middle > edge, "Soft brush falloff must decrease monotonically from center to edge")
	assert_true(edge > 0.0, "Soft brush must retain a feathered value just inside its edge")
	assert_true(soft_image.get_pixel(54, 32).r < 0.01, "Soft brush must clip outside its radius")

func _test_intensity_accumulation_and_erase() -> void:
	var image := _blank_image(Vector2i(32, 32))
	var center := Vector2(16.0, 16.0)
	var radius := Vector2(6.0, 6.0)
	BrushEngine.paint_stamp(image, center, radius, 0.25, 0.0, BrushEngine.BrushMode.PAINT)
	_assert_approx(image.get_pixel(16, 16).r, 0.25, 0.015, "First low-intensity stamp must apply its configured strength")
	BrushEngine.paint_stamp(image, center, radius, 0.25, 0.0, BrushEngine.BrushMode.PAINT)
	_assert_approx(image.get_pixel(16, 16).r, 0.4375, 0.015, "Repeated paint must accumulate without exceeding one")
	BrushEngine.paint_stamp(image, center, radius, 0.5, 0.0, BrushEngine.BrushMode.ERASE)
	_assert_approx(image.get_pixel(16, 16).r, 0.21875, 0.015, "Erase must reduce existing darkness multiplicatively")

func _test_segment_interpolation() -> void:
	var image := _blank_image(Vector2i(64, 16))
	BrushEngine.paint_segment(
		image,
		Vector2(5.0, 8.0),
		Vector2(58.0, 8.0),
		Vector2(2.5, 2.5),
		1.0,
		0.0,
		0.75,
		BrushEngine.BrushMode.PAINT
	)
	for x in range(5, 59):
		assert_true(image.get_pixel(x, 8).r > 0.0, "Interpolated stroke must not leave a gap at x=%d" % x)

func _test_edge_clipping_and_coordinate_mapping() -> void:
	var image := _blank_image(Vector2i(40, 20))
	var original_size := image.get_size()
	BrushEngine.paint_stamp(
		image,
		Vector2(0.0, 0.0),
		Vector2(12.0, 6.0),
		1.0,
		0.5,
		BrushEngine.BrushMode.PAINT
	)
	assert_eq(image.get_size(), original_size, "A boundary stamp must not resize the mask")
	assert_true(image.get_pixel(0, 0).r > 0.0, "A boundary stamp must still paint its visible portion")

	var canvas_size := Vector2(800.0, 200.0)
	var image_size := Vector2i(400, 100)
	assert_eq(
		BrushEngine.local_to_pixel(Vector2(400.0, 100.0), canvas_size, image_size),
		Vector2(200.0, 50.0),
		"Canvas center must map to mask center"
	)
	assert_eq(
		BrushEngine.pixel_to_local(Vector2(100.0, 25.0), canvas_size, image_size),
		Vector2(200.0, 50.0),
		"Mask coordinates must map back into local canvas space"
	)

func _blank_image(size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	image.fill(Color.BLACK)
	return image

func _assert_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	assert_true(absf(actual - expected) <= tolerance, "%s: expected %.4f, got %.4f" % [message, expected, actual])
