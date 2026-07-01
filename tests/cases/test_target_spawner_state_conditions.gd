extends "res://tests/test_case.gd"

const TargetSpawnerScript = preload("res://objects/environment/smart/target/target.gd")

func run() -> Array[String]:
	_test_cycle_state_conditions_use_public_methods()
	_test_game_state_condition_uses_public_method()
	return get_failures()

func _test_cycle_state_conditions_use_public_methods() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return
	CycleState.reset_cycle_state()

	var spawner := TargetSpawnerScript.new()
	spawner.game_state_flag_name = "ate_this_cycle"
	spawner.game_state_expected_value = true

	assert_true(not bool(spawner.call("_is_game_state_condition_met")), "Ate condition must start false")
	CycleState.mark_ate()
	assert_true(bool(spawner.call("_is_game_state_condition_met")), "Ate condition must use CycleState.has_eaten_this_cycle()")
	CycleState.reset_cycle_state()
	spawner.free()

func _test_game_state_condition_uses_public_method() -> void:
	assert_true(GameState != null, "GameState autoload is missing")
	if GameState == null:
		return
	GameState.reset_run()

	var spawner := TargetSpawnerScript.new()
	spawner.game_state_flag_name = "unique_feeding_intro_played"
	spawner.game_state_expected_value = true

	assert_true(not bool(spawner.call("_is_game_state_condition_met")), "Unique feeding condition must start false")
	GameState.mark_unique_feeding_intro_played()
	assert_true(bool(spawner.call("_is_game_state_condition_met")), "Unique feeding condition must use GameState.is_unique_feeding_intro_played()")
	GameState.reset_run()
	spawner.free()
