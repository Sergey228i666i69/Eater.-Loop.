extends RefCounted


func resolve_nodes(
	scheme: Dictionary,
	active_minigame: Node,
	nodes_key: String,
	provider_key: String
) -> Array[Node]:
	var raw_nodes: Variant = scheme.get(nodes_key, [])
	var provider: Variant = scheme.get(provider_key, Callable())
	if provider is Callable:
		var callable_provider := provider as Callable
		if callable_provider.is_valid():
			raw_nodes = callable_provider.call()
	return coerce_nodes(raw_nodes, active_minigame)


func coerce_nodes(raw_nodes: Variant, active_minigame: Node) -> Array[Node]:
	var result: Array[Node] = []
	if raw_nodes is Array:
		for entry in raw_nodes:
			var node := resolve_node(entry, active_minigame)
			if node == null:
				continue
			if result.has(node):
				continue
			if not is_node_focusable(node):
				continue
			result.append(node)
	return result


func resolve_node(entry: Variant, active_minigame: Node) -> Node:
	var entry_type := typeof(entry)
	if entry_type == TYPE_OBJECT:
		var direct_node := as_valid_node(entry)
		if direct_node != null:
			return direct_node
		var weak := entry as WeakRef
		if weak == null:
			return null
		return as_valid_node(weak.get_ref())
	if entry_type == TYPE_NODE_PATH:
		if active_minigame == null:
			return null
		return as_valid_node(active_minigame.get_node_or_null(entry))
	return null


func is_node_focusable(node: Node) -> bool:
	if node == null:
		return false
	if not is_instance_valid(node):
		return false
	if node.is_queued_for_deletion():
		return false
	if node.has_method("is_gamepad_focusable"):
		return bool(node.call("is_gamepad_focusable"))
	if node is CanvasItem:
		var item := node as CanvasItem
		if not item.visible:
			return false
	if node is BaseButton:
		var button := node as BaseButton
		if button.disabled:
			return false
	return true


func as_valid_node(value: Variant) -> Node:
	if value == null:
		return null
	if typeof(value) != TYPE_OBJECT:
		return null
	var object_value := value as Object
	if object_value == null:
		return null
	if not is_instance_valid(object_value):
		return null
	if not (object_value is Node):
		return null
	var node := object_value as Node
	if node == null:
		return null
	if node.is_queued_for_deletion():
		return null
	return node
