@tool
extends VBoxContainer

signal settings_changed
signal paint_mode_changed(enabled: bool)
signal clear_requested
signal fill_requested

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

func set_target_available(available: bool) -> void:
	if _paint_toggle == null:
		return
	_target_available = available
	_paint_toggle.disabled = not available
	_clear_button.disabled = not available
	_fill_button.disabled = not available
	if not available:
		_paint_toggle.set_pressed_no_signal(false)
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
	_clear_button.tooltip_text = "Remove the complete mask. This action is undoable."
	_clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear_button.pressed.connect(func() -> void:
		clear_requested.emit()
	)
	action_row.add_child(_clear_button)

	_fill_button = Button.new()
	_fill_button.text = "Fill"
	_fill_button.tooltip_text = "Fill the complete mask with darkness. This action is undoable."
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

func _update_status() -> void:
	if _status_label == null:
		return
	if not _target_available:
		_status_label.text = "Select a PaintedShadowCanvas2D node."
	elif is_paint_mode_enabled():
		_status_label.text = "Paint active: left-drag inside the blue bounds. Space or middle-drag pans; wheel zooms."
	else:
		_status_label.text = "Enable Paint, then draw inside the blue bounds in the 2D viewport."

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
