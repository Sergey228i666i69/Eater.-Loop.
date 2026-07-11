@tool
extends VBoxContainer

signal settings_changed
signal paint_mode_changed(enabled: bool)
signal clear_requested
signal fill_requested
signal layer_selected(layer_id: String)
signal layer_add_requested
signal layer_remove_requested(layer_id: String)
signal layer_name_changed(layer_id: String, display_name: String)
signal layer_enabled_changed(layer_id: String, enabled: bool)
signal layer_z_range_changed(layer_id: String, z_min: int, z_max: int)

enum BrushPreset {
	SOFT_ROUND,
	HARD_ROUND,
	AIRBRUSH,
	CUSTOM,
}

enum PaintMode {
	DARKEN,
	ERASE,
}

var _paint_toggle: Button = null
var _layer_option: OptionButton = null
var _layer_add_button: Button = null
var _layer_remove_button: Button = null
var _layer_name_edit: LineEdit = null
var _layer_enabled_check: CheckBox = null
var _layer_z_min_spin: SpinBox = null
var _layer_z_max_spin: SpinBox = null
var _preset_option: OptionButton = null
var _mode_option: OptionButton = null
var _size_spin: SpinBox = null
var _strength_spin: SpinBox = null
var _softness_spin: SpinBox = null
var _spacing_spin: SpinBox = null
var _clear_button: Button = null
var _fill_button: Button = null
var _status_label: Label = null
var _applying_preset := false
var _target_available := false
var _updating_layer_controls := false
var _layer_summaries: Array[Dictionary] = []

func _ready() -> void:
	_build_ui()
	_apply_preset(BrushPreset.SOFT_ROUND)
	set_target_available(false)

func is_paint_mode_enabled() -> bool:
	return _paint_toggle != null and _paint_toggle.button_pressed

func is_erase_mode() -> bool:
	return _mode_option != null and _mode_option.selected == PaintMode.ERASE

func get_brush_size() -> float:
	return float(_size_spin.value) if _size_spin != null else 128.0

func get_brush_strength() -> float:
	return float(_strength_spin.value) * 0.01 if _strength_spin != null else 0.35

func get_brush_softness() -> float:
	return float(_softness_spin.value) * 0.01 if _softness_spin != null else 0.85

func get_brush_spacing() -> float:
	return float(_spacing_spin.value) * 0.01 if _spacing_spin != null else 0.18

func set_erase_mode(enabled: bool) -> void:
	if _mode_option == null:
		return
	_mode_option.select(PaintMode.ERASE if enabled else PaintMode.DARKEN)
	settings_changed.emit()

func adjust_brush_size(scale_factor: float) -> void:
	if _size_spin == null:
		return
	_size_spin.value = clampf(_size_spin.value * scale_factor, _size_spin.min_value, _size_spin.max_value)

func get_selected_layer_id() -> String:
	if _layer_option == null or _layer_option.selected < 0:
		return ""
	return String(_layer_option.get_item_metadata(_layer_option.selected))

func set_layer_summaries(summaries: Array, active_layer_id: String) -> void:
	if _layer_option == null:
		return
	_updating_layer_controls = true
	_layer_summaries.clear()
	for summary_variant in summaries:
		if summary_variant is Dictionary:
			_layer_summaries.append((summary_variant as Dictionary).duplicate(true))
	_layer_option.clear()
	var selected_index := -1
	for index in range(_layer_summaries.size()):
		var summary := _layer_summaries[index]
		var display_name := String(summary.get("name", "Shadow"))
		var layer_id := String(summary.get("id", ""))
		_layer_option.add_item(display_name)
		_layer_option.set_item_metadata(index, layer_id)
		_layer_option.set_item_tooltip(index, "%s · affects final Z %d…%d" % [
			display_name,
			int(summary.get("z_min", -1024)),
			int(summary.get("z_max", 1024)),
		])
		if layer_id == active_layer_id:
			selected_index = index
	if selected_index < 0 and not _layer_summaries.is_empty():
		selected_index = 0
	if selected_index >= 0:
		_layer_option.select(selected_index)
	_apply_selected_layer_summary()
	_updating_layer_controls = false
	_update_target_controls()

func set_paint_mode_enabled(enabled: bool) -> void:
	if _paint_toggle == null:
		return
	_paint_toggle.button_pressed = enabled and not _paint_toggle.disabled

func set_target_available(available: bool) -> void:
	if _paint_toggle == null:
		return
	_target_available = available
	if not available:
		_paint_toggle.set_pressed_no_signal(false)
	_update_target_controls()
	_update_status()

func _build_ui() -> void:
	custom_minimum_size = Vector2(280.0, 0.0)

	var title := Label.new()
	title.text = "Painted Shadow Canvas 2D"
	title.add_theme_font_size_override("font_size", 17)
	add_child(title)

	var explanation := Label.new()
	explanation.text = "Paints subtractive 2D light. Lamps and the flashlight naturally illuminate it."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.82, 0.86, 0.92)
	add_child(explanation)

	add_child(HSeparator.new())
	_build_layer_ui()
	add_child(HSeparator.new())

	_paint_toggle = Button.new()
	_paint_toggle.text = "Paint in 2D View"
	_paint_toggle.toggle_mode = true
	_paint_toggle.tooltip_text = "When enabled, left-drag paints the selected canvas. Esc cancels the current stroke."
	_paint_toggle.toggled.connect(func(enabled: bool) -> void:
		_update_status()
		paint_mode_changed.emit(enabled)
	)
	add_child(_paint_toggle)

	_preset_option = _add_option_row("Brush", ["Soft Round", "Hard Round", "Airbrush", "Custom"])
	_preset_option.item_selected.connect(func(index: int) -> void:
		_apply_preset(index)
	)

	_mode_option = _add_option_row("Mode", ["Darken (B)", "Erase (E)"])
	_mode_option.item_selected.connect(func(_index: int) -> void:
		settings_changed.emit()
	)

	_size_spin = _add_spin_row("Size", 4.0, 1024.0, 1.0, 128.0, " units")
	_strength_spin = _add_spin_row("Intensity", 1.0, 100.0, 1.0, 35.0, " %")
	_softness_spin = _add_spin_row("Softness", 0.0, 100.0, 1.0, 85.0, " %")
	_spacing_spin = _add_spin_row("Spacing", 1.0, 100.0, 1.0, 18.0, " %")

	for spin in [_size_spin, _strength_spin, _softness_spin, _spacing_spin]:
		spin.value_changed.connect(func(_value: float) -> void:
			_on_numeric_setting_changed()
		)

	var action_row := HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(action_row)

	_clear_button = Button.new()
	_clear_button.text = "Clear"
	_clear_button.tooltip_text = "Clear the selected layer mask. This action is undoable."
	_clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear_button.pressed.connect(func() -> void:
		clear_requested.emit()
	)
	action_row.add_child(_clear_button)

	_fill_button = Button.new()
	_fill_button.text = "Fill"
	_fill_button.tooltip_text = "Fill the selected layer mask with darkness. This action is undoable."
	_fill_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_button.pressed.connect(func() -> void:
		fill_requested.emit()
	)
	action_row.add_child(_fill_button)

	add_child(HSeparator.new())
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.modulate = Color(0.72, 0.78, 0.86)
	add_child(_status_label)

	var shortcut_label := Label.new()
	shortcut_label.text = "Shortcuts: B darken · E erase · [ / ] size · Esc cancel stroke"
	shortcut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shortcut_label.modulate = Color(0.62, 0.68, 0.76)
	add_child(shortcut_label)

func _build_layer_ui() -> void:
	var selection_row := HBoxContainer.new()
	selection_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(selection_row)

	var layer_label := Label.new()
	layer_label.text = "Layer"
	layer_label.custom_minimum_size.x = 88.0
	selection_row.add_child(layer_label)

	_layer_option = OptionButton.new()
	_layer_option.fit_to_longest_item = false
	_layer_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layer_option.item_selected.connect(_on_layer_selected)
	selection_row.add_child(_layer_option)

	_layer_add_button = Button.new()
	_layer_add_button.text = "+"
	_layer_add_button.tooltip_text = "Add a blank painted-shadow layer."
	_layer_add_button.pressed.connect(func() -> void:
		layer_add_requested.emit()
	)
	selection_row.add_child(_layer_add_button)

	_layer_remove_button = Button.new()
	_layer_remove_button.text = "−"
	_layer_remove_button.tooltip_text = "Remove the selected layer. The Base layer cannot be removed."
	_layer_remove_button.pressed.connect(func() -> void:
		var layer_id := get_selected_layer_id()
		if not layer_id.is_empty():
			layer_remove_requested.emit(layer_id)
	)
	selection_row.add_child(_layer_remove_button)

	var name_row := HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Name"
	name_label.custom_minimum_size.x = 88.0
	name_row.add_child(name_label)
	_layer_name_edit = LineEdit.new()
	_layer_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layer_name_edit.placeholder_text = "Shadow layer"
	_layer_name_edit.text_submitted.connect(func(_value: String) -> void:
		_emit_layer_name_if_changed()
	)
	_layer_name_edit.focus_exited.connect(_emit_layer_name_if_changed)
	name_row.add_child(_layer_name_edit)
	_layer_enabled_check = CheckBox.new()
	_layer_enabled_check.text = "Visible"
	_layer_enabled_check.tooltip_text = "Enable this layer's subtractive light. Hidden layers cannot be painted."
	_layer_enabled_check.toggled.connect(func(enabled: bool) -> void:
		if _updating_layer_controls:
			return
		var layer_id := get_selected_layer_id()
		if not layer_id.is_empty():
			layer_enabled_changed.emit(layer_id, enabled)
	)
	name_row.add_child(_layer_enabled_check)

	var z_row := HBoxContainer.new()
	z_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(z_row)
	var z_label := Label.new()
	z_label.text = "Affects Z"
	z_label.custom_minimum_size.x = 88.0
	z_label.tooltip_text = "Final CanvasItem Z values affected by this layer. Set Min = Max for one exact Z."
	z_row.add_child(z_label)
	_layer_z_min_spin = _create_integer_spin(-4096, 4096)
	_layer_z_min_spin.tooltip_text = "Minimum final Z affected by this shadow layer."
	_layer_z_min_spin.value_changed.connect(func(_value: float) -> void:
		_on_layer_z_changed(true)
	)
	z_row.add_child(_layer_z_min_spin)
	var z_to_label := Label.new()
	z_to_label.text = "to"
	z_row.add_child(z_to_label)
	_layer_z_max_spin = _create_integer_spin(-4096, 4096)
	_layer_z_max_spin.tooltip_text = "Maximum final Z affected. For a shadow behind an object at Z 7, use Max 6."
	_layer_z_max_spin.value_changed.connect(func(_value: float) -> void:
		_on_layer_z_changed(false)
	)
	z_row.add_child(_layer_z_max_spin)

func _update_status() -> void:
	if _status_label == null:
		return
	if not _target_available:
		_status_label.text = "Select a PaintedShadowCanvas2D node."
	elif not _is_selected_layer_enabled():
		_status_label.text = "The selected layer is hidden. Enable Visible before painting."
	elif is_paint_mode_enabled():
		_status_label.text = "Paint active: left-drag inside the blue bounds. Space or middle-drag pans; wheel zooms."
	else:
		_status_label.text = "Enable Paint, then draw inside the blue bounds in the 2D viewport."

func _on_layer_selected(index: int) -> void:
	if _updating_layer_controls or index < 0 or index >= _layer_summaries.size():
		return
	_updating_layer_controls = true
	_apply_selected_layer_summary()
	_updating_layer_controls = false
	_update_target_controls()
	var layer_id := get_selected_layer_id()
	if not layer_id.is_empty():
		layer_selected.emit(layer_id)

func _apply_selected_layer_summary() -> void:
	var index := _layer_option.selected if _layer_option != null else -1
	if index < 0 or index >= _layer_summaries.size():
		if _layer_name_edit != null:
			_layer_name_edit.text = ""
		return
	var summary := _layer_summaries[index]
	_layer_name_edit.text = String(summary.get("name", "Shadow"))
	_layer_enabled_check.button_pressed = bool(summary.get("enabled", true))
	_layer_z_min_spin.value = int(summary.get("z_min", -1024))
	_layer_z_max_spin.value = int(summary.get("z_max", 1024))
	_layer_remove_button.disabled = not bool(summary.get("removable", false))

func _emit_layer_name_if_changed() -> void:
	if _updating_layer_controls or _layer_name_edit == null:
		return
	var index := _layer_option.selected
	if index < 0 or index >= _layer_summaries.size():
		return
	var current_name := String(_layer_summaries[index].get("name", "Shadow"))
	var requested_name := _layer_name_edit.text.strip_edges()
	if requested_name.is_empty():
		requested_name = "Base" if get_selected_layer_id() == "base" else "Shadow"
	if requested_name == current_name:
		return
	layer_name_changed.emit(get_selected_layer_id(), requested_name)

func _on_layer_z_changed(changed_minimum: bool) -> void:
	if _updating_layer_controls:
		return
	_updating_layer_controls = true
	var z_min := int(_layer_z_min_spin.value)
	var z_max := int(_layer_z_max_spin.value)
	if z_min > z_max:
		if changed_minimum:
			z_max = z_min
			_layer_z_max_spin.value = z_max
		else:
			z_min = z_max
			_layer_z_min_spin.value = z_min
	_updating_layer_controls = false
	var layer_id := get_selected_layer_id()
	if not layer_id.is_empty():
		layer_z_range_changed.emit(layer_id, z_min, z_max)

func _is_selected_layer_enabled() -> bool:
	var index := _layer_option.selected if _layer_option != null else -1
	return (
		index >= 0
		and index < _layer_summaries.size()
		and bool(_layer_summaries[index].get("enabled", false))
	)

func _update_target_controls() -> void:
	if _paint_toggle == null:
		return
	var has_layer := _target_available and not _layer_summaries.is_empty()
	var can_paint_layer := has_layer and _is_selected_layer_enabled()
	_paint_toggle.disabled = not can_paint_layer
	_clear_button.disabled = not can_paint_layer
	_fill_button.disabled = not can_paint_layer
	if not can_paint_layer:
		_paint_toggle.set_pressed_no_signal(false)
	_layer_option.disabled = not _target_available
	_layer_add_button.disabled = not _target_available
	if not has_layer:
		_layer_remove_button.disabled = true
	_layer_name_edit.editable = has_layer
	_layer_enabled_check.disabled = not has_layer
	_layer_z_min_spin.editable = has_layer
	_layer_z_max_spin.editable = has_layer
	_update_status()

func _create_integer_spin(min_value: int, max_value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1.0
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin

func _add_option_row(label_text: String, items: Array[String]) -> OptionButton:
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 88.0
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		option.add_item(item)
	row.add_child(option)
	return option

func _add_spin_row(
	label_text: String,
	min_value: float,
	max_value: float,
	step: float,
	default_value: float,
	suffix: String
) -> SpinBox:
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 88.0
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = default_value
	spin.suffix = suffix
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spin)
	return spin

func _apply_preset(index: int) -> void:
	if _preset_option == null or _size_spin == null:
		return
	_preset_option.select(index)
	if index == BrushPreset.CUSTOM:
		settings_changed.emit()
		return
	_applying_preset = true
	match index:
		BrushPreset.HARD_ROUND:
			_size_spin.value = 96.0
			_strength_spin.value = 75.0
			_softness_spin.value = 8.0
			_spacing_spin.value = 20.0
		BrushPreset.AIRBRUSH:
			_size_spin.value = 180.0
			_strength_spin.value = 12.0
			_softness_spin.value = 78.0
			_spacing_spin.value = 7.0
		_:
			_size_spin.value = 128.0
			_strength_spin.value = 35.0
			_softness_spin.value = 85.0
			_spacing_spin.value = 18.0
	_applying_preset = false
	settings_changed.emit()

func _on_numeric_setting_changed() -> void:
	if not _applying_preset and _preset_option != null:
		_preset_option.select(BrushPreset.CUSTOM)
	settings_changed.emit()
