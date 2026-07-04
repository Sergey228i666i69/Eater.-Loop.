class_name FridgeFeedingSession
extends RefCounted

const FeedingMinigameScript := preload("res://levels/minigames/feeding/feed_minigame.gd")

static func can_start(selected_scene: PackedScene, food_scenes: Array[PackedScene]) -> bool:
	return selected_scene != null and not food_scenes.is_empty()

static func create_game(selected_scene: PackedScene) -> FeedingMinigameScript:
	if selected_scene == null:
		return null
	var instance := selected_scene.instantiate()
	var game := instance as FeedingMinigameScript
	if game == null:
		if instance != null:
			instance.free()
		return null
	return game

static func has_finish_signal(game: FeedingMinigameScript) -> bool:
	return game != null

static func configure_game(
	game: FeedingMinigameScript,
	andrey_face: Texture2D,
	food_count: int,
	bg_music: AudioStream,
	win_sound: AudioStream,
	eat_sound: AudioStream,
	background_texture: Texture2D,
	food_scenes: Array[PackedScene]
) -> void:
	if game == null:
		return
	game.setup_game(andrey_face, food_count, bg_music, win_sound, eat_sound, background_texture, food_scenes)
