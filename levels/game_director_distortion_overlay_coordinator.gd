extends RefCounted

const PARAM_INTENSITY := "intensity"
const PARAM_SQUASH := "squash_amount"
const PARAM_DESATURATION := "desaturation"
const PARAM_SHAKE_POWER := "shake_power"
const PARAM_COLOR_BLEEDING := "color_bleeding"
const PARAM_GLITCH_LINES := "glitch_lines"
const PARAM_VIGNETTE_INTENSITY := "vignette_intensity"
const PARAM_NOISE_SPEED := "noise_speed"
const PARAM_GLITCH_AMOUNT := "glitch_amount"
const TWEEN_LIGHT_INTENSITY_PROPERTY := "shader_parameter/intensity"

var _distortion_rect: ColorRect
var _distortion_material: ShaderMaterial
var _transition_rect: ColorRect
var _transition_material: ShaderMaterial
var _damage_rect: ColorRect
var _damage_material: ShaderMaterial
var _light_only_jump_rect: ColorRect
var _light_only_jump_material: ShaderMaterial

func bind_overlays(
	distortion_rect: ColorRect,
	distortion_material: ShaderMaterial,
	transition_rect: ColorRect,
	transition_material: ShaderMaterial,
	damage_rect: ColorRect,
	damage_material: ShaderMaterial,
	light_only_jump_rect: ColorRect,
	light_only_jump_material: ShaderMaterial
) -> void:
	_distortion_rect = distortion_rect
	_distortion_material = distortion_material
	_transition_rect = transition_rect
	_transition_material = transition_material
	_damage_rect = damage_rect
	_damage_material = damage_material
	_light_only_jump_rect = light_only_jump_rect
	_light_only_jump_material = light_only_jump_material

func has_distortion_overlay() -> bool:
	return _is_valid_rect(_distortion_rect) and _is_valid_material(_distortion_material)

func has_damage_overlay() -> bool:
	return _is_valid_rect(_damage_rect) and _is_valid_material(_damage_material)

func has_light_only_jump_overlay() -> bool:
	return _is_valid_rect(_light_only_jump_rect) and _is_valid_material(_light_only_jump_material)

func is_distortion_visible() -> bool:
	return _is_valid_rect(_distortion_rect) and _distortion_rect.visible

func set_distortion_visible(value: bool) -> void:
	if _is_valid_rect(_distortion_rect):
		_distortion_rect.visible = value

func set_transition_visible(value: bool) -> void:
	if _is_valid_rect(_transition_rect):
		_transition_rect.visible = value

func set_damage_visible(value: bool) -> void:
	if _is_valid_rect(_damage_rect):
		_damage_rect.visible = value

func set_light_only_jump_visible(value: bool) -> void:
	if _is_valid_rect(_light_only_jump_rect):
		_light_only_jump_rect.visible = value

func set_distortion_intensity(value: float) -> void:
	_set_shader_parameter(_distortion_material, PARAM_INTENSITY, value)

func set_distortion_squash(value: float) -> void:
	_set_shader_parameter(_distortion_material, PARAM_SQUASH, value)

func set_transition_intensity(value: float) -> void:
	_set_shader_parameter(_transition_material, PARAM_INTENSITY, value)

func set_transition_squash(value: float) -> void:
	_set_shader_parameter(_transition_material, PARAM_SQUASH, value)

func set_damage_intensity(value: float) -> void:
	_set_shader_parameter(_damage_material, PARAM_INTENSITY, value)

func set_light_only_jump_intensity(value: float) -> void:
	_set_shader_parameter(_light_only_jump_material, PARAM_INTENSITY, clampf(value, 0.0, 1.0))

func get_light_only_jump_intensity() -> float:
	if not _is_valid_material(_light_only_jump_material):
		return 0.0
	var value: Variant = _light_only_jump_material.get_shader_parameter(PARAM_INTENSITY)
	if value == null:
		return 0.0
	return clampf(float(value), 0.0, 1.0)

func apply_distortion_progress(progress: float, squash_amount: float) -> void:
	var value := clampf(progress, 0.0, 1.0)
	set_distortion_intensity(value)
	set_distortion_squash(value * squash_amount)

func apply_transition_strength(strength: float, transition_intensity: float) -> void:
	var value := clampf(strength, 0.0, 1.0)
	set_transition_intensity(value * transition_intensity)

func configure_damage_material(
	desaturation: float,
	shake_power: float,
	color_bleeding: float,
	glitch_lines: float,
	vignette_intensity: float
) -> void:
	_set_shader_parameter(_damage_material, PARAM_DESATURATION, desaturation)
	_set_shader_parameter(_damage_material, PARAM_SHAKE_POWER, shake_power)
	_set_shader_parameter(_damage_material, PARAM_COLOR_BLEEDING, color_bleeding)
	_set_shader_parameter(_damage_material, PARAM_GLITCH_LINES, glitch_lines)
	_set_shader_parameter(_damage_material, PARAM_VIGNETTE_INTENSITY, vignette_intensity)

func configure_light_only_jump_material(noise_speed: float, glitch_amount: float) -> void:
	_set_shader_parameter(_light_only_jump_material, PARAM_NOISE_SPEED, noise_speed)
	_set_shader_parameter(_light_only_jump_material, PARAM_GLITCH_AMOUNT, glitch_amount)

func tween_light_only_jump_intensity(tween: Tween, peak: float, attack_time: float, release_time: float) -> void:
	if tween == null or not _is_valid_material(_light_only_jump_material):
		return
	tween.tween_property(_light_only_jump_material, TWEEN_LIGHT_INTENSITY_PROPERTY, peak, attack_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(_light_only_jump_material, TWEEN_LIGHT_INTENSITY_PROPERTY, 0.0, release_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func reset_distortion_overlay() -> void:
	set_distortion_visible(false)
	set_distortion_intensity(0.0)
	set_distortion_squash(0.0)

func reset_transition_overlay() -> void:
	set_transition_visible(false)
	set_transition_intensity(0.0)
	set_transition_squash(0.0)

func reset_damage_overlay() -> void:
	set_damage_visible(false)
	set_damage_intensity(0.0)

func reset_light_only_jump_overlay() -> void:
	set_light_only_jump_visible(false)
	set_light_only_jump_intensity(0.0)

func hide_inactive_overlays(damage_flash_active: bool, light_only_jump_active: bool) -> void:
	reset_distortion_overlay()
	reset_transition_overlay()
	if not damage_flash_active:
		reset_damage_overlay()
	if not light_only_jump_active:
		reset_light_only_jump_overlay()

func _set_shader_parameter(material: ShaderMaterial, parameter: StringName, value: Variant) -> void:
	if not _is_valid_material(material):
		return
	material.set_shader_parameter(parameter, value)

func _is_valid_rect(rect: ColorRect) -> bool:
	return rect != null and is_instance_valid(rect)

func _is_valid_material(material: ShaderMaterial) -> bool:
	return material != null and is_instance_valid(material)
