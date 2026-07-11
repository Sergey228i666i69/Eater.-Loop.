@tool
extends EditorPlugin

const CanvasScript = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_canvas_2d.gd")
const DockScript = preload("res://addons/painted_shadow_canvas/editor/painted_shadow_dock.gd")
const StrokeSampler = preload("res://addons/painted_shadow_canvas/runtime/painted_shadow_stroke_sampler.gd")
const ICON_PATH := "res://addons/painted_shadow_canvas/icon.svg"

var _dock: VBoxContainer = null
var _editor_dock: EditorDock = null
var _edited_canvas: Node2D = null
var _stroke_active := false
var _stroke_changed := false
var _stroke_before := PackedByteArray()
var _stroke_sampler: RefCounted = StrokeSampler.new()
var _cursor_local_position := Vector2.ZERO
var _cursor_visible := false

func _enter_tree() -> void:
	var icon_texture := load(ICON_PATH) as Texture2D
	add_custom_type("PaintedShadowCanvas2D", "Node2D", CanvasScript, icon_texture)
	_dock = DockScript.new()
	_dock.name = "Painted Shadow"
	_dock.settings_changed.connect(_on_settings_changed)
	_dock.paint_mode_changed.connect(_on_paint_mode_changed)
	_dock.clear_requested.connect(_on_clear_requested)
	_dock.fill_requested.connect(_on_fill_requested)
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
	_edited_canvas = null

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
	_edited_canvas = null
	_cursor_visible = false
	if _dock != null:
		_dock.set_target_available(false)
	update_overlays()

func _apply_changes() -> void:
	_finish_stroke()

func _edit(object: Object) -> void:
	_finish_stroke()
	_edited_canvas = object as Node2D if _handles(object) else null
	_cursor_visible = false
	if _dock != null:
		_dock.set_target_available(_edited_canvas != null)
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
		if (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0 or Input.is_key_pressed(KEY_SPACE):
			if _stroke_active:
				_finish_stroke()
			update_overlays()
			return false
		if _stroke_active and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_paint_to(_cursor_local_position)
			update_overlays()
			return true
		if _stroke_active:
			# The mouse may have been released outside the 2D viewport, in which
			# case no MouseButton release reaches this plugin.
			_finish_stroke()
		update_overlays()
		return false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Input.is_key_pressed(KEY_SPACE):
			return false
		var local_position := _screen_to_local(event.position)
		_cursor_local_position = local_position
		_cursor_visible = true
		if event.pressed:
			if not get_canvas_rect().has_point(local_position):
				return false
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
	var canvas_transform: Transform2D = _edited_canvas.get_global_transform_with_canvas()
	var rect: Rect2 = get_canvas_rect()
	var bounds := PackedVector2Array([
		canvas_transform * rect.position,
		canvas_transform * Vector2(rect.end.x, rect.position.y),
		canvas_transform * rect.end,
		canvas_transform * Vector2(rect.position.x, rect.end.y),
		canvas_transform * rect.position,
	])
	overlay.draw_polyline(bounds, Color(0.4, 0.72, 1.0, 0.95), 2.0, true)

	if not _can_paint() or not _cursor_visible:
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
		and _dock.is_paint_mode_enabled()
	)

func _screen_to_local(screen_position: Vector2) -> Vector2:
	return _edited_canvas.make_canvas_position_local(screen_position)

func _begin_stroke(local_position: Vector2) -> void:
	if _stroke_active:
		_finish_stroke()
	_stroke_before = _edited_canvas.call("capture_mask_snapshot") as PackedByteArray
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
		"paint_points",
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
	var after := _edited_canvas.call("capture_mask_snapshot") as PackedByteArray
	if _stroke_changed and after != _stroke_before:
		_commit_snapshot_action("Paint shadow stroke", _stroke_before, after)
	else:
		_edited_canvas.call("apply_mask_snapshot", _stroke_before)
	_stroke_before = PackedByteArray()
	_stroke_changed = false

func _cancel_stroke() -> void:
	if not _stroke_active:
		return
	_stroke_active = false
	if _edited_canvas != null and is_instance_valid(_edited_canvas):
		_edited_canvas.call("apply_mask_snapshot", _stroke_before)
	_stroke_sampler.call("cancel")
	_stroke_before = PackedByteArray()
	_stroke_changed = false
	update_overlays()

func _commit_snapshot_action(action_name: String, before: PackedByteArray, after: PackedByteArray) -> void:
	var undo_redo := get_undo_redo()
	undo_redo.create_action(action_name, UndoRedo.MERGE_DISABLE, _edited_canvas)
	undo_redo.add_do_method(_edited_canvas, &"apply_mask_snapshot", after)
	undo_redo.add_undo_method(_edited_canvas, &"apply_mask_snapshot", before)
	undo_redo.commit_action()

func _apply_full_mask_action(action_name: String, value: float) -> void:
	if _edited_canvas == null or not is_instance_valid(_edited_canvas):
		return
	_finish_stroke()
	var before := _edited_canvas.call("capture_mask_snapshot") as PackedByteArray
	_edited_canvas.call("fill_mask", value)
	var after := _edited_canvas.call("capture_mask_snapshot") as PackedByteArray
	if after == before:
		return
	_commit_snapshot_action(action_name, before, after)
	update_overlays()

func _on_settings_changed() -> void:
	update_overlays()

func _on_paint_mode_changed(enabled: bool) -> void:
	if not enabled:
		_finish_stroke()
		_cursor_visible = false
	update_overlays()

func _on_clear_requested() -> void:
	_apply_full_mask_action("Clear painted shadow", 0.0)

func _on_fill_requested() -> void:
	_apply_full_mask_action("Fill painted shadow", 1.0)
