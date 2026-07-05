extends RefCounted

const METHOD_RELOAD_CURRENT_SCENE := "reload_current_scene"

func prepare_retry(game_state: Object, cycle_state: Object, ui_message: Object) -> bool:
	var restored := _restore_checkpoint(game_state)
	if not restored and cycle_state != null:
		cycle_state.reset_cycle_state()
	if cycle_state != null:
		cycle_state.queue_respawn_blackout()
	if ui_message != null:
		ui_message.set_screen_dark(true)
	return restored

func run_retry_flow(
	game_state: Object,
	cycle_state: Object,
	ui_message: Object,
	death_root: CanvasItem,
	tree: Object,
	restore_camera: Callable,
	release_cursor: Callable,
	release_pause: Callable
) -> bool:
	await prepare_retry(game_state, cycle_state, ui_message)
	return finish_retry_transition(death_root, tree, restore_camera, release_cursor, release_pause)

func finish_retry_transition(death_root: CanvasItem, tree: Object, restore_camera: Callable, release_cursor: Callable, release_pause: Callable) -> bool:
	_call_if_valid(restore_camera)
	if death_root != null:
		death_root.visible = false
	_call_if_valid(release_cursor)
	_call_if_valid(release_pause)
	if tree != null:
		tree.call_deferred(METHOD_RELOAD_CURRENT_SCENE)
		return true
	return false

func _restore_checkpoint(game_state: Object) -> bool:
	if game_state == null:
		return false
	return bool(game_state.restore_respawn_checkpoint())

func _call_if_valid(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()
