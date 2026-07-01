extends "res://tests/test_case.gd"

const DeathRetryCoordinator = preload("res://levels/game_director_death_retry_coordinator.gd")

class RespawnGameState:
	extends RefCounted

	var restore_calls: int = 0
	var should_restore: bool = true

	func restore_respawn_checkpoint() -> bool:
		restore_calls += 1
		return should_restore

class AutosaveGameState:
	extends RefCounted

	var restore_calls: int = 0
	var should_restore: bool = true

	func restore_autosave_run() -> bool:
		restore_calls += 1
		return should_restore

class FakeCycleState:
	extends RefCounted

	var reset_calls: int = 0
	var blackout_calls: int = 0

	func reset_cycle_state() -> void:
		reset_calls += 1

	func queue_respawn_blackout() -> void:
		blackout_calls += 1

class DarkUIMessage:
	extends RefCounted

	var dark_values: Array[bool] = []

	func set_screen_dark(value: bool) -> void:
		dark_values.append(value)

class FadeUIMessage:
	extends RefCounted

	var fade_calls: Array[float] = []

	func fade_out(duration: float) -> void:
		fade_calls.append(duration)
		await Engine.get_main_loop().process_frame

func run() -> Array[String]:
	await _test_respawn_checkpoint_wins_and_preserves_cycle_state()
	await _test_autosave_fallback_is_used_when_respawn_method_is_missing()
	await _test_missing_checkpoint_resets_cycle_and_uses_fade_fallback()
	return get_failures()

func _test_respawn_checkpoint_wins_and_preserves_cycle_state() -> void:
	var coordinator: RefCounted = DeathRetryCoordinator.new()
	var game_state := RespawnGameState.new()
	var cycle_state := FakeCycleState.new()
	var ui_message := DarkUIMessage.new()

	var restored: bool = await coordinator.prepare_retry(game_state, cycle_state, ui_message)

	assert_true(restored, "Death retry must report successful respawn checkpoint restore")
	assert_eq(game_state.restore_calls, 1, "Respawn checkpoint restore must be attempted exactly once")
	assert_eq(cycle_state.reset_calls, 0, "Successful retry restore must not reset cycle state")
	assert_eq(cycle_state.blackout_calls, 1, "Death retry must queue respawn blackout")
	assert_eq(ui_message.dark_values, [true], "Death retry must darken the screen before reload")

func _test_autosave_fallback_is_used_when_respawn_method_is_missing() -> void:
	var coordinator: RefCounted = DeathRetryCoordinator.new()
	var game_state := AutosaveGameState.new()
	var cycle_state := FakeCycleState.new()
	var ui_message := DarkUIMessage.new()

	var restored: bool = await coordinator.prepare_retry(game_state, cycle_state, ui_message)

	assert_true(restored, "Death retry must fall back to autosave restore when respawn method is missing")
	assert_eq(game_state.restore_calls, 1, "Autosave restore must be attempted exactly once")
	assert_eq(cycle_state.reset_calls, 0, "Successful autosave fallback must not reset cycle state")
	assert_eq(cycle_state.blackout_calls, 1, "Autosave fallback must still queue respawn blackout")
	assert_eq(ui_message.dark_values, [true], "Autosave fallback must still darken the screen")

func _test_missing_checkpoint_resets_cycle_and_uses_fade_fallback() -> void:
	var coordinator: RefCounted = DeathRetryCoordinator.new()
	var game_state := RespawnGameState.new()
	game_state.should_restore = false
	var cycle_state := FakeCycleState.new()
	var ui_message := FadeUIMessage.new()

	var restored: bool = await coordinator.prepare_retry(game_state, cycle_state, ui_message)

	assert_true(not restored, "Death retry must report failed restore when no checkpoint is available")
	assert_eq(cycle_state.reset_calls, 1, "Failed retry restore must reset cycle state")
	assert_eq(cycle_state.blackout_calls, 1, "Failed retry restore must still queue respawn blackout")
	assert_eq(ui_message.fade_calls, [0.0], "Legacy UIMessage fallback must fade out instantly before reload")
