extends "res://tests/test_case.gd"

const TOOL_PATH := "res://tools/player_cutout_inpaint/build_player_cutout_inpaint_package.py"
const EXPECTED_TARGETS: Array[String] = [
	"front_thigh",
	"back_thigh",
	"front_shin",
	"back_shin",
	"front_hand",
	"back_hand",
	"flashlight",
]

func run() -> Array[String]:
	assert_true(FileAccess.file_exists(TOOL_PATH), "Player cutout inpaint prep tool must exist")
	if not FileAccess.file_exists(TOOL_PATH):
		return get_failures()

	var source := FileAccess.get_file_as_string(TOOL_PATH)
	assert_true(source.find("DEFAULT_OUT_DIR = Path(\"/tmp/andry-cutout-inpaint\")") != -1, "Inpaint prep output must default outside the repository")
	assert_true(source.find("ImageChops.subtract(editable, locked)") != -1, "Inpaint prep mask must subtract existing visible pixels")
	assert_true(source.find("visible existing pixels are locked by the mask") != -1, "Inpaint prompt must preserve existing Andry pixels")
	assert_true(source.find("AndryWithFlashlight.png") != -1, "Inpaint prep must keep flashlight source reference")
	assert_true(source.find("Andry.png") != -1, "Inpaint prep must keep base Andry source reference")
	assert_true(source.find("--target") != -1 and source.find("--all") != -1, "Inpaint prep must support focused and full package generation")
	for target_name in EXPECTED_TARGETS:
		assert_true(source.find("\"%s\": TargetSpec" % target_name) != -1, "Inpaint prep must keep target: %s" % target_name)
	return get_failures()
