extends "res://tests/test_case.gd"

const DeathScreenReset = preload("res://levels/game_director_death_screen_reset.gd")

class ResetCallbacks:
	extends RefCounted

	var calls: Array[String] = []

	func restore_camera() -> void:
		calls.append("restore_camera")

	func release_cursor() -> void:
		calls.append("release_cursor")

	func release_pause() -> void:
		calls.append("release_pause")

func run() -> Array[String]:
	_test_reset_hides_death_ui_and_releases_owners()
	_test_reset_is_safe_with_missing_nodes_and_callbacks()
	return get_failures()

func _test_reset_hides_death_ui_and_releases_owners() -> void:
	var reset: RefCounted = DeathScreenReset.new()
	var root := Control.new()
	root.visible = true
	var glitch_background := Control.new()
	glitch_background.visible = true
	var fade_rect := ColorRect.new()
	fade_rect.visible = true
	fade_rect.color = Color(1.0, 0.0, 0.0, 0.8)
	var retry_button := Button.new()
	retry_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var callbacks := ResetCallbacks.new()

	reset.reset(
		root,
		glitch_background,
		fade_rect,
		retry_button,
		Callable(callbacks, "restore_camera"),
		Callable(callbacks, "release_cursor"),
		Callable(callbacks, "release_pause")
	)

	assert_true(not root.visible, "Death screen reset must hide the root UI")
	assert_true(not glitch_background.visible, "Death screen reset must hide glitch background")
	assert_true(not fade_rect.visible, "Death screen reset must hide fade rect")
	assert_eq(fade_rect.color, Color(0, 0, 0, 0), "Death screen reset must clear fade color")
	assert_true(not retry_button.has_theme_stylebox_override("focus"), "Death screen reset must clear retry focus override")
	assert_eq(callbacks.calls, ["restore_camera", "release_cursor", "release_pause"], "Death screen reset must restore/release owners in order")

	root.free()
	glitch_background.free()
	fade_rect.free()
	retry_button.free()

func _test_reset_is_safe_with_missing_nodes_and_callbacks() -> void:
	var reset: RefCounted = DeathScreenReset.new()

	reset.reset(null, null, null, null, Callable(), Callable(), Callable())

	assert_true(true, "Death screen reset must tolerate missing nodes and callbacks")
