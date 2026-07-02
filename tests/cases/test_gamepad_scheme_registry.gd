extends "res://tests/test_case.gd"

const GamepadSchemeRegistry = preload("res://levels/minigames/gamepad/gamepad_scheme_registry.gd")


func run() -> Array[String]:
	_test_scheme_is_deep_copied_on_set_and_get()
	_test_clear_removes_registered_scheme()
	_test_cleanup_removes_freed_minigames()
	return get_failures()


func _test_scheme_is_deep_copied_on_set_and_get() -> void:
	var registry := GamepadSchemeRegistry.new()
	var minigame := Node.new()
	var scheme := {
		"mode": "pick_place",
		"nested": {"value": 1},
		"focus_nodes": [NodePath("Focus")]
	}

	registry.set_scheme(minigame, scheme)
	scheme["nested"]["value"] = 2

	var stored := registry.get_scheme(minigame)
	assert_eq(stored.get("mode"), "pick_place", "Registry must keep the registered mode")
	assert_eq((stored.get("nested", {}) as Dictionary).get("value"), 1, "Registry must not keep mutable nested input references")

	var nested := stored.get("nested", {}) as Dictionary
	nested["value"] = 3
	assert_eq((registry.get_scheme(minigame).get("nested", {}) as Dictionary).get("value"), 1, "Returned schemes must also be defensive copies")

	minigame.free()


func _test_clear_removes_registered_scheme() -> void:
	var registry := GamepadSchemeRegistry.new()
	var minigame := Node.new()

	registry.set_scheme(minigame, {"mode": "focus"})
	assert_eq(registry.get_registered_count(), 1, "Registry must track the registered minigame")

	registry.clear_scheme(minigame)
	assert_true(registry.get_scheme(minigame).is_empty(), "Cleared minigame scheme must not be returned")
	assert_eq(registry.get_registered_count(), 0, "Cleared minigame must be removed from the registry")

	minigame.free()


func _test_cleanup_removes_freed_minigames() -> void:
	var registry := GamepadSchemeRegistry.new()
	var minigame := Node.new()

	registry.set_scheme(minigame, {"mode": "focus"})
	assert_eq(registry.get_registered_count(), 1, "Registry must include live minigames before cleanup")

	minigame.free()
	assert_eq(registry.get_registered_count(), 0, "Registry must drop schemes whose minigame was freed")
