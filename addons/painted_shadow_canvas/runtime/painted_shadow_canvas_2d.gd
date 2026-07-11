@tool
extends Node2D

## A paintable local darkness map rendered as a subtractive PointLight2D.
## Normal additive lights naturally compensate this darkness where they overlap.

const BrushEngine = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_brush_engine.gd")
const LayerScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_layer.gd")
const INTERNAL_LIGHT_NAME := &"__PaintedShadowLight"
const EXTRA_LIGHT_PREFIX := "__PaintedShadowLayer_"
const BASE_LAYER_ID := "base"
const MIN_CANVAS_EXTENT := 1.0
const MIN_MASK_DIMENSION := 16
const MAX_MASK_DIMENSION := 2048
const LARGE_MASK_PIXEL_COUNT := 1024 * 1024

signal layers_changed

@export_group("Canvas")
## Physical bounds in local 2D coordinates. The node origin is the top-left corner.
@export var canvas_size: Vector2 = Vector2(1024.0, 512.0):
	set(value):
		canvas_size = Vector2(
			maxf(absf(value.x), MIN_CANVAS_EXTENT),
			maxf(absf(value.y), MIN_CANVAS_EXTENT)
		)
		_sync_shadow_light()
		queue_redraw()

## Grayscale mask resolution. Set this before detailed painting when possible.
@export var mask_resolution: Vector2i = Vector2i(512, 256):
	set(value):
		var sanitized := _sanitize_resolution(value)
		if mask_resolution == sanitized:
			return
		mask_resolution = sanitized
		_resize_mask_preserving_content(mask_resolution)
		_sync_shadow_light()

@export_group("Shadow")
## Enables or disables the painted darkness without deleting it.
@export var shadow_enabled: bool = true:
	set(value):
		shadow_enabled = value
		_sync_shadow_light()

## Overall subtraction strength. Values around 0.25-0.6 work well with this project's ambient darkness.
@export_range(0.0, 2.0, 0.01, "or_greater") var darkness_strength: float = 0.45:
	set(value):
		darkness_strength = maxf(value, 0.0)
		_sync_shadow_light()

## Per-channel subtraction color. White creates a neutral shadow.
@export var subtraction_color: Color = Color.WHITE:
	set(value):
		subtraction_color = value
		_sync_shadow_light()

## CanvasItem light-mask bits affected by this shadow. Layers 1+2 match the world, player, walls, and enemies.
@export_flags_2d_render var affected_item_cull_mask: int = 3:
	set(value):
		affected_item_cull_mask = value
		_sync_shadow_light()

@export_subgroup("Light Range")
@export var canvas_layer_min: int = 0:
	set(value):
		canvas_layer_min = mini(value, canvas_layer_max)
		_sync_shadow_light()

@export var canvas_layer_max: int = 0:
	set(value):
		canvas_layer_max = maxi(value, canvas_layer_min)
		_sync_shadow_light()

@export var z_index_min: int = -1024:
	set(value):
		z_index_min = mini(value, z_index_max)
		_sync_shadow_light()

@export var z_index_max: int = 1024:
	set(value):
		z_index_max = maxi(value, z_index_min)
		_sync_shadow_light()

@export_group("Editor Preview")
@export var show_bounds_in_editor: bool = true:
	set(value):
		show_bounds_in_editor = value
		queue_redraw()

## PNG-compressed grayscale mask stored inside the owning scene.
@export_storage var mask_png: PackedByteArray = PackedByteArray():
	set(value):
		mask_png = value.duplicate()
		_mask_image = null
		_mask_texture = null
		_ensure_mask_image()
		_sync_shadow_light()

## The original single mask remains the base layer for backwards compatibility.
@export_storage var base_layer_name: String = "Base"
@export_storage var base_layer_enabled: bool = true

## Additional scene-local PaintedShadowLayer resources managed by the painter dock.
@export_storage var paint_layers: Array[Resource] = []

var _shadow_light: PointLight2D = null
var _mask_image: Image = null
var _mask_texture: ImageTexture = null
var _texture_update_pending := false
var _extra_mask_images: Dictionary = {}
var _extra_mask_textures: Dictionary = {}
var _extra_shadow_lights: Dictionary = {}
var _extra_texture_update_pending: Dictionary = {}

func _init() -> void:
	_ensure_shadow_light()
	_ensure_mask_image()
	_ensure_extra_layer_runtime()
	_sync_shadow_light()

func _enter_tree() -> void:
	# Parent CanvasItems enter before their children. Defer once so a texture
	# edited while detached is always rebound after the internal light enters.
	_sync_shadow_light.call_deferred()

func _ready() -> void:
	_ensure_shadow_light()
	_ensure_mask_image()
	_ensure_extra_layer_runtime()
	_sync_shadow_light()
	queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_bounds_in_editor:
		return
	var outline := Color(0.45, 0.7, 1.0, 0.9)
	draw_rect(get_canvas_rect(), Color(0.2, 0.45, 0.75, 0.06), true)
	draw_rect(get_canvas_rect(), outline, false, 2.0)
	draw_line(Vector2.ZERO, Vector2(18.0, 0.0), outline, 2.0)
	draw_line(Vector2.ZERO, Vector2(0.0, 18.0), outline, 2.0)

func get_canvas_rect() -> Rect2:
	return Rect2(Vector2.ZERO, canvas_size)

func get_layer_count() -> int:
	return 1 + paint_layers.size()

func get_layer_ids() -> PackedStringArray:
	var ids := PackedStringArray([BASE_LAYER_ID])
	for resource in paint_layers:
		var layer := _as_shadow_layer(resource)
		if layer != null:
			ids.append(String(layer.get("layer_id")))
	return ids

func get_layer_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = [{
		"id": BASE_LAYER_ID,
		"name": _normalize_layer_name(base_layer_name, "Base"),
		"enabled": base_layer_enabled,
		"z_min": z_index_min,
		"z_max": z_index_max,
		"removable": false,
	}]
	for resource in paint_layers:
		var layer := _as_shadow_layer(resource)
		if layer == null:
			continue
		summaries.append({
			"id": String(layer.get("layer_id")),
			"name": String(layer.get("display_name")),
			"enabled": bool(layer.get("enabled")),
			"z_min": int(layer.get("z_min")),
			"z_max": int(layer.get("z_max")),
			"removable": true,
		})
	return summaries

func has_layer(layer_id: StringName) -> bool:
	return String(layer_id) == BASE_LAYER_ID or _find_extra_layer(String(layer_id)) != null

func get_layer_index(layer_id: StringName) -> int:
	var id := String(layer_id)
	if id == BASE_LAYER_ID:
		return 0
	for index in range(paint_layers.size()):
		var layer := _as_shadow_layer(paint_layers[index])
		if layer != null and String(layer.get("layer_id")) == id:
			return index + 1
	return -1

func get_layer_name(layer_id: StringName) -> String:
	if String(layer_id) == BASE_LAYER_ID:
		return _normalize_layer_name(base_layer_name, "Base")
	var layer := _find_extra_layer(String(layer_id))
	return String(layer.get("display_name")) if layer != null else ""

func is_layer_enabled(layer_id: StringName) -> bool:
	if String(layer_id) == BASE_LAYER_ID:
		return base_layer_enabled
	var layer := _find_extra_layer(String(layer_id))
	return bool(layer.get("enabled")) if layer != null else false

func get_layer_z_range(layer_id: StringName) -> Vector2i:
	if String(layer_id) == BASE_LAYER_ID:
		return Vector2i(z_index_min, z_index_max)
	var layer := _find_extra_layer(String(layer_id))
	if layer == null:
		return Vector2i.ZERO
	return Vector2i(int(layer.get("z_min")), int(layer.get("z_max")))

func get_shadow_layer_resource(layer_id: StringName) -> Resource:
	return _find_extra_layer(String(layer_id))

func create_shadow_layer(
	display_name: String = "Shadow",
	z_min: int = -1024,
	z_max: int = 0
) -> Resource:
	var layer := LayerScript.new() as Resource
	layer.set("display_name", _normalize_layer_name(display_name, "Shadow"))
	layer.call("set_z_range", z_min, z_max)
	return layer

func insert_shadow_layer(layer: Resource, layer_index: int = -1) -> void:
	if _as_shadow_layer(layer) == null:
		return
	_persist_extra_working_masks()
	var layer_id := String(layer.get("layer_id"))
	if layer_id.is_empty() or layer_id == BASE_LAYER_ID or has_layer(layer_id):
		layer_id = String(layer.call("regenerate_id"))
	layer.resource_local_to_scene = true
	var extra_index := paint_layers.size() if layer_index < 1 else clampi(layer_index - 1, 0, paint_layers.size())
	paint_layers.insert(extra_index, layer)
	_rebuild_extra_layer_runtime()
	layers_changed.emit()
	update_configuration_warnings()

func remove_shadow_layer(layer_id: StringName) -> Resource:
	var index := get_layer_index(layer_id)
	if index <= 0:
		return null
	_persist_extra_working_masks()
	var removed := paint_layers[index - 1]
	paint_layers.remove_at(index - 1)
	_rebuild_extra_layer_runtime()
	layers_changed.emit()
	update_configuration_warnings()
	return removed

func set_layer_name(layer_id: StringName, display_name: String) -> void:
	var fallback := "Base" if String(layer_id) == BASE_LAYER_ID else "Shadow"
	var normalized := _normalize_layer_name(display_name, fallback)
	if String(layer_id) == BASE_LAYER_ID:
		base_layer_name = normalized
	else:
		var layer := _find_extra_layer(String(layer_id))
		if layer == null:
			return
		layer.set("display_name", normalized)
	layers_changed.emit()

func set_layer_enabled(layer_id: StringName, enabled: bool) -> void:
	if String(layer_id) == BASE_LAYER_ID:
		base_layer_enabled = enabled
	else:
		var layer := _find_extra_layer(String(layer_id))
		if layer == null:
			return
		layer.set("enabled", enabled)
	_sync_shadow_light()
	layers_changed.emit()

func set_layer_z_range(layer_id: StringName, new_min: int, new_max: int) -> void:
	var ordered_min := clampi(
		mini(new_min, new_max),
		RenderingServer.CANVAS_ITEM_Z_MIN,
		RenderingServer.CANVAS_ITEM_Z_MAX
	)
	var ordered_max := clampi(
		maxi(new_min, new_max),
		RenderingServer.CANVAS_ITEM_Z_MIN,
		RenderingServer.CANVAS_ITEM_Z_MAX
	)
	if String(layer_id) == BASE_LAYER_ID:
		# The exported endpoints guard themselves against crossing. When the
		# complete range moves above its old maximum, raise the maximum first so
		# the minimum is not clamped against stale state.
		if ordered_min > z_index_max:
			z_index_max = ordered_max
			z_index_min = ordered_min
		else:
			z_index_min = ordered_min
			z_index_max = ordered_max
	else:
		var layer := _find_extra_layer(String(layer_id))
		if layer == null:
			return
		layer.call("set_z_range", ordered_min, ordered_max)
	_sync_shadow_light()
	layers_changed.emit()

func get_shadow_light() -> PointLight2D:
	_ensure_shadow_light()
	return _shadow_light

func get_shadow_light_for_layer(layer_id: StringName) -> PointLight2D:
	if String(layer_id) == BASE_LAYER_ID:
		return get_shadow_light()
	_ensure_extra_layer_runtime()
	return _extra_shadow_lights.get(String(layer_id)) as PointLight2D

func get_shadow_lights() -> Array[PointLight2D]:
	_ensure_shadow_light()
	_ensure_extra_layer_runtime()
	var lights: Array[PointLight2D] = [_shadow_light]
	for summary in get_layer_summaries().slice(1):
		var light := _extra_shadow_lights.get(String(summary["id"])) as PointLight2D
		if light != null:
			lights.append(light)
	return lights

func get_mask_size() -> Vector2i:
	return get_layer_mask_size(BASE_LAYER_ID)

func get_layer_mask_size(layer_id: StringName) -> Vector2i:
	var image := _get_layer_mask_image(String(layer_id))
	return image.get_size() if image != null else Vector2i.ZERO

func get_mask_value(pixel: Vector2i) -> float:
	return get_layer_mask_value(BASE_LAYER_ID, pixel)

func get_layer_mask_value(layer_id: StringName, pixel: Vector2i) -> float:
	var image := _get_layer_mask_image(String(layer_id))
	if image == null:
		return 0.0
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= image.get_width() or pixel.y >= image.get_height():
		return 0.0
	return image.get_pixelv(pixel).r

func get_mask_image_copy() -> Image:
	return get_layer_mask_image_copy(BASE_LAYER_ID)

func get_layer_mask_image_copy(layer_id: StringName) -> Image:
	var image := _get_layer_mask_image(String(layer_id))
	return image.duplicate() if image != null else Image.new()

func local_to_mask_pixel(local_position: Vector2) -> Vector2:
	return layer_local_to_mask_pixel(BASE_LAYER_ID, local_position)

func layer_local_to_mask_pixel(layer_id: StringName, local_position: Vector2) -> Vector2:
	var image := _get_layer_mask_image(String(layer_id))
	if image == null:
		return Vector2.ZERO
	return BrushEngine.local_to_pixel(local_position, canvas_size, image.get_size())

## Applies a connected world-space brush segment. Changes stay in a working image
## until `capture_mask_snapshot()` or `apply_mask_snapshot()` is used by the editor.
func paint_segment(
	from_local: Vector2,
	to_local: Vector2,
	brush_radius: float,
	strength: float,
	softness: float,
	spacing_ratio: float,
	erase: bool = false
) -> bool:
	return paint_segment_on_layer(
		BASE_LAYER_ID,
		from_local,
		to_local,
		brush_radius,
		strength,
		softness,
		spacing_ratio,
		erase
	)

func paint_segment_on_layer(
	layer_id: StringName,
	from_local: Vector2,
	to_local: Vector2,
	brush_radius: float,
	strength: float,
	softness: float,
	spacing_ratio: float,
	erase: bool = false
) -> bool:
	var radius_local := maxf(absf(brush_radius), 0.5)
	var spacing_local := maxf(0.25, radius_local * 2.0 * clampf(spacing_ratio, 0.01, 1.0))
	var distance := from_local.distance_to(to_local)
	var points := PackedVector2Array()
	if distance <= 0.0001:
		points.append(from_local)
		return paint_points_on_layer(layer_id, points, radius_local, strength, softness, erase)
	var step_count := maxi(1, int(ceil(distance / spacing_local)))
	for index in range(step_count + 1):
		var t := float(index) / float(step_count)
		points.append(from_local.lerp(to_local, t))
	return paint_points_on_layer(layer_id, points, radius_local, strength, softness, erase)

## Applies pre-spaced brush stamps and uploads the mask texture only once.
## The editor plugin carries spacing remainder across mouse events and calls
## this method so stroke density is independent of input event frequency.
func paint_points(
	local_positions: PackedVector2Array,
	brush_radius: float,
	strength: float,
	softness: float,
	erase: bool = false
) -> bool:
	return paint_points_on_layer(BASE_LAYER_ID, local_positions, brush_radius, strength, softness, erase)

func paint_points_on_layer(
	layer_id: StringName,
	local_positions: PackedVector2Array,
	brush_radius: float,
	strength: float,
	softness: float,
	erase: bool = false
) -> bool:
	if local_positions.is_empty():
		return false
	var id := String(layer_id)
	var image := _get_layer_mask_image(id)
	if image == null:
		return false
	var radius_local := maxf(absf(brush_radius), 0.5)
	var pixels_per_local := Vector2(image.get_size()) / canvas_size
	var radius_pixels := radius_local * pixels_per_local
	var mode: BrushEngine.BrushMode = BrushEngine.BrushMode.ERASE if erase else BrushEngine.BrushMode.PAINT
	var changed := false
	for local_position in local_positions:
		changed = BrushEngine.paint_stamp(
			image,
			BrushEngine.local_to_pixel(local_position, canvas_size, image.get_size()),
			radius_pixels,
			strength,
			softness,
			mode
		) or changed
	if changed:
		_update_layer_mask_texture(id)
	return changed

func fill_mask(value: float) -> void:
	fill_layer_mask(BASE_LAYER_ID, value)

func fill_layer_mask(layer_id: StringName, value: float) -> void:
	var id := String(layer_id)
	var image := _get_layer_mask_image(id)
	if image == null:
		return
	var clamped := clampf(value, 0.0, 1.0)
	image.fill(Color(clamped, clamped, clamped, 1.0))
	_update_layer_mask_texture(id)

func clear_mask() -> void:
	clear_layer_mask(BASE_LAYER_ID)

func clear_layer_mask(layer_id: StringName) -> void:
	fill_layer_mask(layer_id, 0.0)

## Returns the current working image as a compact, scene-serializable PNG.
func capture_mask_snapshot() -> PackedByteArray:
	return capture_layer_mask_snapshot(BASE_LAYER_ID)

func capture_layer_mask_snapshot(layer_id: StringName) -> PackedByteArray:
	var image := _get_layer_mask_image(String(layer_id))
	return image.save_png_to_buffer() if image != null else PackedByteArray()

## Applies a snapshot. This is the stable Undo/Redo and scene-persistence seam.
func apply_mask_snapshot(snapshot: PackedByteArray) -> void:
	apply_layer_mask_snapshot(BASE_LAYER_ID, snapshot)

func apply_layer_mask_snapshot(layer_id: StringName, snapshot: PackedByteArray) -> void:
	var id := String(layer_id)
	if id == BASE_LAYER_ID:
		mask_png = snapshot
		return
	var layer := _find_extra_layer(id)
	if layer == null:
		return
	layer.set("mask_png", snapshot)
	_extra_mask_images.erase(id)
	_extra_mask_textures.erase(id)
	_extra_texture_update_pending.erase(id)
	_ensure_extra_mask_image(id)
	_sync_extra_shadow_light(id)

func import_mask_image(image: Image) -> bool:
	return import_layer_mask_image(BASE_LAYER_ID, image)

func import_layer_mask_image(layer_id: StringName, image: Image) -> bool:
	if image == null or image.is_empty():
		return false
	var imported := image.duplicate()
	if imported.is_compressed():
		var error: Error = imported.decompress()
		if error != OK:
			return false
	imported.convert(Image.FORMAT_L8)
	if imported.get_size() != mask_resolution:
		imported.resize(mask_resolution.x, mask_resolution.y, Image.INTERPOLATE_BILINEAR)
	var id := String(layer_id)
	if id == BASE_LAYER_ID:
		_mask_image = imported
		_update_mask_texture()
		mask_png = _mask_image.save_png_to_buffer()
	else:
		var layer := _find_extra_layer(id)
		if layer == null:
			return false
		_extra_mask_images[id] = imported
		_update_extra_mask_texture(id)
		layer.set("mask_png", imported.save_png_to_buffer())
	return true

func _ensure_shadow_light() -> void:
	if _shadow_light != null and is_instance_valid(_shadow_light):
		return
	var existing := get_node_or_null(NodePath(String(INTERNAL_LIGHT_NAME))) as PointLight2D
	if existing != null:
		_shadow_light = existing
		return
	_shadow_light = PointLight2D.new()
	_shadow_light.name = INTERNAL_LIGHT_NAME
	add_child(_shadow_light, false, Node.INTERNAL_MODE_FRONT)

func _as_shadow_layer(resource: Resource) -> Resource:
	if resource == null or resource.get_script() != LayerScript:
		return null
	return resource

func _find_extra_layer(layer_id: String) -> Resource:
	for resource in paint_layers:
		var layer := _as_shadow_layer(resource)
		if layer != null and String(layer.get("layer_id")) == layer_id:
			return layer
	return null

func _normalize_layer_name(value: String, fallback: String) -> String:
	var normalized := value.strip_edges()
	return fallback if normalized.is_empty() else normalized

func _get_layer_mask_image(layer_id: String) -> Image:
	if layer_id == BASE_LAYER_ID:
		_ensure_mask_image()
		return _mask_image
	return _ensure_extra_mask_image(layer_id)

func _ensure_extra_layer_runtime() -> void:
	var seen_ids: Dictionary = {}
	for resource in paint_layers:
		var layer := _as_shadow_layer(resource)
		if layer == null:
			continue
		var layer_id := String(layer.get("layer_id"))
		if layer_id.is_empty() or layer_id == BASE_LAYER_ID or seen_ids.has(layer_id):
			layer_id = String(layer.call("regenerate_id"))
		seen_ids[layer_id] = true
		_ensure_extra_shadow_light(layer_id)
		_ensure_extra_mask_image(layer_id)

func _ensure_extra_shadow_light(layer_id: String) -> PointLight2D:
	var current := _extra_shadow_lights.get(layer_id) as PointLight2D
	if current != null and is_instance_valid(current):
		return current
	var light := PointLight2D.new()
	light.name = StringName(EXTRA_LIGHT_PREFIX + layer_id)
	add_child(light, false, Node.INTERNAL_MODE_FRONT)
	_extra_shadow_lights[layer_id] = light
	return light

func _ensure_extra_mask_image(layer_id: String) -> Image:
	var current := _extra_mask_images.get(layer_id) as Image
	if current != null and not current.is_empty():
		return current
	var layer := _find_extra_layer(layer_id)
	if layer == null:
		return null
	var decoded := Image.new()
	var layer_png := layer.get("mask_png") as PackedByteArray
	if not layer_png.is_empty() and decoded.load_png_from_buffer(layer_png) == OK and not decoded.is_empty():
		decoded.convert(Image.FORMAT_L8)
		if decoded.get_size() != mask_resolution:
			decoded.resize(mask_resolution.x, mask_resolution.y, Image.INTERPOLATE_BILINEAR)
	else:
		decoded = Image.create(mask_resolution.x, mask_resolution.y, false, Image.FORMAT_L8)
		decoded.fill(Color.BLACK)
	_extra_mask_images[layer_id] = decoded
	_update_extra_mask_texture(layer_id)
	return decoded

func _persist_extra_working_masks() -> void:
	for layer_id_variant in _extra_mask_images.keys():
		var layer_id := String(layer_id_variant)
		var layer := _find_extra_layer(layer_id)
		var image := _extra_mask_images.get(layer_id) as Image
		if layer != null and image != null and not image.is_empty():
			layer.set("mask_png", image.save_png_to_buffer())

func _rebuild_extra_layer_runtime() -> void:
	for light_variant in _extra_shadow_lights.values():
		var light := light_variant as PointLight2D
		if light != null and is_instance_valid(light):
			light.free()
	_extra_shadow_lights.clear()
	_extra_mask_images.clear()
	_extra_mask_textures.clear()
	_extra_texture_update_pending.clear()
	_ensure_extra_layer_runtime()
	_sync_extra_shadow_lights()

func _update_layer_mask_texture(layer_id: String) -> void:
	if layer_id == BASE_LAYER_ID:
		_update_mask_texture()
	else:
		_update_extra_mask_texture(layer_id)

func _update_extra_mask_texture(layer_id: String) -> void:
	var image := _extra_mask_images.get(layer_id) as Image
	if image == null or image.is_empty():
		return
	if Engine.is_editor_hint() and is_inside_tree():
		if not bool(_extra_texture_update_pending.get(layer_id, false)):
			_extra_texture_update_pending[layer_id] = true
			Callable(self, "_flush_extra_mask_texture").bind(layer_id).call_deferred()
		return
	_flush_extra_mask_texture(layer_id)

func _flush_extra_mask_texture(layer_id: String) -> void:
	_extra_texture_update_pending[layer_id] = false
	var image := _extra_mask_images.get(layer_id) as Image
	if image == null or image.is_empty():
		return
	var texture_image := image.duplicate()
	texture_image.convert(Image.FORMAT_RGBA8)
	var texture := _extra_mask_textures.get(layer_id) as ImageTexture
	if (
		texture == null
		or texture.get_width() != image.get_width()
		or texture.get_height() != image.get_height()
	):
		texture = ImageTexture.create_from_image(texture_image)
		_extra_mask_textures[layer_id] = texture
	else:
		texture.update(texture_image)
	_sync_extra_shadow_light(layer_id)

func _ensure_mask_image() -> void:
	if _mask_image != null and not _mask_image.is_empty():
		return
	var decoded := Image.new()
	if not mask_png.is_empty() and decoded.load_png_from_buffer(mask_png) == OK and not decoded.is_empty():
		decoded.convert(Image.FORMAT_L8)
		_mask_image = decoded
		mask_resolution = _sanitize_resolution(decoded.get_size())
	else:
		_mask_image = Image.create(mask_resolution.x, mask_resolution.y, false, Image.FORMAT_L8)
		_mask_image.fill(Color.BLACK)
	_update_mask_texture()

func _resize_mask_preserving_content(new_resolution: Vector2i) -> void:
	if _mask_image != null and not _mask_image.is_empty() and _mask_image.get_size() != new_resolution:
		_mask_image.resize(new_resolution.x, new_resolution.y, Image.INTERPOLATE_BILINEAR)
		_update_mask_texture()
		mask_png = _mask_image.save_png_to_buffer()
	for resource in paint_layers:
		var layer := _as_shadow_layer(resource)
		if layer == null:
			continue
		var layer_id := String(layer.get("layer_id"))
		var image := _ensure_extra_mask_image(layer_id)
		if image == null or image.get_size() == new_resolution:
			continue
		image.resize(new_resolution.x, new_resolution.y, Image.INTERPOLATE_BILINEAR)
		_update_extra_mask_texture(layer_id)
		layer.set("mask_png", image.save_png_to_buffer())

func _update_mask_texture() -> void:
	if _mask_image == null or _mask_image.is_empty():
		return
	# Mouse input can produce several stamps in one editor frame. Coalesce them
	# into one full texture conversion/upload while keeping runtime calls eager.
	if Engine.is_editor_hint() and is_inside_tree():
		if not _texture_update_pending:
			_texture_update_pending = true
			_flush_mask_texture.call_deferred()
		return
	_flush_mask_texture()

func _flush_mask_texture() -> void:
	_texture_update_pending = false
	if _mask_image == null or _mask_image.is_empty():
		return
	# GL Compatibility's 2D light atlas expects a color texture. Keep the
	# authoritative mask compact (L8), but upload an RGBA8 GPU copy.
	var texture_image := _mask_image.duplicate()
	texture_image.convert(Image.FORMAT_RGBA8)
	if (
		_mask_texture == null
		or _mask_texture.get_width() != _mask_image.get_width()
		or _mask_texture.get_height() != _mask_image.get_height()
	):
		_mask_texture = ImageTexture.create_from_image(texture_image)
	else:
		_mask_texture.update(texture_image)
	_sync_shadow_light()

func _sync_shadow_light() -> void:
	if _shadow_light != null and is_instance_valid(_shadow_light):
		_configure_shadow_light(
			_shadow_light,
			base_layer_enabled,
			z_index_min,
			z_index_max,
			_mask_texture
		)
	_sync_extra_shadow_lights()

func _sync_extra_shadow_lights() -> void:
	_ensure_extra_layer_runtime()
	for resource in paint_layers:
		var layer := _as_shadow_layer(resource)
		if layer == null:
			continue
		var layer_id := String(layer.get("layer_id"))
		_sync_extra_shadow_light(layer_id)

func _sync_extra_shadow_light(layer_id: String) -> void:
	var layer := _find_extra_layer(layer_id)
	if layer == null:
		return
	var light := _ensure_extra_shadow_light(layer_id)
	var texture := _extra_mask_textures.get(layer_id) as ImageTexture
	_configure_shadow_light(
		light,
		bool(layer.get("enabled")),
		int(layer.get("z_min")),
		int(layer.get("z_max")),
		texture
	)

func _configure_shadow_light(
	light: PointLight2D,
	layer_enabled: bool,
	z_min: int,
	z_max: int,
	texture: ImageTexture
) -> void:
	light.enabled = shadow_enabled and layer_enabled
	light.editor_only = false
	light.blend_mode = Light2D.BLEND_MODE_SUB
	light.color = subtraction_color
	light.energy = darkness_strength
	light.range_item_cull_mask = affected_item_cull_mask
	light.range_layer_min = canvas_layer_min
	light.range_layer_max = canvas_layer_max
	light.range_z_min = mini(z_min, z_max)
	light.range_z_max = maxi(z_min, z_max)
	light.shadow_enabled = false
	light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Assigning a dynamic light texture before the CanvasItem enters a viewport
	# trips the GL Compatibility light-atlas path. The texture is attached from
	# _ready() (and on every in-tree edit) instead.
	if is_inside_tree() and light.is_inside_tree():
		light.texture = texture
	light.texture_scale = 1.0
	light.offset = Vector2.ZERO
	light.position = canvas_size * 0.5
	var texture_size := Vector2(maxi(mask_resolution.x, 1), maxi(mask_resolution.y, 1))
	light.scale = canvas_size / texture_size

func _sanitize_resolution(value: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(abs(value.x), MIN_MASK_DIMENSION, MAX_MASK_DIMENSION),
		clampi(abs(value.y), MIN_MASK_DIMENSION, MAX_MASK_DIMENSION)
	)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if affected_item_cull_mask == 0:
		warnings.append("Affected Item Cull Mask is empty, so the painted shadow cannot affect any CanvasItem.")
	if darkness_strength <= 0.0:
		warnings.append("Darkness Strength is zero, so the painted shadow is invisible.")
	var cumulative_pixels := mask_resolution.x * mask_resolution.y * get_layer_count()
	if cumulative_pixels >= LARGE_MASK_PIXEL_COUNT:
		warnings.append("Painted-shadow layers use one full mask and SUB light each. Reduce resolution, layer count, or canvas coverage if editor/runtime cost becomes high.")
	return warnings
