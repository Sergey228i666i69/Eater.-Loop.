extends RefCounted

const DEFAULT_OVERLAY_LAYER := 90
const PAUSED_OVERLAY_LAYER := 70
const MIN_LAYER := 0
const MAX_LAYER_BELOW_MINIGAME := 89

func resolve_layer(tree_paused: bool, pause_menu_open: bool, minigame_active: bool, active_minigame_layer: int = DEFAULT_OVERLAY_LAYER) -> int:
	if pause_menu_open or (tree_paused and not minigame_active):
		return PAUSED_OVERLAY_LAYER
	if minigame_active:
		return clampi(active_minigame_layer - 1, MIN_LAYER, MAX_LAYER_BELOW_MINIGAME)
	return DEFAULT_OVERLAY_LAYER

func apply_layer(overlay_layer: CanvasLayer, tree_paused: bool, pause_menu_open: bool, minigame_active: bool, active_minigame_layer: int = DEFAULT_OVERLAY_LAYER) -> void:
	if overlay_layer == null:
		return
	var target_layer := resolve_layer(tree_paused, pause_menu_open, minigame_active, active_minigame_layer)
	if overlay_layer.layer != target_layer:
		overlay_layer.layer = target_layer
