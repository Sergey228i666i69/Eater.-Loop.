extends Node

const SearchSpotScript := preload("res://objects/interactable/search_spot/search_spot.gd")

@export var search_spots: Array[NodePath] = []

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("search_key_manager")
	_rng.randomize()
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
	if search_spots.is_empty():
		return

	var resolved: Array[SearchSpotScript] = []
	for path in search_spots:
		var spot := _resolve_search_spot(path)
		if spot == null:
			continue
		spot.set_has_key(false)
		resolved.append(spot)

	if resolved.is_empty():
		return

	var selected := resolved[_rng.randi_range(0, resolved.size() - 1)]
	selected.set_has_key(true)

func _resolve_search_spot(path: NodePath) -> SearchSpotScript:
	if path.is_empty():
		return null
	var spot := get_node_or_null(path) as SearchSpotScript
	if spot == null:
		push_warning("SearchKeyManager: search_spots entry does not point to SearchSpot: %s" % path)
	return spot
