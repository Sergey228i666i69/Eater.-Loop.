extends "res://levels/cycles/level.gd"

const LOCKED_DOOR_MESSAGE := "Дверь заперта"

@export var fridge_path: NodePath = NodePath("Hall2/InteractableObjects/Fridge")
@export var hall2_left_door_path: NodePath = NodePath("Hall2/InteractableObjects/Door(ToParents)")
@export var hall2_right_door_path: NodePath = NodePath("Hall2/InteractableObjects/Door(ToParents)2")

var _fridge: Fridge = null
var _hall2_left_door: Door = null
var _hall2_right_door: Door = null
var _post_fridge_state_applied: bool = false

func _ready() -> void:
	super._ready()
	call_deferred("_setup_level_logic")

func _setup_level_logic() -> void:
	_fridge = get_node_or_null(fridge_path) as Fridge
	_hall2_left_door = get_node_or_null(hall2_left_door_path) as Door
	_hall2_right_door = get_node_or_null(hall2_right_door_path) as Door
	_apply_unified_locked_messages()

	if _fridge != null and not _fridge.interaction_succeeded.is_connected(_on_fridge_interaction_succeeded):
		_fridge.interaction_succeeded.connect(_on_fridge_interaction_succeeded)

	_apply_pre_fridge_layout()
	if CycleState != null and CycleState.has_method("is_fridge_interacted") and CycleState.is_fridge_interacted():
		_apply_post_fridge_layout()

func _on_fridge_interaction_succeeded(_result: Dictionary = {}) -> void:
	_apply_post_fridge_layout()

func _apply_pre_fridge_layout() -> void:
	_post_fridge_state_applied = false
	_set_door_state(_hall2_left_door, false, "Дверь в коридор.")
	_set_door_state(_hall2_right_door, false, "Сначала нужно сделать что-то другое...")

func _apply_post_fridge_layout() -> void:
	if _post_fridge_state_applied:
		return
	_post_fridge_state_applied = true

	_set_door_state(
		_hall2_left_door,
		true,
		"Щелк. Эту дверь заклинило. Придется идти через другую."
	)
	_set_door_state(_hall2_right_door, false, "Дверь в коридор.")

func _set_door_state(door: Door, locked: bool, locked_message: String) -> void:
	if door == null:
		return
	door.set_locked(locked, LOCKED_DOOR_MESSAGE if locked else locked_message)

func _apply_unified_locked_messages() -> void:
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if door != null:
			door.door_locked_message = LOCKED_DOOR_MESSAGE
