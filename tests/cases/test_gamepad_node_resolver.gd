extends "res://tests/test_case.gd"

const GamepadNodeResolver = preload("res://levels/minigames/gamepad/gamepad_node_resolver.gd")


class CustomFocusable:
	extends Node

	var focusable := true

	func is_gamepad_focusable() -> bool:
		return focusable


func run() -> Array[String]:
	_test_resolves_direct_nodes_weakrefs_and_nodepaths()
	_test_provider_overrides_static_nodes()
	_test_filters_duplicates_invisible_disabled_and_custom_unfocusable_nodes()
	return get_failures()


func _test_resolves_direct_nodes_weakrefs_and_nodepaths() -> void:
	var resolver := GamepadNodeResolver.new()
	var root := Node.new()
	var direct := Node.new()
	var path_target := Node.new()
	path_target.name = "PathTarget"
	root.add_child(path_target)

	var nodes := resolver.coerce_nodes([direct, weakref(direct), NodePath("PathTarget")], root)

	assert_eq(nodes.size(), 2, "Resolver must resolve unique direct, weakref and NodePath entries")
	assert_eq(nodes[0], direct, "Resolver must keep direct node entries")
	assert_eq(nodes[1], path_target, "Resolver must resolve NodePath entries against active minigame")

	direct.free()
	root.free()


func _test_provider_overrides_static_nodes() -> void:
	var resolver := GamepadNodeResolver.new()
	var static_node := Node.new()
	var provided_node := Node.new()
	var scheme := {
		"focus_nodes": [static_node],
		"focus_provider": func() -> Array[Node]:
			return [provided_node]
	}

	var nodes := resolver.resolve_nodes(scheme, null, "focus_nodes", "focus_provider")

	assert_eq(nodes.size(), 1, "Valid provider must override static node list")
	assert_eq(nodes[0], provided_node, "Resolver must use provider result when callable is valid")

	static_node.free()
	provided_node.free()


func _test_filters_duplicates_invisible_disabled_and_custom_unfocusable_nodes() -> void:
	var resolver := GamepadNodeResolver.new()
	var focusable := CustomFocusable.new()
	var blocked := CustomFocusable.new()
	blocked.focusable = false
	var invisible := Control.new()
	invisible.visible = false
	var disabled := Button.new()
	disabled.disabled = true

	var nodes := resolver.coerce_nodes([focusable, focusable, blocked, invisible, disabled], null)

	assert_eq(nodes.size(), 1, "Resolver must keep only unique focusable nodes")
	assert_eq(nodes[0], focusable, "Resolver must keep custom-focusable node")

	focusable.free()
	blocked.free()
	invisible.free()
	disabled.free()
