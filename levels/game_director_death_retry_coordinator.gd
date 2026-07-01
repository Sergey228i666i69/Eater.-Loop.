extends RefCounted

const METHOD_RESTORE_RESPAWN := "restore_respawn_checkpoint"
const METHOD_RESTORE_AUTOSAVE := "restore_autosave_run"
const METHOD_RESET_CYCLE := "reset_cycle_state"
const METHOD_QUEUE_BLACKOUT := "queue_respawn_blackout"
const METHOD_SET_SCREEN_DARK := "set_screen_dark"
const METHOD_FADE_OUT := "fade_out"

func prepare_retry(game_state: Object, cycle_state: Object, ui_message: Object) -> bool:
	var restored := _restore_checkpoint(game_state)
	if not restored and cycle_state != null and cycle_state.has_method(METHOD_RESET_CYCLE):
		cycle_state.reset_cycle_state()
	if cycle_state != null and cycle_state.has_method(METHOD_QUEUE_BLACKOUT):
		cycle_state.queue_respawn_blackout()
	if ui_message != null:
		if ui_message.has_method(METHOD_SET_SCREEN_DARK):
			ui_message.set_screen_dark(true)
		elif ui_message.has_method(METHOD_FADE_OUT):
			await ui_message.fade_out(0.0)
	return restored

func _restore_checkpoint(game_state: Object) -> bool:
	if game_state == null:
		return false
	if game_state.has_method(METHOD_RESTORE_RESPAWN):
		return bool(game_state.restore_respawn_checkpoint())
	if game_state.has_method(METHOD_RESTORE_AUTOSAVE):
		return bool(game_state.restore_autosave_run())
	return false
