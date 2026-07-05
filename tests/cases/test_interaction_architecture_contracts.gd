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
const LEGACY_RUNTIME_TEXT_PATTERNS := [
	"Frizzer"
]
const INLINE_KEY_REWARD_PAYLOAD_PATTERNS := [
	"\"reward_type\": \"key\""
]
const LEGACY_INTERACTION_FINISHED_SCRIPT_PATTERNS := [
	".interaction_finished.connect",
	"condition_signal_name: StringName = &\"interaction_finished\""
]
const LEGACY_INTERACTION_FINISHED_SCENE_PATTERNS := [
	"condition_signal_name = &\"interaction_finished\""
]
const CONTENT_OBJECT_STRINGLY_PATTERNS := [
	"UIMessage.has_method(\"fade_out\")",
	"UIMessage.has_method(\"fade_in\")",
	"has_method(\"apply_winch_release_state\")",
	".call(\"apply_winch_release_state\"",
	"has_method(\"try_open_blockpost\")",
	".call(\"try_open_blockpost\"",
	"has_method(\"has_enough_money\")",
	".call(\"has_enough_money\"",
	"has_method(\"add_money\")",
	".call(\"add_money\""
]
const GAME_DIRECTOR_PATH := "res://levels/game_director.gd"
const GAME_STATE_PATH := "res://levels/cycles/game_state.gd"
const CYCLE_STATE_PATH := "res://levels/cycles/cycle_state.gd"
const LEVEL_14_END_PATH := "res://levels/cycles/level_14_end.gd"
const PLAYER_PATH := "res://player/player.gd"
const STAMINA_BAR_PATH := "res://player/stamina_bar.gd"
const FLASHLIGHT_BAR_PATH := "res://player/flashlight_bar.gd"
const UI_MESSAGE_PATH := "res://player/ui_message.gd"
const PAUSE_MANAGER_PATH := "res://levels/menu/pause_manager.gd"
const FRIDGE_PATH := "res://objects/interactable/fridge/fridge.gd"
const FRIDGE_COMPLETION_SESSION_PATH := "res://objects/interactable/fridge/fridge_completion_session.gd"
const FINAL_ENDING_FRIDGE_PATH := "res://objects/interactable/fridge/final_ending_fridge.gd"
const PICKUP_FLASHLIGHT_PATH := "res://objects/interactable/flashlight/pickup_flashlight.gd"
const GENERATOR_PATH := "res://objects/interactable/generator/generator.gd"
const KEY_PATH := "res://objects/interactable/key/key.gd"
const NOTE_OBJECT_PATH := "res://objects/interactable/note/note_object.gd"
const DOOR_PATH := "res://objects/interactable/door/door.gd"
const LAPTOP_PATH := "res://objects/interactable/notebook/laptop.gd"
const LEBEDKA_PATH := "res://objects/interactable/lebedka/lebedka.gd"
const SEARCH_KEY_MINIGAME_PATH := "res://levels/minigames/search_key/search_minigame.gd"
const TARGET_MONSTER_SPAWNER_PATH := "res://objects/environment/smart/target/target.gd"
const INTERACTIVE_OBJECT_PATH := "res://objects/interactable/interactive_object.gd"
const INTERACTION_RESULT_BUILDER_PATH := "res://objects/interactable/interaction_result_builder.gd"
const BED_PATH := "res://objects/interactable/bed/bed.gd"
const CYCLE_LEVEL_PATH := "res://levels/cycles/level.gd"
const MINIGAME_CONTROLLER_PATH := "res://levels/minigames/minigame_controller.gd"
const MINIGAME_PROMPT_VISIBILITY_COORDINATOR_PATH := "res://levels/minigames/minigame_prompt_visibility_coordinator.gd"
const MINIGAME_MUSIC_SESSION_PATH := "res://levels/minigames/minigame_music_session.gd"
const SCENE_CONTEXT_PATH := "res://global/scene_context.gd"
const INTERACTION_MANAGER_PATH := "res://global/interaction_manager.gd"
const PROMPT_VIEW_PATH := "res://levels/prompt_view.gd"
const CRAZY_LEVEL_EVENT_PATH := "res://levels/cycles/crazy_level_event.gd"
const TEXTURE_DISTORTION_MANAGER_PATH := "res://levels/cycles/texture_distortion_manager.gd"
const LEVEL_11_STU_1_PATH := "res://levels/cycles/level_11_stu_1.gd"
const LEVEL_13_STU_3_PATH := "res://levels/cycles/level_13_stu_3.gd"
const LEVEL_11_END_PATH := "res://levels/cycles/level_11_end.gd"
const ENDING_SCREEN_PATH := "res://levels/endings/ending_screen.gd"
const ENDING_CREDITS_PATH := "res://levels/endings/ending_credits.gd"
const ENEMY_BASE_PATH := "res://enemies/enemy.gd"
const ENEMY_FLASHLIGHT_BASE_PATH := "res://enemies/enemy_flashlight_base.gd"
const ENEMY_CEILING_PATH := "res://enemies/light_ceiling/enemy_ceiling.gd"
const ENEMY_LIGHT_ONLY_PATH := "res://enemies/light_only/enemy_light_only.gd"
const FEED_MINIGAME_PATH := "res://levels/minigames/feeding/feed_minigame.gd"
const FEED_DETACH_HANDS_PATH := "res://levels/minigames/feeding/feed_minigame_detach_hands.gd"
const FINAL_FEED_MINIGAME_PATH := "res://levels/minigames/feeding/final_feed_minigame.gd"
const MENU_BASE_PATH := "res://levels/menu/menu_base.gd"
const MAIN_MENU_PATH := "res://levels/menu/main_menu.gd"
const PAUSE_MENU_PATH := "res://levels/menu/pause_menu.gd"
const SETTINGS_PANEL_PATH := "res://levels/menu/settings_panel.gd"
const LEVEL_12_STU_2_PATH := "res://levels/cycles/level_12_stu_2.gd"
const ACTIVE_SCENE_EXCLUDE_SUBSTRINGS: Array[String] = ["archive", "trash"]
const FORBIDDEN_GAME_DIRECTOR_PATTERNS := [
	"has_method(\"handle_custom_death_screen\")",
	"call(\"handle_custom_death_screen\"",
	"call('handle_custom_death_screen'",
	"func _find_stalker_spawn",
	"func _create_stalker",
	"func _restore_stalker_from_checkpoint",
	"target_layer := 90",
	"target_layer = 70",
	"get_active_minigame_layer() - 1",
	"var current_max_time",
	"var _current_timer_duration",
	"CursorManager.request_visible",
	"CursorManager.release_visible",
	"CursorManager.set_in_game",
	"var _death_camera: Camera2D",
	"_death_camera_base_",
	"tween_property(_death_camera",
	"tween_property(_death_fade_rect",
	"apply_next_title(death_title_text)",
	"var _death_sequence_active",
	"var _death_pause_requested",
	"restore_respawn_checkpoint",
	"restore_autosave_run",
	"reset_cycle_state()",
	"queue_respawn_blackout",
	"reload_current_scene",
	"prepare_retry(GameState",
	"finish_retry_transition(",
	"set_screen_dark(true)",
	"fade_out(0.0)",
	"var _minigame_active: bool",
	"var _minigame_blocks_distortion",
	"var _pending_distortion_activation",
	"var _distortion_active",
	"var _distortion_progress",
	"var _transition_active",
	"var _transition_progress",
	"var _flash_active",
	"var _damage_flash_active",
	"var _light_only_jump_active",
	"set_shader_parameter(",
	"get_shader_parameter(",
	"shader_parameter/intensity",
	"func _ease_out",
	"pow(1.0 - t, 2.0)",
	"CycleState.set_phase",
	"CycleState.is_normal_phase",
	"CycleState.is_distorted_phase",
	"CycleState.Phase",
	"Timer.new()",
	"PauseManager.has_method(\"request_pause\")",
	"PauseManager.has_method(\"release_pause\")",
	"PauseManager.has_method(\"is_pause_menu_open\")",
	"MinigameController.has_method(\"get_active_minigame_layer\")",
	"get_tree().paused = true",
	"get_tree().paused = false"
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
const FORBIDDEN_CYCLE_STATE_PUBLIC_FIELD_DECLARATIONS := [
	"var phase:",
	"var ate_this_cycle:",
	"var lab_done:",
	"var completed_labs:",
	"var phone_picked:",
	"var fridge_interacted:",
	"var pending_sleep_spawn:",
	"var pending_respawn_blackout:",
	"var flashlight_collected_this_cycle:"
]
const FORBIDDEN_GAME_STATE_STABLE_FACADE_PROBES := [
	"CycleState.has_method(\"has_flashlight_for_current_cycle\")",
	"CycleState.has_method(\"has_pending_sleep_spawn\")",
	"CycleState.has_method(\"next_cycle\")",
	"CycleState.has_method(\"queue_sleep_spawn\")",
	"CycleState.has_method(\"reset_cycle_state\")",
	"CycleState.has_method(\"set_phase\")",
	"CycleState.has_method(\"mark_ate\")",
	"CycleState.has_method(\"has_eaten_this_cycle\")",
	"CycleState.has_method(\"mark_phone_picked\")",
	"CycleState.has_method(\"mark_fridge_interacted\")",
	"CycleState.has_method(\"is_fridge_interacted\")",
	"CycleState.has_method(\"consume_pending_sleep_spawn\")",
	"CycleState.has_method(\"queue_respawn_blackout\")",
	"CycleState.has_method(\"consume_pending_respawn_blackout\")",
	"CycleState.has_method(\"reset_runtime_state_only\")",
	"CycleState.has_method(\"has_pending_respawn_blackout\")",
	"CycleState.has_method(\"load_save_data\")",
	"CycleState.has_method(\"write_save_data\")",
	"CycleState.has_method(\"export_checkpoint_state\")",
	"CycleState.has_method(\"apply_checkpoint_state\")",
	"GameDirector.has_method(\"apply_checkpoint_state\")",
	"GameDirector.has_method(\"capture_checkpoint_state\")"
]
const FORBIDDEN_CYCLE_STATE_STABLE_FACADE_PROBES := [
	"GameState.has_method(\"is_flashlight_unlocked\")",
	"GameState.has_method(\"autosave_run\")"
]
const FORBIDDEN_ACTIVE_SCENE_PATTERNS := [
	"archive(trash)"
]
const FORBIDDEN_PLAYER_PATTERNS := [
	"var _facing_dir",
	"MinigameController.has_method(",
	"UIMessage.has_method(\"is_screen_dark\")",
	"UIMessage.call(\"is_screen_dark\"",
	"CycleState.has_method(\"has_flashlight_for_current_cycle\")",
	"GameState.has_method(\"is_flashlight_unlocked\")"
]
const FORBIDDEN_UI_MESSAGE_PAUSE_FALLBACK_PATTERNS := [
	"PauseManager.has_method(\"clear_all_pause_requests\")",
	"PauseManager.has_method(\"request_pause\")",
	"PauseManager.has_method(\"release_pause\")",
	"get_tree().paused = true",
	"get_tree().paused = false"
]
const FORBIDDEN_PAUSE_MANAGER_STABLE_FACADE_PROBES := [
	"MinigameController.has_method(\"set_pause_menu_open\")",
	"MinigameController.has_method(\"is_pause_menu_allowed\")",
	"MinigameController.has_method(\"is_cancel_action_allowed\")"
]
const FORBIDDEN_CYCLE_LEVEL_UI_MESSAGE_PATTERNS := [
	"UIMessage.has_method(\"is_screen_dark\")",
	"UIMessage.call(\"is_screen_dark\"",
	"UIMessage.has_method(\"fade_out\")",
	"UIMessage.has_method(\"fade_in\")"
]
const FORBIDDEN_CYCLE_LEVEL_STABLE_FACADE_PATTERNS := [
	"SceneContext.has_method(\"mark_gameplay_scene\")",
	"GameState.has_method(\"apply_checkpoint_to_scene\")",
	"CycleState.has_method(\"is_fridge_interacted\")",
	"GameState.has_method(\"unlock_flashlight\")",
	"GameState.has_method(\"capture_level_start_checkpoint\")"
]
const FORBIDDEN_MINIGAME_CONTROLLER_UI_MESSAGE_PATTERNS := [
	"UIMessage.has_method(\"play_fade_sequence\")",
	"UIMessage.call(\"play_fade_sequence\""
]
const FORBIDDEN_MINIGAME_STABLE_HELPER_PROBES := {
	MINIGAME_CONTROLLER_PATH: [
		"_gamepad_runtime.has_method(\"observe_input_device\")",
	],
	MINIGAME_PROMPT_VISIBILITY_COORDINATOR_PATH: [
		"prompts.has_method(",
		"prompts.call(",
	],
	MINIGAME_MUSIC_SESSION_PATH: [
		"music_manager.has_method(",
		"music_manager.call(\"start_minigame_music\"",
		"music_manager.call(\"push_music\"",
		"music_manager.call(\"pop_music\"",
		"music_manager.call(\"stop_music\"",
		"music_manager.call(\"stop_minigame_music\"",
		"music_manager.call(\"resolve_mix_volume_db\"",
		"music_manager.call(\"play_music\"",
	],
}
const FORBIDDEN_INTERACTION_MANAGER_STRINGLY_PATTERNS := [
	"call(\"_get_interact_action\"",
	"call('_get_interact_action'",
	"call(\"_set_interaction_focus\"",
	"call('_set_interaction_focus'",
	"MinigameController.has_method(\"has_active_minigame\")"
]
const FORBIDDEN_INTERACTIVE_OBJECT_STABLE_FACADE_PROBES := [
	"MinigameController.has_method(\"attach_minigame\")",
	"InteractionManager.has_method(\"register_candidate\")"
]
const FORBIDDEN_ENEMY_STABLE_FACADE_PROBES := {
	ENEMY_BASE_PATH: [
		"UIMessage.has_method(\"play_sfx\")",
		"GameDirector.has_method(\"trigger_death_screen\")",
		"GameDirector.has_method(\"trigger_damage_flash\")",
		"GameDirector.has_method(\"reduce_time\")",
		"MinigameController.has_method(\"has_active_minigame\")",
		"MinigameController.has_method(\"should_block_player_movement\")",
	],
	ENEMY_FLASHLIGHT_BASE_PATH: [
		"player.has_method(\"is_point_lit\")",
		"player.call(\"is_point_lit\"",
		"light_source.has_method(ReactiveLightContracts.METHOD_IS_POINT_LIT)",
		"light_source.call(ReactiveLightContracts.METHOD_IS_POINT_LIT",
	],
	ENEMY_CEILING_PATH: [
		"light_source.has_method(ReactiveLightContracts.METHOD_IS_POINT_LIT)",
		"light_source.call(ReactiveLightContracts.METHOD_IS_POINT_LIT",
	],
	ENEMY_LIGHT_ONLY_PATH: [
		"GameDirector.has_method(\"trigger_light_only_jump_effect\")",
	],
}
const FORBIDDEN_FEEDING_MINIGAME_STABLE_FACADE_PROBES := {
	FEED_MINIGAME_PATH: [
		"GameState.has_method(\"reset_dragging\")",
		"GameState.reset_dragging",
	],
	FEED_DETACH_HANDS_PATH: [
		"MusicManager.has_method(\"stop_minigame_music_with_pitch_drop\")",
	],
	FINAL_FEED_MINIGAME_PATH: [
		"UIMessage.has_method(\"play_sfx\")",
	],
}
const FORBIDDEN_MENU_STABLE_FACADE_PROBES := {
	MENU_BASE_PATH: [
		"SceneContext.has_method(\"mark_menu_scene\")",
	],
	MAIN_MENU_PATH: [
		"GameState.has_method(\"has_active_run_state\")",
		"GameState.has_method(\"get_last_scene_path\")",
		"UIMessage.has_method(\"change_scene_with_fade\")",
	],
	PAUSE_MENU_PATH: [
		"PauseManager.has_method(\"clear_all_pause_requests\")",
		"get_tree().paused = false",
	],
	SETTINGS_PANEL_PATH: [
		"SettingsManager.has_method(\"get_language\")",
	],
	LEVEL_12_STU_2_PATH: [
		"SettingsManager.has_method(\"get_language\")",
	],
}
const FORBIDDEN_UTILITY_STABLE_FACADE_PROBES := {
	CRAZY_LEVEL_EVENT_PATH: [
		"GameDirector.has_method(\"ensure_timer_running\")",
		"GameDirector.has_method(\"get_time_left\")",
		"GameDirector.has_method(\"set_time_left\")",
	],
	TEXTURE_DISTORTION_MANAGER_PATH: [
		"MinigameController.has_method(\"should_block_player_movement\")",
	],
}
const FORBIDDEN_MUSIC_MANAGER_CLEANUP_PROBES := {
	GAME_STATE_PATH: [
		"MusicManager.has_method(\"clear_chase_music_sources\")",
	],
	LEVEL_14_END_PATH: [
		"MusicManager.has_method(\"clear_chase_music_sources\")",
		"MusicManager.has_method(\"clear_stack\")",
		"MusicManager.has_method(\"reset_base_music_state\")",
		"MusicManager.has_method(\"stop_music\")",
	],
}
const FORBIDDEN_LEVEL_STABLE_STATE_PROBES := {
	LEVEL_11_STU_1_PATH: [
		"CycleState.has_method(\"is_fridge_interacted\")",
	],
	LEVEL_13_STU_3_PATH: [
		"CycleState.has_method(\"is_fridge_interacted\")",
	],
	LEVEL_11_END_PATH: [
		"CycleState.has_signal(\"lab_completed\")",
		"CycleState.has_method(\"mark_ate\")",
		"CycleState.has_method(\"has_completed_any_lab\")",
		"UIMessage.has_method(\"change_scene_with_fade\")",
	],
}
const FORBIDDEN_ENDING_STABLE_FACADE_PROBES := {
	ENDING_SCREEN_PATH: [
		"SceneContext.has_method(\"mark_ending_scene\")",
		"UIMessage.has_method(\"change_scene_with_fade\")",
		"UIMessage.has_method(\"is_screen_dark\")",
		"MusicManager.has_method(\"stop_pause_menu_music\")",
		"MusicManager.has_method(\"clear_stack\")",
		"MusicManager.has_method(\"reset_base_music_state\")",
		"MusicManager.has_method(\"stop_music\")",
	],
	ENDING_CREDITS_PATH: [
		"SceneContext.has_method(\"mark_ending_scene\")",
		"MusicManager.has_method(\"clear_stack\")",
		"PauseManager.has_method(\"set_pause_blocked\")",
		"GameState.has_method(\"reset_run\")",
		"UIMessage.has_method(\"play_fade_sequence\")",
	],
}
const FORBIDDEN_FRIDGE_COMPLETION_STABLE_FACADE_PROBES := [
	"cycle_state.has_method(\"mark_ate\")",
	"cycle_state.has_method(\"mark_fridge_interacted\")",
	"music_manager.has_method(\"clear_chase_music_sources\")",
	"game_state.has_method(\"capture_fridge_checkpoint\")",
	"game_state.has_method(\"autosave_run\")",
]
const FORBIDDEN_OBJECT_STABLE_FACADE_PROBES := {
	TARGET_MONSTER_SPAWNER_PATH: [
		"state_owner.has_method(",
		"state_owner.call(",
		"func _call_bool_condition",
	],
	FINAL_ENDING_FRIDGE_PATH: [
		"GameDirector.has_method(\"trigger_distortion_now\")",
		"GameDirector.has_method(\"set_time_left\")",
	],
	PICKUP_FLASHLIGHT_PATH: [
		"CycleState.has_method(\"collect_flashlight_for_cycle\")",
		"CycleState.has_method(\"has_flashlight_for_current_cycle\")",
		"GameState.has_method(\"is_flashlight_unlocked\")",
		"has_method(\"_despawn_pickup\")",
		".call(\"_despawn_pickup\"",
	],
	GENERATOR_PATH: [
		"has_method(\"turn_on\")",
		".call(ReactiveLightContracts.METHOD_TURN_ON",
	],
	LAPTOP_PATH: [
		"CycleState.has_method(\"is_lab_completed\")",
		"CycleState.has_method(\"has_completed_any_lab\")",
	],
	LEBEDKA_PATH: [
		"CycleState.has_method(\"mark_lab_completed\")",
	],
}
const FORBIDDEN_PLAYER_CONTRACT_PROBES := {
	DOOR_PATH: [
		"player.has_method(\"has_key\")",
		"player.has_method(\"remove_key\")",
		"player.has_method(\"set_physics_process\")",
	],
	KEY_PATH: [
		"player.has_method(\"add_key\")",
	],
	NOTE_OBJECT_PATH: [
		"player.has_method(\"add_key\")",
	],
	LEBEDKA_PATH: [
		"player.has_method(\"is_physics_processing\")",
		"player.has_method(\"set_physics_process\")",
	],
	SEARCH_KEY_MINIGAME_PATH: [
		"player.has_method(\"add_key\")",
	],
	STAMINA_BAR_PATH: [
		"player.has_method(\"get_stamina_ratio\")",
		"player.has_method(\"is_running\")",
	],
	FLASHLIGHT_BAR_PATH: [
		"player.has_method(\"has_flashlight_available\")",
		"player.has_method(\"get_flashlight_charge_ratio\")",
		"player.has_method(\"is_flashlight_enabled\")",
	],
}
const FORBIDDEN_LOCAL_UI_HELPER_PROBES := {
	PROMPT_VIEW_PATH: [
		"_text_node.has_method(\"set_text\")",
		"_text_node.call(\"set_text\"",
	],
}

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

		for pattern in LEGACY_RUNTIME_TEXT_PATTERNS:
			assert_true(content.find(pattern) == -1, "Legacy runtime text label is forbidden: %s (%s)" % [path, pattern])

		if path != INTERACTION_RESULT_BUILDER_PATH:
			for pattern in INLINE_KEY_REWARD_PAYLOAD_PATTERNS:
				assert_true(content.find(pattern) == -1, "Key reward payloads must use InteractionResultBuilder.key_reward(...): %s (%s)" % [path, pattern])

		for pattern in LEGACY_INTERACTION_FINISHED_SCRIPT_PATTERNS:
			assert_true(content.find(pattern) == -1, "Runtime scripts must subscribe to typed interaction_succeeded instead of legacy interaction_finished: %s (%s)" % [path, pattern])

		if path.begins_with("res://objects/"):
			for pattern in CONTENT_OBJECT_STRINGLY_PATTERNS:
				assert_true(content.find(pattern) == -1, "Content objects must use typed collaborators instead of stringly method probes: %s (%s)" % [path, pattern])

		if FORBIDDEN_UTILITY_STABLE_FACADE_PROBES.has(path):
			for pattern in FORBIDDEN_UTILITY_STABLE_FACADE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Utility scripts must use stable autoload facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_MUSIC_MANAGER_CLEANUP_PROBES.has(path):
			for pattern in FORBIDDEN_MUSIC_MANAGER_CLEANUP_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Music cleanup paths must use stable MusicManager facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_LEVEL_STABLE_STATE_PROBES.has(path):
			for pattern in FORBIDDEN_LEVEL_STABLE_STATE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"STU level scripts must use stable CycleState facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_ENDING_STABLE_FACADE_PROBES.has(path):
			for pattern in FORBIDDEN_ENDING_STABLE_FACADE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Ending flow scripts must use stable autoload facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_OBJECT_STABLE_FACADE_PROBES.has(path):
			for pattern in FORBIDDEN_OBJECT_STABLE_FACADE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Content objects must use stable autoload facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_PLAYER_CONTRACT_PROBES.has(path):
			for pattern in FORBIDDEN_PLAYER_CONTRACT_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Player-dependent content/HUD scripts must use the stable Player facade directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_LOCAL_UI_HELPER_PROBES.has(path):
			for pattern in FORBIDDEN_LOCAL_UI_HELPER_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Local UI helper scripts must use stable node properties directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_ENEMY_STABLE_FACADE_PROBES.has(path):
			for pattern in FORBIDDEN_ENEMY_STABLE_FACADE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Enemy scripts must use stable autoload facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_FEEDING_MINIGAME_STABLE_FACADE_PROBES.has(path):
			for pattern in FORBIDDEN_FEEDING_MINIGAME_STABLE_FACADE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Feeding minigames must use stable facades and local FoodItem state directly instead of dead/stringly method probes: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_MENU_STABLE_FACADE_PROBES.has(path):
			for pattern in FORBIDDEN_MENU_STABLE_FACADE_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Menu/settings flow must use stable autoload facades directly instead of stringly method probes or local pause fallbacks: %s (%s)" % [path, pattern]
				)

		if FORBIDDEN_MINIGAME_STABLE_HELPER_PROBES.has(path):
			for pattern in FORBIDDEN_MINIGAME_STABLE_HELPER_PROBES[path]:
				assert_true(
					content.find(pattern) == -1,
					"Minigame helper scripts must use stable runtime helpers/facades directly instead of stringly method probes: %s (%s)" % [path, pattern]
				)

		assert_true(content.find("print(") == -1, "Runtime scripts should use print_verbose(), push_warning(), or a typed UI/logging path instead of raw print(): %s" % path)

		if path != GAME_STATE_PATH:
			for pattern in FORBIDDEN_GAME_STATE_FIELD_PATTERNS:
				assert_true(not _contains_symbol_access(content, pattern), "External GameState field access must go through public methods: %s (%s)" % [path, pattern])

		if path != CYCLE_STATE_PATH:
			for pattern in FORBIDDEN_CYCLE_STATE_FIELD_PATTERNS:
				assert_true(not _contains_symbol_access(content, pattern), "External CycleState field access must go through public methods: %s (%s)" % [path, pattern])
		else:
			for pattern in FORBIDDEN_CYCLE_STATE_PUBLIC_FIELD_DECLARATIONS:
				assert_true(content.find(pattern) == -1, "CycleState must keep core state behind private backing fields and public methods: %s" % pattern)
			for pattern in FORBIDDEN_CYCLE_STATE_STABLE_FACADE_PROBES:
				assert_true(
					content.find(pattern) == -1,
					"CycleState must use stable GameState facade directly instead of stringly method probes: %s" % pattern
				)

		if path == GAME_STATE_PATH:
			for pattern in FORBIDDEN_GAME_STATE_STABLE_FACADE_PROBES:
				assert_true(
					content.find(pattern) == -1,
					"GameState must use stable CycleState/GameDirector facades directly instead of stringly method probes: %s" % pattern
				)

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
		for pattern in LEGACY_INTERACTION_FINISHED_SCENE_PATTERNS:
			assert_true(content.find(pattern) == -1, "Active scenes must use typed interaction_succeeded instead of legacy interaction_finished signal wiring: %s (%s)" % [path, pattern])

	var game_director_content := FileAccess.get_file_as_string(GAME_DIRECTOR_PATH)
	assert_true(game_director_content != "", "Failed to read script: %s" % GAME_DIRECTOR_PATH)
	if game_director_content != "":
		for pattern in FORBIDDEN_GAME_DIRECTOR_PATTERNS:
			assert_true(game_director_content.find(pattern) == -1, "GameDirector must delegate extracted policies instead of owning pattern: %s" % pattern)

	var game_state_content := FileAccess.get_file_as_string(GAME_STATE_PATH)
	assert_true(game_state_content.find("func autosave_run") != -1, "GameState must expose public autosave_run()")

	var player_content := FileAccess.get_file_as_string(PLAYER_PATH)
	assert_true(player_content != "", "Failed to read script: %s" % PLAYER_PATH)
	for pattern in FORBIDDEN_PLAYER_PATTERNS:
		assert_true(player_content.find(pattern) == -1, "Player must delegate extracted state instead of owning pattern: %s" % pattern)

	var ui_message_content := FileAccess.get_file_as_string(UI_MESSAGE_PATH)
	assert_true(ui_message_content != "", "Failed to read script: %s" % UI_MESSAGE_PATH)
	for pattern in FORBIDDEN_UI_MESSAGE_PAUSE_FALLBACK_PATTERNS:
		assert_true(
			ui_message_content.find(pattern) == -1,
			"UIMessage modal pause ownership must go through stable PauseManager token API without local tree.paused fallbacks: %s" % pattern
		)

	var pause_manager_content := FileAccess.get_file_as_string(PAUSE_MANAGER_PATH)
	assert_true(pause_manager_content != "", "Failed to read script: %s" % PAUSE_MANAGER_PATH)
	for pattern in FORBIDDEN_PAUSE_MANAGER_STABLE_FACADE_PROBES:
		assert_true(
			pause_manager_content.find(pattern) == -1,
			"PauseManager must use stable MinigameController facades directly instead of stringly method probes: %s" % pattern
		)

	var fridge_content := FileAccess.get_file_as_string(FRIDGE_PATH)
	assert_true(fridge_content.find("FridgeCompletionSessionScript.save_after_feeding") != -1, "Fridge must delegate post-feeding save policy")
	var fridge_completion_content := FileAccess.get_file_as_string(FRIDGE_COMPLETION_SESSION_PATH)
	assert_true(fridge_completion_content.find("autosave_run") != -1, "Fridge completion session must keep autosave fallback after successful interaction")
	for pattern in FORBIDDEN_FRIDGE_COMPLETION_STABLE_FACADE_PROBES:
		assert_true(
			fridge_completion_content.find(pattern) == -1,
			"Fridge completion session must use stable autoload facades directly instead of stringly method probes: %s" % pattern
		)

	var bed_content := FileAccess.get_file_as_string(BED_PATH)
	assert_true(bed_content.find("change_scene_with_fade_delay") != -1, "Bed sleep transition must use the shared UIMessage scene transition API")
	assert_true(bed_content.find("UIMessage.fade_out") == -1, "Bed sleep transition must not add a manual fade_out before shared scene transition")
	assert_true(bed_content.find("UIMessage.fade_in") == -1, "Bed sleep transition must not manually restore fade after load validation")

	var cycle_level_content := FileAccess.get_file_as_string(CYCLE_LEVEL_PATH)
	assert_true(cycle_level_content != "", "Failed to read script: %s" % CYCLE_LEVEL_PATH)
	for pattern in FORBIDDEN_CYCLE_LEVEL_UI_MESSAGE_PATTERNS:
		assert_true(
			cycle_level_content.find(pattern) == -1,
			"CycleLevel must use the stable UIMessage facade directly instead of stringly method probes: %s" % pattern
		)
	for pattern in FORBIDDEN_CYCLE_LEVEL_STABLE_FACADE_PATTERNS:
		assert_true(
			cycle_level_content.find(pattern) == -1,
			"CycleLevel must use stable autoload facades directly instead of stringly method probes: %s" % pattern
		)

	var minigame_controller_content := FileAccess.get_file_as_string(MINIGAME_CONTROLLER_PATH)
	assert_true(minigame_controller_content != "", "Failed to read script: %s" % MINIGAME_CONTROLLER_PATH)
	for pattern in FORBIDDEN_MINIGAME_CONTROLLER_UI_MESSAGE_PATTERNS:
		assert_true(
			minigame_controller_content.find(pattern) == -1,
			"MinigameController must use the stable UIMessage transition facade directly instead of stringly method probes: %s" % pattern
		)

	var interaction_manager_content := FileAccess.get_file_as_string(INTERACTION_MANAGER_PATH)
	assert_true(interaction_manager_content != "", "Failed to read script: %s" % INTERACTION_MANAGER_PATH)
	if interaction_manager_content != "":
		assert_true(
			interaction_manager_content.find("get_interact_action_name()") != -1,
			"InteractionManager must read interact action through InteractiveObject public API"
		)
		assert_true(
			interaction_manager_content.find("set_manager_focus(") != -1,
			"InteractionManager must set focus through InteractiveObject public API"
		)
		for pattern in FORBIDDEN_INTERACTION_MANAGER_STRINGLY_PATTERNS:
			assert_true(
				interaction_manager_content.find(pattern) == -1,
				"InteractionManager must not call InteractiveObject private API by string: %s" % pattern
			)

	var interactive_object_content := FileAccess.get_file_as_string(INTERACTIVE_OBJECT_PATH)
	assert_true(interactive_object_content != "", "Failed to read script: %s" % INTERACTIVE_OBJECT_PATH)
	for pattern in FORBIDDEN_INTERACTIVE_OBJECT_STABLE_FACADE_PROBES:
		assert_true(
			interactive_object_content.find(pattern) == -1,
			"InteractiveObject must use stable interaction/minigame facades directly instead of stringly method probes: %s" % pattern
		)

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
