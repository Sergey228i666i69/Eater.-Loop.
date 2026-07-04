extends "res://tests/test_case.gd"

class FridgeProbe:
	extends "res://objects/interactable/fridge/fridge.gd"

	var feeding_started: bool = false

	func _is_chase_active() -> bool:
		return true

	func _start_feeding_process() -> void:
		feeding_started = true

class TeleportFridgeProbe:
	extends "res://objects/interactable/fridge/fridge.gd"

	var chase_cleared: bool = false

	func _clear_chase_after_teleport_success() -> void:
		chase_cleared = true

class LegacyCodeLockProbe:
	extends Node

	var target_code: String = ""

class FeedingGameProbe:
	extends "res://levels/minigames/feeding/feed_minigame.gd"

	var setup_called: bool = false
	var received_food_count: int = 0
	var received_food_scenes: Array[PackedScene] = []

	func setup_game(_andrey_face: Texture2D, food_count: int, _bg_music: AudioStream, _win_sound: AudioStream, _eat_sound: AudioStream = null, _background_texture: Texture2D = null, food_scenes: Array[PackedScene] = []) -> void:
		setup_called = true
		received_food_count = food_count
		received_food_scenes = food_scenes

class CycleStateProbe:
	extends RefCounted

	var ate_marked: bool = false
	var fridge_marked: bool = false

	func mark_ate() -> void:
		ate_marked = true

	func mark_fridge_interacted() -> void:
		fridge_marked = true

class SaveProbe:
	extends RefCounted

	var checkpoint_scene: Node = null
	var checkpoint_calls: int = 0
	var autosave_calls: int = 0

	func capture_fridge_checkpoint(scene: Node) -> void:
		checkpoint_scene = scene
		checkpoint_calls += 1

	func autosave_run() -> void:
		autosave_calls += 1

class EnemyProbe:
	extends Node

	var chase_stopped: bool = false

	func force_stop_chase() -> void:
		chase_stopped = true

class MusicProbe:
	extends RefCounted

	var clear_calls: int = 0
	var last_fade_time: float = -1.0

	func clear_chase_music_sources(fade_time: float) -> void:
		clear_calls += 1
		last_fade_time = fade_time

const FridgeScript := preload("res://objects/interactable/fridge/fridge.gd")
const FridgeCodeLockSessionScript := preload("res://objects/interactable/fridge/fridge_code_lock_session.gd")
const FridgeFeedingSessionScript := preload("res://objects/interactable/fridge/fridge_feeding_session.gd")
const FridgeCompletionSessionScript := preload("res://objects/interactable/fridge/fridge_completion_session.gd")
const CODE_LOCK_SCENE := preload("res://levels/minigames/ui/code_lock.tscn")
const FEEDING_SCENE := preload("res://levels/minigames/feeding/feed_minigame.tscn")
const FOOD_SCENE := preload("res://levels/minigames/feeding/food/fish/food_fish.tscn")

func run() -> Array[String]:
	_test_fridge_is_not_blocked_during_chase()
	_test_teleport_fridge_clears_chase_state()
	_test_misconfigured_fridge_does_not_grant_food()
	_test_invalid_feeding_scene_does_not_grant_food()
	_test_code_lock_session_applies_access_code()
	_test_feeding_session_configures_game()
	_test_completion_session_marks_cycle_state()
	_test_completion_session_clears_chase_hooks()
	_test_completion_session_teleports_player_to_marker()
	_test_completion_session_saves_checkpoint_or_autosave()
	return get_failures()

func _test_fridge_is_not_blocked_during_chase() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return

	CycleState.reset_cycle_state()

	var fridge := FridgeProbe.new()
	fridge.require_access_code = false
	fridge.require_lab_completion = false
	fridge.call("_on_interact")
	
	assert_true(fridge.feeding_started, "Fridge interaction should proceed even if chase is active")
	fridge.free()

func _test_teleport_fridge_clears_chase_state() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return

	CycleState.reset_cycle_state()

	var fridge := TeleportFridgeProbe.new()
	fridge.enable_teleport = true
	fridge.call("_finish_feeding_logic")

	assert_true(fridge.chase_cleared, "Teleporting fridge must stop chase state after successful feeding")
	fridge.free()

func _test_misconfigured_fridge_does_not_grant_food() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return
	CycleState.reset_cycle_state()
	var fridge := FridgeScript.new()
	fridge.minigame_scene = null
	fridge.food_scenes = []
	fridge.call("_start_feeding_process")
	assert_true(not bool(CycleState.has_eaten_this_cycle()), "Misconfigured fridge must fail closed instead of marking food as eaten")
	fridge.free()
	CycleState.reset_cycle_state()

func _test_invalid_feeding_scene_does_not_grant_food() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return
	CycleState.reset_cycle_state()

	var invalid_root := Node.new()
	var invalid_scene := PackedScene.new()
	assert_eq(invalid_scene.pack(invalid_root), OK, "Invalid feeding test scene must pack")
	invalid_root.free()

	var food_scenes: Array[PackedScene] = [FOOD_SCENE]
	var fridge := FridgeScript.new()
	fridge.unique_intro_once_per_run = false
	fridge.minigame_scene = invalid_scene
	fridge.food_scenes = food_scenes
	fridge.call("_start_feeding_process")
	assert_true(not bool(CycleState.has_eaten_this_cycle()), "Invalid feeding scene must fail closed instead of marking food as eaten")
	assert_true(not fridge.is_completed, "Invalid feeding scene must not complete the fridge interaction")
	fridge.free()
	CycleState.reset_cycle_state()

func _test_code_lock_session_applies_access_code() -> void:
	var lock_instance: Node = FridgeCodeLockSessionScript.create_lock_instance(CODE_LOCK_SCENE, "2718")
	assert_true(lock_instance != null, "Fridge code-lock helper must instantiate the configured scene")
	if lock_instance != null:
		assert_eq(str(lock_instance.get("code_value")), "2718", "Fridge code-lock helper must configure current code_value contract")
		lock_instance.free()

	var legacy_lock := LegacyCodeLockProbe.new()
	FridgeCodeLockSessionScript.apply_access_code(legacy_lock, "3141")
	assert_eq(legacy_lock.target_code, "3141", "Fridge code-lock helper must keep the legacy target_code fallback")
	legacy_lock.free()

func _test_feeding_session_configures_game() -> void:
	var food_scenes: Array[PackedScene] = [FOOD_SCENE]
	var empty_food_scenes: Array[PackedScene] = []
	assert_true(FridgeFeedingSessionScript.can_start(FEEDING_SCENE, food_scenes), "Feeding helper should allow non-empty scene and food config")
	assert_true(not FridgeFeedingSessionScript.can_start(null, food_scenes), "Feeding helper must reject missing minigame scene")
	assert_true(not FridgeFeedingSessionScript.can_start(FEEDING_SCENE, empty_food_scenes), "Feeding helper must reject missing food scenes")

	var game := FeedingGameProbe.new()
	assert_true(FridgeFeedingSessionScript.has_finish_signal(game), "Feeding helper must recognize minigame_finished signal")
	FridgeFeedingSessionScript.configure_game(game, null, 7, null, null, null, null, food_scenes)
	assert_true(game.setup_called, "Feeding helper must call setup_game when supported")
	assert_eq(game.received_food_count, 7, "Feeding helper must pass food_count into setup_game")
	assert_eq(game.received_food_scenes.size(), 1, "Feeding helper must pass food_scenes into setup_game")
	game.free()

func _test_completion_session_marks_cycle_state() -> void:
	var cycle_state := CycleStateProbe.new()
	FridgeCompletionSessionScript.mark_cycle_feeding_completed(cycle_state)
	assert_true(cycle_state.ate_marked, "Completion helper must mark the cycle as fed")
	assert_true(cycle_state.fridge_marked, "Completion helper must mark fridge interaction in cycle state")

func _test_completion_session_clears_chase_hooks() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is required for chase cleanup test")
	if tree == null:
		return

	var enemy := EnemyProbe.new()
	enemy.add_to_group("enemies")
	tree.root.add_child(enemy)
	var music := MusicProbe.new()
	FridgeCompletionSessionScript.clear_chase_after_teleport_success(tree, music)
	assert_true(enemy.chase_stopped, "Completion helper must stop active enemy chase before teleport")
	assert_eq(music.clear_calls, 1, "Completion helper must clear chase music sources")
	assert_true(absf(music.last_fade_time - 0.2) < 0.001, "Completion helper must keep the chase music fade policy")
	enemy.free()

func _test_completion_session_teleports_player_to_marker() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is required for teleport test")
	if tree == null:
		return

	var root := Node2D.new()
	var fridge := Node2D.new()
	var marker := Marker2D.new()
	var player := Node2D.new()
	root.name = "FridgeCompletionSessionTeleportTest"
	fridge.name = "Fridge"
	marker.name = "FridgeMarker"
	player.name = "PlayerProbe"
	player.add_to_group("player")
	tree.root.add_child(root)
	root.add_child(fridge)
	fridge.add_child(marker)
	root.add_child(player)

	marker.global_position = Vector2(42.0, 21.0)
	player.global_position = Vector2.ZERO
	var moved: bool = FridgeCompletionSessionScript.teleport_player_if_needed(fridge, true, NodePath("FridgeMarker"))
	assert_true(moved, "Completion helper must report a successful teleport")
	assert_eq(player.global_position, marker.global_position, "Completion helper must move the player to the configured marker")
	root.free()

func _test_completion_session_saves_checkpoint_or_autosave() -> void:
	var save_probe := SaveProbe.new()
	var scene := Node.new()
	FridgeCompletionSessionScript.save_after_feeding(save_probe, scene)
	assert_eq(save_probe.checkpoint_calls, 1, "Completion helper must prefer fridge checkpoint capture when scene exists")
	assert_eq(save_probe.checkpoint_scene, scene, "Completion helper must pass current scene to fridge checkpoint capture")
	assert_eq(save_probe.autosave_calls, 0, "Completion helper must not autosave after a checkpoint capture")
	scene.free()

	var fallback_probe := SaveProbe.new()
	FridgeCompletionSessionScript.save_after_feeding(fallback_probe, null)
	assert_eq(fallback_probe.checkpoint_calls, 0, "Completion helper must not capture checkpoint without a current scene")
	assert_eq(fallback_probe.autosave_calls, 1, "Completion helper must autosave when no current scene is available")
