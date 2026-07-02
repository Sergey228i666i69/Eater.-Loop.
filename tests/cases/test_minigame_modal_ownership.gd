extends "res://tests/test_case.gd"

const MinigameModalOwnership = preload("res://levels/minigames/minigame_modal_ownership.gd")


class FakePauseManager:
	extends RefCounted

	var requested: Array = []
	var released: Array = []

	func request_pause(owner: Object, reason: String) -> void:
		requested.append({"owner": owner, "reason": reason})

	func release_pause(owner: Object, reason: String) -> void:
		released.append({"owner": owner, "reason": reason})


class FakeCursorManager:
	extends RefCounted

	var requested: Array = []
	var released: Array = []

	func request_visible(owner: Object) -> void:
		requested.append(owner)

	func release_visible(owner: Object) -> void:
		released.append(owner)


func run() -> Array[String]:
	_test_requests_and_releases_pause_and_cursor_once()
	_test_disabled_modal_flags_do_not_request_ownership()
	await _test_pause_fallback_uses_tree_paused()
	return get_failures()


func _test_requests_and_releases_pause_and_cursor_once() -> void:
	var owner := Node.new()
	var pause := FakePauseManager.new()
	var cursor := FakeCursorManager.new()
	var ownership := MinigameModalOwnership.new()

	ownership.configure(true, true)
	ownership.request_pause(owner, null, pause)
	ownership.request_pause(owner, null, pause)
	ownership.request_cursor(owner, cursor)
	ownership.request_cursor(owner, cursor)

	assert_eq(pause.requested.size(), 1, "Pause ownership must be requested once")
	assert_eq(cursor.requested.size(), 1, "Cursor ownership must be requested once")
	assert_true(ownership.is_pause_token_requested(), "Helper must remember active pause ownership")
	assert_true(ownership.is_cursor_requested(), "Helper must remember active cursor ownership")

	ownership.release_pause(owner, null, pause)
	ownership.release_pause(owner, null, pause)
	ownership.release_cursor(owner, cursor)
	ownership.release_cursor(owner, cursor)

	assert_eq(pause.released.size(), 1, "Pause ownership must be released once")
	assert_eq(cursor.released.size(), 1, "Cursor ownership must be released only after a successful request")
	assert_true(not ownership.is_pause_token_requested(), "Pause ownership flag must clear after release")
	assert_true(not ownership.is_cursor_requested(), "Cursor ownership flag must clear after release")

	owner.free()


func _test_disabled_modal_flags_do_not_request_ownership() -> void:
	var owner := Node.new()
	var pause := FakePauseManager.new()
	var cursor := FakeCursorManager.new()
	var ownership := MinigameModalOwnership.new()

	ownership.configure(false, false)
	ownership.request_pause(owner, null, pause)
	ownership.request_cursor(owner, cursor)

	assert_eq(pause.requested.size(), 0, "Disabled pause flag must not request pause ownership")
	assert_eq(cursor.requested.size(), 0, "Disabled cursor flag must not request cursor ownership")

	ownership.release_pause(owner, null, pause)
	ownership.release_cursor(owner, cursor)
	assert_eq(pause.released.size(), 0, "Disabled pause flag must not release an unowned token")
	assert_eq(cursor.released.size(), 0, "Disabled cursor flag must not release an unowned cursor")

	owner.free()


func _test_pause_fallback_uses_tree_paused() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("SceneTree is not available")
		return

	var owner := Node.new()
	var ownership := MinigameModalOwnership.new()
	tree.paused = false

	ownership.configure(true, false)
	ownership.request_pause(owner, tree, null)
	assert_true(tree.paused, "Fallback pause ownership must pause the tree when PauseManager is unavailable")

	ownership.release_pause(owner, tree, null)
	assert_true(not tree.paused, "Fallback pause ownership must unpause the tree on release")

	owner.free()
