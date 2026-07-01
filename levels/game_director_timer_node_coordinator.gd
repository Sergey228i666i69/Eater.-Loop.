extends RefCounted

func create_cycle_timer(owner: Node, timeout_callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	if timeout_callback.is_valid():
		timer.timeout.connect(timeout_callback)
	if owner != null:
		owner.add_child(timer)
	return timer

func stop_timer(timer: Timer) -> void:
	if timer == null:
		return
	timer.stop()
