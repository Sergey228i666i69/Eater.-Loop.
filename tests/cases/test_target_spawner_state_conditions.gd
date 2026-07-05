extends "res://tests/test_case.gd"

const TargetSpawnerScript = preload("res://objects/environment/smart/target/target.gd")

func run() -> Array[String]:
	_test_state_conditions_use_public_facades()
	return get_failures()

func _test_state_conditions_use_public_facades() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	assert_true(GameState != null, "GameState autoload is missing")
	if CycleState == null or GameState == null:
		return

	for flag_name in [
		"ate_this_cycle",
		"lab_done",
		"phone_picked",
		"fridge_interacted",
		"unique_feeding_intro_played",
		"electricity_on",
	]:
		_assert_flag_uses_public_facade(flag_name)

func _assert_flag_uses_public_facade(flag_name: String) -> void:
	_reset_states_for_flag(flag_name)

	var spawner := TargetSpawnerScript.new()
	spawner.game_state_flag_name = flag_name
	spawner.game_state_expected_value = true

	assert_true(
		not bool(spawner.call("_is_game_state_condition_met")),
		"%s condition must start false before its public facade state changes" % flag_name
	)
	_activate_flag(flag_name)
	assert_true(
		bool(spawner.call("_is_game_state_condition_met")),
		"%s condition must use its stable GameState/CycleState facade directly" % flag_name
	)
	_reset_states_for_flag(flag_name)
	spawner.free()

func _reset_states_for_flag(flag_name: String) -> void:
	CycleState.reset_cycle_state()
	GameState.reset_run()
	if flag_name == "electricity_on":
		CycleState.electricity_on = false

func _activate_flag(flag_name: String) -> void:
	match flag_name:
		"ate_this_cycle":
			CycleState.mark_ate()
		"lab_done":
			CycleState.mark_lab_completed("target_spawner_test_lab")
		"phone_picked":
			CycleState.mark_phone_picked()
		"fridge_interacted":
			CycleState.mark_fridge_interacted()
		"unique_feeding_intro_played":
			GameState.mark_unique_feeding_intro_played()
		"electricity_on":
			CycleState.electricity_on = true
