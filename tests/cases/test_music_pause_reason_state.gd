extends "res://tests/test_case.gd"

const MusicPauseReasonStateScript = preload("res://levels/music_pause_reason_state.gd")

func run() -> Array[String]:
	_test_multiple_reasons_gate_resume()
	_test_clear_resets_all_reasons()
	return get_failures()

func _test_multiple_reasons_gate_resume() -> void:
	var state: MusicPauseReasonState = MusicPauseReasonStateScript.new()
	assert_true(not state.is_active(), "New pause reason state must start inactive")
	assert_true(state.request("pause_menu"), "First pause reason must activate the state")
	assert_true(not state.request("minigame"), "Second pause reason must keep state active without a new activation")
	assert_true(state.is_active(), "Pause reason state must stay active while reasons exist")
	assert_true(state.has_reason("pause_menu"), "State must expose active pause_menu reason")
	assert_true(state.has_reason("minigame"), "State must expose active minigame reason")

	assert_true(not state.release("pause_menu"), "Releasing one reason must not resume while another remains")
	assert_true(not state.has_reason("pause_menu"), "Released reason must be removed")
	assert_true(state.has_reason("minigame"), "Unreleased reason must remain")
	assert_true(not state.release("unknown"), "Unknown reason release must not resume")
	assert_true(state.release("minigame"), "Final reason release must allow resume")
	assert_true(not state.is_active(), "Pause reason state must be inactive after final release")

func _test_clear_resets_all_reasons() -> void:
	var state: MusicPauseReasonState = MusicPauseReasonStateScript.new()
	state.request("global")
	state.request("pause_menu")
	assert_true(state.is_active(), "State must be active before clear")
	state.clear()
	assert_true(not state.is_active(), "Clear must remove all pause reasons")
	assert_true(state.get_reasons().is_empty(), "Clear must leave no exported reason snapshot")
