extends "res://tests/test_case.gd"

const PlayerInventoryState = preload("res://player/player_inventory_state.gd")

func run() -> Array[String]:
	_test_key_operations_normalize_ignore_empty_and_dedupe()
	_test_checkpoint_state_round_trips_player_keys()
	return get_failures()

func _test_key_operations_normalize_ignore_empty_and_dedupe() -> void:
	var inventory: RefCounted = PlayerInventoryState.new()

	inventory.add_key("")
	inventory.add_key("  ")
	inventory.add_key(" door_key ")
	inventory.add_key("door_key")

	assert_true(inventory.has_key("door_key"), "Inventory must find normalized key ids")
	assert_true(inventory.has_key(" door_key "), "Inventory lookup must normalize key ids")
	assert_true(not inventory.has_key(""), "Empty key ids must never be considered present")
	assert_eq(_sorted_keys(inventory), ["door_key"], "Inventory must ignore empty ids and dedupe repeated keys")

	inventory.remove_key(" door_key ")
	assert_true(not inventory.has_key("door_key"), "Inventory remove must normalize key ids")

func _test_checkpoint_state_round_trips_player_keys() -> void:
	var inventory: RefCounted = PlayerInventoryState.new()
	inventory.apply_checkpoint_state({"keys": ["alpha", "beta", "", "alpha"]})

	assert_eq(_sorted_keys(inventory), ["alpha", "beta"], "Checkpoint restore must normalize, skip empty and dedupe keys")

	var restored: RefCounted = PlayerInventoryState.new()
	restored.apply_checkpoint_state(inventory.capture_checkpoint_state())

	assert_eq(_sorted_keys(restored), ["alpha", "beta"], "Checkpoint capture/apply must round-trip player keys")

func _sorted_keys(inventory: RefCounted) -> Array[String]:
	var state: Dictionary = inventory.capture_checkpoint_state()
	var raw_keys: Array = state.get("keys", [])
	var keys: Array[String] = []
	for key_id in raw_keys:
		keys.append(str(key_id))
	keys.sort()
	return keys
