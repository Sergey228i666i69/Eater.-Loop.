extends "res://tests/test_case.gd"

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const LEGACY_PLAYER_SCENE_PATH := "res://player/LEGASY-ANIMATIONS-CHARACTER.tscn"
const PLAYER_RIG_SCENE_PATH := "res://player/player_skeleton_rig.tscn"
const LEVEL_DIR := "res://levels/cycles"
const FRONT_HAND_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand"
const EXPECTED_BONE_PATHS: Array[String] = [
	"Hips",
	"Hips/Spine",
	"Hips/Spine/Chest",
	"Hips/Spine/Chest/Neck",
	"Hips/Spine/Chest/Neck/Head",
	"Hips/Spine/Chest/BackUpperArm",
	"Hips/Spine/Chest/BackUpperArm/BackForearm",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand",
	"Hips/Spine/Chest/FrontUpperArm",
	"Hips/Spine/Chest/FrontUpperArm/FrontForearm",
	FRONT_HAND_PATH,
	FRONT_HAND_PATH + "/FlashlightMount",
	"Hips/BackThigh",
	"Hips/BackThigh/BackShin",
	"Hips/BackThigh/BackShin/BackFoot",
	"Hips/FrontThigh",
	"Hips/FrontThigh/FrontShin",
	"Hips/FrontThigh/FrontShin/FrontFoot",
]

func run() -> Array[String]:
	_test_rig_scene_contract()
	_test_legacy_player_keeps_sprite_sequence()
	_test_levels_keep_active_player_scene()
	await _test_player_scene_mounts_and_mirrors_rig()
	return get_failures()

func _test_rig_scene_contract() -> void:
	var rig_scene := assert_loads(PLAYER_RIG_SCENE_PATH) as PackedScene
	assert_true(rig_scene != null, "Player skeleton rig scene failed to load")
	if rig_scene == null:
		return

	var rig := rig_scene.instantiate()
	assert_true(rig is Node2D, "Player skeleton rig root must be Node2D")
	var skeleton := rig.get_node_or_null("Skeleton2D")
	assert_true(skeleton is Skeleton2D, "Player skeleton rig must keep Skeleton2D child")
	if skeleton != null:
		for bone_path in EXPECTED_BONE_PATHS:
			assert_true(skeleton.get_node_or_null(bone_path) is Bone2D, "Player skeleton rig must keep Bone2D: %s" % bone_path)
	var animation_player := rig.get_node_or_null("SkeletonAnimationPlayer") as AnimationPlayer
	assert_true(animation_player != null, "Player skeleton rig must keep SkeletonAnimationPlayer")
	if animation_player != null:
		for animation_name in [&"idle", &"walk", &"light_run"]:
			assert_true(animation_player.has_animation(animation_name), "Player skeleton rig must keep %s animation" % animation_name)
			var animation := animation_player.get_animation(animation_name)
			assert_true(animation != null, "Player skeleton animation must load: %s" % animation_name)
			if animation != null:
				assert_true(animation.loop_mode == Animation.LOOP_LINEAR, "Player skeleton animation must loop: %s" % animation_name)
				assert_true(animation.get_track_count() > 0, "Player skeleton animation must animate at least one bone: %s" % animation_name)
	var visual_nodes := rig.find_children("Visual*", "", true, false)
	assert_true(visual_nodes.size() >= 12, "Player skeleton rig must include visible bone-driven body parts")
	rig.free()

func _test_legacy_player_keeps_sprite_sequence() -> void:
	var legacy_scene := assert_loads(LEGACY_PLAYER_SCENE_PATH) as PackedScene
	assert_true(legacy_scene != null, "Legacy player scene failed to load")
	if legacy_scene == null:
		return
	var legacy_player := legacy_scene.instantiate()
	assert_true(legacy_player.get_node_or_null("AnimatedSprite2D") is AnimatedSprite2D, "Legacy player must keep old AnimatedSprite2D sequence")
	legacy_player.free()

func _test_levels_keep_active_player_scene() -> void:
	for path in utils.list_files(LEVEL_DIR, ".tscn", ["tests", ".godot", "addons"], ["archive", "trash"]):
		var content := FileAccess.get_file_as_string(path)
		if content.find("res://player/") == -1:
			continue
		assert_true(content.find(LEGACY_PLAYER_SCENE_PATH) == -1, "Levels must not use legacy player scene: %s" % path)
		assert_true(content.find(PLAYER_SCENE_PATH) != -1, "Levels with player references must use active skeleton player scene: %s" % path)

func _test_player_scene_mounts_and_mirrors_rig() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var player_scene := assert_loads(PLAYER_SCENE_PATH) as PackedScene
	assert_true(player_scene != null, "Player scene failed to load")
	if player_scene == null:
		return

	var root := Node2D.new()
	tree.root.add_child(root)
	var player := player_scene.instantiate()
	root.add_child(player)
	await tree.process_frame

	var rig := player.get_node_or_null("PlayerSkeletonRig") as Node2D
	assert_true(player.get_node_or_null("AnimatedSprite2D") == null, "Active player must not keep legacy AnimatedSprite2D")
	assert_true(rig != null, "Player must mount PlayerSkeletonRig")
	assert_true(player.get_node_or_null("StepAudioComponent") is StepAudioComponent, "Active skeleton player must keep step audio component")
	if rig != null:
		var animation_player := rig.get_node_or_null("SkeletonAnimationPlayer") as AnimationPlayer
		assert_true(animation_player != null, "Mounted PlayerSkeletonRig must keep SkeletonAnimationPlayer")
		if animation_player != null:
			assert_eq(animation_player.current_animation, "idle", "Player skeleton animation must start from idle")
		assert_eq(rig.position, Vector2(-5.375, 83.37938), "PlayerSkeletonRig must keep the old player visual anchor")
		assert_true(_almost_eq(absf(rig.scale.x), 0.44800887), "PlayerSkeletonRig x-scale must keep the old player visual scale")
		assert_true(_almost_eq(rig.scale.y, 0.44800875), "PlayerSkeletonRig y-scale must keep the old player visual scale")
		player.call("apply_checkpoint_state", {"facing_dir": -1.0})
		assert_true(rig.scale.x < 0.0, "PlayerSkeletonRig must mirror with the player facing direction")
		player.call("_update_walk_animation", 0.016, 1.0)
		assert_eq(animation_player.current_animation, "walk", "Player skeleton animation must switch to walk while moving")
		player.set("_is_running", true)
		player.call("_update_walk_animation", 0.016, 1.0)
		assert_eq(animation_player.current_animation, "light_run", "Player skeleton animation must switch to light_run while running")
		player.set("_is_running", false)
		player.call("_update_walk_animation", 0.016, 0.0)
		assert_eq(animation_player.current_animation, "idle", "Player skeleton animation must return to idle when stopped")

	root.queue_free()
	await tree.process_frame

func _almost_eq(left: float, right: float, epsilon: float = 0.0001) -> bool:
	return absf(left - right) <= epsilon
