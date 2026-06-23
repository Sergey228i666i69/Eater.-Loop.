extends "res://tests/test_case.gd"

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const LEGACY_PLAYER_SCENE_PATH := "res://player/LEGASY-ANIMATIONS-CHARACTER.tscn"
const PLAYER_RIG_SCENE_PATH := "res://player/player_skeleton_rig.tscn"
const LEVEL_DIR := "res://levels/cycles"
const FRONT_HAND_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand"
const FLASHLIGHT_VISUAL_PATH := FRONT_HAND_PATH + "/FlashlightMount/VisualFlashlight"
const FOOT_VISUAL_PATHS: Array[String] = [
	"Hips/BackThigh/BackShin/BackFoot/VisualBackFoot",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
]
const WALK_CONTACT_TIMES: Array[float] = [0.2, 0.6]
const WALK_SAMPLE_TIMES: Array[float] = [0.0, 0.2, 0.4, 0.6]
const LIGHT_RUN_CONTACT_TIMES: Array[float] = [0.1375, 0.4125]
const LIGHT_RUN_SAMPLE_TIMES: Array[float] = [0.0, 0.1375, 0.275, 0.4125]
const FOOT_CONTACT_GROUND_TOLERANCE := 12.0
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
const EXPECTED_CUTOUT_VISUAL_PATHS: Array[String] = [
	"Hips/Spine/Chest/Neck/Head/VisualHead",
	"Hips/Spine/Chest/VisualTorso",
	"Hips/VisualPelvis",
	"Hips/Spine/Chest/BackUpperArm/VisualBackUpperArm",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackForearm",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand",
	"Hips/Spine/Chest/FrontUpperArm/VisualFrontUpperArm",
	"Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontForearm",
	FRONT_HAND_PATH + "/VisualFrontHand",
	FLASHLIGHT_VISUAL_PATH,
	"Hips/BackThigh/VisualBackThigh",
	"Hips/BackThigh/BackShin/VisualBackShin",
	"Hips/BackThigh/BackShin/BackFoot/VisualBackFoot",
	"Hips/FrontThigh/VisualFrontThigh",
	"Hips/FrontThigh/FrontShin/VisualFrontShin",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
]
var _opaque_texture_points: Dictionary = {}

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
				_assert_animation_tracks_use_cubic_interpolation(animation, String(animation_name))
		if skeleton != null:
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"walk", WALK_CONTACT_TIMES, WALK_SAMPLE_TIMES)
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"light_run", LIGHT_RUN_CONTACT_TIMES, LIGHT_RUN_SAMPLE_TIMES)
	if skeleton != null:
		for visual_path in EXPECTED_CUTOUT_VISUAL_PATHS:
			var visual := skeleton.get_node_or_null(visual_path) as Sprite2D
			assert_true(visual != null, "Player skeleton rig must keep Sprite2D cutout visual: %s" % visual_path)
			if visual != null:
				assert_true(visual.texture != null, "Player skeleton cutout visual must keep texture: %s" % visual_path)
				if visual.texture != null:
					assert_true(String(visual.texture.resource_path).begins_with("res://player/skeleton/cutouts/"), "Player skeleton visual must use Andry cutout texture: %s" % visual_path)
	rig.free()

func _test_legacy_player_keeps_sprite_sequence() -> void:
	var legacy_scene := assert_loads(LEGACY_PLAYER_SCENE_PATH) as PackedScene
	assert_true(legacy_scene != null, "Legacy player scene failed to load")
	if legacy_scene == null:
		return
	var legacy_player := legacy_scene.instantiate()
	assert_true(legacy_player.get_node_or_null("AnimatedSprite2D") is AnimatedSprite2D, "Legacy player must keep old AnimatedSprite2D sequence")
	assert_true(legacy_player.get_node_or_null("PlayerSkeletonRig") == null, "Legacy player must stay sprite-only and must not mount the new skeleton rig")
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
	if GameState != null and GameState.has_method("reset_run"):
		GameState.reset_run()
	if CycleState != null and CycleState.has_method("reset_cycle_state"):
		CycleState.reset_cycle_state()
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
		var flashlight_visual := rig.get_node_or_null("Skeleton2D/" + FLASHLIGHT_VISUAL_PATH) as Sprite2D
		assert_true(flashlight_visual != null, "Player skeleton must keep optional flashlight cutout")
		if flashlight_visual != null:
			assert_true(not flashlight_visual.visible, "Player skeleton flashlight cutout must be hidden before flashlight unlock")
		if CycleState != null and CycleState.has_method("collect_flashlight_for_cycle"):
			CycleState.collect_flashlight_for_cycle()
			player.call("_update_skeleton_flashlight_visibility")
			if flashlight_visual != null:
				assert_true(flashlight_visual.visible, "Player skeleton flashlight cutout must appear after flashlight unlock")
		player.call("apply_checkpoint_state", {"facing_dir": -1.0})
		assert_true(rig.scale.x < 0.0, "PlayerSkeletonRig must mirror with the player facing direction")
		if animation_player != null:
			player.call("_update_walk_animation", 0.016, 1.0)
			assert_eq(animation_player.current_animation, "walk", "Player skeleton animation must switch to walk while moving")
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "walk", 0.0, 0.19, 0.21)
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "walk", 0.4, 0.59, 0.61)
			player.set("_is_running", true)
			player.call("_update_walk_animation", 0.016, 1.0)
			assert_eq(animation_player.current_animation, "light_run", "Player skeleton animation must switch to light_run while running")
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "light_run", 0.0, 0.13, 0.145)
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "light_run", 0.275, 0.405, 0.42)
			player.set("_is_running", false)
			player.call("_update_walk_animation", 0.016, 0.0)
			assert_eq(animation_player.current_animation, "idle", "Player skeleton animation must return to idle when stopped")

	root.queue_free()
	await tree.process_frame

func _almost_eq(left: float, right: float, epsilon: float = 0.0001) -> bool:
	return absf(left - right) <= epsilon

func _assert_animation_tracks_use_cubic_interpolation(animation: Animation, animation_name: String) -> void:
	for track_index in range(animation.get_track_count()):
		assert_eq(
			animation.track_get_interpolation_type(track_index),
			Animation.INTERPOLATION_CUBIC,
			"Player skeleton animation %s track %d must use cubic interpolation for smoother bone motion" % [animation_name, track_index]
		)

func _assert_skeleton_steps_follow_contact_times(player: Node, animation_player: AnimationPlayer, animation_name: String, start_position: float, before_contact: float, after_contact: float) -> void:
	var step_audio := player.get_node_or_null("StepAudioComponent") as StepAudioComponent
	assert_true(step_audio != null, "Player must keep StepAudioComponent for skeleton contact sounds")
	if step_audio == null:
		return
	var events: Array[StringName] = []
	step_audio.step_triggered.connect(func(_frame_index: int, source_animation: StringName) -> void:
		events.append(source_animation)
	)
	step_audio.step_sounds = []
	animation_player.seek(start_position, true)
	player.call("_update_skeleton_step_audio", true)
	animation_player.seek(before_contact, true)
	player.call("_update_skeleton_step_audio", true)
	assert_eq(events.size(), 0, "Skeleton step sound must not fire before foot contact in %s" % animation_name)
	animation_player.seek(after_contact, true)
	player.call("_update_skeleton_step_audio", true)
	assert_eq(events.size(), 1, "Skeleton step sound must fire exactly when crossing foot contact in %s" % animation_name)
	assert_eq(events[0], StringName(animation_name), "Skeleton step sound must report source animation")

func _assert_foot_contact_keys_reach_ground(
		skeleton: Node,
		animation_player: AnimationPlayer,
		animation_name: StringName,
		contact_times: Array[float],
		sample_times: Array[float]
) -> void:
	var ground_y := -INF
	for sample_time in sample_times:
		animation_player.play(animation_name)
		animation_player.seek(sample_time, true)
		ground_y = maxf(ground_y, _lowest_foot_opaque_pixel_y(skeleton))
	for contact_time in contact_times:
		animation_player.play(animation_name)
		animation_player.seek(contact_time, true)
		var contact_y := _lowest_foot_opaque_pixel_y(skeleton)
		assert_true(
			ground_y - contact_y <= FOOT_CONTACT_GROUND_TOLERANCE,
			"Skeleton %s footstep key %.4f must keep a foot visually on the floor" % [animation_name, contact_time]
		)

func _lowest_foot_opaque_pixel_y(skeleton: Node) -> float:
	var lowest_y := -INF
	for foot_path in FOOT_VISUAL_PATHS:
		var foot := skeleton.get_node_or_null(foot_path) as Sprite2D
		assert_true(foot != null, "Player skeleton must keep foot visual for contact test: %s" % foot_path)
		if foot == null or foot.texture == null:
			continue
		var transform := foot.get_global_transform()
		for local_point in _get_opaque_texture_points(foot.texture):
			var visual_point := local_point + foot.offset
			var global_point := transform * visual_point
			lowest_y = maxf(lowest_y, global_point.y)
	return lowest_y

func _get_opaque_texture_points(texture: Texture2D) -> Array[Vector2]:
	var cache_key := String(texture.resource_path)
	if _opaque_texture_points.has(cache_key):
		return _opaque_texture_points[cache_key]
	var points: Array[Vector2] = []
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton foot texture must expose alpha pixels: %s" % cache_key)
	if image == null:
		_opaque_texture_points[cache_key] = points
		return points
	var size := Vector2(image.get_width(), image.get_height())
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			points.append(Vector2(float(x) + 0.5, float(y) + 0.5) - size * 0.5)
	_opaque_texture_points[cache_key] = points
	return points
