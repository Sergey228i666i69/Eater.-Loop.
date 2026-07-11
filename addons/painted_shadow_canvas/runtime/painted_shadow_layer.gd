@tool
extends Resource

## Serializable data for one additional painted-shadow layer.
## The base layer remains on PaintedShadowCanvas2D for backwards compatibility.

@export_storage var layer_id: String = "":
	set(value):
		layer_id = value.strip_edges()
		if layer_id.is_empty():
			layer_id = Resource.generate_scene_unique_id()
		emit_changed()

@export_storage var display_name: String = "Shadow":
	set(value):
		display_name = value.strip_edges()
		if display_name.is_empty():
			display_name = "Shadow"
		emit_changed()

@export_storage var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

@export_storage var z_min: int = -1024:
	set(value):
		z_min = clampi(
			value,
			RenderingServer.CANVAS_ITEM_Z_MIN,
			RenderingServer.CANVAS_ITEM_Z_MAX
		)
		if z_max < z_min:
			z_max = z_min
		emit_changed()

@export_storage var z_max: int = 0:
	set(value):
		z_max = clampi(
			value,
			RenderingServer.CANVAS_ITEM_Z_MIN,
			RenderingServer.CANVAS_ITEM_Z_MAX
		)
		if z_min > z_max:
			z_min = z_max
		emit_changed()

@export_storage var mask_png: PackedByteArray = PackedByteArray():
	set(value):
		mask_png = value.duplicate()
		emit_changed()

func _init() -> void:
	resource_local_to_scene = true
	if layer_id.is_empty():
		layer_id = Resource.generate_scene_unique_id()

func regenerate_id() -> String:
	layer_id = Resource.generate_scene_unique_id()
	return layer_id

func set_z_range(new_min: int, new_max: int) -> void:
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
	z_min = ordered_min
	z_max = ordered_max
	emit_changed()
