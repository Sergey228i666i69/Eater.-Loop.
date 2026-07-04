extends RefCounted

const PauseManagerScript := preload("res://levels/menu/pause_manager.gd")
const CursorManagerScript := preload("res://levels/minigames/cursor_manager.gd")

var _pause_requested: bool = true
var _pause_token_requested: bool = false
var _show_mouse_cursor: bool = true
var _cursor_requested: bool = false


func configure(pause_requested: bool, show_mouse_cursor: bool) -> void:
	_pause_requested = pause_requested
	_show_mouse_cursor = show_mouse_cursor


func request_pause(owner: Object, tree: SceneTree, pause_manager: PauseManagerScript) -> void:
	if not _pause_requested:
		return
	if _pause_token_requested:
		return
	_pause_token_requested = true
	if pause_manager != null:
		pause_manager.request_pause(owner, "minigame")
	elif tree != null:
		tree.paused = true


func release_pause(owner: Object, tree: SceneTree, pause_manager: PauseManagerScript) -> void:
	if not _pause_token_requested:
		return
	_pause_token_requested = false
	if pause_manager != null:
		pause_manager.release_pause(owner, "minigame")
	elif tree != null:
		tree.paused = false


func request_cursor(owner: Object, cursor_manager: CursorManagerScript) -> void:
	if not _show_mouse_cursor:
		return
	if _cursor_requested:
		return
	if cursor_manager == null:
		return
	cursor_manager.request_visible(owner)
	_cursor_requested = true


func release_cursor(owner: Object, cursor_manager: CursorManagerScript) -> void:
	if not _cursor_requested:
		return
	_cursor_requested = false
	if cursor_manager != null:
		cursor_manager.release_visible(owner)


func is_pause_token_requested() -> bool:
	return _pause_token_requested


func is_cursor_requested() -> bool:
	return _cursor_requested
