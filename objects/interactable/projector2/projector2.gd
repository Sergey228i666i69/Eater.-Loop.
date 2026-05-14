extends InteractiveObject
class_name Projector2

## Сценический прожектор: при взаимодействии включает/выключает направленный
## луч света. В отличие от старого Projector — все настройки геометрии (где
## линза, куда светит, насколько широк луч) сидят на отдельных Marker2D-узлах,
## которые удобно тащить мышкой в редакторе. Скрипт сам подгоняет PointLight2D
## так, чтобы яркая вершина текстуры всегда была ровно у линзы.

@export_group("Power")
## Если true — прожектор не зажжётся, пока кто-то не вызовет turn_on().
@export var requires_generator: bool = false
## Включать прожектор сразу при загрузке сцены.
@export var start_on: bool = false

@export_group("Sound")
## Звук щелчка переключателя.
@export var switch_sfx: AudioStream = preload("res://objects/interactable/lamp/lamp.wav")
## Громкость щелчка в дБ.
@export var switch_volume_db: float = 0.0
@export_range(0.5, 1.5, 0.01) var switch_pitch_min: float = 0.95
@export_range(0.5, 1.5, 0.01) var switch_pitch_max: float = 1.05

@export_group("Light Look")
## Цвет луча.
@export var light_color: Color = Color(1.0, 0.97, 0.88, 1.0)
## Энергия PointLight2D.
@export var light_energy: float = 1.85
## Длина луча в пикселях (от линзы до полного затухания).
@export var beam_length: float = 1500.0
## Поле зрения луча в градусах — используется для логики is_point_lit
## (определяет, освещён ли враг и т.п.). Визуальная ширина задаётся текстурой.
@export_range(1.0, 180.0, 1.0) var light_fov_deg: float = 38.0

@export_group("Wiring")
## Анимированный спрайт корпуса прожектора (для смены off/on текстуры).
@export var sprite_node: NodePath = NodePath("Body")
## Marker2D, который стоит точно у линзы — отсюда берёт начало луч и тут же
## висит маленький "блик" свечения самого прожектора.
@export var lens_anchor: NodePath = NodePath("LensAnchor")
## Marker2D, обозначающий направление луча: вектор от LensAnchor до этого
## маркера задаёт куда светит прожектор.
@export var beam_target: NodePath = NodePath("LensAnchor/BeamTarget")
## PointLight2D — длинный луч.
@export var beam_light: NodePath = NodePath("LensAnchor/BeamLight")
## PointLight2D — маленький "блик" самого прожектора у линзы.
@export var lens_glow: NodePath = NodePath("LensAnchor/LensGlow")
## Marker2D, над которым показывается иконка взаимодействия.
@export var prompt_anchor: NodePath = NodePath("PromptAnchor")

@export_group("Sprites")
## Текстура корпуса в выключенном состоянии (если пусто — берётся текущая).
@export var off_texture: Texture2D
## Текстура корпуса во включенном состоянии (опционально).
@export var on_texture: Texture2D

var _is_on: bool = false
var _has_power: bool = false

var _body: Sprite2D = null
var _lens_anchor: Node2D = null
var _beam_target: Node2D = null
var _beam_light: PointLight2D = null
var _lens_glow: PointLight2D = null
var _prompt_anchor: Node2D = null
var _sfx_player: AudioStreamPlayer2D = null

func _ready() -> void:
	super._ready()

	_body = get_node_or_null(sprite_node) as Sprite2D
	_lens_anchor = get_node_or_null(lens_anchor) as Node2D
	_beam_target = get_node_or_null(beam_target) as Node2D
	_beam_light = get_node_or_null(beam_light) as PointLight2D
	_lens_glow = get_node_or_null(lens_glow) as PointLight2D
	_prompt_anchor = get_node_or_null(prompt_anchor) as Node2D

	if _body != null and off_texture == null:
		off_texture = _body.texture

	_sfx_player = AudioStreamPlayer2D.new()
	_sfx_player.bus = "Sounds"
	_sfx_player.volume_db = switch_volume_db
	add_child(_sfx_player)

	if not is_in_group("reactive_light_source"):
		add_to_group("reactive_light_source")
	if requires_generator and not is_in_group("generator_required_light"):
		add_to_group("generator_required_light")

	_apply_light_settings()

	_has_power = not requires_generator
	_is_on = start_on
	_update_light_enabled(false)

# --- Public API -------------------------------------------------------------

## Подаёт питание (например, по сигналу от генератора).
func turn_on() -> void:
	_has_power = true
	_is_on = true
	_update_light_enabled(true)

## Включён ли прожектор сейчас (для других систем).
func is_light_active() -> bool:
	return _beam_light != null and _beam_light.enabled

## Освещена ли точка world-space лучом прожектора (используется врагами).
func is_point_lit(point: Vector2) -> bool:
	if not is_light_active():
		return false
	if _lens_anchor == null:
		return false
	var origin := _lens_anchor.global_position
	var facing := _resolve_beam_direction()
	if facing.length_squared() <= 0.000001:
		return false
	return ReactiveLightUtils.is_point_within_cone(
		origin, facing, point, beam_length, light_fov_deg
	)

# --- InteractiveObject overrides --------------------------------------------

func _on_interact() -> void:
	_toggle()

func get_prompt_world_position() -> Vector2:
	if _prompt_anchor != null:
		return _prompt_anchor.global_position
	return super.get_prompt_world_position()


# --- Toggle / state ---------------------------------------------------------

func _toggle() -> void:
	if not _has_power:
		if UIMessage:
			UIMessage.show_notification("Нет электричества.")
		return
	_is_on = not _is_on
	_update_light_enabled(true)

func _update_light_enabled(play_sound: bool) -> void:
	var should_enable := _is_on and _has_power
	var was_enabled := false

	if _beam_light != null:
		was_enabled = _beam_light.enabled
		_beam_light.enabled = should_enable
	if _lens_glow != null:
		_lens_glow.enabled = should_enable

	if play_sound and was_enabled != should_enable:
		_play_switch_sound()

	_update_body_texture(should_enable)

	if is_player_in_range():
		_show_prompt()

func _get_prompt_text() -> String:
	if is_light_active():
		return tr("E — выключить прожектор")
	return tr("E — включить прожектор")

func _update_body_texture(is_lit: bool) -> void:
	if _body == null:
		return
	if is_lit and on_texture != null:
		_body.texture = on_texture
	elif not is_lit and off_texture != null:
		_body.texture = off_texture

# --- Light geometry ---------------------------------------------------------

## Применяет цвет/энергию и пересчитывает геометрию луча так, чтобы вершина
## градиента всегда стояла ровно в LensAnchor, а сам луч уходил в нужную
## сторону.
func _apply_light_settings() -> void:
	if _beam_light != null:
		_beam_light.color = light_color
		_beam_light.energy = light_energy
	if _lens_glow != null:
		# Маленькому блику возьмём ту же палитру, но без растягивания.
		_lens_glow.color = light_color
		_lens_glow.energy = clampf(light_energy * 0.7, 0.4, 2.0)
	_update_beam_geometry()

func _update_beam_geometry() -> void:
	if _beam_light == null or _beam_light.texture == null:
		return
	var texture_width := float(_beam_light.texture.get_width())
	if texture_width <= 0.0:
		return

	# Текстура — вытянутый радиальный градиент (2048×384) с центром
	# градиента у fill_from = (0.04, 0.5). Узкий по высоте → даёт
	# конусообразный луч, а не рассеянный блоб.
	# Масштаб подбираем так, чтобы ширина текстуры в мире = beam_length.
	var desired_scale := maxf(0.1, beam_length / texture_width)
	_beam_light.texture_scale = desired_scale

	# Яркий центр градиента (fill_from) стоит на 4% ширины текстуры.
	# Чтобы этот яркий центр оказался ровно в позиции PointLight2D
	# (которая совпадает с LensAnchor), смещаем текстуру так:
	#   offset.x = (0.5 - fill_from_x) * texture_width * scale
	# При fill_from_x = 0.04:
	#   offset.x = (0.5 - 0.04) * tw * scale = 0.46 * tw * scale
	# Это сдвигает текстуру вправо, ставя её яркий центр точно на линзу.
	var fill_from_x := 0.04
	_beam_light.offset = Vector2((0.5 - fill_from_x) * texture_width * desired_scale, 0.0)

	var direction := _resolve_beam_direction_local()
	_beam_light.rotation = direction.angle()

## Направление луча в локальных координатах LensAnchor (используется для
## визуального поворота PointLight2D).
func _resolve_beam_direction_local() -> Vector2:
	if _lens_anchor == null or _beam_target == null:
		return Vector2.RIGHT
	# beam_target всегда висит ребёнком lens_anchor, поэтому его position
	# уже в координатах lens_anchor.
	var local := _beam_target.position
	if local.length_squared() <= 0.000001:
		return Vector2.RIGHT
	return local.normalized()

## Направление луча в мировом пространстве (для логики is_point_lit, чтобы
## враги корректно попадали в конус).
func _resolve_beam_direction() -> Vector2:
	if _lens_anchor == null or _beam_target == null:
		return Vector2.RIGHT
	var origin := _lens_anchor.global_position
	var aim := _beam_target.global_position
	var dir := aim - origin
	if dir.length_squared() <= 0.000001:
		return Vector2.RIGHT
	return dir.normalized()

# --- SFX --------------------------------------------------------------------

func _play_switch_sound() -> void:
	if switch_sfx == null or _sfx_player == null:
		return
	_sfx_player.stream = switch_sfx
	_sfx_player.volume_db = switch_volume_db
	var min_pitch: float = minf(switch_pitch_min, switch_pitch_max)
	var max_pitch: float = maxf(switch_pitch_min, switch_pitch_max)
	_sfx_player.pitch_scale = randf_range(min_pitch, max_pitch)
	_sfx_player.play()

# --- Checkpoint persistence -------------------------------------------------

func capture_checkpoint_state() -> Dictionary:
	var state := super.capture_checkpoint_state()
	state["is_on"] = _is_on
	state["has_power"] = _has_power
	return state

func apply_checkpoint_state(state: Dictionary) -> void:
	super.apply_checkpoint_state(state)
	_is_on = bool(state.get("is_on", _is_on))
	_has_power = bool(state.get("has_power", _has_power))
	_update_light_enabled(false)
