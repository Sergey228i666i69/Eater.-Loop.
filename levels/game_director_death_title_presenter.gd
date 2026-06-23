extends RefCounted

const DEATH_TITLE_GLITCH_SHADER: Shader = preload("res://shaders/death_text_glitch.gdshader")
const DEATH_TITLE_PENANCE_LINE := "Никогда не заслужу прощения."
const DEATH_TITLE_PENANCE_TEXT := "Никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения, никогда, никогда, никогда, никогда не заслужу прощения"
const DEATH_TITLE_SEQUENCE: Array[String] = [
	"Ошибся",
	"Напортачил",
	"Оплошал",
	"Накосячил",
	"Провинился",
	"Облажался",
	"Согрешил",
	DEATH_TITLE_PENANCE_TEXT,
]
const DEATH_GLITCH_BACKGROUND_LAYOUT := [
	{"anchor": Vector2(0.06, 0.08), "offset": Vector2(-280.0, -120.0), "width": 860.0, "font_size": 70, "rotation": -0.22, "scale": Vector2(1.26, 1.26), "alpha": 0.2, "strength": 0.82},
	{"anchor": Vector2(0.48, 0.03), "offset": Vector2(-140.0, -160.0), "width": 940.0, "font_size": 78, "rotation": 0.12, "scale": Vector2(1.38, 1.38), "alpha": 0.15, "strength": 0.72},
	{"anchor": Vector2(0.88, 0.1), "offset": Vector2(-110.0, -90.0), "width": 760.0, "font_size": 62, "rotation": 0.2, "scale": Vector2(1.14, 1.14), "alpha": 0.22, "strength": 0.88},
	{"anchor": Vector2(0.0, 0.48), "offset": Vector2(-320.0, -60.0), "width": 980.0, "font_size": 74, "rotation": -0.08, "scale": Vector2(1.32, 1.32), "alpha": 0.17, "strength": 0.78},
	{"anchor": Vector2(0.8, 0.44), "offset": Vector2(60.0, -20.0), "width": 900.0, "font_size": 68, "rotation": -0.18, "scale": Vector2(1.18, 1.18), "alpha": 0.18, "strength": 0.8},
	{"anchor": Vector2(0.12, 0.78), "offset": Vector2(-200.0, 10.0), "width": 840.0, "font_size": 64, "rotation": 0.18, "scale": Vector2(1.22, 1.22), "alpha": 0.18, "strength": 0.86},
	{"anchor": Vector2(0.54, 0.82), "offset": Vector2(-60.0, 20.0), "width": 980.0, "font_size": 76, "rotation": -0.12, "scale": Vector2(1.42, 1.42), "alpha": 0.14, "strength": 0.74},
	{"anchor": Vector2(0.9, 0.92), "offset": Vector2(-40.0, 60.0), "width": 740.0, "font_size": 60, "rotation": 0.26, "scale": Vector2(1.1, 1.1), "alpha": 0.2, "strength": 0.9},
]

var _owner: Node
var _title_label: Label
var _glitch_background: Control
var _title_readable_glitch_material: ShaderMaterial
var _title_sequence_index: int = 0


func _init(owner: Node, title_label: Label, glitch_background: Control) -> void:
	_owner = owner
	_title_label = title_label
	_glitch_background = glitch_background
	_title_readable_glitch_material = _build_death_glitch_material(0.38, 0.028, 0.008, 0.12, 6.5, Color(1.0, 0.9, 0.9, 1.0))


func apply_next_title(default_title: String) -> void:
	if _title_sequence_index < DEATH_TITLE_SEQUENCE.size():
		var next_index := _title_sequence_index
		_title_sequence_index += 1
		var is_glitch_title := next_index == DEATH_TITLE_SEQUENCE.size() - 1
		apply_title(DEATH_TITLE_SEQUENCE[next_index], is_glitch_title)
		return
	apply_title(default_title, false)


func apply_title(text: String, glitchy: bool) -> void:
	if _title_label == null:
		return
	_update_title_layout(glitchy)
	_title_label.text = _get_readable_death_glitch_text(text) if glitchy else text
	_title_label.rotation = 0.0
	_title_label.scale = Vector2.ONE
	_title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_title_label.remove_theme_color_override("font_color")
	_title_label.remove_theme_color_override("font_shadow_color")
	_title_label.remove_theme_constant_override("shadow_offset_x")
	_title_label.remove_theme_constant_override("shadow_offset_y")
	if glitchy:
		_title_label.add_theme_font_size_override("font_size", 58)
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9, 1.0))
		_title_label.add_theme_color_override("font_shadow_color", Color(0.32, 0.0, 0.0, 0.92))
		_title_label.add_theme_constant_override("shadow_offset_x", 3)
		_title_label.add_theme_constant_override("shadow_offset_y", 3)
		_title_label.material = _title_readable_glitch_material
		_show_glitch_background(text)
	else:
		_title_label.add_theme_font_size_override("font_size", 112)
		_title_label.material = null
		if _glitch_background:
			_glitch_background.visible = false


func _update_title_layout(glitchy: bool = false) -> void:
	if _title_label == null:
		return
	var title_width := 1280.0
	if _owner != null and _owner.get_viewport():
		var visible_size := _owner.get_viewport().get_visible_rect().size
		var width_ratio := 0.92 if glitchy else 0.82
		var min_width := 860.0 if glitchy else 620.0
		title_width = maxf(min_width, visible_size.x * width_ratio)
	_title_label.custom_minimum_size = Vector2(title_width, 0.0)


func _get_readable_death_glitch_text(text: String) -> String:
	if text == DEATH_TITLE_PENANCE_TEXT:
		return "%s\n%s" % [DEATH_TITLE_PENANCE_LINE, DEATH_TITLE_PENANCE_LINE]
	return text


func _show_glitch_background(text: String) -> void:
	if _glitch_background == null:
		return
	var viewport_size := Vector2(1920.0, 1080.0)
	if _owner != null and _owner.get_viewport():
		viewport_size = _owner.get_viewport().get_visible_rect().size
	var background_text := _build_glitch_background_text(text)
	for child in _glitch_background.get_children():
		child.free()
	for layout_variant in DEATH_GLITCH_BACKGROUND_LAYOUT:
		if not (layout_variant is Dictionary):
			continue
		var layout := layout_variant as Dictionary
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = background_text
		label.add_theme_font_size_override("font_size", int(layout.get("font_size", 64)))
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.86, float(layout.get("alpha", 0.18))))
		label.add_theme_color_override("font_shadow_color", Color(0.25, 0.0, 0.0, minf(0.95, float(layout.get("alpha", 0.18)) + 0.16)))
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 3)
		label.rotation = float(layout.get("rotation", 0.0))
		var scale_value: Variant = layout.get("scale", Vector2.ONE)
		if scale_value is Vector2:
			label.scale = scale_value
		var anchor_value: Variant = layout.get("anchor", Vector2.ZERO)
		var offset_value: Variant = layout.get("offset", Vector2.ZERO)
		var anchor := Vector2.ZERO
		if anchor_value is Vector2:
			anchor = anchor_value
		var offset := Vector2.ZERO
		if offset_value is Vector2:
			offset = offset_value
		var width := float(layout.get("width", viewport_size.x * 0.45))
		label.position = Vector2(viewport_size.x * anchor.x, viewport_size.y * anchor.y) + offset
		label.custom_minimum_size = Vector2(width, 0.0)
		var alpha := float(layout.get("alpha", 0.18))
		var strength := float(layout.get("strength", 0.8))
		label.material = _build_death_glitch_material(strength, 0.065, 0.018, 0.32, 12.0, Color(1.0, 0.8, 0.8, alpha))
		_glitch_background.add_child(label)
	_glitch_background.visible = true


func _build_glitch_background_text(text: String) -> String:
	var compact := text.replace("\n", " ").strip_edges()
	if compact == "":
		compact = DEATH_TITLE_PENANCE_LINE
	if compact == DEATH_TITLE_PENANCE_TEXT:
		return DEATH_TITLE_PENANCE_TEXT
	return ("%s %s %s" % [compact, compact, compact]).strip_edges()


func _build_death_glitch_material(glitch_strength: float, line_jitter: float, chroma_shift: float, scanline_strength: float, flicker_speed: float, tint: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = DEATH_TITLE_GLITCH_SHADER
	material.set_shader_parameter("glitch_strength", glitch_strength)
	material.set_shader_parameter("line_jitter", line_jitter)
	material.set_shader_parameter("chroma_shift", chroma_shift)
	material.set_shader_parameter("scanline_strength", scanline_strength)
	material.set_shader_parameter("flicker_speed", flicker_speed)
	material.set_shader_parameter("tint", tint)
	return material
