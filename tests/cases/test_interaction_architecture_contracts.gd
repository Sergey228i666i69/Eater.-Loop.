extends "res://tests/test_case.gd"

const SEARCH_DIRS := [
	"res://levels",
	"res://objects",
	"res://player",
	"res://enemies",
	"res://global"
]
const SCENE_DIRS := [
	"res://levels",
	"res://player",
	"res://enemies",
	"res://objects"
]
const ALLOWED_PRIVATE_INTERACTIVE_ACCESS := {
	"res://objects/interactable/interactive_object.gd": true
}
const INTERACTIVE_PRIVATE_PATTERNS := [
	"_setup_dependency_listener",
	"_refresh_prompt_state"
]
const LEGACY_UI_TEXT_PATTERNS := [
	"show_text(",
	"show_message(",
	"show_subtitle("
]
const LEGACY_INTERACTION_FLAG_PATTERNS := [
	".auto_prompt =",
	".handle_input ="
]
const LEGACY_SCENE_CALLBACK_PATTERNS := [
	"on_fed_andrey"
]
const GAME_DIRECTOR_PATH := "res://levels/game_director.gd"
const GAME_STATE_PATH := "res://levels/cycles/game_state.gd"
const CYCLE_STATE_PATH := "res://levels/cycles/cycle_state.gd"
const FRIDGE_PATH := "res://objects/interactable/fridge/fridge.gd"
const SCENE_CONTEXT_PATH := "res://global/scene_context.gd"
const ACTIVE_SCENE_EXCLUDE_SUBSTRINGS: Array[String] = ["archive", "trash"]
const FORBIDDEN_GAME_DIRECTOR_PATTERNS := [
	"has_method(\"handle_custom_death_screen\")",
	"call(\"handle_custom_death_screen\"",
	"call('handle_custom_death_screen'",
	"func _find_stalker_spawn",
	"func _create_stalker",
	"func _restore_stalker_from_checkpoint"
]
const FORBIDDEN_GAME_STATE_FIELD_PATTERNS := [
	"GameState.last_scene_path",
	"GameState.has_active_run",
	"GameState.flashlight_unlocked",
	"GameState.unique_feeding_intro_played"
]
const FORBIDDEN_CYCLE_STATE_FIELD_PATTERNS := [
	"CycleState.phase",
	"CycleState.ate_this_cycle",
	"CycleState.lab_done",
	"CycleState.completed_labs",
	"CycleState.phone_picked",
	"CycleState.fridge_interacted",
	"CycleState.pending_sleep_spawn",
	"CycleState.pending_respawn_blackout",
	"CycleState.flashlight_collected_this_cycle"
]
const FORBIDDEN_ACTIVE_SCENE_PATTERNS := [
	"archive(trash)"
]

func run() -> Array[String]:
	var scripts: Array[String] = []
	for dir_path in SEARCH_DIRS:
		scripts.append_array(utils.list_files(dir_path, ".gd", ["tests", ".godot", "addons"]))
	scripts.sort()

	for path in scripts:
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read script: %s" % path)
		if content == "":
			continue

		if not ALLOWED_PRIVATE_INTERACTIVE_ACCESS.has(path):
			for pattern in INTERACTIVE_PRIVATE_PATTERNS:
				assert_true(content.find(pattern) == -1, "InteractiveObject private API usage is forbidden: %s (%s)" % [path, pattern])

		for pattern in LEGACY_UI_TEXT_PATTERNS:
			assert_true(content.find(pattern) == -1, "Legacy UI text API usage is forbidden: %s (%s)" % [path, pattern])

		for pattern in LEGACY_INTERACTION_FLAG_PATTERNS:
			assert_true(content.find(pattern) == -1, "Legacy interaction flag mutation is forbidden: %s (%s)" % [path, pattern])

		for pattern in LEGACY_SCENE_CALLBACK_PATTERNS:
			assert_true(content.find(pattern) == -1, "Legacy scene callback is forbidden: %s (%s)" % [path, pattern])

		assert_true(content.find("print(") == -1, "Runtime scripts should use print_verbose(), push_warning(), or a typed UI/logging path instead of raw print(): %s" % path)

		if path != GAME_STATE_PATH:
			for pattern in FORBIDDEN_GAME_STATE_FIELD_PATTERNS:
				assert_true(not _contains_symbol_access(content, pattern), "External GameState field access must go through public methods: %s (%s)" % [path, pattern])

		if path != CYCLE_STATE_PATH:
			for pattern in FORBIDDEN_CYCLE_STATE_FIELD_PATTERNS:
				assert_true(not _contains_symbol_access(content, pattern), "External CycleState field access must go through public methods: %s (%s)" % [path, pattern])

		if path != SCENE_CONTEXT_PATH:
			assert_true(content.find("path.find(\"/levels/cycles/\")") == -1, "Gameplay scene path checks must go through SceneContext: %s" % path)
			assert_true(content.find("path.find(\"/levels/menu/\")") == -1, "Menu scene path checks must go through SceneContext: %s" % path)

	var scenes: Array[String] = []
	for dir_path in SCENE_DIRS:
		scenes.append_array(utils.list_files(dir_path, ".tscn", ["tests", ".godot", "addons"], ACTIVE_SCENE_EXCLUDE_SUBSTRINGS))
	scenes.sort()
	for path in scenes:
		var content := FileAccess.get_file_as_string(path)
		assert_true(content != "", "Failed to read scene: %s" % path)
		if content == "":
			continue
		for pattern in FORBIDDEN_ACTIVE_SCENE_PATTERNS:
			assert_true(content.find(pattern) == -1, "Active scene must not reference archived resources: %s (%s)" % [path, pattern])

	var game_director_content := FileAccess.get_file_as_string(GAME_DIRECTOR_PATH)
	assert_true(game_director_content != "", "Failed to read script: %s" % GAME_DIRECTOR_PATH)
	if game_director_content != "":
		for pattern in FORBIDDEN_GAME_DIRECTOR_PATTERNS:
			assert_true(game_director_content.find(pattern) == -1, "Stringly custom death handler access is forbidden: %s" % pattern)

	var game_state_content := FileAccess.get_file_as_string(GAME_STATE_PATH)
	assert_true(game_state_content.find("func autosave_run") != -1, "GameState must expose public autosave_run()")

	var fridge_content := FileAccess.get_file_as_string(FRIDGE_PATH)
	assert_true(fridge_content.find("autosave_run") != -1, "Fridge must trigger autosave after successful interaction")

	return get_failures()

func _contains_symbol_access(content: String, symbol: String) -> bool:
	var from := 0
	while true:
		var index := content.find(symbol, from)
		if index == -1:
			return false
		var end := index + symbol.length()
		if end >= content.length() or not _is_identifier_char(content.unicode_at(end)):
			return true
		from = end
	return false

func _is_identifier_char(codepoint: int) -> bool:
	return codepoint == 95 \
		or (codepoint >= 48 and codepoint <= 57) \
		or (codepoint >= 65 and codepoint <= 90) \
		or (codepoint >= 97 and codepoint <= 122)
