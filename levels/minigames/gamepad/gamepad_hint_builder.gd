extends RefCounted

const MODE_PICK_PLACE := "pick_place"


func build(
	scheme: Dictionary,
	mode: String,
	selected_source: Node,
	source_nodes: Array[Node],
	target_nodes: Array[Node],
	has_secondary_callback: bool
) -> Dictionary:
	var hints: Dictionary = {}
	var custom_hints: Variant = scheme.get("hints", {})
	if custom_hints is Dictionary:
		hints = (custom_hints as Dictionary).duplicate(true)
	if mode == MODE_PICK_PLACE:
		if not hints.has("confirm"):
			hints["confirm"] = "Поместить" if selected_source != null else "Выбрать"
		if selected_source != null:
			hints["cancel"] = "Отменить выбор"
			if source_nodes.size() > 0 and target_nodes.size() > 0:
				if not hints.has("tab_left"):
					hints["tab_left"] = "Секция"
				if not hints.has("tab_right"):
					hints["tab_right"] = "Секция"
		elif not hints.has("cancel"):
			hints["cancel"] = "Выход"
	else:
		if not hints.has("confirm"):
			hints["confirm"] = "Подтвердить"
		if not hints.has("cancel"):
			hints["cancel"] = "Выход"
	if not has_secondary_callback and not hints.has("secondary"):
		hints.erase("secondary")
	return hints
