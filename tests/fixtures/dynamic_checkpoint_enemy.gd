extends CharacterBody2D

var state_value: int = 0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("checkpoint_stateful")

func capture_checkpoint_state() -> Dictionary:
	return {
		"state_value": state_value,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	state_value = int(state.get("state_value", state_value))
