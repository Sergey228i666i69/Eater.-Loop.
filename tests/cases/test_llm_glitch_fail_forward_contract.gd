extends "res://tests/test_case.gd"

const LLM_GLITCH_SCRIPT_PATH := "res://levels/minigames/labs/LLM/llm_minigame_glitch.gd"

func run() -> Array[String]:
	var script_text := FileAccess.get_file_as_string(LLM_GLITCH_SCRIPT_PATH)
	assert_true(script_text != "", "Failed to read llm_minigame_glitch.gd")
	if script_text == "":
		return get_failures()

	assert_true(script_text.find("const INTENTIONAL_FAIL_FORWARD_MAX_PROGRESS := 0.96") != -1, "LLM glitch must name its intentional max progress cap")
	assert_true(script_text.find("const SUCCESS_PROGRESS_THRESHOLD := 1.0") != -1, "LLM glitch must name its unreachable success threshold")
	assert_true(script_text.find("complete_lab_on_failure = true") != -1, "LLM glitch must explicitly keep failure as the lab-completion path")
	assert_true(script_text.find("clamp(_progress + chaotic_gain, 0.0, INTENTIONAL_FAIL_FORWARD_MAX_PROGRESS)") != -1, "LLM glitch progress must be capped by the named fail-forward constant")
	assert_true(script_text.find("_progress >= SUCCESS_PROGRESS_THRESHOLD") != -1, "LLM glitch success check must use the named threshold")

	return get_failures()
