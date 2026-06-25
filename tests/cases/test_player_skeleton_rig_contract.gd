extends "res://tests/test_case.gd"

const PLAYER_SCENE_PATH := "res://player/player.tscn"
const LEGACY_PLAYER_SCENE_PATH := "res://player/LEGASY-ANIMATIONS-CHARACTER.tscn"
const PLAYER_RIG_SCENE_PATH := "res://player/player_skeleton_rig.tscn"
const LEVEL_DIR := "res://levels/cycles"
const ACTIVE_FRONT_FOREARM_MESH_PATH := "MeshFrontForearm"
const FRONT_HAND_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand"
const HEAD_VISUAL_PATH := "Hips/Spine/Chest/Neck/Head/VisualHead"
const TORSO_VISUAL_PATH := "Hips/Spine/Chest/VisualTorso"
const NECK_COLLAR_VISUAL_PATH := "Hips/Spine/Chest/VisualNeckCollarCover"
const PELVIS_VISUAL_PATH := "Hips/VisualPelvis"
const BACK_LEG_UNDERLAY_VISUAL_PATH := "Hips/VisualBackLegUnderlay"
const BACK_UPPER_ARM_VISUAL_PATH := "Hips/Spine/Chest/BackUpperArm/VisualBackUpperArm"
const BACK_FOREARM_VISUAL_PATH := "Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackForearm"
const FRONT_UPPER_ARM_VISUAL_PATH := "Hips/Spine/Chest/FrontUpperArm/VisualFrontUpperArm"
const FRONT_FOREARM_VISUAL_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontForearm"
const FRONT_ELBOW_VISUAL_PATH := "Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontElbowCover"
const FRONT_ANKLE_VISUAL_PATH := "Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontAnkleCover"
const FRONT_HAND_VISUAL_PATH := FRONT_HAND_PATH + "/VisualFrontHand"
const FRONT_HAND_EMPTY_VISUAL_PATH := FRONT_HAND_PATH + "/VisualFrontHandEmpty"
const FLASHLIGHT_VISUAL_PATH := FRONT_HAND_PATH + "/FlashlightMount/VisualFlashlight"
const FOOT_VISUAL_PATHS: Array[String] = [
	"Hips/BackThigh/BackShin/BackFoot/VisualBackFoot",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
]
const CLEANED_ARM_CUTOUT_VISUAL_PATHS: Array[String] = [
	BACK_FOREARM_VISUAL_PATH,
	"Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand",
	FRONT_FOREARM_VISUAL_PATH,
	FRONT_HAND_VISUAL_PATH,
	FRONT_HAND_EMPTY_VISUAL_PATH,
]
const CLEANED_LOWER_BODY_CUTOUT_VISUAL_PATHS: Array[String] = [
	"Hips/VisualPelvis",
	CLEANED_BACK_THIGH_VISUAL_PATH,
	CLEANED_BACK_SHIN_VISUAL_PATH,
	CLEANED_FRONT_THIGH_VISUAL_PATH,
	CLEANED_FRONT_SHIN_VISUAL_PATH,
]
const CLEANED_SEAM_FILL_VISUAL_PATH := "Hips/VisualSeamFill"
const CLEANED_PELVIS_VISUAL_PATH := "Hips/VisualPelvis"
const CLEANED_FRONT_THIGH_VISUAL_PATH := "Hips/FrontThigh/VisualFrontThigh"
const CLEANED_BACK_THIGH_VISUAL_PATH := "Hips/BackThigh/VisualBackThigh"
const CLEANED_FRONT_SHIN_VISUAL_PATH := "Hips/FrontThigh/FrontShin/VisualFrontShin"
const CLEANED_BACK_SHIN_VISUAL_PATH := "Hips/BackThigh/BackShin/VisualBackShin"
const CLEANED_FRONT_HAND_VISUAL_PATH := FRONT_HAND_VISUAL_PATH
const CLEANED_FRONT_HAND_EMPTY_VISUAL_PATH := FRONT_HAND_EMPTY_VISUAL_PATH
const CLEANED_BACK_HAND_VISUAL_PATH := "Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand"
const SAFE_ALPHA_MARGIN_VISUAL_PATHS: Array[String] = [
	HEAD_VISUAL_PATH,
	CLEANED_FRONT_HAND_VISUAL_PATH,
	CLEANED_BACK_HAND_VISUAL_PATH,
]
const HIDDEN_STATIC_PATCH_VISUAL_PATHS: Array[String] = [
	CLEANED_PELVIS_VISUAL_PATH,
	BACK_LEG_UNDERLAY_VISUAL_PATH,
]
const SINGLE_ALPHA_COMPONENT_VISUAL_PATHS: Array[String] = [
	TORSO_VISUAL_PATH,
	CLEANED_PELVIS_VISUAL_PATH,
	CLEANED_SEAM_FILL_VISUAL_PATH,
	BACK_FOREARM_VISUAL_PATH,
	FRONT_FOREARM_VISUAL_PATH,
	CLEANED_FRONT_THIGH_VISUAL_PATH,
	CLEANED_FRONT_SHIN_VISUAL_PATH,
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
]
const SEAM_FILL_MAX_INTERNAL_WIDTH := 52
const SEAM_FILL_MIN_INTERNAL_X := 88
const SEAM_FILL_MAX_INTERNAL_X := 136
const SEAM_FILL_MAX_INTERNAL_Y := 208
const SEAM_FILL_WAIST_BRIDGE_MAX_Y := 108
const SEAM_FILL_WAIST_BRIDGE_MAX_WIDTH := 72
const SEAM_FILL_WAIST_BRIDGE_MIN_X := 72
const SEAM_FILL_WAIST_BRIDGE_MAX_X := 146
const SEAM_FILL_WAIST_BRIDGE_MIN_ROWS := 18
const SEAM_FILL_WAIST_BRIDGE_MIN_WIDTH := 58
const SEAM_FILL_LOWER_STRIP_MAX_ALPHA := 0.47
const CUTOUT_MIN_SAFE_ALPHA_MARGIN := 6
const HEAD_MAX_LOWER_LEFT_SHOULDER_PIXELS := 20
const HEAD_MIN_UPPER_RIGHT_HAIR_PIXELS := 680
const HEAD_SHIRT_TAIL_MIN_Y := 144
const HEAD_MAX_LOWER_SHIRT_TAIL_PIXELS := 4
const HEAD_SHIRT_TAIL_MAX_SATURATION := 0.18
const HEAD_NECK_SOLID_SAMPLE_Y := 136
const HEAD_NECK_SOFT_SAMPLE_Y := 142
const HEAD_NECK_BOTTOM_SAMPLE_Y := 146
const HEAD_NECK_MIN_SOLID_ALPHA := 0.90
const HEAD_NECK_MAX_SOFT_ALPHA := 0.55
const HEAD_NECK_MAX_BOTTOM_ALPHA := 0.20
const NECK_COLLAR_MAX_TEXTURE_SIZE := Vector2i(96, 88)
const NECK_COLLAR_MIN_TRANSPARENT_RATIO := 0.15
const NECK_COLLAR_MIN_LOCAL_X := -24.0
const NECK_COLLAR_MAX_LOCAL_X := 0.0
const NECK_COLLAR_MIN_LOCAL_Y := -108.0
const NECK_COLLAR_MAX_LOCAL_Y := -84.0
const FRONT_SHIN_DETACHED_STRIP_MIN_X := 71
const FRONT_SHIN_DETACHED_STRIP_MIN_Y := 8
const FRONT_SHIN_DETACHED_STRIP_MAX_Y := 150
const FRONT_SHIN_LOWER_SOFT_EDGE_MIN_Y := 176
const FRONT_SHIN_LOWER_SOFT_EDGE_SAMPLE_WIDTH := 8
const FRONT_SHIN_LOWER_SOFT_EDGE_MAX_ALPHA := 0.67
const TORSO_STATIC_SIDE_ARM_TOP_Y := 62
const TORSO_STATIC_SIDE_ARM_LOWER_Y := 115
const TORSO_STATIC_SIDE_ARM_LEFT_MAX_X := 62
const TORSO_STATIC_SIDE_ARM_RIGHT_MIN_X := 145
const TORSO_STATIC_SIDE_ARM_LOWER_LEFT_MAX_X := 78
const TORSO_STATIC_SIDE_ARM_LOWER_RIGHT_MIN_X := 132
const TORSO_STATIC_SIDE_ARM_MAX_SKIN_PIXELS := 100
const TORSO_TOP_RIGHT_HEAD_SHARD_MIN_X := 116
const TORSO_TOP_RIGHT_HEAD_SHARD_MAX_Y := 12
const TORSO_TOP_RIGHT_HEAD_SHARD_MAX_PIXELS := 2
const TORSO_HEAD_SHARD_MIN_SATURATION := 0.18
const TORSO_STATIC_PAJAMA_MIN_Y := 277
const TORSO_SIDE_EDGE_DARK_MATTE_MIN_Y := 108
const TORSO_SIDE_EDGE_DARK_MATTE_MAX_Y := 278
const TORSO_SIDE_EDGE_DARK_MATTE_SAMPLE_WIDTH := 6
const TORSO_LEFT_EDGE_MAX_DARK_MATTE_PIXELS := 112
const TORSO_RIGHT_EDGE_MAX_DARK_MATTE_PIXELS := 28
const TORSO_EDGE_DARK_MATTE_MIN_ALPHA := 0.235
const TORSO_EDGE_DARK_MATTE_MAX_LUMINANCE := 0.23
const THIGH_MOVING_WAISTBAND_CLEAR_ROWS := 20
const THIGH_TOP_FADE_START_Y := 20
const THIGH_TOP_FADE_END_Y := 44
const THIGH_TOP_FADE_ALPHA_TOLERANCE := 0.04
const FLASHLIGHT_HANDLE_GAP_X_RANGE := Vector2i(22, 62)
const FLASHLIGHT_HANDLE_GAP_Y_RANGE := Vector2i(25, 34)
const FLASHLIGHT_MIN_FILLED_GAP_COLUMNS := 32
const FLASHLIGHT_GRIP_MIN_LOCAL_X := -4.0
const FLASHLIGHT_GRIP_MAX_LOCAL_X := 2.0
const FLASHLIGHT_GRIP_MIN_LOCAL_Y_OFFSET := 6.0
const FLASHLIGHT_GRIP_MAX_LOCAL_Y_OFFSET := 12.0
const BACK_THIGH_SOFT_EDGE_MIN_Y := 70
const BACK_THIGH_SOFT_EDGE_MAX_ALPHA := 0.55
const BACK_LEG_UNDERLAY_MAX_ALPHA := 0.50
const BACK_LEG_UNDERLAY_MAX_VISIBLE_RATIO := 0.66
const BACK_LEG_UNDERLAY_MAX_SKIN_PIXELS := 24
const BACK_SHIN_SOFT_INNER_EDGE_MIN_Y := 44
const BACK_SHIN_SOFT_SIDE_EDGE_MAX_ALPHA := 0.50
const BACK_SHIN_LOWER_TAPER_SAMPLE_ROWS: Array[int] = [144, 162, 180, 198]
const BACK_SHIN_LOWER_TAPER_MAX_WIDTHS: Array[int] = [46, 44, 37, 35]
const FRONT_THIGH_SMOOTH_HIP_MIN_Y := 88
const FRONT_THIGH_SMOOTH_HIP_MAX_Y := 132
const FRONT_THIGH_MAX_LEFT_EDGE_STEP := 2
const FRONT_THIGH_SOFT_EDGE_MIN_Y := 96
const FRONT_THIGH_SOFT_EDGE_MAX_Y := 206
const FRONT_THIGH_SOFT_EDGE_MAX_ALPHA := 0.55
const BACK_UPPER_ARM_TORSO_TAIL_MIN_Y := 104
const BACK_UPPER_ARM_TORSO_TAIL_MIN_LEFT_X := 22
const BACK_UPPER_ARM_TORSO_TAIL_MAX_WIDTH := 29
const UPPER_ARM_DUPLICATE_SLEEVE_CLEAR_ROWS := 56
const UPPER_ARM_SOFT_EDGE_MIN_Y := 68
const UPPER_ARM_SOFT_EDGE_MAX_ALPHA := 0.68
const FOREARM_SOFT_SIDE_EDGE_MIN_Y := 16
const FOREARM_SOFT_SIDE_EDGE_MAX_ALPHA := 0.65
const ARM_EDGE_MAX_OPAQUE_DARK_MATTE_PIXELS := 16
const BACK_ARM_EDGE_MAX_VISIBLE_DARK_FRINGE_PIXELS := 24
const FRONT_UPPER_ARM_EDGE_MAX_VISIBLE_DARK_FRINGE_PIXELS := 4
const ARM_EDGE_VISIBLE_DARK_FRINGE_MIN_ALPHA := 0.235
const ARM_EDGE_VISIBLE_DARK_FRINGE_MAX_LUMINANCE := 0.30
const FRONT_ELBOW_COVER_MAX_ALPHA := 0.75
const FRONT_ELBOW_COVER_MAX_VISIBLE_RATIO := 0.50
const FRONT_ELBOW_COVER_MIN_LOCAL_X := 1.0
const FRONT_ELBOW_COVER_MAX_LOCAL_X := 3.0
const FRONT_ELBOW_COVER_MIN_LOCAL_Y := 6.0
const FRONT_ELBOW_COVER_MAX_LOCAL_Y := 10.0
const FRONT_ANKLE_COVER_MIN_CUFF_ALPHA := 0.70
const FRONT_ANKLE_COVER_CUFF_SAMPLE_Y := 24
const FRONT_ANKLE_COVER_LOWER_FADE_START_Y := 44
const FRONT_ANKLE_COVER_LOWER_MAX_ALPHA := 0.30
const FRONT_ANKLE_COVER_BOTTOM_SAMPLE_Y := 50
const FRONT_ANKLE_COVER_BOTTOM_MAX_ALPHA := 0.05
const FRONT_FOREARM_ELBOW_OVERLAP_TOP_RIGHT_X := -10.0
const FRONT_FOREARM_ELBOW_OVERLAP_MID_RIGHT_X := -12.0
const FRONT_FOREARM_ELBOW_OVERLAP_LOW_RIGHT_X := -14.0
const FRONT_FOREARM_GRIP_RIGHT_X := -16.0
const FRONT_UPPER_ARM_TORSO_TAIL_MIN_Y := 80
const FRONT_UPPER_ARM_TORSO_TAIL_MAX_RIGHT_X := 58
const BACK_FOREARM_WRIST_TAPER_MIN_Y := 104
const BACK_FOREARM_WRIST_TAPER_MAX_Y := 128
const BACK_FOREARM_WRIST_TAPER_MAX_WIDTH := 22
const BACK_FOREARM_HAND_TAIL_CLEAR_Y := 130
const FOREARM_MAX_CLOTHING_FRAGMENT_PIXELS := 20
const FRONT_FOREARM_SOFT_TOP_CLEAR_ROWS := 11
const FRONT_FOREARM_SOFT_TOP_SAMPLE_ROW := 20
const FRONT_FOREARM_SOFT_TOP_MAX_ALPHA := 0.45
const PELVIS_STATIC_FRONT_HAND_MAX_SKIN_PIXELS := 20
const WALK_CONTACT_TIMES: Array[float] = [0.2, 0.6]
const WALK_SAMPLE_TIMES: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
const LIGHT_WALK_CONTACT_TIMES: Array[float] = [0.2, 0.6]
const LIGHT_WALK_SAMPLE_TIMES: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
const RUN_CONTACT_TIMES: Array[float] = [0.1375, 0.4125]
const RUN_SAMPLE_TIMES: Array[float] = [0.0, 0.06875, 0.1375, 0.20625, 0.275, 0.34375, 0.4125, 0.48125]
const LIGHT_RUN_CONTACT_TIMES: Array[float] = [0.1375, 0.4125]
const LIGHT_RUN_SAMPLE_TIMES: Array[float] = [0.0, 0.06875, 0.1375, 0.20625, 0.275, 0.34375, 0.4125, 0.48125]
const FOOT_CONTACT_GROUND_TOLERANCE := 12.0
const IDLE_MIN_HAND_BREATH_RANGE := 0.009
const IDLE_MAX_HAND_BREATH_RANGE := 0.02
const IDLE_MIN_EMPTY_HAND_BREATH_RANGE := 0.008
const IDLE_MAX_EMPTY_HAND_BREATH_RANGE := 0.012
const IDLE_MIN_FLASHLIGHT_BOB_RANGE := 0.02
const IDLE_MAX_FLASHLIGHT_BOB_RANGE := 0.03
const LIGHT_IDLE_MIN_HELD_HAND_BREATH_RANGE := 0.01
const LIGHT_IDLE_MAX_HELD_HAND_BREATH_RANGE := 0.017
const LIGHT_IDLE_MIN_FLASHLIGHT_BOB_RANGE := 0.026
const LIGHT_IDLE_MAX_FLASHLIGHT_BOB_RANGE := 0.032
const LIGHT_IDLE_MIN_FLASHLIGHT_HOLD_BIAS := -0.03
const LIGHT_IDLE_MAX_FLASHLIGHT_HOLD_BIAS := -0.018
const WALK_MIN_HIPS_BOUNCE_RANGE := 2.5
const WALK_MAX_HIPS_BOUNCE_RANGE := 3.5
const WALK_MIN_LEG_SWING_RANGE := 0.055
const WALK_MAX_LEG_SWING_RANGE := 0.07
const WALK_MIN_BACK_THIGH_SWING_RANGE := 0.04
const WALK_MAX_BACK_THIGH_SWING_RANGE := 0.05
const WALK_MIN_BACK_SHIN_SWING_RANGE := 0.06
const WALK_MAX_BACK_SHIN_SWING_RANGE := 0.075
const WALK_MIN_ARM_SWING_RANGE := 0.06
const WALK_MAX_ARM_SWING_RANGE := 0.075
const WALK_MIN_FOREARM_FOLLOW_RANGE := 0.035
const WALK_MAX_FOREARM_FOLLOW_RANGE := 0.045
const WALK_MIN_FLASHLIGHT_BOB_RANGE := 0.085
const WALK_MAX_FLASHLIGHT_BOB_RANGE := 0.095
const WALK_MIN_EMPTY_HAND_SWAY_RANGE := 0.03
const WALK_MAX_EMPTY_HAND_SWAY_RANGE := 0.04
const LIGHT_WALK_MIN_ARM_SWING_RANGE := 0.055
const LIGHT_WALK_MAX_ARM_SWING_RANGE := 0.065
const LIGHT_WALK_MIN_FOREARM_FOLLOW_RANGE := 0.028
const LIGHT_WALK_MAX_FOREARM_FOLLOW_RANGE := 0.035
const LIGHT_WALK_MIN_FLASHLIGHT_BOB_RANGE := 0.105
const LIGHT_WALK_MAX_FLASHLIGHT_BOB_RANGE := 0.115
const LIGHT_WALK_MIN_WRIST_SWING_RANGE := 0.03
const LIGHT_WALK_MAX_WRIST_SWING_RANGE := 0.04
const WALK_MIN_CHEST_COUNTER_RANGE := 0.03
const WALK_MAX_CHEST_COUNTER_RANGE := 0.04
const WALK_MIN_SPINE_SWAY_RANGE := 0.03
const WALK_MAX_SPINE_SWAY_RANGE := 0.04
const WALK_MIN_NECK_COUNTER_RANGE := 0.018
const WALK_MAX_NECK_COUNTER_RANGE := 0.03
const WALK_MIN_HEAD_COUNTER_RANGE := 0.02
const WALK_MAX_HEAD_COUNTER_RANGE := 0.025
const LIGHT_RUN_MIN_HIPS_BOUNCE_RANGE := 5.0
const LIGHT_RUN_MAX_HIPS_BOUNCE_RANGE := 6.5
const LIGHT_RUN_MIN_LEG_SWING_RANGE := 0.115
const LIGHT_RUN_MAX_LEG_SWING_RANGE := 0.13
const RUN_MIN_ARM_SWING_RANGE := 0.14
const RUN_MAX_ARM_SWING_RANGE := 0.15
const RUN_MIN_FOREARM_FOLLOW_RANGE := 0.085
const RUN_MAX_FOREARM_FOLLOW_RANGE := 0.095
const RUN_MIN_EMPTY_HAND_SWAY_RANGE := 0.10
const RUN_MAX_EMPTY_HAND_SWAY_RANGE := 0.11
const RUN_MIN_WRIST_SWING_RANGE := 0.13
const RUN_MAX_WRIST_SWING_RANGE := 0.14
const LIGHT_RUN_MIN_BACK_THIGH_SWING_RANGE := 0.08
const LIGHT_RUN_MAX_BACK_THIGH_SWING_RANGE := 0.09
const LIGHT_RUN_MIN_BACK_SHIN_SWING_RANGE := 0.095
const LIGHT_RUN_MAX_BACK_SHIN_SWING_RANGE := 0.105
const LIGHT_RUN_MIN_ARM_SWING_RANGE := 0.10
const LIGHT_RUN_MAX_ARM_SWING_RANGE := 0.115
const LIGHT_RUN_MIN_FOREARM_FOLLOW_RANGE := 0.06
const LIGHT_RUN_MAX_FOREARM_FOLLOW_RANGE := 0.07
const LIGHT_RUN_MIN_FLASHLIGHT_BOB_RANGE := 0.17
const LIGHT_RUN_MAX_FLASHLIGHT_BOB_RANGE := 0.19
const LIGHT_RUN_MIN_EMPTY_HAND_SWAY_RANGE := 0.065
const LIGHT_RUN_MAX_EMPTY_HAND_SWAY_RANGE := 0.075
const LIGHT_RUN_MIN_CHEST_COUNTER_RANGE := 0.055
const LIGHT_RUN_MAX_CHEST_COUNTER_RANGE := 0.065
const LIGHT_RUN_MIN_SPINE_SWAY_RANGE := 0.04
const LIGHT_RUN_MAX_SPINE_SWAY_RANGE := 0.05
const RUN_MIN_SPINE_FORWARD_BIAS := 0.01
const RUN_MAX_SPINE_FORWARD_BIAS := 0.02
const LIGHT_RUN_MIN_NECK_COUNTER_RANGE := 0.025
const LIGHT_RUN_MAX_NECK_COUNTER_RANGE := 0.035
const LIGHT_RUN_MIN_HEAD_COUNTER_RANGE := 0.035
const LIGHT_RUN_MAX_HEAD_COUNTER_RANGE := 0.04
const WALK_MIN_FOOT_LIFT_RANGE := 9.0
const WALK_MAX_FOOT_LIFT_RANGE := 11.0
const WALK_MIN_FOOT_ROLL_RANGE := 0.075
const WALK_MAX_FOOT_ROLL_RANGE := 0.09
const LIGHT_RUN_MIN_FOOT_LIFT_RANGE := 13.5
const LIGHT_RUN_MAX_FOOT_LIFT_RANGE := 17.0
const LIGHT_RUN_MIN_FOOT_ROLL_RANGE := 0.125
const LIGHT_RUN_MAX_FOOT_ROLL_RANGE := 0.14
const LIGHT_RUN_MIN_FRONT_FOOT_STRIDE_RANGE := 10.5
const LIGHT_RUN_MAX_FRONT_FOOT_STRIDE_RANGE := 11.5
const LIGHT_RUN_MIN_BACK_FOOT_STRIDE_RANGE := 7.5
const LIGHT_RUN_MAX_BACK_FOOT_STRIDE_RANGE := 8.5
const WALK_MIN_WRIST_SWING_RANGE := 0.03
const WALK_MAX_WRIST_SWING_RANGE := 0.05
const LIGHT_RUN_MIN_WRIST_SWING_RANGE := 0.08
const LIGHT_RUN_MAX_WRIST_SWING_RANGE := 0.095
const WALK_FOOT_PASSING_KEY_COUNT := 9
const LIGHT_RUN_FOOT_PASSING_KEY_COUNT := 9
const HIPS_POSITION_TRACK := NodePath("Skeleton2D/Hips:position")
const FRONT_THIGH_ROTATION_TRACK := NodePath("Skeleton2D/Hips/FrontThigh:rotation")
const BACK_THIGH_ROTATION_TRACK := NodePath("Skeleton2D/Hips/BackThigh:rotation")
const BACK_SHIN_ROTATION_TRACK := NodePath("Skeleton2D/Hips/BackThigh/BackShin:rotation")
const SPINE_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine:rotation")
const CHEST_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest:rotation")
const NECK_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/Neck:rotation")
const HEAD_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/Neck/Head:rotation")
const FRONT_UPPER_ARM_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm:rotation")
const FRONT_FOREARM_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm:rotation")
const BACK_FOREARM_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/BackUpperArm/BackForearm:rotation")
const FLASHLIGHT_MOUNT_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/FlashlightMount:rotation")
const FRONT_HAND_EMPTY_VISUAL_ROTATION_TRACK := NodePath("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/VisualFrontHandEmpty:rotation")
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
	BACK_UPPER_ARM_VISUAL_PATH,
	"Hips/Spine/Chest/BackUpperArm/VisualBackShoulderCover",
	BACK_FOREARM_VISUAL_PATH,
	"Hips/Spine/Chest/BackUpperArm/BackForearm/VisualBackElbowCover",
	"Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand/VisualBackHand",
	FRONT_UPPER_ARM_VISUAL_PATH,
	"Hips/Spine/Chest/FrontUpperArm/VisualFrontShoulderCover",
	FRONT_FOREARM_VISUAL_PATH,
	"Hips/Spine/Chest/FrontUpperArm/FrontForearm/VisualFrontElbowCover",
	FRONT_HAND_EMPTY_VISUAL_PATH,
	FRONT_HAND_PATH + "/VisualFrontHand",
	FLASHLIGHT_VISUAL_PATH,
	BACK_LEG_UNDERLAY_VISUAL_PATH,
	CLEANED_BACK_THIGH_VISUAL_PATH,
	CLEANED_BACK_SHIN_VISUAL_PATH,
	"Hips/BackThigh/BackShin/VisualBackKneeCover",
	"Hips/BackThigh/BackShin/BackFoot/VisualBackFoot",
	"Hips/BackThigh/BackShin/BackFoot/VisualBackAnkleCover",
	CLEANED_FRONT_THIGH_VISUAL_PATH,
	CLEANED_FRONT_SHIN_VISUAL_PATH,
	"Hips/FrontThigh/FrontShin/VisualFrontKneeCover",
	"Hips/FrontThigh/FrontShin/FrontFoot/VisualFrontFoot",
	FRONT_ANKLE_VISUAL_PATH,
]
const CONVERTED_LIMB_VISUAL_PATHS: Array[String] = [
	BACK_UPPER_ARM_VISUAL_PATH,
	BACK_FOREARM_VISUAL_PATH,
	CLEANED_BACK_HAND_VISUAL_PATH,
	CLEANED_BACK_THIGH_VISUAL_PATH,
	CLEANED_BACK_SHIN_VISUAL_PATH,
	FRONT_UPPER_ARM_VISUAL_PATH,
	FRONT_FOREARM_VISUAL_PATH,
	CLEANED_FRONT_THIGH_VISUAL_PATH,
	CLEANED_FRONT_SHIN_VISUAL_PATH,
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
		for animation_name in [&"idle", &"light_idle", &"walk", &"light_walk", &"run", &"light_run"]:
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
					_assert_animation_track_value_range(animation, FRONT_HAND_EMPTY_VISUAL_ROTATION_TRACK, IDLE_MIN_EMPTY_HAND_BREATH_RANGE, IDLE_MAX_EMPTY_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FLASHLIGHT_MOUNT_ROTATION_TRACK, IDLE_MIN_FLASHLIGHT_BOB_RANGE, IDLE_MAX_FLASHLIGHT_BOB_RANGE, String(animation_name))
				elif animation_name == &"light_idle":
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, LIGHT_IDLE_MIN_HELD_HAND_BREATH_RANGE, LIGHT_IDLE_MAX_HELD_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOREARM_ROTATION_TRACK, LIGHT_IDLE_MIN_HELD_HAND_BREATH_RANGE, LIGHT_IDLE_MAX_HELD_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, LIGHT_IDLE_MIN_HELD_HAND_BREATH_RANGE, LIGHT_IDLE_MAX_HELD_HAND_BREATH_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FLASHLIGHT_MOUNT_ROTATION_TRACK, LIGHT_IDLE_MIN_FLASHLIGHT_BOB_RANGE, LIGHT_IDLE_MAX_FLASHLIGHT_BOB_RANGE, String(animation_name))
					_assert_animation_track_mean_in_range(animation, FLASHLIGHT_MOUNT_ROTATION_TRACK, LIGHT_IDLE_MIN_FLASHLIGHT_HOLD_BIAS, LIGHT_IDLE_MAX_FLASHLIGHT_HOLD_BIAS, String(animation_name))
				elif animation_name == &"walk":
					_assert_animation_vector2_y_range(animation, HIPS_POSITION_TRACK, WALK_MIN_HIPS_BOUNCE_RANGE, WALK_MAX_HIPS_BOUNCE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_THIGH_ROTATION_TRACK, WALK_MIN_LEG_SWING_RANGE, WALK_MAX_LEG_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_THIGH_ROTATION_TRACK, WALK_MIN_BACK_THIGH_SWING_RANGE, WALK_MAX_BACK_THIGH_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_SHIN_ROTATION_TRACK, WALK_MIN_BACK_SHIN_SWING_RANGE, WALK_MAX_BACK_SHIN_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, SPINE_ROTATION_TRACK, WALK_MIN_SPINE_SWAY_RANGE, WALK_MAX_SPINE_SWAY_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, CHEST_ROTATION_TRACK, WALK_MIN_CHEST_COUNTER_RANGE, WALK_MAX_CHEST_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, NECK_ROTATION_TRACK, WALK_MIN_NECK_COUNTER_RANGE, WALK_MAX_NECK_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, HEAD_ROTATION_TRACK, WALK_MIN_HEAD_COUNTER_RANGE, WALK_MAX_HEAD_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, WALK_MIN_ARM_SWING_RANGE, WALK_MAX_ARM_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOREARM_ROTATION_TRACK, WALK_MIN_FOREARM_FOLLOW_RANGE, WALK_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOREARM_ROTATION_TRACK, WALK_MIN_FOREARM_FOLLOW_RANGE, WALK_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FLASHLIGHT_MOUNT_ROTATION_TRACK, WALK_MIN_FLASHLIGHT_BOB_RANGE, WALK_MAX_FLASHLIGHT_BOB_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_EMPTY_VISUAL_ROTATION_TRACK, WALK_MIN_EMPTY_HAND_SWAY_RANGE, WALK_MAX_EMPTY_HAND_SWAY_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, FRONT_FOOT_POSITION_TRACK, WALK_MIN_FOOT_LIFT_RANGE, WALK_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, BACK_FOOT_POSITION_TRACK, WALK_MIN_FOOT_LIFT_RANGE, WALK_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOOT_ROTATION_TRACK, WALK_MIN_FOOT_ROLL_RANGE, WALK_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOOT_ROTATION_TRACK, WALK_MIN_FOOT_ROLL_RANGE, WALK_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_POSITION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_POSITION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_ROTATION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_ROTATION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, WALK_MIN_WRIST_SWING_RANGE, WALK_MAX_WRIST_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, WALK_MIN_WRIST_SWING_RANGE, WALK_MAX_WRIST_SWING_RANGE, String(animation_name))
				elif animation_name == &"light_walk":
					_assert_animation_vector2_y_range(animation, HIPS_POSITION_TRACK, WALK_MIN_HIPS_BOUNCE_RANGE, WALK_MAX_HIPS_BOUNCE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_THIGH_ROTATION_TRACK, WALK_MIN_LEG_SWING_RANGE, WALK_MAX_LEG_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_THIGH_ROTATION_TRACK, WALK_MIN_BACK_THIGH_SWING_RANGE, WALK_MAX_BACK_THIGH_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_SHIN_ROTATION_TRACK, WALK_MIN_BACK_SHIN_SWING_RANGE, WALK_MAX_BACK_SHIN_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, SPINE_ROTATION_TRACK, WALK_MIN_SPINE_SWAY_RANGE, WALK_MAX_SPINE_SWAY_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, CHEST_ROTATION_TRACK, WALK_MIN_CHEST_COUNTER_RANGE, WALK_MAX_CHEST_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, NECK_ROTATION_TRACK, WALK_MIN_NECK_COUNTER_RANGE, WALK_MAX_NECK_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, HEAD_ROTATION_TRACK, WALK_MIN_HEAD_COUNTER_RANGE, WALK_MAX_HEAD_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, LIGHT_WALK_MIN_ARM_SWING_RANGE, LIGHT_WALK_MAX_ARM_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOREARM_ROTATION_TRACK, LIGHT_WALK_MIN_FOREARM_FOLLOW_RANGE, LIGHT_WALK_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOREARM_ROTATION_TRACK, WALK_MIN_FOREARM_FOLLOW_RANGE, WALK_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FLASHLIGHT_MOUNT_ROTATION_TRACK, LIGHT_WALK_MIN_FLASHLIGHT_BOB_RANGE, LIGHT_WALK_MAX_FLASHLIGHT_BOB_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, FRONT_FOOT_POSITION_TRACK, WALK_MIN_FOOT_LIFT_RANGE, WALK_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, BACK_FOOT_POSITION_TRACK, WALK_MIN_FOOT_LIFT_RANGE, WALK_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOOT_ROTATION_TRACK, WALK_MIN_FOOT_ROLL_RANGE, WALK_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOOT_ROTATION_TRACK, WALK_MIN_FOOT_ROLL_RANGE, WALK_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_POSITION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_POSITION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_ROTATION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_ROTATION_TRACK, WALK_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, LIGHT_WALK_MIN_WRIST_SWING_RANGE, LIGHT_WALK_MAX_WRIST_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, WALK_MIN_WRIST_SWING_RANGE, WALK_MAX_WRIST_SWING_RANGE, String(animation_name))
				elif animation_name == &"run":
					_assert_animation_vector2_y_range(animation, HIPS_POSITION_TRACK, LIGHT_RUN_MIN_HIPS_BOUNCE_RANGE, LIGHT_RUN_MAX_HIPS_BOUNCE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_THIGH_ROTATION_TRACK, LIGHT_RUN_MIN_LEG_SWING_RANGE, LIGHT_RUN_MAX_LEG_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_THIGH_ROTATION_TRACK, LIGHT_RUN_MIN_BACK_THIGH_SWING_RANGE, LIGHT_RUN_MAX_BACK_THIGH_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_SHIN_ROTATION_TRACK, LIGHT_RUN_MIN_BACK_SHIN_SWING_RANGE, LIGHT_RUN_MAX_BACK_SHIN_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, SPINE_ROTATION_TRACK, LIGHT_RUN_MIN_SPINE_SWAY_RANGE, LIGHT_RUN_MAX_SPINE_SWAY_RANGE, String(animation_name))
					_assert_animation_track_mean_in_range(animation, SPINE_ROTATION_TRACK, RUN_MIN_SPINE_FORWARD_BIAS, RUN_MAX_SPINE_FORWARD_BIAS, String(animation_name))
					_assert_animation_track_value_range(animation, CHEST_ROTATION_TRACK, LIGHT_RUN_MIN_CHEST_COUNTER_RANGE, LIGHT_RUN_MAX_CHEST_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, NECK_ROTATION_TRACK, LIGHT_RUN_MIN_NECK_COUNTER_RANGE, LIGHT_RUN_MAX_NECK_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, HEAD_ROTATION_TRACK, LIGHT_RUN_MIN_HEAD_COUNTER_RANGE, LIGHT_RUN_MAX_HEAD_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, RUN_MIN_ARM_SWING_RANGE, RUN_MAX_ARM_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOREARM_ROTATION_TRACK, RUN_MIN_FOREARM_FOLLOW_RANGE, RUN_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOREARM_ROTATION_TRACK, LIGHT_RUN_MIN_FOREARM_FOLLOW_RANGE, LIGHT_RUN_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_EMPTY_VISUAL_ROTATION_TRACK, RUN_MIN_EMPTY_HAND_SWAY_RANGE, RUN_MAX_EMPTY_HAND_SWAY_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FOOT_LIFT_RANGE, LIGHT_RUN_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FOOT_LIFT_RANGE, LIGHT_RUN_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_x_range(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FRONT_FOOT_STRIDE_RANGE, LIGHT_RUN_MAX_FRONT_FOOT_STRIDE_RANGE, String(animation_name))
					_assert_animation_vector2_x_range(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_BACK_FOOT_STRIDE_RANGE, LIGHT_RUN_MAX_BACK_FOOT_STRIDE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOOT_ROTATION_TRACK, LIGHT_RUN_MIN_FOOT_ROLL_RANGE, LIGHT_RUN_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOOT_ROTATION_TRACK, LIGHT_RUN_MIN_FOOT_ROLL_RANGE, LIGHT_RUN_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_ROTATION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_ROTATION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, RUN_MIN_WRIST_SWING_RANGE, RUN_MAX_WRIST_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, LIGHT_RUN_MIN_WRIST_SWING_RANGE, LIGHT_RUN_MAX_WRIST_SWING_RANGE, String(animation_name))
				elif animation_name == &"light_run":
					_assert_animation_vector2_y_range(animation, HIPS_POSITION_TRACK, LIGHT_RUN_MIN_HIPS_BOUNCE_RANGE, LIGHT_RUN_MAX_HIPS_BOUNCE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_THIGH_ROTATION_TRACK, LIGHT_RUN_MIN_LEG_SWING_RANGE, LIGHT_RUN_MAX_LEG_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_THIGH_ROTATION_TRACK, LIGHT_RUN_MIN_BACK_THIGH_SWING_RANGE, LIGHT_RUN_MAX_BACK_THIGH_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_SHIN_ROTATION_TRACK, LIGHT_RUN_MIN_BACK_SHIN_SWING_RANGE, LIGHT_RUN_MAX_BACK_SHIN_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, SPINE_ROTATION_TRACK, LIGHT_RUN_MIN_SPINE_SWAY_RANGE, LIGHT_RUN_MAX_SPINE_SWAY_RANGE, String(animation_name))
					_assert_animation_track_mean_in_range(animation, SPINE_ROTATION_TRACK, RUN_MIN_SPINE_FORWARD_BIAS, RUN_MAX_SPINE_FORWARD_BIAS, String(animation_name))
					_assert_animation_track_value_range(animation, CHEST_ROTATION_TRACK, LIGHT_RUN_MIN_CHEST_COUNTER_RANGE, LIGHT_RUN_MAX_CHEST_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, NECK_ROTATION_TRACK, LIGHT_RUN_MIN_NECK_COUNTER_RANGE, LIGHT_RUN_MAX_NECK_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, HEAD_ROTATION_TRACK, LIGHT_RUN_MIN_HEAD_COUNTER_RANGE, LIGHT_RUN_MAX_HEAD_COUNTER_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_UPPER_ARM_ROTATION_TRACK, LIGHT_RUN_MIN_ARM_SWING_RANGE, LIGHT_RUN_MAX_ARM_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOREARM_ROTATION_TRACK, LIGHT_RUN_MIN_FOREARM_FOLLOW_RANGE, LIGHT_RUN_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOREARM_ROTATION_TRACK, LIGHT_RUN_MIN_FOREARM_FOLLOW_RANGE, LIGHT_RUN_MAX_FOREARM_FOLLOW_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FLASHLIGHT_MOUNT_ROTATION_TRACK, LIGHT_RUN_MIN_FLASHLIGHT_BOB_RANGE, LIGHT_RUN_MAX_FLASHLIGHT_BOB_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_EMPTY_VISUAL_ROTATION_TRACK, LIGHT_RUN_MIN_EMPTY_HAND_SWAY_RANGE, LIGHT_RUN_MAX_EMPTY_HAND_SWAY_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FOOT_LIFT_RANGE, LIGHT_RUN_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_y_range(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FOOT_LIFT_RANGE, LIGHT_RUN_MAX_FOOT_LIFT_RANGE, String(animation_name))
					_assert_animation_vector2_x_range(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_FRONT_FOOT_STRIDE_RANGE, LIGHT_RUN_MAX_FRONT_FOOT_STRIDE_RANGE, String(animation_name))
					_assert_animation_vector2_x_range(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_MIN_BACK_FOOT_STRIDE_RANGE, LIGHT_RUN_MAX_BACK_FOOT_STRIDE_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_FOOT_ROTATION_TRACK, LIGHT_RUN_MIN_FOOT_ROLL_RANGE, LIGHT_RUN_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_FOOT_ROTATION_TRACK, LIGHT_RUN_MIN_FOOT_ROLL_RANGE, LIGHT_RUN_MAX_FOOT_ROLL_RANGE, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_POSITION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_POSITION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, FRONT_FOOT_ROTATION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_key_count_at_least(animation, BACK_FOOT_ROTATION_TRACK, LIGHT_RUN_FOOT_PASSING_KEY_COUNT, String(animation_name))
					_assert_animation_track_value_range(animation, FRONT_HAND_ROTATION_TRACK, LIGHT_RUN_MIN_WRIST_SWING_RANGE, LIGHT_RUN_MAX_WRIST_SWING_RANGE, String(animation_name))
					_assert_animation_track_value_range(animation, BACK_HAND_ROTATION_TRACK, LIGHT_RUN_MIN_WRIST_SWING_RANGE, LIGHT_RUN_MAX_WRIST_SWING_RANGE, String(animation_name))
		if skeleton != null:
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"walk", WALK_CONTACT_TIMES, WALK_SAMPLE_TIMES)
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"light_walk", LIGHT_WALK_CONTACT_TIMES, LIGHT_WALK_SAMPLE_TIMES)
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"run", RUN_CONTACT_TIMES, RUN_SAMPLE_TIMES)
			_assert_foot_contact_keys_reach_ground(skeleton, animation_player, &"light_run", LIGHT_RUN_CONTACT_TIMES, LIGHT_RUN_SAMPLE_TIMES)
	if skeleton != null:
		for visual_path in EXPECTED_CUTOUT_VISUAL_PATHS:
			var visual := skeleton.get_node_or_null(visual_path) as CanvasItem
			assert_true(visual != null, "Player skeleton rig must keep CanvasItem cutout visual: %s" % visual_path)
			if visual != null:
				var visual_texture := _get_visual_texture(visual)
				assert_true(visual_texture != null, "Player skeleton cutout visual must keep texture: %s" % visual_path)
				assert_true(visual.z_index >= 0, "Player skeleton visual z-index must not fall behind level objects: %s" % visual_path)
				if visual_texture != null:
					assert_true(_is_player_skeleton_texture_path(String(visual_texture.resource_path)), "Player skeleton visual must use Andry cutout/cover texture: %s" % visual_path)
					assert_true(_is_tight_cutout_texture(visual_texture), "Player skeleton cutout texture must not keep the full Andry canvas: %s" % visual_path)
					if HIDDEN_STATIC_PATCH_VISUAL_PATHS.has(visual_path) and not visual.visible:
						continue
					if SAFE_ALPHA_MARGIN_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_safe_alpha_margin(visual_texture, visual_path, CUTOUT_MIN_SAFE_ALPHA_MARGIN)
					if visual_path == HEAD_VISUAL_PATH:
						_assert_head_cutout_keeps_source_head_shape(visual_texture, visual_path)
					if SINGLE_ALPHA_COMPONENT_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_single_alpha_component(visual_texture, visual_path)
					if visual_path == TORSO_VISUAL_PATH:
						_assert_torso_does_not_keep_static_side_arms(visual_texture, visual_path)
						_assert_torso_does_not_keep_top_right_head_shard(visual_texture, visual_path)
						_assert_torso_does_not_keep_static_pajama_waist(visual_texture, visual_path)
						_assert_torso_side_edges_do_not_keep_dark_matte(visual_texture, visual_path)
					if visual_path == CLEANED_SEAM_FILL_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.70)
						_assert_seam_fill_is_internal_strip(visual_texture, visual_path)
					elif visual_path == CLEANED_PELVIS_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.45)
						_assert_pelvis_does_not_keep_static_front_hand(visual_texture, visual_path)
					elif visual_path == CLEANED_FRONT_THIGH_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.30)
						_assert_thigh_does_not_own_moving_waistband(visual_texture, visual_path)
						_assert_thigh_top_fades_under_shirt(visual_texture, visual_path)
						_assert_front_thigh_has_soft_outer_edge(visual_texture, visual_path)
					elif visual_path == BACK_LEG_UNDERLAY_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.34)
						_assert_back_leg_underlay_stays_subtle(visual_texture, visual_path)
					elif visual_path == CLEANED_BACK_THIGH_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.25)
						_assert_thigh_does_not_own_moving_waistband(visual_texture, visual_path)
						_assert_thigh_top_fades_under_shirt(visual_texture, visual_path)
						_assert_back_thigh_has_soft_lower_edges(visual_texture, visual_path)
					elif visual_path == CLEANED_FRONT_SHIN_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.32)
						_assert_front_shin_does_not_keep_detached_side_strip(visual_texture, visual_path)
						_assert_front_shin_has_soft_lower_outer_edge(visual_texture, visual_path)
					elif visual_path == CLEANED_BACK_SHIN_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.24)
						_assert_back_shin_has_soft_inner_edge(visual_texture, visual_path)
					elif visual_path == CLEANED_FRONT_HAND_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.62)
					elif visual_path == CLEANED_FRONT_HAND_EMPTY_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.58)
					elif visual_path == CLEANED_BACK_HAND_VISUAL_PATH:
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.68)
					elif visual_path == FLASHLIGHT_VISUAL_PATH:
						_assert_flashlight_cutout_has_completed_handle(visual_texture, visual_path)
					elif visual_path == BACK_UPPER_ARM_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_upper_arm_does_not_keep_duplicate_sleeve(visual_texture, visual_path)
						_assert_back_upper_arm_does_not_keep_lower_torso_tail(visual_texture, visual_path)
						_assert_arm_cutout_has_soft_side_edges(visual_texture, visual_path, UPPER_ARM_SOFT_EDGE_MIN_Y, UPPER_ARM_SOFT_EDGE_MAX_ALPHA)
						_assert_arm_cutout_does_not_keep_opaque_dark_matte_edge(visual_texture, visual_path)
						_assert_arm_cutout_does_not_keep_visible_dark_edge_fringe(
								visual_texture,
								visual_path,
								BACK_ARM_EDGE_MAX_VISIBLE_DARK_FRINGE_PIXELS
						)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.45)
					elif visual_path == FRONT_UPPER_ARM_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_upper_arm_does_not_keep_duplicate_sleeve(visual_texture, visual_path)
						_assert_front_upper_arm_does_not_keep_side_torso_tail(visual_texture, visual_path)
						_assert_arm_cutout_has_soft_side_edges(visual_texture, visual_path, UPPER_ARM_SOFT_EDGE_MIN_Y, UPPER_ARM_SOFT_EDGE_MAX_ALPHA)
						_assert_arm_cutout_does_not_keep_opaque_dark_matte_edge(visual_texture, visual_path)
						_assert_arm_cutout_does_not_keep_visible_dark_edge_fringe(
								visual_texture,
								visual_path,
								FRONT_UPPER_ARM_EDGE_MAX_VISIBLE_DARK_FRINGE_PIXELS
						)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.40)
					elif visual_path == BACK_FOREARM_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_back_forearm_does_not_keep_hand_tail(visual_texture, visual_path)
						_assert_forearm_does_not_keep_clothing_fragments(visual_texture, visual_path)
						_assert_arm_cutout_has_soft_side_edges(visual_texture, visual_path, FOREARM_SOFT_SIDE_EDGE_MIN_Y, FOREARM_SOFT_SIDE_EDGE_MAX_ALPHA)
						_assert_arm_cutout_does_not_keep_opaque_dark_matte_edge(visual_texture, visual_path)
						_assert_arm_cutout_does_not_keep_visible_dark_edge_fringe(
								visual_texture,
								visual_path,
								BACK_ARM_EDGE_MAX_VISIBLE_DARK_FRINGE_PIXELS
						)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.25)
					elif visual_path == FRONT_FOREARM_VISUAL_PATH:
						_assert_limb_visual_is_bone_sprite(visual, visual_path)
						_assert_front_forearm_has_soft_elbow_taper(visual_texture, visual_path)
						_assert_forearm_does_not_keep_clothing_fragments(visual_texture, visual_path)
						_assert_arm_cutout_has_soft_side_edges(visual_texture, visual_path, FOREARM_SOFT_SIDE_EDGE_MIN_Y, FOREARM_SOFT_SIDE_EDGE_MAX_ALPHA)
						_assert_arm_cutout_does_not_keep_opaque_dark_matte_edge(visual_texture, visual_path)
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.25)
					elif visual_path == FRONT_ANKLE_VISUAL_PATH:
						_assert_front_ankle_cover_fades_above_foot(visual_texture, visual_path)
					elif CLEANED_ARM_CUTOUT_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.25)
					elif CLEANED_LOWER_BODY_CUTOUT_VISUAL_PATHS.has(visual_path):
						_assert_cutout_has_alpha_negative_space(visual_texture, visual_path, 0.23)
		var front_hand_visual := skeleton.get_node_or_null(FRONT_HAND_VISUAL_PATH) as Sprite2D
		var front_hand_empty_visual := skeleton.get_node_or_null(FRONT_HAND_EMPTY_VISUAL_PATH) as Sprite2D
		var flashlight_visual := skeleton.get_node_or_null(FLASHLIGHT_VISUAL_PATH) as Sprite2D
		var torso_visual := skeleton.get_node_or_null(TORSO_VISUAL_PATH) as Sprite2D
		var neck_collar_visual := skeleton.get_node_or_null(NECK_COLLAR_VISUAL_PATH) as Sprite2D
		var head_visual := skeleton.get_node_or_null(HEAD_VISUAL_PATH) as Sprite2D
		var pelvis_visual := skeleton.get_node_or_null(PELVIS_VISUAL_PATH) as Sprite2D
		var back_leg_underlay_visual := skeleton.get_node_or_null(BACK_LEG_UNDERLAY_VISUAL_PATH) as Sprite2D
		var front_upper_arm_visual := skeleton.get_node_or_null(FRONT_UPPER_ARM_VISUAL_PATH) as CanvasItem
		var front_forearm_visual := skeleton.get_node_or_null(FRONT_FOREARM_VISUAL_PATH) as CanvasItem
		var front_forearm_mesh := rig.get_node_or_null(ACTIVE_FRONT_FOREARM_MESH_PATH) as Polygon2D
		var front_elbow_visual := skeleton.get_node_or_null(FRONT_ELBOW_VISUAL_PATH) as Sprite2D
		var front_thigh_visual := skeleton.get_node_or_null(CLEANED_FRONT_THIGH_VISUAL_PATH) as CanvasItem
		assert_true(front_hand_visual != null, "Player skeleton must keep front hand visual for flashlight layering")
		assert_true(front_hand_empty_visual != null, "Player skeleton must keep empty front hand visual for no-flashlight variant")
		assert_true(flashlight_visual != null, "Player skeleton must keep flashlight visual for layering")
		assert_true(torso_visual != null, "Player skeleton must keep torso visual for photo-cutout layering")
		assert_true(neck_collar_visual != null, "Player skeleton must keep the optional neck/collar cover anchor for controlled QA")
		assert_true(head_visual != null, "Player skeleton must keep head visual for photo-cutout layering")
		assert_true(pelvis_visual != null, "Player skeleton must keep pelvis visual for photo-cutout layering")
		assert_true(back_leg_underlay_visual != null, "Player skeleton must keep the optional back-leg underlay anchor for controlled QA")
		assert_true(front_upper_arm_visual != null, "Player skeleton must keep front upper arm visual for photo-cutout layering")
		assert_true(front_forearm_visual != null, "Player skeleton must keep legacy front forearm Sprite2D anchor while the mesh rollout is partial")
		assert_true(front_forearm_mesh != null, "Player skeleton must use an active weighted Polygon2D mesh for the front forearm")
		assert_true(front_elbow_visual != null, "Player skeleton must keep front elbow cover for the upper-arm/forearm seam")
		assert_true(front_thigh_visual != null, "Player skeleton must keep front thigh visual for photo-cutout layering")
		if back_leg_underlay_visual != null:
			assert_true(not back_leg_underlay_visual.visible, "Player skeleton back-leg underlay must stay hidden now that weighted leg meshes carry the lower-body continuity")
		if pelvis_visual != null:
			assert_true(not pelvis_visual.visible, "Player skeleton pelvis block must stay hidden now that weighted thigh meshes carry the waist/lower-body continuity")
		if front_forearm_visual != null:
			assert_true(not front_forearm_visual.visible, "Player skeleton legacy front forearm Sprite2D anchor must stay hidden behind the weighted mesh")
		for converted_visual_path in CONVERTED_LIMB_VISUAL_PATHS:
			var converted_visual := skeleton.get_node_or_null(converted_visual_path) as CanvasItem
			if converted_visual != null:
				assert_true(not converted_visual.visible, "Player skeleton converted limb Sprite2D anchor must stay hidden behind its weighted mesh: %s" % converted_visual_path)
		for mesh_spec in _active_limb_mesh_specs():
			var mesh := rig.get_node_or_null(String(mesh_spec["path"])) as Polygon2D
			assert_true(mesh != null, "Player skeleton must keep weighted limb mesh: %s" % mesh_spec["path"])
			if mesh != null:
				_assert_active_limb_mesh(mesh, mesh_spec)
		if front_hand_visual != null and front_hand_visual.texture != null:
			assert_true(not front_hand_visual.visible, "Player skeleton held-hand cutout must stay hidden before flashlight unlock")
			assert_true(
					String(front_hand_visual.texture.resource_path).ends_with("/front_hand.png"),
					"Player skeleton held-hand cutout must use the flashlight-grip hand texture"
			)
		if front_hand_empty_visual != null and front_hand_empty_visual.texture != null:
			assert_true(front_hand_empty_visual.visible, "Player skeleton empty-hand cutout must be the default no-flashlight hand")
			assert_true(
					String(front_hand_empty_visual.texture.resource_path).ends_with("/front_hand_empty.png"),
					"Player skeleton empty-hand cutout must use the base Andry hand texture"
			)
		if front_hand_visual != null and flashlight_visual != null:
			assert_true(flashlight_visual.z_index < front_hand_visual.z_index, "Player skeleton flashlight must render behind the gripping hand")
			_assert_flashlight_visual_sits_inside_front_grip(front_hand_visual, flashlight_visual)
		if torso_visual != null and front_upper_arm_visual != null:
			assert_true(torso_visual.z_index > front_upper_arm_visual.z_index, "Player skeleton torso must hide the front upper-arm photo seam")
		if torso_visual != null and front_forearm_mesh != null:
			assert_true(front_forearm_mesh.z_index > torso_visual.z_index, "Player skeleton front forearm mesh must remain visible over the torso")
		if front_forearm_mesh != null and front_elbow_visual != null:
			assert_true(front_elbow_visual.z_index > front_forearm_mesh.z_index, "Player skeleton front elbow cover must sit over the forearm mesh seam")
			_assert_front_elbow_cover_stays_subtle(front_elbow_visual)
		if torso_visual != null and neck_collar_visual != null and head_visual != null:
			_assert_neck_collar_cover_is_disabled_anchor(torso_visual, neck_collar_visual, head_visual)
		if pelvis_visual != null and torso_visual != null:
			assert_true(pelvis_visual.z_index >= torso_visual.z_index, "Player skeleton pelvis must cover torso/lower-body seams")
		if pelvis_visual != null and front_thigh_visual != null:
			assert_true(pelvis_visual.z_index > front_thigh_visual.z_index, "Player skeleton pelvis must cover the front-thigh upper crop seam")
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
		var front_hand_visual := rig.get_node_or_null("Skeleton2D/" + FRONT_HAND_VISUAL_PATH) as Sprite2D
		var front_hand_empty_visual := rig.get_node_or_null("Skeleton2D/" + FRONT_HAND_EMPTY_VISUAL_PATH) as Sprite2D
		assert_true(flashlight_visual != null, "Player skeleton must keep optional flashlight cutout")
		assert_true(front_hand_visual != null, "Player skeleton must keep held-hand cutout")
		assert_true(front_hand_empty_visual != null, "Player skeleton must keep empty-hand cutout")
		if flashlight_visual != null:
			assert_true(not flashlight_visual.visible, "Player skeleton flashlight cutout must be hidden before flashlight unlock")
		if front_hand_visual != null:
			assert_true(not front_hand_visual.visible, "Player skeleton held-hand cutout must be hidden before flashlight unlock")
		if front_hand_empty_visual != null:
			assert_true(front_hand_empty_visual.visible, "Player skeleton empty-hand cutout must show before flashlight unlock")
		if animation_player != null:
			player.call("_update_walk_animation", 0.016, 1.0)
			assert_eq(animation_player.current_animation, "walk", "Player skeleton animation must use no-flashlight walk before flashlight unlock")
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "walk", 0.0, 0.19, 0.21)
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "walk", 0.4, 0.59, 0.61)
			player.set("_is_running", true)
			player.call("_update_walk_animation", 0.016, 1.0)
			assert_eq(animation_player.current_animation, "run", "Player skeleton animation must use no-flashlight run before flashlight unlock")
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "run", 0.0, 0.13, 0.145)
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "run", 0.275, 0.405, 0.42)
			player.set("_is_running", false)
			player.call("_update_walk_animation", 0.016, 0.0)
			assert_eq(animation_player.current_animation, "idle", "Player skeleton animation must return to idle after no-flashlight run")
		if CycleState != null and CycleState.has_method("collect_flashlight_for_cycle"):
			CycleState.collect_flashlight_for_cycle()
			player.call("_update_skeleton_flashlight_visibility")
			if flashlight_visual != null:
				assert_true(flashlight_visual.visible, "Player skeleton flashlight cutout must appear after flashlight unlock")
			if front_hand_visual != null:
				assert_true(front_hand_visual.visible, "Player skeleton held-hand cutout must appear with the flashlight")
			if front_hand_empty_visual != null:
				assert_true(not front_hand_empty_visual.visible, "Player skeleton empty-hand cutout must hide when the flashlight hand is active")
			if animation_player != null:
				player.call("_update_walk_animation", 0.016, 0.0)
				assert_eq(animation_player.current_animation, "light_idle", "Player skeleton animation must use light_idle while standing with flashlight")
		player.call("apply_checkpoint_state", {"facing_dir": -1.0})
		assert_true(rig.scale.x < 0.0, "PlayerSkeletonRig must mirror with the player facing direction")
		if animation_player != null:
			player.call("_update_walk_animation", 0.016, 1.0)
			assert_eq(animation_player.current_animation, "light_walk", "Player skeleton animation must switch to light_walk while moving with flashlight")
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "light_walk", 0.0, 0.19, 0.21)
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "light_walk", 0.4, 0.59, 0.61)
			player.set("_is_running", true)
			player.call("_update_walk_animation", 0.016, 1.0)
			assert_eq(animation_player.current_animation, "light_run", "Player skeleton animation must switch to light_run while running with flashlight")
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "light_run", 0.0, 0.13, 0.145)
			_assert_skeleton_steps_follow_contact_times(player, animation_player, "light_run", 0.275, 0.405, 0.42)
			player.set("_is_running", false)
			player.call("_update_walk_animation", 0.016, 0.0)
			assert_eq(animation_player.current_animation, "light_idle", "Player skeleton animation must return to light_idle when stopped with flashlight")

	root.queue_free()
	await tree.process_frame

func _almost_eq(left: float, right: float, epsilon: float = 0.0001) -> bool:
	return absf(left - right) <= epsilon

func _get_visual_texture(visual: CanvasItem) -> Texture2D:
	var sprite := visual as Sprite2D
	if sprite != null:
		return sprite.texture
	var polygon := visual as Polygon2D
	if polygon != null:
		return polygon.texture
	return null

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

	var lower_shirt_tail_pixels := 0
	for y in range(mini(HEAD_SHIRT_TAIL_MIN_Y, image.get_height()), image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if _is_visible_low_saturation_shirt_pixel(color):
				lower_shirt_tail_pixels += 1
	assert_true(
			lower_shirt_tail_pixels <= HEAD_MAX_LOWER_SHIRT_TAIL_PIXELS,
			"Player skeleton head cutout must not carry a lower shirt/collar tail that rotates with the head: %s" % visual_path
	)
	assert_true(
			_get_max_alpha_in_row(image, HEAD_NECK_SOLID_SAMPLE_Y) >= HEAD_NECK_MIN_SOLID_ALPHA,
			"Player skeleton head cutout must keep enough visible neck before the torso collar seam: %s" % visual_path
	)
	assert_true(
			_get_max_alpha_in_row(image, HEAD_NECK_SOFT_SAMPLE_Y) <= HEAD_NECK_MAX_SOFT_ALPHA,
			"Player skeleton head cutout lower neck must fade instead of ending in a hard line: %s" % visual_path
	)
	assert_true(
			_get_max_alpha_in_row(image, HEAD_NECK_BOTTOM_SAMPLE_Y) <= HEAD_NECK_MAX_BOTTOM_ALPHA,
			"Player skeleton head cutout lower neck edge must be nearly transparent at the collar seam: %s" % visual_path
	)

func _is_visible_low_saturation_shirt_pixel(color: Color) -> bool:
	if color.a <= 0.1:
		return false
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	if max_channel <= 0.0:
		return false
	var saturation := (max_channel - min_channel) / max_channel
	return saturation <= HEAD_SHIRT_TAIL_MAX_SATURATION and max_channel >= 0.27 and max_channel <= 0.88

func _assert_neck_collar_cover_is_disabled_anchor(torso_visual: Sprite2D, neck_collar_visual: Sprite2D, head_visual: Sprite2D) -> void:
	assert_true(not neck_collar_visual.visible, "Player skeleton neck/collar cover must stay hidden now that head and torso cutouts carry the seam cleanly")
	assert_true(neck_collar_visual.texture != null, "Player skeleton neck/collar cover anchor must keep a compact texture")
	if neck_collar_visual.texture != null:
		assert_true(
				neck_collar_visual.texture.get_width() <= NECK_COLLAR_MAX_TEXTURE_SIZE.x
						and neck_collar_visual.texture.get_height() <= NECK_COLLAR_MAX_TEXTURE_SIZE.y,
				"Player skeleton neck/collar cover anchor must stay compact instead of duplicating the full torso"
		)
		_assert_cutout_has_alpha_negative_space(neck_collar_visual.texture, NECK_COLLAR_VISUAL_PATH, NECK_COLLAR_MIN_TRANSPARENT_RATIO)
		_assert_cutout_has_single_alpha_component(neck_collar_visual.texture, NECK_COLLAR_VISUAL_PATH)
	assert_true(
			neck_collar_visual.z_index > 0,
			"Player skeleton neck/collar cover anchor must retain its old seam-layer z-index for QA toggles"
	)
	assert_true(
			neck_collar_visual.z_index >= torso_visual.z_index,
			"Player skeleton neck/collar cover anchor must stay at the shirt seam level for QA toggles"
	)
	assert_true(
			neck_collar_visual.z_index < head_visual.z_index,
			"Player skeleton neck/collar cover anchor must stay under the rotating head if it is temporarily enabled"
	)
	assert_true(
			neck_collar_visual.position.x >= NECK_COLLAR_MIN_LOCAL_X
					and neck_collar_visual.position.x <= NECK_COLLAR_MAX_LOCAL_X
					and neck_collar_visual.position.y >= NECK_COLLAR_MIN_LOCAL_Y
					and neck_collar_visual.position.y <= NECK_COLLAR_MAX_LOCAL_Y,
			"Player skeleton neck/collar cover anchor must stay on the chest-side head seam"
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
	var waist_bridge_rows := 0
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
		var row_width := max_x - min_x + 1.0
		if y <= SEAM_FILL_WAIST_BRIDGE_MAX_Y:
			if row_width >= SEAM_FILL_WAIST_BRIDGE_MIN_WIDTH:
				waist_bridge_rows += 1
			assert_true(row_width <= SEAM_FILL_WAIST_BRIDGE_MAX_WIDTH, "Player skeleton seam fill waist bridge must stay compact under the shirt hem: %s" % visual_path)
			assert_true(min_x >= SEAM_FILL_WAIST_BRIDGE_MIN_X, "Player skeleton seam fill waist bridge must not keep the left hand or outer leg: %s" % visual_path)
			assert_true(max_x <= SEAM_FILL_WAIST_BRIDGE_MAX_X, "Player skeleton seam fill waist bridge must not keep the right hand or outer leg: %s" % visual_path)
		else:
			assert_true(row_width <= SEAM_FILL_MAX_INTERNAL_WIDTH, "Player skeleton seam fill must stay a narrow hidden strip below the waist bridge: %s" % visual_path)
			assert_true(min_x >= SEAM_FILL_MIN_INTERNAL_X, "Player skeleton seam fill must not keep the left hand or outer leg below the waist bridge: %s" % visual_path)
			assert_true(max_x <= SEAM_FILL_MAX_INTERNAL_X, "Player skeleton seam fill must not keep the right hand or outer leg below the waist bridge: %s" % visual_path)
			for x in range(image.get_width()):
				assert_true(
						image.get_pixel(x, y).a <= SEAM_FILL_LOWER_STRIP_MAX_ALPHA,
						"Player skeleton seam fill below the waist bridge must stay translucent instead of becoming a static trouser strip: %s" % visual_path
				)
	assert_true(max_visible_y <= SEAM_FILL_MAX_INTERNAL_Y, "Player skeleton seam fill must fade before the lower shin/ankle: %s" % visual_path)
	assert_true(
			waist_bridge_rows >= SEAM_FILL_WAIST_BRIDGE_MIN_ROWS,
			"Player skeleton seam fill must keep a short waist bridge so the shirt hem does not reveal a black rectangle: %s" % visual_path
	)

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

func _assert_torso_does_not_keep_static_pajama_waist(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton torso texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(mini(TORSO_STATIC_PAJAMA_MIN_Y, image.get_height()), image.get_height()):
		for x in range(image.get_width()):
			assert_true(
					image.get_pixel(x, y).a <= 0.05,
					"Player skeleton torso must not keep the static pajama strip below the shirt hem: %s" % visual_path
			)

func _assert_thigh_top_fades_under_shirt(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton thigh texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(THIGH_TOP_FADE_START_Y, mini(THIGH_TOP_FADE_END_Y, image.get_height())):
		var max_alpha := 0.0
		for x in range(image.get_width()):
			max_alpha = maxf(max_alpha, image.get_pixel(x, y).a)
		var fade_progress := float(y - THIGH_TOP_FADE_START_Y) / float(THIGH_TOP_FADE_END_Y - THIGH_TOP_FADE_START_Y)
		var expected_max_alpha := smoothstep(0.0, 1.0, fade_progress) + THIGH_TOP_FADE_ALPHA_TOLERANCE
		assert_true(
				max_alpha <= expected_max_alpha,
				"Player skeleton thigh top must fade under the shirt instead of starting as a blocky pajama strip: %s" % visual_path
		)

func _assert_front_shin_does_not_keep_detached_side_strip(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton front shin texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(FRONT_SHIN_DETACHED_STRIP_MIN_Y, mini(FRONT_SHIN_DETACHED_STRIP_MAX_Y, image.get_height())):
		for x in range(FRONT_SHIN_DETACHED_STRIP_MIN_X, image.get_width()):
			assert_true(
					image.get_pixel(x, y).a <= 0.05,
					"Player skeleton front shin must not keep the detached dark source-gap strip: %s" % visual_path
			)

func _assert_front_shin_has_soft_lower_outer_edge(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton front shin texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(FRONT_SHIN_LOWER_SOFT_EDGE_MIN_Y, image.get_height()):
		var min_x := image.get_width()
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
		if min_x >= image.get_width():
			continue
		for x in range(min_x, mini(image.get_width(), min_x + FRONT_SHIN_LOWER_SOFT_EDGE_SAMPLE_WIDTH)):
			assert_true(
					image.get_pixel(x, y).a <= FRONT_SHIN_LOWER_SOFT_EDGE_MAX_ALPHA,
					"Player skeleton front shin lower outer edge must fade into the ankle instead of forming a sharp trouser shard: %s" % visual_path
			)

func _assert_torso_does_not_keep_static_side_arms(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton torso texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var side_arm_skin_pixels := 0
	for y in range(TORSO_STATIC_SIDE_ARM_TOP_Y, image.get_height()):
		for x in range(image.get_width()):
			if not _is_torso_static_side_arm_region(x, y):
				continue
			if _is_skin_toned_pixel(image.get_pixel(x, y)):
				side_arm_skin_pixels += 1
	assert_true(
			side_arm_skin_pixels <= TORSO_STATIC_SIDE_ARM_MAX_SKIN_PIXELS,
			"Player skeleton torso must not keep static side-arm skin that duplicates skeletal arms: %s" % visual_path
	)

func _assert_torso_side_edges_do_not_keep_dark_matte(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton torso texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var left_dark_edge_pixels := 0
	var right_dark_edge_pixels := 0
	for y in range(TORSO_SIDE_EDGE_DARK_MATTE_MIN_Y, mini(TORSO_SIDE_EDGE_DARK_MATTE_MAX_Y, image.get_height())):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		for x in range(min_x, mini(image.get_width(), min_x + TORSO_SIDE_EDGE_DARK_MATTE_SAMPLE_WIDTH)):
			if _is_torso_dark_matte_edge_pixel(image.get_pixel(x, y)):
				left_dark_edge_pixels += 1
		for x in range(maxi(0, max_x - TORSO_SIDE_EDGE_DARK_MATTE_SAMPLE_WIDTH + 1), max_x + 1):
			if _is_torso_dark_matte_edge_pixel(image.get_pixel(x, y)):
				right_dark_edge_pixels += 1
	assert_true(
			left_dark_edge_pixels <= TORSO_LEFT_EDGE_MAX_DARK_MATTE_PIXELS,
			"Player skeleton torso left side edge must not keep a dark source-matte line beside the arm: %s" % visual_path
	)
	assert_true(
			right_dark_edge_pixels <= TORSO_RIGHT_EDGE_MAX_DARK_MATTE_PIXELS,
			"Player skeleton torso right side edge must not keep a dark source-matte line beside the arm: %s" % visual_path
	)

func _is_torso_dark_matte_edge_pixel(color: Color) -> bool:
	if color.a <= TORSO_EDGE_DARK_MATTE_MIN_ALPHA:
		return false
	var luminance := 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	return luminance < TORSO_EDGE_DARK_MATTE_MAX_LUMINANCE

func _assert_torso_does_not_keep_top_right_head_shard(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton torso texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var head_shard_pixels := 0
	for y in range(mini(TORSO_TOP_RIGHT_HEAD_SHARD_MAX_Y + 1, image.get_height())):
		for x in range(TORSO_TOP_RIGHT_HEAD_SHARD_MIN_X, image.get_width()):
			if _is_torso_top_head_shard_pixel(image.get_pixel(x, y)):
				head_shard_pixels += 1
	assert_true(
			head_shard_pixels <= TORSO_TOP_RIGHT_HEAD_SHARD_MAX_PIXELS,
			"Player skeleton torso must not keep top-right head/chin pixels that render as a shard behind the rotating head: %s" % visual_path
	)

func _assert_pelvis_does_not_keep_static_front_hand(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton pelvis texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var static_hand_skin_pixels := 0
	for y in range(0, mini(160, image.get_height())):
		for x in range(0, mini(72, image.get_width())):
			if _is_skin_toned_pixel(image.get_pixel(x, y)):
				static_hand_skin_pixels += 1
	assert_true(
			static_hand_skin_pixels <= PELVIS_STATIC_FRONT_HAND_MAX_SKIN_PIXELS,
			"Player skeleton pelvis cutout must not keep a static duplicate of the front hand: %s" % visual_path
	)

func _is_torso_static_side_arm_region(x: int, y: int) -> bool:
	if y > TORSO_STATIC_SIDE_ARM_LOWER_Y:
		return x < TORSO_STATIC_SIDE_ARM_LOWER_LEFT_MAX_X or x > TORSO_STATIC_SIDE_ARM_LOWER_RIGHT_MIN_X
	return x < TORSO_STATIC_SIDE_ARM_LEFT_MAX_X or x > TORSO_STATIC_SIDE_ARM_RIGHT_MIN_X

func _is_torso_top_head_shard_pixel(color: Color) -> bool:
	if color.a <= 0.1:
		return false
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	if max_channel <= 0.0:
		return false
	var saturation := (max_channel - min_channel) / max_channel
	return saturation >= TORSO_HEAD_SHARD_MIN_SATURATION and color.r >= color.b and max_channel >= 0.18

func _is_skin_toned_pixel(color: Color) -> bool:
	if color.a <= 0.05:
		return false
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	if max_channel <= 0.0:
		return false
	var saturation := (max_channel - min_channel) / max_channel
	var hue := _rgb_hue(color, max_channel, min_channel)
	return (
			hue >= 0.02
			and hue <= 0.12
			and saturation >= 0.18
			and max_channel >= 0.25
			and color.r > color.g * 1.03
			and color.g > color.b * 0.92
	)

func _rgb_hue(color: Color, max_channel: float, min_channel: float) -> float:
	var delta := max_channel - min_channel
	if delta <= 0.0001:
		return 0.0
	var hue_sector := 0.0
	if is_equal_approx(max_channel, color.r):
		hue_sector = fmod((color.g - color.b) / delta, 6.0)
	elif is_equal_approx(max_channel, color.g):
		hue_sector = ((color.b - color.r) / delta) + 2.0
	else:
		hue_sector = ((color.r - color.g) / delta) + 4.0
	var hue := hue_sector / 6.0
	if hue < 0.0:
		hue += 1.0
	return hue

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

func _assert_limb_visual_is_bone_sprite(visual: CanvasItem, visual_path: String) -> void:
	var sprite := visual as Sprite2D
	assert_true(sprite != null, "Active player skeleton limb visual must be a natively rendered Sprite2D: %s" % visual_path)
	if sprite == null:
		return
	assert_true(sprite.get_parent() is Bone2D, "Active player skeleton limb Sprite2D must be parented to a Bone2D: %s" % visual_path)

func _active_limb_mesh_specs() -> Array[Dictionary]:
	return [
		{
			"path": "MeshBackUpperArm",
			"texture": "/back_upper_arm.png",
			"z_index": 0,
			"first_bone": NodePath("../Skeleton2D/Hips/Spine/Chest"),
			"second_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/BackUpperArm"),
		},
		{
			"path": "MeshBackForearm",
			"texture": "/back_forearm.png",
			"z_index": 0,
			"first_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/BackUpperArm"),
			"second_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/BackUpperArm/BackForearm"),
		},
		{
			"path": "MeshBackHand",
			"texture": "/back_hand.png",
			"z_index": 0,
			"first_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/BackUpperArm/BackForearm"),
			"second_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/BackUpperArm/BackForearm/BackHand"),
		},
		{
			"path": "MeshBackThigh",
			"texture": "/back_thigh.png",
			"z_index": 0,
			"first_bone": NodePath("../Skeleton2D/Hips"),
			"second_bone": NodePath("../Skeleton2D/Hips/BackThigh"),
		},
		{
			"path": "MeshBackShin",
			"texture": "/back_shin.png",
			"z_index": 0,
			"first_bone": NodePath("../Skeleton2D/Hips/BackThigh"),
			"second_bone": NodePath("../Skeleton2D/Hips/BackThigh/BackShin"),
		},
		{
			"path": "MeshFrontUpperArm",
			"texture": "/front_upper_arm.png",
			"z_index": 1,
			"first_bone": NodePath("../Skeleton2D/Hips/Spine/Chest"),
			"second_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/FrontUpperArm"),
		},
		{
			"path": "MeshFrontForearm",
			"texture": "/front_forearm.png",
			"z_index": 3,
			"first_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/FrontUpperArm"),
			"second_bone": NodePath("../Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm"),
		},
		{
			"path": "MeshFrontThigh",
			"texture": "/front_thigh.png",
			"z_index": 1,
			"first_bone": NodePath("../Skeleton2D/Hips"),
			"second_bone": NodePath("../Skeleton2D/Hips/FrontThigh"),
		},
		{
			"path": "MeshFrontShin",
			"texture": "/front_shin.png",
			"z_index": 3,
			"first_bone": NodePath("../Skeleton2D/Hips/FrontThigh"),
			"second_bone": NodePath("../Skeleton2D/Hips/FrontThigh/FrontShin"),
		},
	]

func _assert_active_limb_mesh(mesh: Polygon2D, spec: Dictionary) -> void:
	var mesh_path := String(spec["path"])
	assert_true(mesh.visible, "Active player limb mesh must render instead of the legacy Sprite2D anchor: %s" % mesh_path)
	assert_true(mesh.texture != null, "Active player limb mesh must keep a texture: %s" % mesh_path)
	if mesh.texture != null:
		assert_true(String(mesh.texture.resource_path).ends_with(String(spec["texture"])), "Active player limb mesh must use the expected cutout texture: %s" % mesh_path)
	assert_eq(mesh.z_index, int(spec["z_index"]), "Active player limb mesh must keep expected layering z-index: %s" % mesh_path)
	assert_true(mesh.skeleton == NodePath("../Skeleton2D"), "Active player limb mesh must bind to the sibling Skeleton2D: %s" % mesh_path)
	assert_true(mesh.polygon.size() == mesh.uv.size(), "Active player limb mesh polygon and UV arrays must match: %s" % mesh_path)
	assert_true(mesh.polygon.size() == 12, "Active player limb mesh must keep contour row vertices for smooth deformation: %s" % mesh_path)
	assert_true(mesh.internal_vertex_count == 0, "Active player limb mesh must avoid internal center vertices that create native-render cracks: %s" % mesh_path)
	assert_true(mesh.polygons.size() == 5, "Active player limb mesh must keep explicit contour strip polygons for stable native rendering: %s" % mesh_path)
	assert_true(mesh.get_bone_count() == 2, "Active player limb mesh must blend across two neighboring bones: %s" % mesh_path)
	_assert_polygon_bone_weights(mesh, 0, spec["first_bone"], true)
	_assert_polygon_bone_weights(mesh, 1, spec["second_bone"], false)
	if mesh_path == "MeshFrontForearm":
		_assert_front_forearm_mesh_keeps_elbow_overlap(mesh)

func _assert_front_forearm_mesh_keeps_elbow_overlap(mesh: Polygon2D) -> void:
	if mesh.polygon.size() < 7:
		return
	assert_true(
			mesh.polygon[1].x >= FRONT_FOREARM_ELBOW_OVERLAP_TOP_RIGHT_X
					and mesh.polygon[2].x >= FRONT_FOREARM_ELBOW_OVERLAP_TOP_RIGHT_X,
			"Player skeleton front forearm mesh must overlap the upper-arm elbow seam at the top"
	)
	assert_true(
			mesh.polygon[3].x >= FRONT_FOREARM_ELBOW_OVERLAP_MID_RIGHT_X
					and mesh.polygon[4].x >= FRONT_FOREARM_ELBOW_OVERLAP_LOW_RIGHT_X,
			"Player skeleton front forearm mesh must taper its elbow overlap instead of leaving a hard gap"
	)
	assert_true(
			mesh.polygon[5].x <= FRONT_FOREARM_GRIP_RIGHT_X
					and mesh.polygon[6].x <= FRONT_FOREARM_GRIP_RIGHT_X,
			"Player skeleton front forearm mesh must not widen the lower grip/flashlight hand area"
	)

func _assert_polygon_bone_weights(mesh: Polygon2D, bone_index: int, expected_path: NodePath, stronger_at_top: bool) -> void:
	assert_true(mesh.get_bone_path(bone_index) == expected_path, "Active player limb mesh must keep the expected weighted bone path: %s" % mesh.name)
	var weights := mesh.get_bone_weights(bone_index)
	assert_true(weights.size() == mesh.polygon.size(), "Active player limb mesh bone weights must match polygon vertices: %s" % mesh.name)
	if weights.size() < 4:
		return
	if stronger_at_top:
		assert_true(weights[0] > weights[6], "Active player limb mesh first-bone influence must be stronger at the top than the bottom: %s" % mesh.name)
	else:
		assert_true(weights[6] > weights[0], "Active player limb mesh second-bone influence must be stronger at the bottom than the top: %s" % mesh.name)

func _assert_back_forearm_does_not_keep_hand_tail(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton back forearm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(BACK_FOREARM_WRIST_TAPER_MIN_Y, mini(BACK_FOREARM_WRIST_TAPER_MAX_Y + 1, image.get_height())):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		assert_true(
				max_x - min_x + 1 <= BACK_FOREARM_WRIST_TAPER_MAX_WIDTH,
				"Player skeleton back forearm must taper to a narrow wrist instead of keeping hand pixels: %s" % visual_path
		)
	for y in range(mini(BACK_FOREARM_HAND_TAIL_CLEAR_Y, image.get_height()), image.get_height()):
		for x in range(image.get_width()):
			assert_true(
					image.get_pixel(x, y).a <= 0.05,
					"Player skeleton back forearm must leave the hand to the separate back-hand cutout: %s" % visual_path
			)

func _assert_forearm_does_not_keep_clothing_fragments(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton forearm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var clothing_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if _is_forearm_clothing_fragment_pixel(image.get_pixel(x, y)):
				clothing_pixels += 1
	assert_true(
			clothing_pixels <= FOREARM_MAX_CLOTHING_FRAGMENT_PIXELS,
			"Player skeleton forearm cutout must not carry shirt or trouser fragments over the arm: %s" % visual_path
	)

func _is_forearm_clothing_fragment_pixel(color: Color) -> bool:
	if color.a <= 0.05:
		return false
	if _is_forearm_skin_or_shadow_pixel(color):
		return false
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	if max_channel <= 0.0:
		return false
	var saturation := (max_channel - min_channel) / max_channel
	var luminance := 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	var blue_pajama := (
			color.b > color.r * 1.02
			and color.b > color.g * 0.88
			and saturation >= 0.08
			and luminance >= 0.12
	)
	var gray_shirt := saturation < 0.14 and luminance >= 0.16
	return blue_pajama or gray_shirt

func _is_forearm_skin_or_shadow_pixel(color: Color) -> bool:
	if color.a <= 0.05:
		return false
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	if max_channel <= 0.0:
		return false
	var saturation := (max_channel - min_channel) / max_channel
	return (
			max_channel >= 0.16
			and saturation >= 0.10
			and color.r > color.b * 1.08
			and color.g > color.b * 0.82
			and color.r >= color.g * 0.88
	)

func _assert_arm_cutout_has_soft_side_edges(texture: Texture2D, visual_path: String, min_y: int, max_edge_alpha: float) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton arm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(min_y, image.get_height()):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		assert_true(
				image.get_pixel(min_x, y).a <= max_edge_alpha,
				"Player skeleton arm side edge must stay alpha-tapered instead of reading as a cutout slab: %s" % visual_path
		)
		assert_true(
				image.get_pixel(max_x, y).a <= max_edge_alpha,
				"Player skeleton arm side edge must stay alpha-tapered instead of reading as a cutout slab: %s" % visual_path
		)

func _assert_arm_cutout_does_not_keep_opaque_dark_matte_edge(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton arm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var opaque_dark_matte_pixels := 0
	for y in range(image.get_height()):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		for x in range(min_x, max_x + 1):
			if mini(x - min_x, max_x - x) > 4:
				continue
			if _is_opaque_dark_matte_pixel(image.get_pixel(x, y)):
				opaque_dark_matte_pixels += 1
	assert_true(
			opaque_dark_matte_pixels <= ARM_EDGE_MAX_OPAQUE_DARK_MATTE_PIXELS,
			"Player skeleton arm cutout edge must not keep opaque dark source-matte pixels: %s" % visual_path
	)

func _assert_arm_cutout_does_not_keep_visible_dark_edge_fringe(texture: Texture2D, visual_path: String, max_fringe_pixels: int) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton arm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var visible_dark_fringe_pixels := 0
	for y in range(image.get_height()):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		for x in range(min_x, max_x + 1):
			if mini(x - min_x, max_x - x) > 4:
				continue
			if _is_visible_dark_edge_fringe_pixel(image.get_pixel(x, y)):
				visible_dark_fringe_pixels += 1
	assert_true(
			visible_dark_fringe_pixels <= max_fringe_pixels,
			"Player skeleton arm cutout edge must not keep visible dark fringe pixels: %s" % visual_path
	)

func _is_visible_dark_edge_fringe_pixel(color: Color) -> bool:
	if color.a <= ARM_EDGE_VISIBLE_DARK_FRINGE_MIN_ALPHA:
		return false
	var luminance := 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	return luminance < ARM_EDGE_VISIBLE_DARK_FRINGE_MAX_LUMINANCE

func _is_opaque_dark_matte_pixel(color: Color) -> bool:
	if color.a <= 0.70:
		return false
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	if max_channel <= 0.0:
		return false
	var saturation := (max_channel - min_channel) / max_channel
	return max_channel < 0.38 and saturation < 0.32

func _assert_front_elbow_cover_stays_subtle(visual: Sprite2D) -> void:
	assert_true(visual.texture != null, "Player skeleton front elbow cover must keep a texture")
	if visual.texture == null:
		return
	assert_true(
			visual.position.x >= FRONT_ELBOW_COVER_MIN_LOCAL_X
					and visual.position.x <= FRONT_ELBOW_COVER_MAX_LOCAL_X
					and visual.position.y >= FRONT_ELBOW_COVER_MIN_LOCAL_Y
					and visual.position.y <= FRONT_ELBOW_COVER_MAX_LOCAL_Y,
			"Player skeleton front elbow cover must stay tucked onto the forearm seam"
	)
	var image := visual.texture.get_image()
	assert_true(image != null, "Player skeleton front elbow cover texture must expose alpha pixels")
	if image == null:
		return
	var max_alpha := 0.0
	var visible_pixels := 0
	var total_pixels := image.get_width() * image.get_height()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			max_alpha = maxf(max_alpha, alpha)
			if alpha > 0.05:
				visible_pixels += 1
	assert_true(
			max_alpha <= FRONT_ELBOW_COVER_MAX_ALPHA,
			"Player skeleton front elbow cover must not become an opaque patch over the arm"
	)
	assert_true(
			float(visible_pixels) / float(total_pixels) <= FRONT_ELBOW_COVER_MAX_VISIBLE_RATIO,
			"Player skeleton front elbow cover must stay compact enough to hide the seam without reading as a separate oval"
	)

func _assert_front_ankle_cover_fades_above_foot(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton front ankle cover texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	assert_true(
			_get_max_alpha_in_row(image, FRONT_ANKLE_COVER_CUFF_SAMPLE_Y) >= FRONT_ANKLE_COVER_MIN_CUFF_ALPHA,
			"Player skeleton front ankle cover must keep a visible cuff at the trouser seam: %s" % visual_path
	)
	for y in range(FRONT_ANKLE_COVER_LOWER_FADE_START_Y, image.get_height()):
		assert_true(
				_get_max_alpha_in_row(image, y) <= FRONT_ANKLE_COVER_LOWER_MAX_ALPHA,
				"Player skeleton front ankle cover must fade before it reads as a cloth slab over the foot: %s" % visual_path
		)
	assert_true(
			_get_max_alpha_in_row(image, FRONT_ANKLE_COVER_BOTTOM_SAMPLE_Y) <= FRONT_ANKLE_COVER_BOTTOM_MAX_ALPHA,
			"Player skeleton front ankle cover must be almost transparent at the lower foot edge: %s" % visual_path
	)

func _get_max_alpha_in_row(image: Image, y: int) -> float:
	if y < 0 or y >= image.get_height():
		return 0.0
	var max_alpha := 0.0
	for x in range(image.get_width()):
		max_alpha = maxf(max_alpha, image.get_pixel(x, y).a)
	return max_alpha

func _assert_upper_arm_does_not_keep_duplicate_sleeve(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton upper-arm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var duplicate_sleeve_pixels := 0
	for y in range(mini(UPPER_ARM_DUPLICATE_SLEEVE_CLEAR_ROWS, image.get_height())):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.05:
				duplicate_sleeve_pixels += 1
	assert_true(
			duplicate_sleeve_pixels == 0,
			"Player skeleton upper arm must not keep the duplicate shirt sleeve that rotates with the arm: %s" % visual_path
	)

func _assert_back_upper_arm_does_not_keep_lower_torso_tail(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton back upper-arm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(mini(BACK_UPPER_ARM_TORSO_TAIL_MIN_Y, image.get_height()), image.get_height()):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		assert_true(
				min_x >= BACK_UPPER_ARM_TORSO_TAIL_MIN_LEFT_X,
				"Player skeleton back upper arm must not rotate the lower torso/shirt tail with the arm: %s" % visual_path
		)
		assert_true(
				max_x - min_x + 1 <= BACK_UPPER_ARM_TORSO_TAIL_MAX_WIDTH,
				"Player skeleton back upper arm lower edge must stay a narrow arm/sleeve shape: %s" % visual_path
		)

func _assert_front_upper_arm_does_not_keep_side_torso_tail(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton front upper-arm texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(FRONT_UPPER_ARM_TORSO_TAIL_MIN_Y, image.get_height()):
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		assert_true(
				max_x <= FRONT_UPPER_ARM_TORSO_TAIL_MAX_RIGHT_X,
				"Player skeleton front upper arm must not rotate the side torso/shirt tail with the arm: %s" % visual_path
		)

func _assert_back_thigh_has_soft_lower_edges(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton back thigh texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(BACK_THIGH_SOFT_EDGE_MIN_Y, image.get_height()):
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		assert_true(
				image.get_pixel(min_x, y).a <= BACK_THIGH_SOFT_EDGE_MAX_ALPHA,
				"Player skeleton back thigh lower left edge must stay alpha-tapered: %s" % visual_path
		)
		assert_true(
				image.get_pixel(max_x, y).a <= BACK_THIGH_SOFT_EDGE_MAX_ALPHA,
				"Player skeleton back thigh lower right edge must stay alpha-tapered: %s" % visual_path
		)

func _assert_back_leg_underlay_stays_subtle(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton back-leg underlay texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var max_alpha := 0.0
	var visible_pixels := 0
	var skin_pixels := 0
	var total_pixels := image.get_width() * image.get_height()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a <= 0.05:
				continue
			visible_pixels += 1
			max_alpha = maxf(max_alpha, color.a)
			if _is_skin_toned_pixel(color):
				skin_pixels += 1
	assert_true(
			max_alpha <= BACK_LEG_UNDERLAY_MAX_ALPHA,
			"Player skeleton back-leg underlay must stay translucent instead of becoming a static full leg: %s" % visual_path
	)
	assert_true(
			float(visible_pixels) / float(total_pixels) <= BACK_LEG_UNDERLAY_MAX_VISIBLE_RATIO,
			"Player skeleton back-leg underlay must stay sparse enough to avoid a static lower-body ghost: %s" % visual_path
	)
	assert_true(
			skin_pixels <= BACK_LEG_UNDERLAY_MAX_SKIN_PIXELS,
			"Player skeleton back-leg underlay must not bring hands or feet back under the skeleton: %s" % visual_path
	)

func _assert_back_shin_has_soft_inner_edge(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton back shin texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	for y in range(BACK_SHIN_SOFT_INNER_EDGE_MIN_Y, image.get_height()):
		var edge_x := _find_left_visible_pixel_in_row(image, y)
		if edge_x < 0:
			continue
		assert_true(
				image.get_pixel(edge_x, y).a <= BACK_SHIN_SOFT_SIDE_EDGE_MAX_ALPHA,
				"Player skeleton back shin inner edge must stay alpha-tapered instead of reading as a hard cut: %s" % visual_path
		)
		var right_edge_x := _find_right_visible_pixel_in_row(image, y)
		if right_edge_x < 0:
			continue
		assert_true(
				image.get_pixel(right_edge_x, y).a <= BACK_SHIN_SOFT_SIDE_EDGE_MAX_ALPHA,
				"Player skeleton back shin outer edge must stay alpha-tapered instead of reading as a hard cut: %s" % visual_path
		)
	_assert_back_shin_lower_contour_tapers(image, visual_path)

func _assert_back_shin_lower_contour_tapers(image: Image, visual_path: String) -> void:
	for index in range(BACK_SHIN_LOWER_TAPER_SAMPLE_ROWS.size()):
		var y := BACK_SHIN_LOWER_TAPER_SAMPLE_ROWS[index]
		if y < 0 or y >= image.get_height():
			continue
		var min_x := image.get_width()
		var max_x := -1
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if max_x < 0:
			continue
		var row_width := max_x - min_x + 1
		assert_true(
				row_width <= BACK_SHIN_LOWER_TAPER_MAX_WIDTHS[index],
				"Player skeleton back shin lower contour must taper instead of keeping a rectangular side slab: %s" % visual_path
		)

func _assert_front_thigh_has_soft_outer_edge(texture: Texture2D, visual_path: String) -> void:
	var image := texture.get_image()
	assert_true(image != null, "Player skeleton front thigh texture must expose alpha pixels: %s" % visual_path)
	if image == null:
		return
	var previous_left_x := -1
	for y in range(FRONT_THIGH_SMOOTH_HIP_MIN_Y, mini(FRONT_THIGH_SMOOTH_HIP_MAX_Y + 1, image.get_height())):
		var left_x := _find_left_visible_pixel_in_row(image, y)
		if left_x < 0:
			continue
		if previous_left_x >= 0:
			assert_true(
					previous_left_x - left_x <= FRONT_THIGH_MAX_LEFT_EDGE_STEP,
					"Player skeleton front thigh left hip contour must not jump into a blocky side slab: %s" % visual_path
			)
		previous_left_x = left_x
	for y in range(FRONT_THIGH_SOFT_EDGE_MIN_Y, mini(FRONT_THIGH_SOFT_EDGE_MAX_Y + 1, image.get_height())):
		var edge_x := _find_left_visible_pixel_in_row(image, y)
		if edge_x < 0:
			continue
		assert_true(
				image.get_pixel(edge_x, y).a <= FRONT_THIGH_SOFT_EDGE_MAX_ALPHA,
				"Player skeleton front thigh outer edge must stay alpha-tapered: %s" % visual_path
		)

func _find_left_visible_pixel_in_row(image: Image, y: int) -> int:
	for x in range(image.get_width()):
		if image.get_pixel(x, y).a > 0.05:
			return x
	return -1

func _find_right_visible_pixel_in_row(image: Image, y: int) -> int:
	for x in range(image.get_width() - 1, -1, -1):
		if image.get_pixel(x, y).a > 0.05:
			return x
	return -1

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

func _assert_animation_track_mean_in_range(animation: Animation, track_path: NodePath, min_mean: float, max_mean: float, animation_name: String) -> void:
	var track_index := -1
	for candidate_index in range(animation.get_track_count()):
		if animation.track_get_path(candidate_index) == track_path:
			track_index = candidate_index
			break
	assert_true(track_index >= 0, "Player skeleton animation %s must animate track %s" % [animation_name, track_path])
	if track_index < 0:
		return
	var value_sum := 0.0
	var key_count := animation.track_get_key_count(track_index)
	for key_index in range(key_count):
		value_sum += float(animation.track_get_key_value(track_index, key_index))
	var value_mean := value_sum / float(key_count)
	assert_true(value_mean >= min_mean, "Player skeleton animation %s track %s must keep its forward run lean" % [animation_name, track_path])
	assert_true(value_mean <= max_mean, "Player skeleton animation %s track %s must avoid excessive forward run lean" % [animation_name, track_path])

func _assert_animation_track_key_count_at_least(animation: Animation, track_path: NodePath, min_key_count: int, animation_name: String) -> void:
	var track_index := -1
	for candidate_index in range(animation.get_track_count()):
		if animation.track_get_path(candidate_index) == track_path:
			track_index = candidate_index
			break
	assert_true(track_index >= 0, "Player skeleton animation %s must animate track %s" % [animation_name, track_path])
	if track_index < 0:
		return
	assert_true(
			animation.track_get_key_count(track_index) >= min_key_count,
			"Player skeleton animation %s track %s must keep intermediate passing keys for smoother foot arcs" % [animation_name, track_path]
	)

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
	assert_true(value_range >= min_range, "Player skeleton animation %s track %s must keep visible vertical motion" % [animation_name, track_path])
	assert_true(value_range <= max_range, "Player skeleton animation %s track %s must avoid excessive vertical motion" % [animation_name, track_path])

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
