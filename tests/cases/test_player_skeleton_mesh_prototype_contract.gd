extends "res://tests/test_case.gd"

const ACTIVE_PLAYER_SCENE_PATH := "res://player/player.tscn"
const FOREARM_MESH_PROTOTYPE_SCENE_PATH := "res://player/player_skeleton_forearm_mesh_prototype.tscn"
const MESH_PATH := "MeshFrontForearm"
const SKELETON_PATH := "Skeleton2D"
const UPPER_ARM_BONE_PATH := "../Skeleton2D/FrontUpperArm"
const FOREARM_BONE_PATH := "../Skeleton2D/FrontUpperArm/FrontForearm"
const MIN_INTERNAL_VERTEX_COUNT := 8
const EXPECTED_MESH_ANIMATION := &"forearm_mesh_flex"

func run() -> Array[String]:
	_test_forearm_mesh_prototype_contract()
	_test_active_player_does_not_use_mesh_prototype_scene()
	return get_failures()

func _test_forearm_mesh_prototype_contract() -> void:
	var prototype_scene := assert_loads(FOREARM_MESH_PROTOTYPE_SCENE_PATH) as PackedScene
	assert_true(prototype_scene != null, "Player forearm mesh prototype scene failed to load")
	if prototype_scene == null:
		return

	var prototype := prototype_scene.instantiate()
	var skeleton := prototype.get_node_or_null(SKELETON_PATH) as Skeleton2D
	var mesh := prototype.get_node_or_null(MESH_PATH) as Polygon2D
	var animation_player := prototype.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_true(skeleton != null, "Player forearm mesh prototype must keep a Skeleton2D")
	assert_true(skeleton != null and skeleton.get_node_or_null("FrontUpperArm") is Bone2D, "Player forearm mesh prototype must keep an upper-arm bone")
	assert_true(skeleton != null and skeleton.get_node_or_null("FrontUpperArm/FrontForearm") is Bone2D, "Player forearm mesh prototype must keep a forearm bone")
	assert_true(mesh != null, "Player forearm mesh prototype must keep a Polygon2D mesh")
	if mesh != null:
		assert_true(mesh.texture != null, "Player forearm mesh prototype must use the current front-forearm cutout texture")
		if mesh.texture != null:
			assert_true(String(mesh.texture.resource_path).ends_with("/front_forearm.png"), "Player forearm mesh prototype must use front_forearm.png")
		assert_true(mesh.skeleton == NodePath("../Skeleton2D"), "Player forearm mesh prototype must bind Polygon2D to the sibling Skeleton2D")
		assert_true(mesh.polygon.size() == mesh.uv.size(), "Player forearm mesh prototype polygon and UV arrays must match")
		assert_true(mesh.internal_vertex_count >= MIN_INTERNAL_VERTEX_COUNT, "Player forearm mesh prototype must keep internal vertices for non-rigid deformation")
		assert_true(mesh.get_bone_count() == 2, "Player forearm mesh prototype must blend across upper-arm and forearm bones")
		_assert_mesh_weights(mesh, 0, NodePath(UPPER_ARM_BONE_PATH), true)
		_assert_mesh_weights(mesh, 1, NodePath(FOREARM_BONE_PATH), false)
	assert_true(animation_player != null, "Player forearm mesh prototype must keep an AnimationPlayer")
	if animation_player != null:
		assert_true(animation_player.has_animation(EXPECTED_MESH_ANIMATION), "Player forearm mesh prototype must keep a flex animation")
	prototype.free()

func _test_active_player_does_not_use_mesh_prototype_scene() -> void:
	var active_scene_text := FileAccess.get_file_as_string(ACTIVE_PLAYER_SCENE_PATH)
	assert_true(active_scene_text.find(FOREARM_MESH_PROTOTYPE_SCENE_PATH) == -1, "Active player must not switch to the experimental forearm mesh prototype scene")

func _assert_mesh_weights(mesh: Polygon2D, bone_index: int, expected_path: NodePath, upper_arm_weights: bool) -> void:
	assert_true(mesh.get_bone_path(bone_index) == expected_path, "Player forearm mesh prototype must keep the expected weighted bone path")
	var weights := mesh.get_bone_weights(bone_index)
	assert_true(weights.size() == mesh.polygon.size(), "Player forearm mesh prototype bone weights must match polygon vertices")
	if weights.size() < 4:
		return
	if upper_arm_weights:
		assert_true(weights[0] > weights[2], "Player forearm mesh prototype upper-arm influence must be stronger near the elbow")
	else:
		assert_true(weights[2] > weights[0], "Player forearm mesh prototype forearm influence must be stronger near the wrist")
