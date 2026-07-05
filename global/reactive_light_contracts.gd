extends RefCounted
class_name ReactiveLightContracts

const REACTIVE_LIGHT_SOURCE_GROUP := "reactive_light_source"
const GENERATOR_REQUIRED_LIGHT_GROUP := "generator_required_light"
const GENERATOR_REQUIRED_LAMP_GROUP := "generator_required_lamp"
const METHOD_IS_POINT_LIT := "is_point_lit"
const METHOD_TURN_ON := "turn_on"

static func register_reactive_light_source(node: Node) -> void:
	_add_to_group_if_needed(node, REACTIVE_LIGHT_SOURCE_GROUP)

static func register_generator_required_light(node: Node) -> void:
	_add_to_group_if_needed(node, GENERATOR_REQUIRED_LIGHT_GROUP)

static func register_generator_required_lamp(node: Node) -> void:
	_add_to_group_if_needed(node, GENERATOR_REQUIRED_LAMP_GROUP)

static func get_reactive_light_sources(tree: SceneTree) -> Array[Node]:
	return _nodes_in_group(tree, REACTIVE_LIGHT_SOURCE_GROUP)

static func is_point_lit(light_source: Node, point: Vector2) -> bool:
	if light_source == null or not is_instance_valid(light_source):
		return false
	if not light_source.has_method(METHOD_IS_POINT_LIT):
		push_warning("Reactive light source does not expose %s(point): %s" % [METHOD_IS_POINT_LIT, light_source.get_path()])
		return false
	return bool(light_source.call(METHOD_IS_POINT_LIT, point))

static func get_generator_required_lights(tree: SceneTree) -> Array[Node]:
	var nodes: Array[Node] = []
	var seen := {}
	for group_name in [GENERATOR_REQUIRED_LIGHT_GROUP, GENERATOR_REQUIRED_LAMP_GROUP]:
		for node in _nodes_in_group(tree, group_name):
			var node_id := node.get_instance_id()
			if seen.has(node_id):
				continue
			seen[node_id] = true
			nodes.append(node)
	return nodes

static func turn_on_generator_light(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if not node.has_method(METHOD_TURN_ON):
		push_warning("Generator light contract node does not expose %s(): %s" % [METHOD_TURN_ON, node.get_path()])
		return false
	node.call(METHOD_TURN_ON)
	return true

static func _add_to_group_if_needed(node: Node, group_name: String) -> void:
	if node != null and not node.is_in_group(group_name):
		node.add_to_group(group_name)

static func _nodes_in_group(tree: SceneTree, group_name: String) -> Array[Node]:
	var nodes: Array[Node] = []
	if tree == null:
		return nodes
	for node in tree.get_nodes_in_group(group_name):
		if node != null and is_instance_valid(node):
			nodes.append(node)
	return nodes
