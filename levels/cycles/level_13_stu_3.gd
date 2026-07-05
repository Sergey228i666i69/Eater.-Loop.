extends "res://levels/cycles/level.gd"

@export var door_to_bathroom_path: NodePath = NodePath("1thLevel/1thHall/InteractableObjects/Door(ToBathroom)")
@export var door_to_bathroom_default_target: NodePath = NodePath("../../../1thBathroom/InteractableObjects/Door(In1thBathroom)")
@export var door_to_bedroom_target: NodePath = NodePath("../../../../Bedroom/InteractableObjects/Door(InBedroom)")
@export var primary_fridge_path: NodePath = NodePath("")
@export var secondary_fridge_path: NodePath = NodePath("Stolovaya/InteractableObjects/Fridge")

var _door_to_bathroom: Door = null
var _fridges: Array[Fridge] = []

func _ready() -> void:
	super._ready()
	call_deferred("_wire_bathroom_redirect")

func _wire_bathroom_redirect() -> void:
	_door_to_bathroom = get_node_or_null(door_to_bathroom_path) as Door
	_fridges.clear()
	_register_fridge(primary_fridge_path)
	_register_fridge(secondary_fridge_path)

	for fridge in _fridges:
		if fridge == null:
			continue
		if not fridge.interaction_succeeded.is_connected(_on_fridge_interaction_succeeded):
			fridge.interaction_succeeded.connect(_on_fridge_interaction_succeeded)

	if CycleState != null and CycleState.has_signal("fridge_interacted_changed"):
		var on_changed := Callable(self, "_on_fridge_interacted_changed")
		if not CycleState.is_connected("fridge_interacted_changed", on_changed):
			CycleState.connect("fridge_interacted_changed", on_changed)

	_update_bathroom_door_target()

func _register_fridge(path: NodePath) -> void:
	var fridge := get_node_or_null(path) as Fridge
	if fridge == null:
		return
	_fridges.append(fridge)

func _on_fridge_interaction_succeeded(_result: Dictionary = {}) -> void:
	_update_bathroom_door_target()

func _on_fridge_interacted_changed() -> void:
	_update_bathroom_door_target()

func _update_bathroom_door_target() -> void:
	if _door_to_bathroom == null:
		return
	var target := door_to_bedroom_target if _is_fridge_interacted() else door_to_bathroom_default_target
	_door_to_bathroom.set_target_marker_path(target)

func _is_fridge_interacted() -> bool:
	if CycleState != null and CycleState.is_fridge_interacted():
		return true
	for fridge in _fridges:
		if fridge != null and is_instance_valid(fridge) and bool(fridge.is_completed):
			return true
	return false
