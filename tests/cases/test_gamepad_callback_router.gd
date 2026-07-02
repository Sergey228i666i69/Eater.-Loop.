extends "res://tests/test_case.gd"

const GamepadCallbackRouter = preload("res://levels/minigames/gamepad/gamepad_callback_router.gd")

func run() -> Array[String]:
	_test_missing_or_invalid_callbacks_are_ignored()
	_test_invoke_callback_calls_valid_callable()
	_test_consumed_callback_matches_runtime_semantics()
	_test_call_callback_forwards_arguments()
	return get_failures()

func _test_missing_or_invalid_callbacks_are_ignored() -> void:
	var router: RefCounted = GamepadCallbackRouter.new()
	var scheme := {
		"not_callable": "value",
		"invalid_callable": Callable()
	}

	assert_true(not router.has_callback(scheme, "missing"), "Missing callbacks must not be reported as valid")
	assert_true(not router.has_callback(scheme, "not_callable"), "Non-callable values must not be reported as callbacks")
	assert_true(not router.has_callback(scheme, "invalid_callable"), "Invalid Callable values must be ignored")
	assert_true(not router.invoke_callback(scheme, "missing"), "Missing callback invoke must return false")
	assert_eq(router.call_callback(scheme, "missing"), null, "Missing callback calls must return null")

func _test_invoke_callback_calls_valid_callable() -> void:
	var router: RefCounted = GamepadCallbackRouter.new()
	var state := {"calls": 0}
	var scheme := {
		"on_focus_changed": func(_active: Node, _context: Dictionary) -> void:
			state["calls"] += 1
	}

	assert_true(router.has_callback(scheme, "on_focus_changed"), "Valid Callable must be detected")
	assert_true(router.invoke_callback(scheme, "on_focus_changed", [null, {}]), "Valid callback invoke must return true")
	assert_eq(state["calls"], 1, "Callback must be called exactly once")

func _test_consumed_callback_matches_runtime_semantics() -> void:
	var router: RefCounted = GamepadCallbackRouter.new()
	var scheme := {
		"returns_true": func() -> bool:
			return true,
		"returns_false": func() -> bool:
			return false,
		"returns_void": func() -> void:
			pass
	}

	assert_true(router.invoke_callback_consumed(scheme, "returns_true"), "True callback result must consume input")
	assert_true(not router.invoke_callback_consumed(scheme, "returns_false"), "False callback result must not consume input")
	assert_true(router.invoke_callback_consumed(scheme, "returns_void"), "Non-bool callback result keeps legacy consumed semantics")
	assert_true(not router.invoke_callback_consumed(scheme, "missing"), "Missing callback must not consume input")

func _test_call_callback_forwards_arguments() -> void:
	var router: RefCounted = GamepadCallbackRouter.new()
	var state := {"sum": 0}
	var scheme := {
		"add": func(left: int, right: int) -> int:
			state["sum"] = left + right
			return state["sum"]
	}

	assert_eq(router.call_callback(scheme, "add", [2, 3]), 5, "Callback result must be returned")
	assert_eq(state["sum"], 5, "Callback arguments must be forwarded in order")
