extends Area2D

@export var next_level_scene: PackedScene

@export_multiline var not_ate_message: String = "Нельзя спать: сначала поешь."
@export_multiline var sleep_message_template: String = "Поспал. Цикл %d → %d"
@export_group("Sounds")
@export var sleep_sound: AudioStream
@export var wake_sound: AudioStream

var _player_in_range: Node = null
var _is_sleeping: bool = false # Защита от повторного нажатия
var _audio_player: AudioStreamPlayer

func _ready() -> void:
	input_pickable = false
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = body

func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		_player_in_range = null

func _unhandled_input(event: InputEvent) -> void:
	if _is_sleeping: return

	if event.is_action_pressed("interact") and _player_in_range != null:
		_try_sleep()

func _try_sleep() -> void:
	if not GameState.ate_this_cycle:
		UIMessage.show_text(not_ate_message)
		return

	_is_sleeping = true

	var old_cycle := GameState.cycle
	GameState.next_cycle()
	var new_cycle := GameState.cycle

	UIMessage.show_text(sleep_message_template % [old_cycle, new_cycle])
	
	if next_level_scene == null:
		push_warning("Bed: не назначена следующая сцена")
		_is_sleeping = false
		return

	# Плавная смена сцены: затемнение -> звук -> смена -> звук -> проявление
	var tree := get_tree()
	await UIMessage.fade_out(0.5)
	# Даем игроку секунду прочитать сообщение уже на затемнении
	await tree.create_timer(1.0).timeout
	if sleep_sound:
		_audio_player.stream = sleep_sound
		_audio_player.play()
	
	tree.change_scene_to_packed(next_level_scene)
	await tree.process_frame
	
	if wake_sound:
		_audio_player.stream = wake_sound
		_audio_player.play()
	
	await UIMessage.fade_in(0.5)
	_is_sleeping = false
	
	
