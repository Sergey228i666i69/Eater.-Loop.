extends "res://tests/test_case.gd"

const DeathCursorCoordinator = preload("res://levels/game_director_death_cursor_coordinator.gd")
const InputDeviceUtilsClass := preload("res://global/input_device_utils.gd")

class FakeCursorManager:
	extends RefCounted

	var requested_sources: Array[Object] = []
	var released_sources: Array[Object] = []

	func request_visible(source: Object) -> void:
		requested_sources.append(source)

	func release_visible(source: Object) -> void:
		released_sources.append(source)

func run() -> Array[String]:
	_test_gamepad_mode_releases_cursor_and_hides_focus_outline()
	_test_keyboard_mode_requests_cursor_and_restores_focus_outline()
	_test_release_cursor_request_is_safe_and_delegated()
	return get_failures()

func _test_gamepad_mode_releases_cursor_and_hides_focus_outline() -> void:
	var coordinator: RefCounted = DeathCursorCoordinator.new()
	var button := Button.new()
	var cursor := FakeCursorManager.new()
	var owner := RefCounted.new()

	coordinator.apply_input_mode(button, cursor, owner, InputDeviceUtilsClass.InputKind.GAMEPAD)

	assert_eq(cursor.requested_sources.size(), 0, "Gamepad death screen must not request a visible mouse cursor")
	assert_eq(cursor.released_sources.size(), 1, "Gamepad death screen must release the director cursor request")
	assert_true(button.has_theme_stylebox_override("focus"), "Gamepad death screen should hide the default focus outline")

	button.free()

func _test_keyboard_mode_requests_cursor_and_restores_focus_outline() -> void:
	var coordinator: RefCounted = DeathCursorCoordinator.new()
	var button := Button.new()
	var cursor := FakeCursorManager.new()
	var owner := RefCounted.new()

	coordinator.apply_input_mode(button, cursor, owner, InputDeviceUtilsClass.InputKind.GAMEPAD)
	coordinator.apply_input_mode(button, cursor, owner, InputDeviceUtilsClass.InputKind.KEYBOARD)

	assert_eq(cursor.requested_sources.size(), 1, "Keyboard death screen must request a visible mouse cursor")
	assert_eq(cursor.released_sources.size(), 1, "Keyboard switch must not leak the earlier gamepad release")
	assert_true(not button.has_theme_stylebox_override("focus"), "Keyboard death screen should restore the default focus outline")

	button.free()

func _test_release_cursor_request_is_safe_and_delegated() -> void:
	var coordinator: RefCounted = DeathCursorCoordinator.new()
	var cursor := FakeCursorManager.new()
	var owner := RefCounted.new()

	coordinator.release_cursor_request(cursor, owner)
	coordinator.release_cursor_request(null, owner)

	assert_eq(cursor.released_sources.size(), 1, "Cursor release must be delegated exactly once for a real manager")
