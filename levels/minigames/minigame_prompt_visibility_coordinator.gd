extends RefCounted

signal restore_requested

var _previous_enabled: bool = true
var _suspended: bool = false
var _restore_target: Node = null


func suspend(prompts: Object) -> void:
	if prompts == null:
		return
	if _suspended:
		return
	if prompts.has_method("are_prompts_enabled"):
		_previous_enabled = bool(prompts.call("are_prompts_enabled"))
	else:
		_previous_enabled = true
	if prompts.has_method("set_prompts_enabled"):
		prompts.call("set_prompts_enabled", false)
	_suspended = true


func restore(prompts: Object) -> void:
	if not _suspended:
		return
	if prompts != null and prompts.has_method("set_prompts_enabled"):
		prompts.call("set_prompts_enabled", _previous_enabled)
	_suspended = false


func schedule_restore_target(minigame: Node) -> bool:
	if not _suspended:
		return false
	clear_restore_target()
	if minigame == null or not minigame.is_inside_tree():
		return false
	_restore_target = minigame
	var callback := Callable(self, "_on_restore_target_exited")
	if not minigame.is_connected("tree_exited", callback):
		minigame.connect("tree_exited", callback)
	return true


func clear_restore_target() -> void:
	if _restore_target == null:
		return
	var callback := Callable(self, "_on_restore_target_exited")
	if is_instance_valid(_restore_target) and _restore_target.is_connected("tree_exited", callback):
		_restore_target.disconnect("tree_exited", callback)
	_restore_target = null


func is_suspended() -> bool:
	return _suspended


func has_restore_target() -> bool:
	return _restore_target != null and is_instance_valid(_restore_target)


func _on_restore_target_exited() -> void:
	_restore_target = null
	restore_requested.emit()
