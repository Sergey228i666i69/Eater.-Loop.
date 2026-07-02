extends "res://tests/test_case.gd"

const GAMEPAD_SCRIPT_ROOTS: Array[String] = [
	"res://levels/minigames",
	"res://objects/interactable/fridge"
]
const EXCLUDE_DIRS: Array[String] = [".godot", "addons"]
const GAMEPAD_REGISTRATION := "MinigameController.set_gamepad_scheme(self"
const GAMEPAD_CLEANUP_NEEDLES: Array[String] = [
	"MinigameController.clear_gamepad_scheme",
	"cleanup_timed_lab"
]

func run() -> Array[String]:
	var scripts_with_scheme := _find_scripts_with_gamepad_scheme()
	assert_true(not scripts_with_scheme.is_empty(), "Gamepad binding contract must discover registered minigame scripts")
	for path in scripts_with_scheme:
		_assert_script_contains(path, GAMEPAD_REGISTRATION, "Missing gamepad scheme registration")
		_assert_script_contains_any(path, GAMEPAD_CLEANUP_NEEDLES, "Missing gamepad scheme cleanup")

	_assert_script_contains("res://levels/minigames/minigame_controller.gd", "func set_gamepad_scheme", "MinigameController API set_gamepad_scheme missing")
	_assert_script_contains("res://levels/minigames/minigame_controller.gd", "func clear_gamepad_scheme", "MinigameController API clear_gamepad_scheme missing")
	_assert_script_not_contains("res://levels/minigames/minigame_controller.gd", "warp_mouse", "Legacy warp_mouse call must be removed")
	return get_failures()

func _find_scripts_with_gamepad_scheme() -> Array[String]:
	var result: Array[String] = []
	for root in GAMEPAD_SCRIPT_ROOTS:
		for path in utils.list_files(root, ".gd", EXCLUDE_DIRS):
			if path == "res://levels/minigames/minigame_controller.gd":
				continue
			if _script_contains(path, GAMEPAD_REGISTRATION):
				result.append(path)
	result.sort()
	return result

func _assert_script_contains(path: String, needle: String, message: String) -> void:
	if not FileAccess.file_exists(path):
		fail("Missing file: %s" % path)
		return
	assert_true(_script_contains(path, needle), "%s (%s)" % [message, path])

func _assert_script_contains_any(path: String, needles: Array[String], message: String) -> void:
	if not FileAccess.file_exists(path):
		fail("Missing file: %s" % path)
		return
	var content := FileAccess.get_file_as_string(path)
	for needle in needles:
		if content.find(needle) != -1:
			return
	assert_true(false, "%s (%s)" % [message, path])

func _assert_script_not_contains(path: String, needle: String, message: String) -> void:
	if not FileAccess.file_exists(path):
		fail("Missing file: %s" % path)
		return
	var content := FileAccess.get_file_as_string(path)
	assert_true(content.find(needle) == -1, "%s (%s)" % [message, path])

func _script_contains(path: String, needle: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	return FileAccess.get_file_as_string(path).find(needle) != -1
