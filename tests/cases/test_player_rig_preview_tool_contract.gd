extends "res://tests/test_case.gd"

const SCENE_CONTEXT_TOOL_PATH := "res://tools/player_rig_preview/export_player_rig_scene_context.py"

func run() -> Array[String]:
	assert_true(FileAccess.file_exists(SCENE_CONTEXT_TOOL_PATH), "Player rig scene-context preview tool must exist")
	if not FileAccess.file_exists(SCENE_CONTEXT_TOOL_PATH):
		return get_failures()

	var source := FileAccess.get_file_as_string(SCENE_CONTEXT_TOOL_PATH)
	assert_true(source.find("DEFAULT_OUTPUT = Path(\"/tmp/andry_player_rig_scene_context.png\")") != -1, "Scene-context preview must default outside the repository")
	assert_true(source.find("BEHIND_OBJECT_Z = 1") != -1, "Scene-context preview must keep a behind-player probe object")
	assert_true(source.find("PLAYER_ROOT_Z = 2") != -1, "Scene-context preview must render the player above behind-player objects")
	assert_true(source.find("FOREGROUND_OBJECT_Z = 10") != -1, "Scene-context preview must keep a foreground occluder probe")
	assert_true(source.find("BEHIND_DOOR_TEXTURE") != -1 and source.find("DoorBasic.png") != -1, "Scene-context preview must use a real door asset behind the player")
	assert_true(source.find("FOREGROUND_CHAIR_TEXTURE") != -1 and source.find("ChairBedroom.png") != -1, "Scene-context preview must use a real foreground object")
	assert_true(source.find("PLAYER_ROOT_Z + int(visual[\"z_index\"])") != -1, "Scene-context preview must sort individual player visuals by effective z-index")
	assert_true(source.find("_build_godot_dump_script") != -1, "Scene-context preview must sample real Godot skeleton transforms")
	assert_true(source.find("--flashlight") != -1, "Scene-context preview must support the flashlight variant")
	var montage_source := FileAccess.get_file_as_string("res://tools/player_rig_preview/export_player_rig_montage.py")
	assert_true(montage_source.find("VisualFrontHandEmpty") != -1, "Rig preview dump must switch the empty-hand cutout for no-flashlight previews")
	assert_true(montage_source.find("held_hand.visible = SHOW_FLASHLIGHT") != -1, "Rig preview dump must show the held hand only with flashlight previews")
	return get_failures()
