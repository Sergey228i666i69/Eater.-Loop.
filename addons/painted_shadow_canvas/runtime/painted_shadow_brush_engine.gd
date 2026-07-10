@tool
extends RefCounted

## Stateless image-painting primitives used by both the editor plugin and tests.

enum BrushMode {
	PAINT,
	ERASE,
}

const MIN_RADIUS_PIXELS := 0.5

## Paints one elliptical stamp into a grayscale mask.
## `radius_pixels` may be non-uniform so a world-space circular brush stays
## circular even when the mask resolution and canvas aspect ratios differ.
static func paint_stamp(
	image: Image,
	center_pixels: Vector2,
	radius_pixels: Vector2,
	strength: float,
	softness: float,
	mode: BrushMode = BrushMode.PAINT
) -> bool:
	if image == null or image.is_empty():
		return false
	var radius := Vector2(
		maxf(absf(radius_pixels.x), MIN_RADIUS_PIXELS),
		maxf(absf(radius_pixels.y), MIN_RADIUS_PIXELS)
	)
	var amount := clampf(strength, 0.0, 1.0)
	if amount <= 0.0:
		return false
	var feather := clampf(softness, 0.0, 1.0)
	var min_x := maxi(0, int(floor(center_pixels.x - radius.x)))
	var min_y := maxi(0, int(floor(center_pixels.y - radius.y)))
	var max_x := mini(image.get_width() - 1, int(ceil(center_pixels.x + radius.x)))
	var max_y := mini(image.get_height() - 1, int(ceil(center_pixels.y + radius.y)))
	if min_x > max_x or min_y > max_y:
		return false

	var changed := false
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var sample := Vector2(float(x) + 0.5, float(y) + 0.5)
			var normalized_delta := (sample - center_pixels) / radius
			var normalized_distance := normalized_delta.length()
			if normalized_distance > 1.0:
				continue
			var weight := _falloff(normalized_distance, feather)
			var stamp_amount := amount * weight
			if stamp_amount <= 0.0:
				continue
			var previous := image.get_pixel(x, y).r
			var next_value := previous
			if mode == BrushMode.ERASE:
				next_value = previous * (1.0 - stamp_amount)
			else:
				next_value = 1.0 - (1.0 - previous) * (1.0 - stamp_amount)
			next_value = clampf(next_value, 0.0, 1.0)
			if is_equal_approx(previous, next_value):
				continue
			image.set_pixel(x, y, Color(next_value, next_value, next_value, 1.0))
			changed = true
	return changed

## Paints a connected segment in image space. This helper is useful for tests
## and non-editor callers. The editor-facing node samples in world space so it
## can preserve spacing under non-uniform mask resolutions.
static func paint_segment(
	image: Image,
	from_pixels: Vector2,
	to_pixels: Vector2,
	radius_pixels: Vector2,
	strength: float,
	softness: float,
	spacing_ratio: float,
	mode: BrushMode = BrushMode.PAINT
) -> bool:
	var distance := from_pixels.distance_to(to_pixels)
	if distance <= 0.0001:
		return paint_stamp(image, from_pixels, radius_pixels, strength, softness, mode)
	var effective_radius := maxf(MIN_RADIUS_PIXELS, minf(absf(radius_pixels.x), absf(radius_pixels.y)))
	var spacing := maxf(0.5, effective_radius * 2.0 * clampf(spacing_ratio, 0.01, 1.0))
	var step_count := maxi(1, int(ceil(distance / spacing)))
	var changed := false
	for index in range(step_count + 1):
		var t := float(index) / float(step_count)
		changed = paint_stamp(
			image,
			from_pixels.lerp(to_pixels, t),
			radius_pixels,
			strength,
			softness,
			mode
		) or changed
	return changed

static func local_to_pixel(local_position: Vector2, canvas_size: Vector2, image_size: Vector2i) -> Vector2:
	var safe_size := Vector2(maxf(canvas_size.x, 0.001), maxf(canvas_size.y, 0.001))
	return local_position / safe_size * Vector2(image_size)

static func pixel_to_local(pixel_position: Vector2, canvas_size: Vector2, image_size: Vector2i) -> Vector2:
	var safe_image_size := Vector2(maxi(image_size.x, 1), maxi(image_size.y, 1))
	return pixel_position / safe_image_size * canvas_size

static func _falloff(normalized_distance: float, softness: float) -> float:
	if normalized_distance > 1.0:
		return 0.0
	if softness <= 0.0001:
		return 1.0
	var hard_core := 1.0 - softness
	if normalized_distance <= hard_core:
		return 1.0
	var t := clampf((normalized_distance - hard_core) / maxf(softness, 0.0001), 0.0, 1.0)
	var smooth_t := t * t * (3.0 - 2.0 * t)
	return 1.0 - smooth_t
