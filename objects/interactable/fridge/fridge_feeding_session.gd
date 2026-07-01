class_name FridgeFeedingSession
extends RefCounted

static func can_start(selected_scene: PackedScene, food_scenes: Array[PackedScene]) -> bool:
	return selected_scene != null and not food_scenes.is_empty()

static func create_game(selected_scene: PackedScene) -> Node:
	if selected_scene == null:
		return null
	return selected_scene.instantiate() as Node

static func has_finish_signal(game: Node) -> bool:
	return game != null and game.has_signal("minigame_finished")

static func configure_game(
	game: Node,
	andrey_face: Texture2D,
	food_count: int,
	bg_music: AudioStream,
	win_sound: AudioStream,
	eat_sound: AudioStream,
	background_texture: Texture2D,
	food_scenes: Array[PackedScene]
) -> void:
	if game == null or not game.has_method("setup_game"):
		return
	game.setup_game(andrey_face, food_count, bg_music, win_sound, eat_sound, background_texture, food_scenes)
