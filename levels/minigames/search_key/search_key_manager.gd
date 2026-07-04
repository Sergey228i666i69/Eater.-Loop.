extends Node
class_name SearchKeyManager

const SearchSpotScript := preload("res://objects/interactable/search_spot/search_spot.gd")

@export var search_spots: Array[NodePath] = []

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("search_key_manager")
	_rng.randomize()
	_connect_search_spots()
	_assign_key_to_random_spot()

func mark_all_spots_searched_empty() -> void:
	if search_spots.is_empty():
		return
	for path in search_spots:
		var spot := _resolve_search_spot(path)
		if spot == null:
			continue
		spot.set_has_key(false)
		spot.set_searched_empty(true)

func _assign_key_to_random_spot() -> void:
	var resolved := _resolved_search_spots()
	if resolved.is_empty():
		return
	for spot in resolved:
		spot.set_has_key(false)

	var selected := resolved[_rng.randi_range(0, resolved.size() - 1)]
	selected.set_has_key(true)

func _connect_search_spots() -> void:
	for spot in _resolved_search_spots():
		if not spot.interaction_succeeded.is_connected(_on_search_spot_succeeded):
			spot.interaction_succeeded.connect(_on_search_spot_succeeded)

func _on_search_spot_succeeded(_result: Dictionary = {}) -> void:
	mark_all_spots_searched_empty()

func _resolved_search_spots() -> Array[SearchSpotScript]:
	var resolved: Array[SearchSpotScript] = []
	for path in search_spots:
		var spot := _resolve_search_spot(path)
		if spot != null:
			resolved.append(spot)
	return resolved

func _resolve_search_spot(path: NodePath) -> SearchSpotScript:
	if path.is_empty():
		return null
	var spot := get_node_or_null(path) as SearchSpotScript
	if spot == null:
		push_warning("SearchKeyManager: search_spots entry does not point to SearchSpot: %s" % path)
	return spot
