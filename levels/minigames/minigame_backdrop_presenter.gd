extends RefCounted

var backdrop_color: Color = Color(0.0, 0.0, 0.0, 1.0)

var _backdrops: Dictionary = {}


func ensure_backdrop(minigame: Node, target_layer: int, parent: Node) -> void:
	if minigame == null or parent == null:
		return
	var id := minigame.get_instance_id()
	var existing := _backdrops.get(id, null) as CanvasLayer
	if existing != null and is_instance_valid(existing):
		existing.layer = target_layer - 1
		return
	if _has_builtin_fullscreen_backdrop(minigame):
		return

	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.name = "MinigameBackdrop"
	backdrop_layer.layer = target_layer - 1
	backdrop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	backdrop_layer.visible = false

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = backdrop_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_layer.add_child(rect)

	parent.add_child(backdrop_layer)
	_backdrops[id] = backdrop_layer
	minigame.tree_exited.connect(Callable(self, "cleanup_backdrop").bind(id), Object.CONNECT_ONE_SHOT)


func cleanup_backdrop(minigame_id: int) -> void:
	var backdrop := _backdrops.get(minigame_id, null) as CanvasLayer
	if backdrop != null and is_instance_valid(backdrop):
		backdrop.queue_free()
	_backdrops.erase(minigame_id)


func set_backdrop_visible(minigame: Node, visible: bool) -> void:
	var backdrop := get_backdrop(minigame)
	if backdrop == null:
		return
	backdrop.visible = visible


func get_backdrop(minigame: Node) -> CanvasLayer:
	if minigame == null:
		return null
	var id := minigame.get_instance_id()
	var backdrop := _backdrops.get(id, null) as CanvasLayer
	if backdrop != null and not is_instance_valid(backdrop):
		_backdrops.erase(id)
		return null
	return backdrop


func _has_builtin_fullscreen_backdrop(minigame: Node) -> bool:
	return _find_builtin_fullscreen_backdrop(minigame, minigame)


func _find_builtin_fullscreen_backdrop(node: Node, root: Node) -> bool:
	if node is ColorRect:
		var rect := node as ColorRect
		if _is_opaque_fullscreen_rect(rect, root):
			return true
	for child in node.get_children():
		var child_node := child as Node
		if child_node != null and _find_builtin_fullscreen_backdrop(child_node, root):
			return true
	return false


func _is_opaque_fullscreen_rect(rect: ColorRect, root: Node) -> bool:
	if rect == null or not rect.visible:
		return false
	if rect.color.a < 0.98:
		return false
	return _fills_minigame_rect(rect, root)


func _fills_minigame_rect(control: Control, root: Node) -> bool:
	var current: Node = control
	while current != null and current != root:
		if not (current is Control) or not _is_full_rect_control(current as Control):
			return false
		current = current.get_parent()
	if current != root:
		return false
	if root is Control:
		return _is_full_rect_control(root as Control)
	return root is CanvasLayer


func _is_full_rect_control(control: Control) -> bool:
	return _is_zero_approx(control.anchor_left) \
		and _is_zero_approx(control.anchor_top) \
		and is_equal_approx(control.anchor_right, 1.0) \
		and is_equal_approx(control.anchor_bottom, 1.0) \
		and _is_zero_approx(control.offset_left) \
		and _is_zero_approx(control.offset_top) \
		and _is_zero_approx(control.offset_right) \
		and _is_zero_approx(control.offset_bottom)


func _is_zero_approx(value: float) -> bool:
	return absf(value) <= 0.5
