extends "res://tests/test_case.gd"

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const LEGACY_PLAYER_SCENE_PATH := "res://player/LEGASY-ANIMATIONS-CHARACTER.tscn"
const PLAYER_RIG_SCENE_PATH := "res://player/player_skeleton_rig.tscn"
const LEVEL_DIR := "res://levels/cycles"
const FRONT_HAND_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand"
const HEAD_VISUAL_PATH := "Hips/Spine/Chest/Neck/Head/VisualHead"
const TORSO_VISUAL_PATH := "Hips/Spine/Chest/VisualTorso"
const NECK_COLLAR_VISUAL_PATH := "Hips/Spine/Chest/VisualNeckCollarCover"
const PELVIS_VISUAL_PATH := "Hips/VisualPelvis"
const FRONT_UPPER_ARM_VISUAL_PATH := "Hips/Spine/Chest/FrontUpperArm/VisualFrontUpperArm"
const FRONT_FOREARM_VISUAL_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontForearm"
const FRONT_HAND_VISUAL_PATH := FRONT_HAND_PATH + "/VisualFrontHand"
const FLASHLIGHT_VISUAL_PATH := FRONT_HAND_PATH + "/FlashlightMount/VisualFlashlight"
const FOOT_VISUAL_PATHS: Array[String] = [
	"Hips/BackThigh/BackShin/BackFoot/VisualBackFoot",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
]
const CLEANED_ARM_CUTOUT_VISUAL_PATHS: Array[String] = [
	"Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackForearm",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand",
	"Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontForearm",
	FRONT_HAND_VISUAL_PATH,
]
const CLEANED_LOWER_BODY_CUTOUT_VISUAL_PATHS: Array[String] = [
	"Hips/VisualPelvis",
	"Hips/BackThigh/VisualBackThigh",
	"Hips/BackThigh/BackShin/VisualBackShin",
	"Hips/FrontThigh/VisualFrontThigh",
	"Hips/FrontThigh/FrontShin/VisualFrontShin",
]
const CLEANED_SEAM_FILL_VISUAL_PATH := "Hips/VisualSeamFill"
const CLEANED_PELVIS_VISUAL_PATH := "Hips/VisualPelvis"
const CLEANED_FRONT_THIGH_VISUAL_PATH := "Hips/FrontThigh/VisualFrontThigh"
const CLEANED_BACK_THIGH_VISUAL_PATH := "Hips/BackThigh/VisualBackThigh"
const CLEANED_FRONT_SHIN_VISUAL_PATH := "Hips/FrontThigh/FrontShin/VisualFrontShin"
const CLEANED_BACK_SHIN_VISUAL_PATH := "Hips/BackThigh/BackShin/VisualBackShin"
const CLEANED_FRONT_HAND_VISUAL_PATH := FRONT_HAND_VISUAL_PATH
const CLEANED_BACK_HAND_VISUAL_PATH := "Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand"
const SAFE_ALPHA_MARGIN_VISUAL_PATHS: Array[String] = [
	HEAD_VISUAL_PATH,
	CLEANED_FRONT_HAND_VISUAL_PATH,
	CLEANED_BACK_HAND_VISUAL_PATH,
]
const SINGLE_ALPHA_COMPONENT_VISUAL_PATHS: Array[String] = [
	TORSO_VISUAL_PATH,
	CLEANED_PELVIS_VISUAL_PATH,
	CLEANED_SEAM_FILL_VISUAL_PATH,
	"Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackForearm",
	FRONT_FOREARM_VISUAL_PATH,
	CLEANED_FRONT_THIGH_VISUAL_PATH,
	CLEANED_FRONT_SHIN_VISUAL_PATH,
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
]
const SEAM_FILL_MAX_INTERNAL_WIDTH := 52
const SEAM_FILL_MIN_INTERNAL_X := 88
const SEAM_FILL_MAX_INTERNAL_X := 136
const SEAM_FILL_MAX_INTERNAL_Y := 330
const CUTOUT_MIN_SAFE_ALPHA_MARGIN := 6
const HEAD_MAX_LOWER_LEFT_SHOULDER_PIXELS := 20
const HEAD_MIN_UPPER_RIGHT_HAIR_PIXELS := 680
const NECK_COLLAR_MAX_TEXTURE_SIZE := Vector2i(96, 88)
const NECK_COLLAR_MIN_TRANSPARENT_RATIO := 0.15
const NECK_COLLAR_MIN_LOCAL_X := -24.0
const NECK_COLLAR_MAX_LOCAL_X := 0.0
const NECK_COLLAR_MIN_LOCAL_Y := -108.0
const NECK_COLLAR_MAX_LOCAL_Y := -84.0
const THIGH_MOVING_WAISTBAND_CLEAR_ROWS := 20
const FLASHLIGHT_HANDLE_GAP_X_RANGE := Vector2i(22, 62)
const FLASHLIGHT_HANDLE_GAP_Y_RANGE := Vector2i(25, 34)
const FLASHLIGHT_MIN_FILLED_GAP_COLUMNS := 32
const FLASHLIGHT_GRIP_MIN_LOCAL_X := -4.0
const FLASHLIGHT_GRIP_MAX_LOCAL_X := 2.0
const FLASHLIGHT_GRIP_MIN_LOCAL_Y_OFFSET := 6.0
const FLASHLIGHT_GRIP_MAX_LOCAL_Y_OFFSET := 12.0
const FRONT_FOREARM_SOFT_TOP_CLEAR_ROWS := 11
const FRONT_FOREARM_SOFT_TOP_SAMPLE_ROW := 20
const FRONT_FOREARM_SOFT_TOP_MAX_ALPHA := 0.45
const WALK_CONTACT_TIMES: Array[float] = [0.2, 0.6]
const WALK_SAMPLE_TIMES: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
const LIGHT_RUN_CONTACT_TIMES: Array[float] = [0.1375, 0.4125]
const LIGHT_RUN_SAMPLE_TIMES: Array[float] = [0.0, 0.06875, 0.1375, 0.20625, 0.275, 0.34375, 0.4125, 0.48125]
const FOOT_CONTACT_GROUND_TOLERANCE := 12.0
const IDLE_MIN_HAND_BREATH_RANGE := 0.009
const IDLE_MAX_HAND_BREATH_RANGE := 0.02
const WALK_MIN_LEG_SWING_RANGE := 0.08
const WALK_MAX_LEG_SWING_RANGE := 0.12
const WALK_MIN_ARM_SWING_RANGE := 0.035
const WALK_MAX_ARM_SWING_RANGE := 0.06
const WALK_MIN_SPINE_SWAY_RANGE := 0.03
const WALK_MAX_SPINE_SWAY_RANGE := 0.04
const WALK_MIN_NECK_COUNTER_RANGE := 0.018
const WALK_MAX_NECK_COUNTER_RANGE := 0.03
const LIGHT_RUN_MIN_LEG_SWING_RANGE := 0.13
const LIGHT_RUN_MAX_LEG_SWING_RANGE := 0.17
const LIGHT_RUN_MIN_ARM_SWING_RANGE := 0.06
const LIGHT_RUN_MAX_ARM_SWING_RANGE := 0.09
const LIGHT_RUN_MIN_NECK_COUNTER_RANGE := 0.025
const LIGHT_RUN_MAX_NECK_COUNTER_RANGE := 0.035
const WALK_MIN_FOOT_LIFT_RANGE := 6.0
const WALK_MAX_FOOT_LIFT_RANGE := 10.0
const WALK_MIN_FOOT_ROLL_RANGE := 0.075
const WALK_MAX_FOOT_ROLL_RANGE := 0.09
const LIGHT_RUN_MIN_FOOT_LIFT_RANGE := 9.0
const LIGHT_RUN_MAX_FOOT_LIFT_RANGE := 12.0
const LIGHT_RUN_MIN_FOOT_ROLL_RANGE := 0.12
const LIGHT_RUN_MAX_FOOT_ROLL_RANGE := 0.14
const LIGHT_RUN_MIN_FRONT_FOOT_STRIDE_RANGE := 5.5
const LIGHT_RUN_MAX_FRONT_FOOT_STRIDE_RANGE := 6.5
const LIGHT_RUN_MIN_BACK_FOOT_STRIDE_RANGE := 3.5
const LIGHT_RUN_MAX_BACK_FOOT_STRIDE_RANGE := 4.5
const WALK_MIN_WRIST_SWING_RANGE := 0.03
const WALK_MAX_WRIST_SWING_RANGE := 0.05
const LIGHT_RUN_MIN_WRIST_SWING_RANGE := 0.05
const LIGHT_RUN_MAX_WRIST_SWING_RANGE := 0.07
const FRONT_THIGH_ROTATION_TRACK := NodePath("Skeleton2D/Hips/FrontThigh:rotation")
const SPINE_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine:rotation")
const NECK_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/Neck:rotation")
const FRONT_UPPER_ARM_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm:rotation")
const FRONT_FOREARM_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm:rotation")
const BACK_FOREARM_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/BackUpperArm/BackForearm:rotation")
const FRONT_FOOT_POSITION_TRACK := NodePath("Skeleton2D/Hips/FrontThigh/FrontShin/FrontFoot:position")
const BACK_FOOT_POSITION_TRACK := NodePath("Skeleton2D/Hips/BackThigh/BackShin/BackFoot:position")
const FRONT_FOOT_ROTATION_TRACK := NodePath("Skeleton2D/Hips/FrontThigh/FrontShin/FrontFoot:rotation")
const BACK_FOOT_ROTATION_TRACK := NodePath("Skeleton2D/Hips/BackThigh/BackShin/BackFoot:rotation")
const FRONT_HAND_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand:rotation")
const BACK_HAND_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand:rotation")
const SOURCE_ANDRY_TEXTURE_SIZE := Vector2i(226, 774)
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
	HEAD_VISUAL_PATH,
	"Hips/Spine/Chest/VisualTorso",
	NECK_COLLAR_VISUAL_PATH,
	"Hips/VisualPelvis",
	"Hips/VisualSeamFill",
	"Hips/Spine/Chest/BackUpperArm/VisualBackUpperArm",
	"Hips/Spine/Chest/BackUpperArm/VisualBackShoulderCover",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackForearm",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackElbowCover",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand",
	"Hips/Spine/Chest/FrontUpperArm/VisualFrontUpperArm",
	"Hips/Spine/Chest/FrontUpperArm/VisualFrontShoulderCover",
	"Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontForearm",
	"Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontElbowCover",
	FRONT_HAND_PATH + "/VisualFrontHand",
	FLASHLIGHT_VISUAL_PATH,
	"Hips/BackThigh/VisualBackThigh",
	"Hips/BackThigh/BackShin/VisualBackShin",
	"Hips/BackThigh/BackShin/VisualBackKneeCover",
	"Hips/BackThigh/BackShin/BackFoot/VisualBackFoot",
	"Hips/BackThigh/BackShin/BackFoot/VisualBackAnkleCover",
	"Hips/FrontThigh/VisualFrontThigh",
	"Hips/FrontThigh/FrontShin/VisualFrontShin",
	"Hips/FrontThigh/FrontShin/VisualFrontKneeCover",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontAnkleCover",
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
				if animation_name == &"idle":
					_assert_animation_track_value_range(animation, FRONT_FOREARM_ROTATION_TRACK, IDLE_MIN_HAND_BREATH_RANGE, IDLE_MAX_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOREARM_ROTATION_TRACK, IDLE_MIN_HAND_BREATH_RANGE, IDLE_MAX_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, IDLE_MIN_HAND_BREATH_RANGE, IDLE_MAX_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, IDLE_MIN_HAND_BREATH_RANGE, IDLE_MAX_HAND_BREATH_RANGE, String(animation_name))
				elif animation_name == &"walk":
					_assert_animation_track_value_range(animation, FRONT_THIGH_ROTATION_TRACK, WALK_MIN_LEG_SWING_RANGE, WALK_MAX_LEG_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, SPINE_ROTATION_TRACK, WALK_MIN_SPINE_SWAY_RANGE, WALK_MAX_SPINE_SWAY_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, NECK_ROTATION_TRACK, WALK_MIN_NECK_COUNTER_RANGE, WALK_MAX_NECK_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, WALK_MIN_ARM_SWING_RANGE, WALK_MAX_ARM_SWING_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, FRONT_FOOT_POSITION_TRACK, WALK_MIN_FOOT_LIFT_RANGE, WALK_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, BACK_FOOT_POSITION_TRACK, WALK_MIN_FOOT_LIFT_RANGE, WALK_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOOT_ROTATION_TRACK, WALK_MIN_FOOT_ROLL_RANGE, WALK_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOOT_ROTATION_TRACK, WALK_MIN_FOOT_ROLL_RANGE, WALK_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, WALK_MIN_WRIST_SWING_RANGE, WALK_MAX_WRIST_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, WALK_MIN_WRIST_SWING_RANGE, WALK_MAX_WRIST_SWING_RANGE, String(animation_name))
				elif animation_name == &"light_run":
					_assert_animation_track_value_range(animation, FRONT_THIGH_ROTATION_TRACK, LIGHT_RUN_MIN_LEG_SWING_RANGE, LIGHT_RUN_MAX_LEG_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, NECK_ROTATION_TRACK, LIGHT_RUN_MIN_NECK_COUNTER_RANGE, LIGHT_RUN_MAX_NECK_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, LIGHT_RUN_MIN_ARM_SWING_RANGE, LIGHT_RUN_MAX_ARM_SWING_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FOOT_LIFT_RANGE, LIGHT_RUN_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FOOT_LIFT_RANGE, LIGHT_RUN_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_x_range(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FRONT_FOOT_STRIDE_RANGE, LIGHT_RUN_MAX_FRONT_FOOT_STRIDE_RANGE, String(animation_name))
					_assert_animation_vector2_x_range(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_BACK_FOOT_STRIDE_RANGE, LIGHT_RUN_MAX_BACK_FOOT_STRIDE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOOT_ROTATION_TRACK, LIGHT_RUN_MIN_FOOT_ROLL_RANGE, LIGHT_RUN_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOOT_ROTATION_TRACK, LIGHT_RUN_MIN_FOOT_ROLL_RANGE, LIGHT_RUN_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, LIGHT_RUN_MIN_WRIST_SWING_RANGE, LIGHT_RUN_MAX_WRIST_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, LIGHT_RUN_MIN_WRIST_SWING_RANGE, LIGHT_RUN_MAX_WRIST_SWING_RANGE, String(animation_name))
		if skeleton != null:
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"walk", WALK_CONTACT_TIMES, WALK_SAMPLE_TIMES)
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"light_run", LIGHT_RUN_CONTACT_TIMES, LIGHT_RUN_SAMPLE_TIMES)
	if skeleton != null:
		for visual_path in EXPECTED_CUTOUT_VISUAL_PATHS:
			var visual := skeleton.get_node_or_null(visual_path) as Sprite2D
			assert_true(visual != null, "Player skeleton rig must keep Sprite2D cutout visual: %s" % visual_path)
			if visual != null:
				assert_true(visual.texture != null, "Player skeleton cutout visual must keep texture: %s" % visual_path)
				assert_true(visual.z_index >= 0, "Player skeleton visual z-index must not fall behind level objects: %s" % visual_path)
				if visual.texture != null:
					assert_true(_is_player_skeleton_texture_path(String(visual.texture.resource_path)), "Player skeleton visual must use Andry cutout/cover texture: %s" % visual_path)
					assert_true(_is_tight_cutout_texture(visual.texture), "Player skeleton cutout texture must not keep the full Andry canvas: %s" % visual_path)
					if SAFE_ALPHA_MARGIN_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_safe_alpha_margin(visual.texture, visual_path, CUTOUT_MIN_SAFE_ALPHA_MARGIN)
					if visual_path == HEAD_VISUAL_PATH:
						_assert_head_cutout_keeps_source_head_shape(visual.texture, visual_path)
					if SINGLE_ALPHA_COMPONENT_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_single_alpha_component(visual.texture, visual_path)
					if visual_path == CLEANED_SEAM_FILL_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.70)
						_assert_seam_fill_is_internal_strip(visual.texture, visual_path)
					elif visual_path == CLEANED_PELVIS_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.45)
					elif visual_path == CLEANED_FRONT_THIGH_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.30)
						_assert_thigh_does_not_own_moving_waistband(visual.texture, visual_path)
					elif visual_path == CLEANED_BACK_THIGH_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.25)
						_assert_thigh_does_not_own_moving_waistband(visual.texture, visual_path)
					elif visual_path == CLEANED_FRONT_SHIN_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.32)
					elif visual_path == CLEANED_BACK_SHIN_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.24)
					elif visual_path == CLEANED_FRONT_HAND_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.62)
					elif visual_path == CLEANED_BACK_HAND_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.68)
					elif visual_path == FLASHLIGHT_VISUAL_PATH:
						_assert_flashlight_cutout_has_completed_handle(visual.texture, visual_path)
					elif visual_path == FRONT_FOREARM_VISUAL_PATH:
						_assert_front_forearm_has_soft_elbow_taper(visual.texture, visual_path)
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.25)
					elif CLEANED_ARM_CUTOUT_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.25)
					elif CLEANED_LOWER_BODY_CUTOUT_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_alpha_negative_space(visual.texture, visual_path, 0.23)
		var front_hand_visual := skeleton.get_node_or_null(FRONT_HAND_VISUAL_PATH) as Sprite2D
		var flashlight_visual := skeleton.get_node_or_null(FLASHLIGHT_VISUAL_PATH) as Sprite2D
		var torso_visual := skeleton.get_node_or_null(TORSO_VISUAL_PATH) as Sprite2D
		var neck_collar_visual := skeleton.get_node_or_null(NECK_COLLAR_VISUAL_PATH) as Sprite2D
		var head_visual := skeleton.get_node_or_null(HEAD_VISUAL_PATH) as Sprite2D
		var pelvis_visual := skeleton.get_node_or_null(PELVIS_VISUAL_PATH) as Sprite2D
		var front_upper_arm_visual := skeleton.get_node_or_null(FRONT_UPPER_ARM_VISUAL_PATH) as Sprite2D
		var front_forearm_visual := skeleton.get_node_or_null(FRONT_FOREARM_VISUAL_PATH) as Sprite2D
		assert_true(front_hand_visual != null, "Player skeleton must keep front hand visual for flashlight layering")
		assert_true(flashlight_visual != null, "Player skeleton must keep flashlight visual for layering")
		assert_true(torso_visual != null, "Player skeleton must keep torso visual for photo-cutout layering")
		assert_true(neck_collar_visual != null, "Player skeleton must keep neck/collar cover for head-torso seam")
		assert_true(head_visual != null, "Player skeleton must keep head visual for photo-cutout layering")
		assert_true(pelvis_visual != null, "Player skeleton must keep pelvis visual for photo-cutout layering")
		assert_true(front_upper_arm_visual != null, "Player skeleton must keep front upper arm visual for photo-cutout layering")
		assert_true(front_forearm_visual != null, "Player skeleton must keep front forearm visual for photo-cutout layering")
		if front_hand_visual != null and flashlight_visual != null:
			assert_true(flashlight_visual.z_index < front_hand_visual.z_index, "Player skeleton flashlight must render behind the gripping hand")
			_assert_flashlight_visual_sits_inside_front_grip(front_hand_visual, flashlight_visual)
		if torso_visual != null and front_upper_arm_visual != null:
			assert_true(torso_visual.z_index > front_upper_arm_visual.z_index, "Player skeleton torso must hide the front upper-arm photo seam")
		if torso_visual != null and front_forearm_visual != null:
			assert_true(front_forearm_visual.z_index > torso_visual.z_index, "Player skeleton front forearm must remain visible over the torso")
		if torso_visual != null and neck_collar_visual != null and head_visual != null:
			_assert_neck_collar_cover_sits_between_torso_and_head(torso_visual, neck_collar_visual, head_visual)
		if pelvis_visual != null and torso_visual != null:
			assert_true(pelvis_visual.z_index >= torso_visual.z_index, "Player skeleton pelvis must cover torso/lower-body seams")
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

func _is_tight_cutout_texture(texture: Texture2D) -> bool:
	return texture.get_width() < SOURCE_ANDRY_TEXTURE_SIZE.x and texture.get_height() < SOURCE_ANDRY_TEXTURE_SIZE.y

func _is_player_skeleton_texture_path(resource_path: String) -> bool:
	return (
			resource_path.begins_with("res://player/skeleton/cutouts/")
			or resource_path.begins_with("res://player/skeleton/covers/")
	)

func _assert_cutout_has_alpha_negative_space(texture: Texture2D, visual_path: String, min_transparent_ratio: float) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton cleaned cutout texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var transparent_pixels := 0
	var total_pixels := image.get_width() * image.get_height()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				transparent_pixels += 1
	assert_true(
			float(transparent_pixels) / float(total_pixels) >= min_transparent_ratio,
			"Player skeleton cleaned cutout must not keep a full opaque source rectangle: %s" % visual_path
	)

func _assert_cutout_has_safe_alpha_margin(texture: Texture2D, visual_path: String, min_margin: int) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton cutout texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	assert_true(max_x >= 0, "Player skeleton safe-margin cutout must contain visible pixels: %s" % visual_path)
	if max_x < 0:
		return
	assert_true(min_x >= min_margin, "Player skeleton cutout must keep left transparent margin: %s" % visual_path)
	assert_true(min_y >= min_margin, "Player skeleton cutout must keep top transparent margin: %s" % visual_path)
	assert_true(image.get_width() - max_x - 1 >= min_margin, "Player skeleton cutout must keep right transparent margin: %s" % visual_path)
	assert_true(image.get_height() - max_y - 1 >= min_margin, "Player skeleton cutout must keep bottom transparent margin: %s" % visual_path)

func _assert_head_cutout_keeps_source_head_shape(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton head cutout texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var lower_left_shoulder_pixels := 0
	for y in range(mini(100, image.get_height()), image.get_height()):
		for x in range(mini(35, image.get_width())):
			if image.get_pixel(x, y).a > 0.1:
				lower_left_shoulder_pixels += 1
	assert_true(
			lower_left_shoulder_pixels <= HEAD_MAX_LOWER_LEFT_SHOULDER_PIXELS,
			"Player skeleton head cutout must not carry the left shoulder/shirt corner: %s" % visual_path
	)

	var upper_right_hair_pixels := 0
	for y in range(mini(18, image.get_height()), mini(80, image.get_height())):
		for x in range(mini(112, image.get_width()), mini(141, image.get_width())):
			if image.get_pixel(x, y).a > 0.1:
				upper_right_hair_pixels += 1
	assert_true(
			upper_right_hair_pixels >= HEAD_MIN_UPPER_RIGHT_HAIR_PIXELS,
			"Player skeleton head cutout must keep Andry's rounded upper head instead of a diagonal crop: %s" % visual_path
	)

func _assert_neck_collar_cover_sits_between_torso_and_head(torso_visual: Sprite2D, neck_collar_visual: Sprite2D, head_visual: Sprite2D) -> void:
	assert_true(neck_collar_visual.texture != null, "Player skeleton neck/collar cover must keep a compact texture")
	if neck_collar_visual.texture != null:
		assert_true(
				neck_collar_visual.texture.get_width() <= NECK_COLLAR_MAX_TEXTURE_SIZE.x
						and neck_collar_visual.texture.get_height() <= NECK_COLLAR_MAX_TEXTURE_SIZE.y,
				"Player skeleton neck/collar cover must stay compact instead of duplicating the full torso"
		)
		_assert_cutout_has_alpha_negative_space(neck_collar_visual.texture, NECK_COLLAR_VISUAL_PATH, NECK_COLLAR_MIN_TRANSPARENT_RATIO)
		_assert_cutout_has_single_alpha_component(neck_collar_visual.texture, NECK_COLLAR_VISUAL_PATH)
	assert_true(
			neck_collar_visual.z_index >= torso_visual.z_index,
			"Player skeleton neck/collar cover must draw over the torso seam"
	)
	assert_true(
			neck_collar_visual.z_index < head_visual.z_index,
			"Player skeleton neck/collar cover must stay under the rotating head"
	)
	assert_true(
			neck_collar_visual.position.x >= NECK_COLLAR_MIN_LOCAL_X
					and neck_collar_visual.position.x <= NECK_COLLAR_MAX_LOCAL_X
					and neck_collar_visual.position.y >= NECK_COLLAR_MIN_LOCAL_Y
					and neck_collar_visual.position.y <= NECK_COLLAR_MAX_LOCAL_Y,
			"Player skeleton neck/collar cover must stay on the chest-side head seam"
	)

func _assert_cutout_has_single_alpha_component(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton cutout texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var visited: Dictionary = {}
	var component_count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var point := Vector2i(x, y)
			if visited.has(point) or image.get_pixel(x, y).a <= 0.0:
				continue
			component_count += 1
			_mark_alpha_component_visited(image, point, visited)
	assert_true(component_count == 1, "Player skeleton cutout must not keep detached alpha islands: %s" % visual_path)

func _mark_alpha_component_visited(image: Image, start: Vector2i, visited: Dictionary) -> void:
	var stack: Array[Vector2i] = [start]
	visited[start] = true
	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()
		for y_offset in range(-1, 2):
			for x_offset in range(-1, 2):
				var next_point := Vector2i(point.x + x_offset, point.y + y_offset)
				if next_point.x < 0 or next_point.x >= image.get_width() or next_point.y < 0 or next_point.y >= image.get_height():
					continue
				if visited.has(next_point) or image.get_pixel(next_point.x, next_point.y).a <= 0.0:
					continue
				visited[next_point] = true
				stack.append(next_point)

func _assert_seam_fill_is_internal_strip(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton seam fill texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var max_visible_y := -1
	for y in range(image.get_height()):
		var min_x := INF
		var max_x := -INF
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = minf(min_x, float(x))
			max_x = maxf(max_x, float(x))
		if max_x == -INF:
			continue
		max_visible_y = maxi(max_visible_y, y)
		assert_true(max_x - min_x + 1.0 <= SEAM_FILL_MAX_INTERNAL_WIDTH, "Player skeleton seam fill must stay a narrow hidden strip: %s" % visual_path)
		assert_true(min_x >= SEAM_FILL_MIN_INTERNAL_X, "Player skeleton seam fill must not keep the left hand or outer leg: %s" % visual_path)
		assert_true(max_x <= SEAM_FILL_MAX_INTERNAL_X, "Player skeleton seam fill must not keep the right hand or outer leg: %s" % visual_path)
	assert_true(max_visible_y <= SEAM_FILL_MAX_INTERNAL_Y, "Player skeleton seam fill must fade before the lower shin/ankle: %s" % visual_path)

func _assert_thigh_does_not_own_moving_waistband(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton thigh texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(mini(THIGH_MOVING_WAISTBAND_CLEAR_ROWS, image.get_height())):
		for x in range(image.get_width()):
			assert_true(
					image.get_pixel(x, y).a <= 0.05,
					"Player skeleton thigh cutout must not keep moving waistband/pelvis pixels: %s" % visual_path
			)

func _assert_flashlight_cutout_has_completed_handle(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton flashlight texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var filled_columns := 0
	for x in range(FLASHLIGHT_HANDLE_GAP_X_RANGE.x, FLASHLIGHT_HANDLE_GAP_X_RANGE.y + 1):
		var column_has_handle := false
		for y in range(FLASHLIGHT_HANDLE_GAP_Y_RANGE.x, FLASHLIGHT_HANDLE_GAP_Y_RANGE.y + 1):
			if x >= image.get_width() or y >= image.get_height():
				continue
			if image.get_pixel(x, y).a > 0.2:
				column_has_handle = true
				break
		if column_has_handle:
			filled_columns += 1
	assert_true(
			filled_columns >= FLASHLIGHT_MIN_FILLED_GAP_COLUMNS,
			"Player skeleton flashlight cutout must complete the handle hidden under the front hand: %s" % visual_path
	)

func _assert_front_forearm_has_soft_elbow_taper(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton front forearm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(mini(FRONT_FOREARM_SOFT_TOP_CLEAR_ROWS, image.get_height())):
		for x in range(image.get_width()):
			assert_true(
					image.get_pixel(x, y).a <= 0.05,
					"Player skeleton front forearm must not start with a hard rectangular elbow crop: %s" % visual_path
			)
	if FRONT_FOREARM_SOFT_TOP_SAMPLE_ROW >= image.get_height():
		return
	var max_alpha := 0.0
	for x in range(image.get_width()):
		max_alpha = maxf(max_alpha, image.get_pixel(x, FRONT_FOREARM_SOFT_TOP_SAMPLE_ROW).a)
	assert_true(
			max_alpha <= FRONT_FOREARM_SOFT_TOP_MAX_ALPHA,
			"Player skeleton front forearm must fade in under the upper arm instead of covering it with an opaque strip: %s" % visual_path
	)

func _assert_flashlight_visual_sits_inside_front_grip(front_hand_visual: Sprite2D, flashlight_visual: Sprite2D) -> void:
	assert_true(
			flashlight_visual.position.x >= FLASHLIGHT_GRIP_MIN_LOCAL_X
					and flashlight_visual.position.x <= FLASHLIGHT_GRIP_MAX_LOCAL_X,
			"Player skeleton flashlight must stay horizontally tucked under the front-hand grip"
	)
	var y_offset := front_hand_visual.position.y - flashlight_visual.position.y
	assert_true(
			y_offset >= FLASHLIGHT_GRIP_MIN_LOCAL_Y_OFFSET
					and y_offset <= FLASHLIGHT_GRIP_MAX_LOCAL_Y_OFFSET,
			"Player skeleton flashlight must sit high enough through the front-hand grip without floating above it"
	)

func _assert_animation_tracks_use_cubic_interpolation(animation: Animation, animation_name: String) -> void:
	for track_index in range(animation.get_track_count()):
		assert_eq(
			animation.track_get_interpolation_type(track_index),
			Animation.INTERPOLATION_CUBIC,
			"Player skeleton animation %s track %d must use cubic interpolation for smoother bone motion" % [animation_name, track_index]
		)

func _assert_animation_track_value_range(animation: Animation, track_path: NodePath, min_range: float, max_range: float, animation_name: String) -> void:
	var track_index := -1
	for candidate_index in range(animation.get_track_count()):
		if animation.track_get_path(candidate_index) == track_path:
			track_index = candidate_index
			break
	assert_true(track_index >= 0, "Player skeleton animation %s must animate track %s" % [animation_name, track_path])
	if track_index < 0:
		return
	var min_value := INF
	var max_value := -INF
	for key_index in range(animation.track_get_key_count(track_index)):
		var value := float(animation.track_get_key_value(track_index, key_index))
		min_value = minf(min_value, value)
		max_value = maxf(max_value, value)
	var value_range := max_value - min_value
	assert_true(value_range >= min_range, "Player skeleton animation %s track %s must keep visible limb swing" % [animation_name, track_path])
	assert_true(value_range <= max_range, "Player skeleton animation %s track %s must avoid excessive cutout-breaking swing" % [animation_name, track_path])

func _assert_animation_vector2_y_range(animation: Animation, track_path: NodePath, min_range: float, max_range: float, animation_name: String) -> void:
	var track_index := -1
	for candidate_index in range(animation.get_track_count()):
		if animation.track_get_path(candidate_index) == track_path:
			track_index = candidate_index
			break
	assert_true(track_index >= 0, "Player skeleton animation %s must animate track %s" % [animation_name, track_path])
	if track_index < 0:
		return
	var min_value := INF
	var max_value := -INF
	for key_index in range(animation.track_get_key_count(track_index)):
		var value := animation.track_get_key_value(track_index, key_index) as Vector2
		min_value = minf(min_value, value.y)
		max_value = maxf(max_value, value.y)
	var value_range := max_value - min_value
	assert_true(value_range >= min_range, "Player skeleton animation %s track %s must keep visible foot lift" % [animation_name, track_path])
	assert_true(value_range <= max_range, "Player skeleton animation %s track %s must avoid excessive foot lift" % [animation_name, track_path])

func _assert_animation_vector2_x_range(animation: Animation, track_path: NodePath, min_range: float, max_range: float, animation_name: String) -> void:
	var track_index := -1
	for candidate_index in range(animation.get_track_count()):
		if animation.track_get_path(candidate_index) == track_path:
			track_index = candidate_index
			break
	assert_true(track_index >= 0, "Player skeleton animation %s must animate track %s" % [animation_name, track_path])
	if track_index < 0:
		return
	var min_value := INF
	var max_value := -INF
	for key_index in range(animation.track_get_key_count(track_index)):
		var value := animation.track_get_key_value(track_index, key_index) as Vector2
		min_value = minf(min_value, value.x)
		max_value = maxf(max_value, value.x)
	var value_range := max_value - min_value
	assert_true(value_range >= min_range, "Player skeleton animation %s track %s must keep visible stride" % [animation_name, track_path])
	assert_true(value_range <= max_range, "Player skeleton animation %s track %s must avoid excessive stride" % [animation_name, track_path])

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
