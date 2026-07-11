@tool
extends EditorPlugin

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")
const DockScript = preload("res://addons/painted_shadow_canvas/editor/painted_shadow_dock.gd")
const StrokeSampler = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_stroke_sampler.gd")
const ICON_PATH := "res://addons/painted_shadow_canvas/icon.svg"
const BASE_LAYER_ID := "base"

var _dock: VBoxContainer = null
var _editor_dock: EditorDock = null
var _edited_canvas: Node2D = null
var _stroke_active := false
var _stroke_changed := false
var _stroke_before := PackedByteArray()
var _stroke_layer_id := BASE_LAYER_ID
var _stroke_sampler: RefCounted = StrokeSampler.new()
var _cursor_local_position := Vector2.ZERO
var _cursor_visible := false
var _active_layer_id := BASE_LAYER_ID

static func compose_local_to_viewport_transform(
	viewport_canvas_transform: Transform2D,
	item_canvas_transform: Transform2D
) -> Transform2D:
	return viewport_canvas_transform * item_canvas_transform

static func viewport_position_to_local(
	viewport_position: Vector2,
	viewport_canvas_transform: Transform2D,
	item_canvas_transform: Transform2D
) -> Vector2:
	return compose_local_to_viewport_transform(
		viewport_canvas_transform,
		item_canvas_transform
	).affine_inverse() * viewport_position

static func should_capture_paint_pointer_event(
	event: InputEvent,
	navigation_active: bool
) -> bool:
	if navigation_active:
		return false
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventMouseMotion:
		return (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	return false

func _enter_tree() -> void:
	var icon_texture := load(ICON_PATH) as Texture2D
	add_custom_type("PaintedShadowCanvas2D", "Node2D", CanvasScript, icon_texture)
	_dock = DockScript.new()
	_dock.name = "Painted Shadow"
	_dock.settings_changed.connect(_on_settings_changed)
	_dock.paint_mode_changed.connect(_on_paint_mode_changed)
	_dock.clear_requested.connect(_on_clear_requested)
	_dock.fill_requested.connect(_on_fill_requested)
	_dock.layer_selected.connect(_on_layer_selected)
	_dock.layer_add_requested.connect(_on_layer_add_requested)
	_dock.layer_remove_requested.connect(_on_layer_remove_requested)
	_dock.layer_name_changed.connect(_on_layer_name_changed)
	_dock.layer_enabled_changed.connect(_on_layer_enabled_changed)
	_dock.layer_z_range_changed.connect(_on_layer_z_range_changed)
	_editor_dock = EditorDock.new()
	_editor_dock.name = "PaintedShadowCanvasDock"
	_editor_dock.title = "Painted Shadow"
	# Use a dedicated key so editors that saved the original hidden Inspector-tab
	# placement migrate to the visible bottom painter on the next plugin reload.
	_editor_dock.layout_key = "painted_shadow_canvas_painter"
	_editor_dock.dock_icon = icon_texture
	_editor_dock.force_show_icon = true
	_editor_dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	_editor_dock.available_layouts = EditorDock.DOCK_LAYOUT_ALL
	_editor_dock.global = false
	_editor_dock.transient = true
	_editor_dock.add_child(_dock)
	add_dock(_editor_dock)
	_editor_dock.close()
	set_force_draw_over_forwarding_enabled()

func _exit_tree() -> void:
	_finish_stroke()
	if _editor_dock != null:
		remove_dock(_editor_dock)
		_editor_dock.queue_free()
		_editor_dock = null
	_dock = null
	remove_custom_type("PaintedShadowCanvas2D")
	_set_edited_canvas(null)

func _handles(object: Object) -> bool:
	if object == null:
		return false
	var script := object.get_script() as Script
	while script != null:
		if script == CanvasScript:
			return true
		script = script.get_base_script()
	return false

func _clear() -> void:
	_cancel_stroke()
	_set_edited_canvas(null)
	_active_layer_id = BASE_LAYER_ID
	_cursor_visible = false
	if _dock != null:
		_dock.set_target_available(false)
		_dock.set_layer_summaries([], "")
	update_overlays()

func _apply_changes() -> void:
	_finish_stroke()

func _edit(object: Object) -> void:
	_finish_stroke()
	_set_edited_canvas(object as Node2D if _handles(object) else null)
	_active_layer_id = BASE_LAYER_ID
	_cursor_visible = false
	if _dock != null:
		_dock.set_target_available(_edited_canvas != null)
		_refresh_layer_controls()
	update_overlays()

func _make_visible(visible: bool) -> void:
	if _dock == null or _editor_dock == null:
		return
	if visible:
		# open() only unhides an EditorDock. make_visible() also focuses its tab
		# and expands the bottom panel, which is required for a contextual painter.
		_editor_dock.make_visible()
	else:
		_cancel_stroke()
		_cursor_visible = false
		_editor_dock.close()
	update_overlays()

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not _can_paint():
		return false

	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed or event.meta_pressed or event.alt_pressed:
			# Let the editor handle its shortcuts, but first turn an in-flight
			# stroke into the newest Undo action. In particular, Cmd/Ctrl+Z must
			# undo that stroke instead of removing a newly added active layer.
			if _stroke_active:
				_finish_stroke()
			return false
		match event.keycode:
			KEY_B:
				_dock.set_erase_mode(false)
				return true
			KEY_E:
				_dock.set_erase_mode(true)
				return true
			KEY_BRACKETLEFT:
				_dock.adjust_brush_size(0.85)
				return true
			KEY_BRACKETRIGHT:
				_dock.adjust_brush_size(1.18)
				return true
			KEY_ESCAPE:
				if _stroke_active:
					_cancel_stroke()
					return true
				return false

	if event is InputEventMouseMotion:
		_cursor_local_position = _screen_to_local(event.position)
		_cursor_visible = true
		var navigation_active: bool = (
			(event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0
			or Input.is_key_pressed(KEY_SPACE)
		)
		if navigation_active:
			if _stroke_active:
				_finish_stroke()
			update_overlays()
			return false
		var capture_left_drag := should_capture_paint_pointer_event(event, navigation_active)
		if _stroke_active and capture_left_drag:
			_paint_to(_cursor_local_position)
			update_overlays()
			return true
		if _stroke_active:
			# The mouse may have been released outside the 2D viewport, in which
			# case no MouseButton release reaches this plugin.
			_finish_stroke()
		update_overlays()
		# Paint mode owns an unmodified left drag everywhere in the viewport.
		# Outside the bounds it paints nothing, but it must not move/rotate/scale
		# the selected canvas through the built-in CanvasItemEditor tools.
		return capture_left_drag

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Input.is_key_pressed(KEY_SPACE):
			return false
		var local_position := _screen_to_local(event.position)
		_cursor_local_position = local_position
		_cursor_visible = true
		if event.pressed:
			if get_canvas_rect().has_point(local_position):
				_begin_stroke(local_position)
			update_overlays()
			return true
		if _stroke_active:
			_finish_stroke()
		update_overlays()
		return true

	return false

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		return
	var canvas_transform := _get_local_to_viewport_transform()
	var rect: Rect2 = get_canvas_rect()
	var bounds := PackedVector2Array([
		canvas_transform * rect.position,
		canvas_transform * Vector2(rect.end.x, rect.position.y),
		canvas_transform * rect.end,
		canvas_transform * Vector2(rect.position.x, rect.end.y),
		canvas_transform * rect.position,
	])
	overlay.draw_polyline(bounds, Color(0.4, 0.72, 1.0, 0.95), 2.0, true)

	if not _can_paint() or not _cursor_visible or not rect.has_point(_cursor_local_position):
		return
	var radius: float = float(_dock.call("get_brush_size")) * 0.5
	var cursor_points := PackedVector2Array()
	var segment_count := 48
	for index in range(segment_count + 1):
		var angle := TAU * float(index) / float(segment_count)
		var local_point: Vector2 = _cursor_local_position + Vector2.from_angle(angle) * radius
		cursor_points.append(canvas_transform * local_point)
	var cursor_color := Color(1.0, 0.45, 0.35, 0.95) if _dock.is_erase_mode() else Color(0.72, 0.86, 1.0, 0.95)
	overlay.draw_polyline(cursor_points, cursor_color, 2.0, true)
	var center := canvas_transform * _cursor_local_position
	overlay.draw_circle(center, 2.5, cursor_color)

func get_canvas_rect() -> Rect2:
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		return Rect2()
	return _edited_canvas.call("get_canvas_rect") as Rect2

func _can_paint() -> bool:
	return (
		_edited_canvas != null
		and is_instance_valid(_edited_canvas)
		and _dock != null
		and bool(_edited_canvas.call("has_layer", _active_layer_id))
		and bool(_edited_canvas.call("is_layer_enabled", _active_layer_id))
		and _dock.is_paint_mode_enabled()
	)

func _screen_to_local(screen_position: Vector2) -> Vector2:
	var editor_viewport := EditorInterface.get_editor_viewport_2d()
	return viewport_position_to_local(
		screen_position,
		editor_viewport.global_canvas_transform,
		_edited_canvas.get_global_transform_with_canvas()
	)

func _get_local_to_viewport_transform() -> Transform2D:
	var editor_viewport := EditorInterface.get_editor_viewport_2d()
	return compose_local_to_viewport_transform(
		editor_viewport.global_canvas_transform,
		_edited_canvas.get_global_transform_with_canvas()
	)

func _begin_stroke(local_position: Vector2) -> void:
	if _stroke_active:
		_finish_stroke()
	_stroke_layer_id = _active_layer_id
	_stroke_before = _edited_canvas.call("capture_layer_mask_snapshot", _stroke_layer_id) as PackedByteArray
	_stroke_active = true
	_stroke_changed = false
	var radius: float = float(_dock.call("get_brush_size")) * 0.5
	var spacing_world := maxf(0.25, radius * 2.0 * float(_dock.call("get_brush_spacing")))
	_paint_points(_stroke_sampler.call("begin", local_position, spacing_world) as PackedVector2Array)

func _paint_to(local_position: Vector2) -> void:
	if not _stroke_active:
		return
	_paint_points(_stroke_sampler.call("sample", local_position) as PackedVector2Array)

func _paint_points(points: PackedVector2Array) -> void:
	if points.is_empty() or not _stroke_active:
		return
	var radius: float = float(_dock.call("get_brush_size")) * 0.5
	var changed: bool = _edited_canvas.call(
		"paint_points_on_layer",
		_stroke_layer_id,
		points,
		radius,
		_dock.get_brush_strength(),
		_dock.get_brush_softness(),
		_dock.is_erase_mode()
	)
	_stroke_changed = _stroke_changed or changed

func _finish_stroke() -> void:
	if not _stroke_active:
		return
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		_stroke_active = false
		_stroke_sampler.call("cancel")
		_stroke_before = PackedByteArray()
		_stroke_changed = false
		return
	_paint_points(_stroke_sampler.call("finish", true) as PackedVector2Array)
	_stroke_active = false
	var after := _edited_canvas.call("capture_layer_mask_snapshot", _stroke_layer_id) as PackedByteArray
	if _stroke_changed and after != _stroke_before:
		_commit_snapshot_action("Paint shadow stroke", _stroke_layer_id, _stroke_before, after)
	else:
		_edited_canvas.call("apply_layer_mask_snapshot", _stroke_layer_id, _stroke_before)
	_stroke_before = PackedByteArray()
	_stroke_changed = false

func _cancel_stroke() -> void:
	if not _stroke_active:
		return
	_stroke_active = false
	if _edited_canvas != null and is_instance_valid(_edited_canvas):
		_edited_canvas.call("apply_layer_mask_snapshot", _stroke_layer_id, _stroke_before)
	_stroke_sampler.call("cancel")
	_stroke_before = PackedByteArray()
	_stroke_changed = false
	update_overlays()

func _commit_snapshot_action(
	action_name: String,
	layer_id: String,
	before: PackedByteArray,
	after: PackedByteArray
) -> void:
	var undo_redo := get_undo_redo()
	undo_redo.create_action(action_name, UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"apply_layer_mask_snapshot", layer_id, after)
	undo_redo.add_undo_method(_edited_canvas, &"apply_layer_mask_snapshot", layer_id, before)
	undo_redo.commit_action()

func _apply_full_mask_action(action_name: String, value: float) -> void:
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		return
	_finish_stroke()
	var before := _edited_canvas.call("capture_layer_mask_snapshot", _active_layer_id) as PackedByteArray
	_edited_canvas.call("fill_layer_mask", _active_layer_id, value)
	var after := _edited_canvas.call("capture_layer_mask_snapshot", _active_layer_id) as PackedByteArray
	if after == before:
		return
	_commit_snapshot_action(action_name, _active_layer_id, before, after)
	update_overlays()

func _set_edited_canvas(canvas: Node2D) -> void:
	var callback := Callable(self, "_on_canvas_layers_changed")
	if (
		_edited_canvas != null
		and is_instance_valid(_edited_canvas)
		and _edited_canvas.is_connected(&"layers_changed", callback)
	):
		_edited_canvas.disconnect(&"layers_changed", callback)
	_edited_canvas = canvas
	if (
		_edited_canvas != null
		and is_instance_valid(_edited_canvas)
		and not _edited_canvas.is_connected(&"layers_changed", callback)
	):
		_edited_canvas.connect(&"layers_changed", callback)

func _refresh_layer_controls() -> void:
	if _dock == null:
		return
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		_dock.set_layer_summaries([], "")
		return
	if not bool(_edited_canvas.call("has_layer", _active_layer_id)):
		_active_layer_id = BASE_LAYER_ID
	var summaries: Array[Dictionary] = []
	for summary_variant in _edited_canvas.call("get_layer_summaries") as Array:
		summaries.append(summary_variant as Dictionary)
	_dock.set_layer_summaries(summaries, _active_layer_id)

func _on_canvas_layers_changed() -> void:
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		return
	if _stroke_active and not bool(_edited_canvas.call("has_layer", _stroke_layer_id)):
		_cancel_stroke()
	if not bool(_edited_canvas.call("has_layer", _active_layer_id)):
		_active_layer_id = BASE_LAYER_ID
	_refresh_layer_controls()
	update_overlays()

func _on_layer_selected(layer_id: String) -> void:
	if _edited_canvas == null or not bool(_edited_canvas.call("has_layer", layer_id)):
		return
	_finish_stroke()
	_active_layer_id = layer_id
	_refresh_layer_controls()
	update_overlays()

func _on_layer_add_requested() -> void:
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		return
	_finish_stroke()
	# get_layer_count() includes Base, so its current value is the ordinal of
	# the next additional layer (Base only -> Shadow 1).
	var layer_number := int(_edited_canvas.call("get_layer_count"))
	var layer := _edited_canvas.call(
		"create_shadow_layer",
		"Shadow %d" % layer_number,
		-1024,
		0
	) as Resource
	if layer == null:
		return
	var layer_id := String(layer.get("layer_id"))
	var insertion_index := int(_edited_canvas.call("get_layer_count"))
	_active_layer_id = layer_id
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Add painted shadow layer", UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"insert_shadow_layer", layer, insertion_index)
	undo_redo.add_undo_method(_edited_canvas, &"remove_shadow_layer", layer_id)
	undo_redo.commit_action()

func _on_layer_remove_requested(layer_id: String) -> void:
	if _edited_canvas == null or layer_id == BASE_LAYER_ID:
		return
	_finish_stroke()
	var layer := _edited_canvas.call("get_shadow_layer_resource", layer_id) as Resource
	var layer_index := int(_edited_canvas.call("get_layer_index", layer_id))
	if layer == null or layer_index <= 0:
		return
	if _active_layer_id == layer_id:
		_active_layer_id = BASE_LAYER_ID
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Remove painted shadow layer", UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"remove_shadow_layer", layer_id)
	undo_redo.add_undo_method(_edited_canvas, &"insert_shadow_layer", layer, layer_index)
	undo_redo.commit_action()

func _on_layer_name_changed(layer_id: String, display_name: String) -> void:
	if _edited_canvas == null:
		return
	_finish_stroke()
	var old_name := String(_edited_canvas.call("get_layer_name", layer_id))
	if old_name == display_name:
		return
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Rename painted shadow layer", UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"set_layer_name", layer_id, display_name)
	undo_redo.add_undo_method(_edited_canvas, &"set_layer_name", layer_id, old_name)
	undo_redo.commit_action()

func _on_layer_enabled_changed(layer_id: String, enabled: bool) -> void:
	if _edited_canvas == null:
		return
	_finish_stroke()
	var old_enabled := bool(_edited_canvas.call("is_layer_enabled", layer_id))
	if old_enabled == enabled:
		return
	if not enabled and _dock != null:
		_dock.set_paint_mode_enabled(false)
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Toggle painted shadow layer", UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"set_layer_enabled", layer_id, enabled)
	undo_redo.add_undo_method(_edited_canvas, &"set_layer_enabled", layer_id, old_enabled)
	undo_redo.commit_action()

func _on_layer_z_range_changed(layer_id: String, z_min: int, z_max: int) -> void:
	if _edited_canvas == null:
		return
	_finish_stroke()
	var old_range := _edited_canvas.call("get_layer_z_range", layer_id) as Vector2i
	var new_range := Vector2i(mini(z_min, z_max), maxi(z_min, z_max))
	if old_range == new_range:
		return
	var undo_redo := get_undo_redo()
	# Layer selection itself is not an Undo action. MERGE_ENDS would therefore
	# merge consecutive edits of different layers under this shared action name,
	# keeping the first layer's undo and the second layer's redo. Keep each
	# committed Z change independent and correct.
	undo_redo.create_action("Set painted shadow layer Z", UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"set_layer_z_range", layer_id, new_range.x, new_range.y)
	undo_redo.add_undo_method(_edited_canvas, &"set_layer_z_range", layer_id, old_range.x, old_range.y)
	undo_redo.commit_action()

func _on_settings_changed() -> void:
	update_overlays()

func _on_paint_mode_changed(enabled: bool) -> void:
	if not enabled:
		_finish_stroke()
		_cursor_visible = false
	update_overlays()

func _on_clear_requested() -> void:
	_apply_full_mask_action("Clear painted shadow layer", 0.0)

func _on_fill_requested() -> void:
	_apply_full_mask_action("Fill painted shadow layer", 1.0)
