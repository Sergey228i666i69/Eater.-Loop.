extends "res://tests/test_case.gd"

const TimerNodeCoordinator = preload("res://levels/game_director_timer_node_coordinator.gd")

var _timeout_calls: int = 0

func run() -> Array[String]:
	_test_create_cycle_timer_configures_and_parents_timer()
	await _test_stop_timer_is_null_safe()
	return get_failures()

func _test_create_cycle_timer_configures_and_parents_timer() -> void:
	var owner := Node.new()
	var coordinator: RefCounted = TimerNodeCoordinator.new()
	var callback := Callable(self, "_on_timer_timeout")

	var timer: Timer = coordinator.create_cycle_timer(owner, callback)

	assert_true(timer != null, "Coordinator must create a Timer")
	assert_true(timer.one_shot, "Cycle timer must be one-shot")
	assert_eq(timer.process_mode, Node.PROCESS_MODE_PAUSABLE, "Cycle timer must use pausable process mode")
	assert_eq(timer.get_parent(), owner, "Cycle timer must be parented to the owner")
	assert_true(timer.timeout.is_connected(callback), "Cycle timer must connect timeout callback")
	owner.queue_free()

func _test_stop_timer_is_null_safe() -> void:
	var coordinator: RefCounted = TimerNodeCoordinator.new()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return
	var owner := Node.new()
	tree.root.add_child(owner)
	var timer: Timer = coordinator.create_cycle_timer(owner, Callable())
	await tree.process_frame

	timer.start(3.0)
	assert_true(not timer.is_stopped(), "Timer must be running before stop_timer")
	coordinator.stop_timer(timer)
	assert_true(timer.is_stopped(), "stop_timer must stop a running timer")
	coordinator.stop_timer(null)
	owner.queue_free()

func _on_timer_timeout() -> void:
	_timeout_calls += 1
