extends Node

signal distortion_started

const DeathCameraCoordinator = preload("res://levels/game_director_death_camera_coordinator.gd")
const DeathCursorCoordinator = preload("res://levels/game_director_death_cursor_coordinator.gd")
const DeathRetryCoordinator = preload("res://levels/game_director_death_retry_coordinator.gd")
const DeathTitlePresenter = preload("res://levels/game_director_death_title_presenter.gd")
const DistortionGate = preload("res://levels/game_director_distortion_gate.gd")
const DistortionProgress = preload("res://levels/game_director_distortion_progress.gd")
const OverlayLayerCoordinator = preload("res://levels/game_director_overlay_layer_coordinator.gd")
const StalkerService = preload("res://levels/game_director_stalker_service.gd")

## Время по умолчанию, если на уровне не задано.
@export var default_time: float = 15.0
## Длительность плавного появления постоянного искажения (сек).
@export_range(0.5, 10.0, 0.1) var distortion_ramp_duration: float = 2.0
## Сила сплющивания камеры для постоянного искажения.
@export_range(0.0, 0.2, 0.005) var distortion_squash_amount: float = 0.08
## Длительность переходного эффекта сразу после искажения (сек).
@export_range(1.0, 6.0, 0.1) var distortion_transition_duration: float = 4.0
## Сила переходного эффекта сразу после искажения.
@export_range(0.0, 1.0, 0.05) var distortion_transition_intensity: float = 1.0
## Сила сплющивания камеры в переходном эффекте.
@export_range(0.0, 0.2, 0.005) var distortion_transition_squash_amount: float = 0.25

@export_group("Stalker Spawn")
## Сцена сталкера для спавна по окончанию таймера.
@export var stalker_scene: PackedScene = preload("res://enemies/stalker/enemy_stalker.tscn")

@export_group("Damage Flash")
## Длительность резкого эффекта от урона (сек).
@export_range(0.01, 1.0, 0.01) var damage_flash_duration: float = 0.15
## Интенсивность резкого эффекта от урона.
@export_range(0.0, 1.0, 0.05) var damage_flash_intensity: float = 1.0
## Сила обесцвечивания в резком эффекте от урона.
@export_range(0.0, 1.0, 0.05) var damage_flash_desaturation: float = 0.85
## Сила тряски в резком эффекте от урона.
@export_range(0.0, 0.12, 0.005) var damage_flash_shake_power: float = 0.06
## Сила хроматической аберрации в резком эффекте от урона.
@export_range(0.0, 0.2, 0.01) var damage_flash_color_bleeding: float = 0.09
## Количество полос глитча в резком эффекте от урона.
@export_range(0.0, 140.0, 1.0) var damage_flash_glitch_lines: float = 95.0
## Сила виньетки в резком эффекте от урона.
@export_range(0.0, 2.0, 0.05) var damage_flash_vignette_intensity: float = 1.35
## Насколько резко отдаляется камера при ударе.
@export_range(0.0, 0.6, 0.01) var damage_flash_camera_zoom_punch: float = 0.14
## Максимальный случайный сдвиг камеры при ударе (px).
@export_range(0.0, 60.0, 0.5) var damage_flash_camera_offset_jitter: float = 12.0
## Поворот камеры при ударе (градусы).
@export_range(0.0, 12.0, 0.1) var damage_flash_camera_tilt_deg: float = 1.8

@export_group("LightOnly Jump FX")
## Включить экранный эффект скачка для врагов light_only.
@export var light_only_jump_effect_enabled: bool = true
## Пиковая интенсивность эффекта при скачке.
@export_range(0.0, 1.0, 0.05) var light_only_jump_peak_intensity: float = 1.0
## Длительность резкого появления эффекта (сек).
@export_range(0.01, 0.3, 0.01) var light_only_jump_attack_duration: float = 0.05
## Длительность плавного затухания эффекта (сек).
@export_range(0.05, 1.0, 0.01) var light_only_jump_release_duration: float = 0.2
## Скорость анимации шума.
@export_range(0.0, 80.0, 0.5) var light_only_jump_noise_speed: float = 30.0
## Сила горизонтальных разрывов строк.
@export_range(0.0, 0.4, 0.005) var light_only_jump_glitch_amount: float = 0.08

@export_group("Death Screen")
## Длительность затемнения до экрана смерти (сек).
@export_range(0.05, 3.0, 0.05) var death_fade_duration: float = 0.55
## Наклон камеры при смерти (градусы).
@export_range(0.0, 20.0, 0.1) var death_camera_tilt_deg: float = 5.0
## Множитель зума камеры при смерти.
@export_range(1.0, 2.5, 0.01) var death_camera_zoom_mult: float = 1.08
## Заголовок после завершения особой цепочки смертей.
@export var death_title_text: String = "Умер"
## Текст кнопки повтора.
@export var death_retry_text: String = "Попробовать ещё раз"

var _timer: Timer
var _overlay_layer: CanvasLayer
var _distortion_rect: ColorRect
var _distortion_material: ShaderMaterial
var _transition_rect: ColorRect
var _transition_material: ShaderMaterial
var _damage_rect: ColorRect
var _damage_material: ShaderMaterial
var _light_only_jump_rect: ColorRect
var _light_only_jump_material: ShaderMaterial
var _light_only_jump_tween: Tween = null
var current_max_time: float = 1.0
var _current_cycle_number: int = 0
var _current_timer_duration: float = 0.0
var _distortion_active: bool = false
var _distortion_progress: float = 0.0
var _transition_active: bool = false
var _transition_progress: float = 0.0
var _flash_active: bool = false
var _damage_flash_active: bool = false
var _light_only_jump_active: bool = false
var _in_game_scene: bool = false
var _stalker_spawned: bool = false
var _death_layer: CanvasLayer
var _death_fade_rect: ColorRect
var _death_root: Control
var _death_glitch_background: Control
var _death_title_label: Label
var _death_retry_button: Button
var _death_sequence_active: bool = false
var _death_pause_requested: bool = false
var _input_kind: int = 0
var _death_camera_coordinator: RefCounted
var _death_cursor_coordinator: RefCounted
var _death_retry_coordinator: RefCounted
var _death_title_presenter: RefCounted
var _distortion_gate: RefCounted
var _distortion_progress_helper: RefCounted
var _overlay_layer_coordinator: RefCounted
var _stalker_service: RefCounted

const InputDeviceUtilsClass := preload("res://global/input_device_utils.gd")
const INPUT_KIND_KEYBOARD := InputDeviceUtilsClass.InputKind.KEYBOARD
const INPUT_KIND_GAMEPAD := InputDeviceUtilsClass.InputKind.GAMEPAD
const INPUT_KIND_UNKNOWN := InputDeviceUtilsClass.InputKind.UNKNOWN
const CycleLevelBase = preload("res://levels/cycles/level.gd")
const LIGHT_ONLY_JUMP_SHADER: Shader = preload("res://shaders/light_only_jump_overlay.gdshader")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	_timer.timeout.connect(_on_distortion_timeout)
	add_child(_timer)
	_create_distortion_overlay()
	_create_death_overlay()
	_death_camera_coordinator = DeathCameraCoordinator.new()
	_death_cursor_coordinator = DeathCursorCoordinator.new()
	_death_retry_coordinator = DeathRetryCoordinator.new()
	_distortion_gate = DistortionGate.new()
	_distortion_progress_helper = DistortionProgress.new()
	_overlay_layer_coordinator = OverlayLayerCoordinator.new()
	_stalker_service = StalkerService.new()
	_sync_stalker_service()
	_connect_minigame_controller()
	if get_tree() and get_tree().has_signal("scene_changed"):
		get_tree().scene_changed.connect(_on_scene_changed)
	_update_for_scene(get_tree().current_scene)

func _input(event: InputEvent) -> void:
	var next_input_kind := _resolve_input_kind(event)
	if next_input_kind == INPUT_KIND_UNKNOWN:
		return
	if next_input_kind == _input_kind:
		return
	_input_kind = next_input_kind
	if _death_sequence_active:
		_apply_death_input_mode()

func _process(delta: float) -> void:
	_update_overlay_layer()
	if _death_sequence_active:
		return
	if _distortion_rect == null or _distortion_material == null:
		return
	if not _is_distortion_allowed():
		_hide_distortion_overlays()
		return
	var has_active := false
	if _distortion_active:
		_distortion_rect.visible = true
		_advance_distortion(delta)
		has_active = true
	if _transition_active:
		_transition_rect.visible = true
		_advance_transition(delta)
		has_active = true
	if _damage_flash_active:
		has_active = true
	if _light_only_jump_active:
		has_active = true
	if _flash_active:
		return
	if not has_active:
		_hide_distortion_overlays()

func start_normal_phase(timer_duration: float = -1.0) -> void:
	if CycleState != null:
		CycleState.set_phase(CycleState.Phase.NORMAL)
	_get_distortion_gate().clear_pending_activation()
	_distortion_active = false
	_distortion_progress = 0.0
	_transition_active = false
	_transition_progress = 0.0
	_flash_active = false
	_damage_flash_active = false
	_stop_light_only_jump_effect()
	_stalker_spawned = false
	_hide_distortion_overlays()
	
	var time_to_set: float = timer_duration
	if time_to_set < 0.0:
		time_to_set = default_time
	
	# Если время больше 0, запускаем таймер
	if time_to_set > 0.0:
		current_max_time = time_to_set
		_timer.start(time_to_set)
		print_verbose("GameDirector: Таймер запущен на %.1f сек." % time_to_set)
	else:
		# Если время 0 или меньше, останавливаем таймер (он не будет тикать)
		_timer.stop()
		current_max_time = 0.0 
		print_verbose("GameDirector: Таймер отключен для уровня.")

func reduce_time(amount: float, damage_flash: bool = false) -> void:
	if amount <= 0.0:
		return
	if not is_timer_running():
		return
	set_time_left(get_time_left() - amount)
	if CycleState != null and not CycleState.is_normal_phase():
		return
	if damage_flash:
		trigger_damage_flash()
	else:
		_flash_red()

func trigger_damage_flash() -> void:
	if _death_sequence_active:
		return
	_flash_damage()

func _on_distortion_timeout() -> void:
	if CycleState != null and CycleState.is_distorted_phase():
		_get_distortion_gate().clear_pending_activation()
		return
	if _should_defer_distortion_activation():
		_get_distortion_gate().mark_pending_activation()
		return
	_activate_distortion_phase()

func _activate_distortion_phase() -> void:
	if CycleState != null and CycleState.is_distorted_phase():
		_get_distortion_gate().clear_pending_activation()
		return
	_get_distortion_gate().clear_pending_activation()
	if CycleState != null:
		CycleState.set_phase(CycleState.Phase.DISTORTED)
	_distortion_active = true
	_distortion_progress = 0.0
	_transition_active = true
	_transition_progress = 0.0
	_flash_active = false
	_damage_flash_active = false
	if _damage_rect:
		_damage_rect.visible = false
	_set_damage_intensity(0.0)
	_distortion_rect.visible = _is_distortion_allowed()
	_transition_rect.visible = _is_distortion_allowed()
	_apply_distortion_progress(0.0)
	_apply_transition_strength(1.0)
	_spawn_stalker_if_needed()
	distortion_started.emit()

func _should_defer_distortion_activation() -> bool:
	return _get_distortion_gate().should_defer_activation(_death_sequence_active)

func trigger_distortion_now() -> void:
	if _death_sequence_active:
		return
	if not _in_game_scene:
		return
	_on_distortion_timeout()

func get_time_ratio() -> float:
	if CycleState != null and not CycleState.is_normal_phase():
		return 0.0
	
	# Если таймер стоит в нормальной фазе — значит время бесконечное (100%)
	if _timer.is_stopped() or current_max_time <= 0.0:
		return 1.0
		
	return _timer.time_left / current_max_time

func get_time_left() -> float:
	if current_max_time <= 0.0:
		return 0.0
	if _timer.is_stopped():
		if CycleState != null and CycleState.is_normal_phase():
			return current_max_time
		return 0.0
	return _timer.time_left

func is_timer_running() -> bool:
	if CycleState != null and not CycleState.is_normal_phase():
		return false
	return current_max_time > 0.0 and not _timer.is_stopped()

func ensure_timer_running(fallback_time: float) -> void:
	if fallback_time <= 0.0:
		return
	if CycleState != null and not CycleState.is_normal_phase():
		return
	if is_timer_running():
		return
	current_max_time = fallback_time
	_timer.start(fallback_time)

func set_time_left(new_time: float) -> void:
	if _death_sequence_active:
		return
	if CycleState != null and not CycleState.is_normal_phase():
		return
	if current_max_time <= 0.0:
		return
	var clamped_time: float = float(clamp(new_time, 0.0, current_max_time))
	if clamped_time <= 0.0:
		_timer.stop()
		_on_distortion_timeout()
		return
	_timer.start(clamped_time)

func _create_distortion_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 90
	add_child(_overlay_layer)
	
	_distortion_rect = ColorRect.new()
	_distortion_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_distortion_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_distortion_rect.visible = false
	_distortion_material = ShaderMaterial.new()
	_distortion_material.shader = preload("res://shaders/distortion_overlay.gdshader")
	_distortion_rect.material = _distortion_material
	_overlay_layer.add_child(_distortion_rect)
	_set_distortion_intensity(0.0)
	_set_distortion_squash(0.0)
	
	_transition_rect = ColorRect.new()
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.visible = false
	_transition_material = ShaderMaterial.new()
	_transition_material.shader = preload("res://shaders/distortion_transition.gdshader")
	_transition_rect.material = _transition_material
	_overlay_layer.add_child(_transition_rect)
	_set_transition_intensity(0.0)
	_set_transition_squash(0.0)

	_damage_rect = ColorRect.new()
	_damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_rect.visible = false
	_damage_material = ShaderMaterial.new()
	_damage_material.shader = preload("res://shaders/distortion_transition.gdshader")
	_damage_rect.material = _damage_material
	_overlay_layer.add_child(_damage_rect)
	_set_damage_intensity(0.0)
	_configure_damage_material()

	_light_only_jump_rect = ColorRect.new()
	_light_only_jump_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_light_only_jump_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light_only_jump_rect.visible = false
	_light_only_jump_material = ShaderMaterial.new()
	_light_only_jump_material.shader = LIGHT_ONLY_JUMP_SHADER
	_light_only_jump_rect.material = _light_only_jump_material
	_overlay_layer.add_child(_light_only_jump_rect)
	_configure_light_only_jump_material()
	_set_light_only_jump_intensity(0.0)

func _flash_red() -> void:
	if _distortion_rect.visible:
		return
	if not _is_distortion_allowed():
		return
	_flash_active = true
	_distortion_rect.visible = true
	_set_distortion_intensity(0.25)
	_set_distortion_squash(0.0)
	get_tree().create_timer(0.1).timeout.connect(func():
		if CycleState == null or CycleState.is_normal_phase():
			_distortion_rect.visible = false
			_set_distortion_intensity(0.0)
			_set_distortion_squash(0.0)
		_flash_active = false
	)

func _flash_damage() -> void:
	if _damage_rect == null or _damage_material == null:
		return
	if _death_sequence_active:
		return
	if _damage_flash_active:
		return
	if not _is_distortion_allowed():
		return
	_damage_flash_active = true
	_configure_damage_material()
	_damage_rect.visible = true
	_set_damage_intensity(damage_flash_intensity)
	_apply_damage_camera_punch()
	get_tree().create_timer(damage_flash_duration).timeout.connect(func():
		if _damage_rect:
			_damage_rect.visible = false
			_set_damage_intensity(0.0)
		_damage_flash_active = false
	)

func _on_scene_changed(scene: Node = null) -> void:
	if scene == null:
		scene = get_tree().current_scene
	_update_for_scene(scene)

func _update_for_scene(scene: Node) -> void:
	_reset_death_screen_state()
	_in_game_scene = SceneContext != null and SceneContext.is_gameplay_scene(scene)
	_get_distortion_gate().reset_for_scene()
	if _in_game_scene:
		_apply_level_settings(scene)
		return
	_timer.stop()
	_distortion_active = false
	_distortion_progress = 0.0
	_transition_active = false
	_transition_progress = 0.0
	_flash_active = false
	_stop_light_only_jump_effect()
	_stalker_spawned = false
	_hide_distortion_overlays()
	if CycleState != null:
		CycleState.set_phase(CycleState.Phase.NORMAL)

func _apply_level_settings(scene: Node) -> void:
	_current_cycle_number = _resolve_cycle_number(scene)
	_current_timer_duration = _resolve_timer_duration(scene)
	start_normal_phase(_current_timer_duration)

func _resolve_cycle_number(scene: Node) -> int:
	if scene == null:
		return 0
	if scene.has_method("get_cycle_number"):
		return int(scene.get_cycle_number())
	return 0

func _resolve_timer_duration(scene: Node) -> float:
	if scene == null:
		return default_time
	if scene.has_method("get_timer_duration"):
		return float(scene.get_timer_duration())
	return default_time

func _create_death_overlay() -> void:
	_death_layer = CanvasLayer.new()
	_death_layer.layer = 120
	_death_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_death_layer)

	_death_fade_rect = ColorRect.new()
	_death_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_fade_rect.color = Color(0, 0, 0, 0)
	_death_fade_rect.visible = false
	_death_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_death_fade_rect.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_death_layer.add_child(_death_fade_rect)

	_death_root = Control.new()
	_death_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_root.visible = false
	_death_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_death_root.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_death_layer.add_child(_death_root)

	_death_glitch_background = Control.new()
	_death_glitch_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_glitch_background.visible = false
	_death_glitch_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_glitch_background.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_death_root.add_child(_death_glitch_background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_root.add_child(center)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(content)

	_death_title_label = Label.new()
	_death_title_label.text = death_title_text
	_death_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_death_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_death_title_label.add_theme_font_size_override("font_size", 112)
	var base_font = load("res://global/fonts/AmaticSC-Regular.ttf")
	if base_font:
		var font_variation := FontVariation.new()
		font_variation.base_font = base_font
		font_variation.spacing_glyph = 3
		_death_title_label.add_theme_font_override("font", font_variation)
	content.add_child(_death_title_label)
	_death_title_presenter = DeathTitlePresenter.new(self, _death_title_label, _death_glitch_background)
	_death_title_presenter.apply_title(death_title_text, false)

	_death_retry_button = Button.new()
	_death_retry_button.text = death_retry_text
	_death_retry_button.custom_minimum_size = Vector2(420, 92)
	_death_retry_button.focus_mode = Control.FOCUS_ALL
	_death_retry_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_death_retry_button.pressed.connect(_on_death_retry_pressed)
	content.add_child(_death_retry_button)

func trigger_death_screen() -> void:
	if _death_sequence_active:
		return
	if _handle_custom_scene_death():
		return
	_death_sequence_active = true
	_release_death_cursor_request()
	_timer.stop()
	_distortion_active = false
	_distortion_progress = 0.0
	_transition_active = false
	_transition_progress = 0.0
	_flash_active = false
	_damage_flash_active = false
	_stop_light_only_jump_effect()
	_hide_distortion_overlays()
	if _death_camera_coordinator == null:
		_death_camera_coordinator = DeathCameraCoordinator.new()
	_death_camera_coordinator.capture(_resolve_primary_camera())
	if _death_title_presenter != null:
		_death_title_presenter.apply_next_title(death_title_text)
	if _death_retry_button:
		_death_retry_button.text = death_retry_text
	if _death_root:
		_death_root.visible = false
	if _death_fade_rect:
		_death_fade_rect.visible = true
		_death_fade_rect.color = Color(0, 0, 0, 0)
	var fade_time: float = maxf(0.01, death_fade_duration)
	var tween := create_tween()
	tween.set_parallel(true)
	if _death_fade_rect:
		tween.tween_property(_death_fade_rect, "color:a", 1.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _death_camera_coordinator.has_camera():
		var tilt_sign := -1.0 if randf() < 0.5 else 1.0
		_death_camera_coordinator.tween_to_death_pose(tween, fade_time, death_camera_tilt_deg, death_camera_zoom_mult, tilt_sign)
	tween.finished.connect(_on_death_fade_completed)

func _handle_custom_scene_death() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	if not (scene is CycleLevelBase):
		return false
	return bool((scene as CycleLevelBase).handle_custom_death_screen())

func _on_death_fade_completed() -> void:
	if not _death_sequence_active:
		return
	if _death_root:
		_death_root.visible = true
	_apply_death_input_mode()
	_request_death_pause()

func _on_death_retry_pressed() -> void:
	if not _death_sequence_active:
		return
	await _get_death_retry_coordinator().prepare_retry(GameState, CycleState, UIMessage)
	_restore_death_camera()
	if _death_root:
		_death_root.visible = false
	_release_death_cursor_request()
	_release_death_pause()
	if get_tree():
		get_tree().call_deferred("reload_current_scene")

func _reset_death_screen_state() -> void:
	_death_sequence_active = false
	_restore_death_camera()
	if _death_root:
		_death_root.visible = false
	if _death_glitch_background:
		_death_glitch_background.visible = false
	if _death_fade_rect:
		_death_fade_rect.visible = false
		_death_fade_rect.color = Color(0, 0, 0, 0)
	if _death_retry_button:
		_death_retry_button.remove_theme_stylebox_override("focus")
	_release_death_cursor_request()
	_release_death_pause()

func _restore_death_camera() -> void:
	if _death_camera_coordinator == null:
		_death_camera_coordinator = DeathCameraCoordinator.new()
	_death_camera_coordinator.restore()

func _get_death_retry_coordinator() -> RefCounted:
	if _death_retry_coordinator == null:
		_death_retry_coordinator = DeathRetryCoordinator.new()
	return _death_retry_coordinator

func _request_death_pause() -> void:
	if _death_pause_requested:
		return
	_death_pause_requested = true
	if PauseManager != null and PauseManager.has_method("request_pause"):
		PauseManager.request_pause(self, "death_screen")
	elif get_tree():
		get_tree().paused = true

func _release_death_pause() -> void:
	if not _death_pause_requested:
		return
	_death_pause_requested = false
	if PauseManager != null and PauseManager.has_method("release_pause"):
		PauseManager.release_pause(self, "death_screen")
	elif get_tree():
		get_tree().paused = false

func _set_distortion_intensity(value: float) -> void:
	if _distortion_material == null:
		return
	_distortion_material.set_shader_parameter("intensity", value)

func _set_distortion_squash(value: float) -> void:
	if _distortion_material == null:
		return
	_distortion_material.set_shader_parameter("squash_amount", value)

func _set_transition_intensity(value: float) -> void:
	if _transition_material == null:
		return
	_transition_material.set_shader_parameter("intensity", value)

func _set_transition_squash(value: float) -> void:
	if _transition_material == null:
		return
	_transition_material.set_shader_parameter("squash_amount", value)

func _set_damage_intensity(value: float) -> void:
	if _damage_material == null:
		return
	_damage_material.set_shader_parameter("intensity", value)

func _set_light_only_jump_intensity(value: float) -> void:
	if _light_only_jump_material == null:
		return
	_light_only_jump_material.set_shader_parameter("intensity", float(clamp(value, 0.0, 1.0)))

func _get_light_only_jump_intensity() -> float:
	if _light_only_jump_material == null:
		return 0.0
	var value: Variant = _light_only_jump_material.get_shader_parameter("intensity")
	if value == null:
		return 0.0
	return clampf(float(value), 0.0, 1.0)

func _configure_light_only_jump_material() -> void:
	if _light_only_jump_material == null:
		return
	_light_only_jump_material.set_shader_parameter("noise_speed", light_only_jump_noise_speed)
	_light_only_jump_material.set_shader_parameter("glitch_amount", light_only_jump_glitch_amount)

func trigger_light_only_jump_effect(peak_intensity: float = -1.0) -> void:
	if not light_only_jump_effect_enabled:
		return
	if _light_only_jump_rect == null or _light_only_jump_material == null:
		return
	if _death_sequence_active:
		return
	_configure_light_only_jump_material()
	var target_peak := light_only_jump_peak_intensity if peak_intensity < 0.0 else peak_intensity
	target_peak = clampf(target_peak, 0.0, 1.0)
	var attack_time := maxf(0.01, light_only_jump_attack_duration)
	var release_time := maxf(0.01, light_only_jump_release_duration)
	var current := _get_light_only_jump_intensity()
	var peak := maxf(current, target_peak)
	_light_only_jump_rect.visible = true
	_light_only_jump_active = true
	if _light_only_jump_tween != null and is_instance_valid(_light_only_jump_tween):
		_light_only_jump_tween.kill()
	_light_only_jump_tween = create_tween()
	_light_only_jump_tween.tween_property(_light_only_jump_material, "shader_parameter/intensity", peak, attack_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_light_only_jump_tween.tween_property(_light_only_jump_material, "shader_parameter/intensity", 0.0, release_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_light_only_jump_tween.finished.connect(_on_light_only_jump_effect_finished)

func _on_light_only_jump_effect_finished() -> void:
	_light_only_jump_tween = null
	_light_only_jump_active = false
	if _light_only_jump_rect:
		_light_only_jump_rect.visible = false
	_set_light_only_jump_intensity(0.0)

func _stop_light_only_jump_effect() -> void:
	if _light_only_jump_tween != null and is_instance_valid(_light_only_jump_tween):
		_light_only_jump_tween.kill()
	_light_only_jump_tween = null
	_light_only_jump_active = false
	if _light_only_jump_rect:
		_light_only_jump_rect.visible = false
	_set_light_only_jump_intensity(0.0)

func _configure_damage_material() -> void:
	if _damage_material == null:
		return
	_damage_material.set_shader_parameter("desaturation", damage_flash_desaturation)
	_damage_material.set_shader_parameter("shake_power", damage_flash_shake_power)
	_damage_material.set_shader_parameter("color_bleeding", damage_flash_color_bleeding)
	_damage_material.set_shader_parameter("glitch_lines", damage_flash_glitch_lines)
	_damage_material.set_shader_parameter("vignette_intensity", damage_flash_vignette_intensity)

func _apply_damage_camera_punch() -> void:
	if damage_flash_duration <= 0.0:
		return
	var camera := _resolve_primary_camera()
	if camera == null:
		return
	var base_zoom := camera.zoom
	var base_offset := camera.offset
	var base_rotation := camera.rotation
	var target_zoom := base_zoom * (1.0 + damage_flash_camera_zoom_punch)
	var jitter := Vector2(
		randf_range(-damage_flash_camera_offset_jitter, damage_flash_camera_offset_jitter),
		randf_range(-damage_flash_camera_offset_jitter, damage_flash_camera_offset_jitter)
	)
	var tilt_sign := -1.0 if randf() < 0.5 else 1.0
	var target_rotation := base_rotation + deg_to_rad(damage_flash_camera_tilt_deg) * tilt_sign
	var in_time: float = maxf(0.02, damage_flash_duration * 0.3)
	var out_time: float = maxf(0.02, damage_flash_duration * 0.7)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "zoom", target_zoom, in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "offset", base_offset + jitter, in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "rotation", target_rotation, in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(camera, "zoom", base_zoom, out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(camera, "offset", base_offset, out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(camera, "rotation", base_rotation, out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _resolve_primary_camera() -> Camera2D:
	if get_viewport() and get_viewport().get_camera_2d():
		return get_viewport().get_camera_2d()
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	if player.has_node("Camera2D"):
		return player.get_node("Camera2D") as Camera2D
	return null

func _apply_death_input_mode() -> void:
	if _death_cursor_coordinator == null:
		_death_cursor_coordinator = DeathCursorCoordinator.new()
	_death_cursor_coordinator.apply_input_mode(_death_retry_button, CursorManager, self, _input_kind)

func _release_death_cursor_request() -> void:
	if _death_cursor_coordinator == null:
		_death_cursor_coordinator = DeathCursorCoordinator.new()
	_death_cursor_coordinator.release_cursor_request(CursorManager, self)

func _resolve_input_kind(event: InputEvent) -> int:
	return InputDeviceUtilsClass.resolve_input_kind(event)

func _apply_distortion_progress(progress: float) -> void:
	var value: float = float(clamp(progress, 0.0, 1.0))
	_set_distortion_intensity(value)
	_set_distortion_squash(value * distortion_squash_amount)

func _apply_transition_strength(strength: float) -> void:
	var value: float = float(clamp(strength, 0.0, 1.0))
	# Мы убрали squash, так как новый шейдер делает всё через intensity
	_set_transition_intensity(value * distortion_transition_intensity)
	# _set_transition_squash(...) — эту строку можно удалить, она больше не нужна

func _advance_distortion(delta: float) -> void:
	_distortion_progress = _get_distortion_progress_helper().advance_progress(_distortion_progress, delta, distortion_ramp_duration)
	var eased: float = _get_distortion_progress_helper().ease_out(_distortion_progress)
	_apply_distortion_progress(eased)

func _advance_transition(delta: float) -> void:
	_transition_progress = _get_distortion_progress_helper().advance_progress(_transition_progress, delta, distortion_transition_duration)
	var strength: float = _get_distortion_progress_helper().transition_strength(_transition_progress)
	_apply_transition_strength(strength)
	if _transition_progress >= 1.0:
		_transition_active = false
		if _transition_rect:
			_transition_rect.visible = false

func _is_distortion_allowed() -> bool:
	return _get_distortion_gate().is_distortion_allowed(_in_game_scene)

func _get_distortion_progress_helper() -> RefCounted:
	if _distortion_progress_helper == null:
		_distortion_progress_helper = DistortionProgress.new()
	return _distortion_progress_helper

func _get_distortion_gate() -> RefCounted:
	if _distortion_gate == null:
		_distortion_gate = DistortionGate.new()
	return _distortion_gate

func _update_overlay_layer() -> void:
	if _overlay_layer == null:
		return
	if _overlay_layer_coordinator == null:
		_overlay_layer_coordinator = OverlayLayerCoordinator.new()
	var pause_menu_open := false
	if PauseManager and PauseManager.has_method("is_pause_menu_open"):
		pause_menu_open = PauseManager.is_pause_menu_open()
	var tree_paused := get_tree() != null and get_tree().paused
	var active_minigame_layer := OverlayLayerCoordinator.DEFAULT_OVERLAY_LAYER
	if MinigameController and MinigameController.has_method("get_active_minigame_layer"):
		active_minigame_layer = MinigameController.get_active_minigame_layer()
	_overlay_layer_coordinator.apply_layer(_overlay_layer, tree_paused, pause_menu_open, _get_distortion_gate().is_minigame_active(), active_minigame_layer)

func _hide_distortion_overlays() -> void:
	if _distortion_rect:
		_distortion_rect.visible = false
	if _transition_rect:
		_transition_rect.visible = false
	if _damage_rect and not _damage_flash_active:
		_damage_rect.visible = false
	if _light_only_jump_rect and not _light_only_jump_active:
		_light_only_jump_rect.visible = false
	_set_distortion_intensity(0.0)
	_set_distortion_squash(0.0)
	_set_transition_intensity(0.0)
	_set_transition_squash(0.0)
	if not _damage_flash_active:
		_set_damage_intensity(0.0)
	if not _light_only_jump_active:
		_set_light_only_jump_intensity(0.0)

func _spawn_stalker_if_needed() -> void:
	if _stalker_spawned:
		return
	if not _in_game_scene:
		return
	_sync_stalker_service()
	if _stalker_service == null or stalker_scene == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var spawn: Node2D = _stalker_service.find_spawn(get_tree(), scene)
	if spawn == null:
		return
	_stalker_spawned = true
	call_deferred("_spawn_stalker_deferred", scene, spawn.global_position)

func _spawn_stalker_deferred(scene: Node, spawn_position: Vector2) -> void:
	if not _stalker_spawned:
		return
	if scene == null or not is_instance_valid(scene):
		_stalker_spawned = false
		return
	if get_tree() == null or scene != get_tree().current_scene:
		_stalker_spawned = false
		return
	_sync_stalker_service()
	if _stalker_service == null or _stalker_service.create_stalker(scene, spawn_position) == null:
		_stalker_spawned = false

func _sync_stalker_service() -> void:
	if _stalker_service == null:
		_stalker_service = StalkerService.new()
	_stalker_service.stalker_scene = stalker_scene

func _connect_minigame_controller() -> void:
	if MinigameController == null:
		return
	if MinigameController.has_signal("minigame_started") and not MinigameController.minigame_started.is_connected(_on_minigame_started):
		MinigameController.minigame_started.connect(_on_minigame_started)
	if MinigameController.has_signal("minigame_finished") and not MinigameController.minigame_finished.is_connected(_on_minigame_finished):
		MinigameController.minigame_finished.connect(_on_minigame_finished)

func _on_minigame_started(_minigame: Node) -> void:
	_get_distortion_gate().on_minigame_started(_minigame_allows_distortion(_minigame))

func _on_minigame_finished(_minigame: Node, _success: bool) -> void:
	if _get_distortion_gate().on_minigame_finished():
		_activate_distortion_phase()

func _minigame_allows_distortion(minigame: Node) -> bool:
	if minigame == null:
		return true
	if minigame.has_method("allows_distortion_overlay"):
		return bool(minigame.allows_distortion_overlay())
	if minigame.has_meta("allow_distortion_overlay"):
		return bool(minigame.get_meta("allow_distortion_overlay"))
	return true

func get_cycle_number() -> int:
	return _current_cycle_number

func capture_checkpoint_state() -> Dictionary:
	var state := {
		"current_max_time": current_max_time,
		"current_cycle_number": _current_cycle_number,
		"current_timer_duration": _current_timer_duration,
		"time_left": get_time_left(),
		"timer_running": is_timer_running(),
		"stalker_spawned": _stalker_spawned,
		"distortion_active": _distortion_active,
		"distortion_progress": _distortion_progress,
		"transition_active": _transition_active,
		"transition_progress": _transition_progress,
	}
	state.merge(_get_distortion_gate().capture_checkpoint_state(), true)
	_sync_stalker_service()
	if _stalker_service != null and get_tree() != null:
		state.merge(_stalker_service.capture_checkpoint_state(get_tree(), get_tree().current_scene, _stalker_spawned), true)
	return state

func apply_checkpoint_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	_current_cycle_number = int(state.get("current_cycle_number", _current_cycle_number))
	_current_timer_duration = float(state.get("current_timer_duration", _current_timer_duration))
	current_max_time = float(state.get("current_max_time", current_max_time))
	_get_distortion_gate().apply_checkpoint_state(state)
	_stalker_spawned = bool(state.get("stalker_spawned", false))
	_distortion_active = bool(state.get("distortion_active", false))
	_distortion_progress = float(state.get("distortion_progress", 0.0))
	_transition_active = bool(state.get("transition_active", false))
	_transition_progress = float(state.get("transition_progress", 0.0))
	_flash_active = false
	_damage_flash_active = false
	_stop_light_only_jump_effect()
	if _damage_rect != null:
		_damage_rect.visible = false
	_set_damage_intensity(0.0)
	if _death_sequence_active:
		_reset_death_screen_state()
	if CycleState != null and CycleState.is_normal_phase() and current_max_time > 0.0:
		var timer_running := bool(state.get("timer_running", false))
		var time_left := clampf(float(state.get("time_left", current_max_time)), 0.0, current_max_time)
		if timer_running and time_left > 0.0:
			_timer.start(time_left)
		else:
			_timer.stop()
	else:
		_timer.stop()
	if _stalker_spawned:
		_sync_stalker_service()
		if _stalker_service != null and get_tree() != null:
			_stalker_service.restore_from_checkpoint(get_tree(), get_tree().current_scene, state)
	if not _distortion_active and not _transition_active:
		_hide_distortion_overlays()
