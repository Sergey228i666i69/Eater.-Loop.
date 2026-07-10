@tool
extends Node2D

## A paintable local darkness map rendered as a subtractive PointLight2D.
## Normal additive lights naturally compensate this darkness where they overlap.

const BrushEngine = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_brush_engine.gd")
const INTERNAL_LIGHT_NAME := &"__PaintedShadowLight"
const MIN_CANVAS_EXTENT := 1.0
const MIN_MASK_DIMENSION := 16
const MAX_MASK_DIMENSION := 2048
const LARGE_MASK_PIXEL_COUNT := 1024 * 1024

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

var _shadow_light: PointLight2D = null
var _mask_image: Image = null
var _mask_texture: ImageTexture = null
var _texture_update_pending := false

func _init() -> void:
	_ensure_shadow_light()
	_ensure_mask_image()
	_sync_shadow_light()

func _enter_tree() -> void:
	# Parent CanvasItems enter before their children. Defer once so a texture
	# edited while detached is always rebound after the internal light enters.
	_sync_shadow_light.call_deferred()

func _ready() -> void:
	_ensure_shadow_light()
	_ensure_mask_image()
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

func get_shadow_light() -> PointLight2D:
	_ensure_shadow_light()
	return _shadow_light

func get_mask_size() -> Vector2i:
	_ensure_mask_image()
	return _mask_image.get_size()

func get_mask_value(pixel: Vector2i) -> float:
	_ensure_mask_image()
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= _mask_image.get_width() or pixel.y >= _mask_image.get_height():
		return 0.0
	return _mask_image.get_pixelv(pixel).r

func get_mask_image_copy() -> Image:
	_ensure_mask_image()
	return _mask_image.duplicate()

func local_to_mask_pixel(local_position: Vector2) -> Vector2:
	_ensure_mask_image()
	return BrushEngine.local_to_pixel(local_position, canvas_size, _mask_image.get_size())

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
	_ensure_mask_image()
	var radius_local := maxf(absf(brush_radius), 0.5)
	var spacing_local := maxf(0.25, radius_local * 2.0 * clampf(spacing_ratio, 0.01, 1.0))
	var distance := from_local.distance_to(to_local)
	var points := PackedVector2Array()
	if distance <= 0.0001:
		points.append(from_local)
		return paint_points(points, radius_local, strength, softness, erase)
	var step_count := maxi(1, int(ceil(distance / spacing_local)))
	for index in range(step_count + 1):
		var t := float(index) / float(step_count)
		points.append(from_local.lerp(to_local, t))
	return paint_points(points, radius_local, strength, softness, erase)

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
	if local_positions.is_empty():
		return false
	_ensure_mask_image()
	var radius_local := maxf(absf(brush_radius), 0.5)
	var pixels_per_local := Vector2(_mask_image.get_size()) / canvas_size
	var radius_pixels := radius_local * pixels_per_local
	var mode: BrushEngine.BrushMode = BrushEngine.BrushMode.ERASE if erase else BrushEngine.BrushMode.PAINT
	var changed := false
	for local_position in local_positions:
		changed = BrushEngine.paint_stamp(
			_mask_image,
			local_to_mask_pixel(local_position),
			radius_pixels,
			strength,
			softness,
			mode
		) or changed
	if changed:
		_update_mask_texture()
	return changed

func fill_mask(value: float) -> void:
	_ensure_mask_image()
	var clamped := clampf(value, 0.0, 1.0)
	_mask_image.fill(Color(clamped, clamped, clamped, 1.0))
	_update_mask_texture()

func clear_mask() -> void:
	fill_mask(0.0)

## Returns the current working image as a compact, scene-serializable PNG.
func capture_mask_snapshot() -> PackedByteArray:
	_ensure_mask_image()
	return _mask_image.save_png_to_buffer()

## Applies a snapshot. This is the stable Undo/Redo and scene-persistence seam.
func apply_mask_snapshot(snapshot: PackedByteArray) -> void:
	mask_png = snapshot

func import_mask_image(image: Image) -> bool:
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
	_mask_image = imported
	_update_mask_texture()
	mask_png = _mask_image.save_png_to_buffer()
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
	if _mask_image == null or _mask_image.is_empty():
		return
	if _mask_image.get_size() == new_resolution:
		return
	_mask_image.resize(new_resolution.x, new_resolution.y, Image.INTERPOLATE_BILINEAR)
	_update_mask_texture()
	mask_png = _mask_image.save_png_to_buffer()

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
	if _shadow_light == null or not is_instance_valid(_shadow_light):
		return
	_shadow_light.enabled = shadow_enabled
	_shadow_light.editor_only = false
	_shadow_light.blend_mode = Light2D.BLEND_MODE_SUB
	_shadow_light.color = subtraction_color
	_shadow_light.energy = darkness_strength
	_shadow_light.range_item_cull_mask = affected_item_cull_mask
	_shadow_light.range_layer_min = canvas_layer_min
	_shadow_light.range_layer_max = canvas_layer_max
	_shadow_light.range_z_min = z_index_min
	_shadow_light.range_z_max = z_index_max
	_shadow_light.shadow_enabled = false
	_shadow_light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Assigning a dynamic light texture before the CanvasItem enters a viewport
	# trips the GL Compatibility light-atlas path. The texture is attached from
	# _ready() (and on every in-tree edit) instead.
	if is_inside_tree() and _shadow_light.is_inside_tree():
		_shadow_light.texture = _mask_texture
	_shadow_light.texture_scale = 1.0
	_shadow_light.offset = Vector2.ZERO
	_shadow_light.position = canvas_size * 0.5
	var texture_size := Vector2(maxi(mask_resolution.x, 1), maxi(mask_resolution.y, 1))
	_shadow_light.scale = canvas_size / texture_size

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
	if mask_resolution.x * mask_resolution.y >= LARGE_MASK_PIXEL_COUNT:
		warnings.append("Large masks make brush uploads and scene snapshots heavier. Prefer several local canvases when possible.")
	return warnings
