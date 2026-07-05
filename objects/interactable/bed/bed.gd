extends "res://objects/interactable/interactive_object.gd"
class_name Bed

## Путь к следующей сцене, куда переносить игрока после сна.
@export_file("*.tscn") var next_level_path: String
## Звук засыпания/пробуждения.
@export var sleep_sfx: AudioStream = preload("res://objects/interactable/bed/OutOfBed.wav")

## Сообщение, если игрок не ел в этом цикле.
@export_multiline var not_ate_message: String = "Нельзя спать: сначала поешь."
## Шаблон сообщения после сна (старый/новый цикл).
@export_multiline var sleep_message_template: String = ""
## Полностью запретить сон на этой кровати.
@export var block_sleep: bool = false
## Сообщение, если сон на этой кровати запрещён.
@export_multiline var blocked_sleep_message: String = ""
## Требовать свет в спальне для сна.
@export var require_light_for_sleep: bool = false
## Сообщение, если света в спальне нет.
@export_multiline var no_bedroom_light_message: String = "Я боюсь засыпать в темноте..."

const DEFAULT_NO_LIGHT_MESSAGE: String = "Я боюсь засыпать в темноте..."
const LampScript := preload("res://objects/interactable/lamp/lamp.gd")

var _is_sleeping: bool = false # Защита от повторного нажатия

func _ready() -> void:
	super._ready()
	input_pickable = false
	if CycleState != null and CycleState.consume_pending_sleep_spawn():
		if UIMessage and sleep_sfx != null:
			UIMessage.play_sfx(sleep_sfx)

func _on_interact() -> void:
	if _is_sleeping:
		return
	_try_sleep()

func _try_sleep() -> void:
	if block_sleep:
		var blocked_message := blocked_sleep_message
		if blocked_message.strip_edges() == "":
			blocked_message = no_bedroom_light_message
		if blocked_message.strip_edges() == "":
			blocked_message = DEFAULT_NO_LIGHT_MESSAGE
		UIMessage.show_notification(blocked_message)
		return

	var ate_this_cycle := false
	if CycleState != null:
		ate_this_cycle = bool(CycleState.has_eaten_this_cycle())
	if not ate_this_cycle:
		UIMessage.show_notification(not_ate_message)
		return
	if require_light_for_sleep and not _is_bedroom_light_on():
		var message := no_bedroom_light_message
		if message.strip_edges() == "":
			message = DEFAULT_NO_LIGHT_MESSAGE
		UIMessage.show_notification(message)
		return

	_is_sleeping = true

	if next_level_path.is_empty():
		push_warning("Bed: не назначена следующая сцена")
		_is_sleeping = false
		return

	var next_level_scene := load(next_level_path) as PackedScene
	if next_level_scene == null:
		push_warning("Bed: не удалось загрузить следующую сцену: %s" % next_level_path)
		_is_sleeping = false
		return
	
	if CycleState != null:
		CycleState.queue_sleep_spawn()
	var sleep_delay := _get_sleep_sfx_delay()
	await UIMessage.change_scene_with_fade_delay(next_level_scene, 0.4, sleep_delay, Callable(self, "_advance_cycle_before_sleep_scene_change"))

func _advance_cycle_before_sleep_scene_change() -> void:
	if GameState != null:
		GameState.next_cycle()

func _is_bedroom_light_on() -> bool:
	var lamps := get_tree().get_nodes_in_group("bedroom_lamp")
	for node in lamps:
		var lamp := node as LampScript
		if lamp != null and lamp.is_light_active():
			return true
	return false

func _get_sleep_sfx_delay() -> float:
	if sleep_sfx == null:
		return 0.0
	var length := sleep_sfx.get_length()
	if length <= 0.0:
		return 1.0
	return length
