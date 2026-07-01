extends "res://tests/test_case.gd"

const DistortionOverlayCoordinator = preload("res://levels/game_director_distortion_overlay_coordinator.gd")
const DISTORTION_SHADER := preload("res://shaders/distortion_overlay.gdshader")
const TRANSITION_SHADER := preload("res://shaders/distortion_transition.gdshader")
const LIGHT_ONLY_JUMP_SHADER := preload("res://shaders/light_only_jump_overlay.gdshader")

func run() -> Array[String]:
	_test_progress_and_transition_parameters_are_applied()
	_test_damage_and_light_material_configuration()
	_test_hide_inactive_overlays_preserves_active_effects()
	return get_failures()

func _test_progress_and_transition_parameters_are_applied() -> void:
	var fixture := _make_bound_fixture()
	var coordinator: RefCounted = fixture["coordinator"]
	var distortion_material: ShaderMaterial = fixture["distortion_material"]
	var transition_material: ShaderMaterial = fixture["transition_material"]

	coordinator.apply_distortion_progress(1.5, 0.25)
	assert_eq(_param(distortion_material, "intensity"), 1.0, "Distortion intensity must clamp above one")
	assert_eq(_param(distortion_material, "squash_amount"), 0.25, "Distortion squash must scale from clamped progress")

	coordinator.apply_distortion_progress(-1.0, 0.25)
	assert_eq(_param(distortion_material, "intensity"), 0.0, "Distortion intensity must clamp below zero")
	assert_eq(_param(distortion_material, "squash_amount"), 0.0, "Distortion squash must clamp below zero")

	coordinator.apply_transition_strength(0.5, 0.8)
	assert_true(absf(_param(transition_material, "intensity") - 0.4) < 0.0001, "Transition intensity must scale by configured strength")

	_free_fixture(fixture)

func _test_damage_and_light_material_configuration() -> void:
	var fixture := _make_bound_fixture()
	var coordinator: RefCounted = fixture["coordinator"]
	var damage_material: ShaderMaterial = fixture["damage_material"]
	var light_material: ShaderMaterial = fixture["light_material"]

	coordinator.configure_damage_material(0.7, 0.03, 0.12, 88.0, 1.4)
	assert_eq(_param(damage_material, "desaturation"), 0.7, "Damage desaturation must be applied")
	assert_eq(_param(damage_material, "shake_power"), 0.03, "Damage shake power must be applied")
	assert_eq(_param(damage_material, "color_bleeding"), 0.12, "Damage color bleeding must be applied")
	assert_eq(_param(damage_material, "glitch_lines"), 88.0, "Damage glitch lines must be applied")
	assert_eq(_param(damage_material, "vignette_intensity"), 1.4, "Damage vignette intensity must be applied")

	coordinator.configure_light_only_jump_material(18.0, 0.17)
	assert_eq(_param(light_material, "noise_speed"), 18.0, "Light-only noise speed must be applied")
	assert_eq(_param(light_material, "glitch_amount"), 0.17, "Light-only glitch amount must be applied")

	coordinator.set_light_only_jump_intensity(2.0)
	assert_eq(coordinator.get_light_only_jump_intensity(), 1.0, "Light-only intensity must clamp above one")
	coordinator.set_light_only_jump_intensity(-2.0)
	assert_eq(coordinator.get_light_only_jump_intensity(), 0.0, "Light-only intensity must clamp below zero")

	_free_fixture(fixture)

func _test_hide_inactive_overlays_preserves_active_effects() -> void:
	var fixture := _make_bound_fixture()
	var coordinator: RefCounted = fixture["coordinator"]
	var distortion_rect: ColorRect = fixture["distortion_rect"]
	var transition_rect: ColorRect = fixture["transition_rect"]
	var damage_rect: ColorRect = fixture["damage_rect"]
	var light_rect: ColorRect = fixture["light_rect"]
	var distortion_material: ShaderMaterial = fixture["distortion_material"]
	var transition_material: ShaderMaterial = fixture["transition_material"]
	var damage_material: ShaderMaterial = fixture["damage_material"]
	var light_material: ShaderMaterial = fixture["light_material"]

	distortion_rect.visible = true
	transition_rect.visible = true
	damage_rect.visible = true
	light_rect.visible = true
	coordinator.set_distortion_intensity(0.8)
	coordinator.set_transition_intensity(0.6)
	coordinator.set_damage_intensity(0.9)
	coordinator.set_light_only_jump_intensity(0.7)

	coordinator.hide_inactive_overlays(true, false)

	assert_true(not distortion_rect.visible, "Distortion overlay must hide when inactive")
	assert_true(not transition_rect.visible, "Transition overlay must hide when inactive")
	assert_eq(_param(distortion_material, "intensity"), 0.0, "Distortion intensity must reset when hidden")
	assert_eq(_param(transition_material, "intensity"), 0.0, "Transition intensity must reset when hidden")
	assert_true(damage_rect.visible, "Active damage overlay must stay visible")
	assert_eq(_param(damage_material, "intensity"), 0.9, "Active damage intensity must be preserved")
	assert_true(not light_rect.visible, "Inactive light-only overlay must hide")
	assert_eq(_param(light_material, "intensity"), 0.0, "Inactive light-only intensity must reset")

	_free_fixture(fixture)

func _make_bound_fixture() -> Dictionary:
	var coordinator: RefCounted = DistortionOverlayCoordinator.new()
	var distortion_rect := ColorRect.new()
	var transition_rect := ColorRect.new()
	var damage_rect := ColorRect.new()
	var light_rect := ColorRect.new()
	var distortion_material := ShaderMaterial.new()
	var transition_material := ShaderMaterial.new()
	var damage_material := ShaderMaterial.new()
	var light_material := ShaderMaterial.new()
	distortion_material.shader = DISTORTION_SHADER
	transition_material.shader = TRANSITION_SHADER
	damage_material.shader = TRANSITION_SHADER
	light_material.shader = LIGHT_ONLY_JUMP_SHADER
	coordinator.bind_overlays(
		distortion_rect,
		distortion_material,
		transition_rect,
		transition_material,
		damage_rect,
		damage_material,
		light_rect,
		light_material
	)
	return {
		"coordinator": coordinator,
		"distortion_rect": distortion_rect,
		"transition_rect": transition_rect,
		"damage_rect": damage_rect,
		"light_rect": light_rect,
		"distortion_material": distortion_material,
		"transition_material": transition_material,
		"damage_material": damage_material,
		"light_material": light_material,
	}

func _free_fixture(fixture: Dictionary) -> void:
	for key in ["distortion_rect", "transition_rect", "damage_rect", "light_rect"]:
		var node: Node = fixture[key]
		node.free()

func _param(material: ShaderMaterial, parameter: StringName) -> float:
	return float(material.get_shader_parameter(parameter))
