extends "res://levels/cycles/level.gd"

const BedScript := preload("res://objects/interactable/bed/bed.gd")

enum EndingBranch {
	NONE,
	LAPTOP,
	FRIDGE,
}

@export_group("Nodes")
@export var laptop_path: NodePath = NodePath("Hall/InteractableObjects/Laptop")
@export var fridge_path: NodePath = NodePath("Hall/InteractableObjects/Fridge")
@export var bed_path: NodePath = NodePath("Bedroom/InteractableObjects/Bed")

@export_group("Ending Scenes")
@export var bad_ending_scene: PackedScene

@export_group("Flow")
@export_range(0.0, 10.0, 0.1) var bad_ending_delay_after_fridge: float = 2.0
@export var laptop_sleep_prompt: String = "Надо лечь спать."

var _branch: EndingBranch = EndingBranch.NONE
var _ending_started: bool = false
var _bad_ending_queued: bool = false

var _laptop: Laptop = null
var _fridge: Fridge = null
var _bed: BedScript = null

func _ready() -> void:
	if not is_in_group(CheckpointStateUtils.CHECKPOINT_STATEFUL_GROUP):
		add_to_group(CheckpointStateUtils.CHECKPOINT_STATEFUL_GROUP)
	super._ready()
	_resolve_nodes()
	_apply_branch_side_effects()
	_connect_level_flow()

func handle_custom_death_screen() -> bool:
	if _ending_started:
		return true
	if _branch != EndingBranch.FRIDGE:
		return false
	_start_bad_ending()
	return true

func _resolve_nodes() -> void:
	_laptop = get_node_or_null(laptop_path) as Laptop
	_fridge = get_node_or_null(fridge_path) as Fridge
	_bed = get_node_or_null(bed_path) as BedScript

func _connect_level_flow() -> void:
	if _laptop != null and not _laptop.interaction_succeeded.is_connected(_on_laptop_interaction_succeeded):
		_laptop.interaction_succeeded.connect(_on_laptop_interaction_succeeded)
	if CycleState != null and not CycleState.lab_completed.is_connected(_on_lab_completed):
		CycleState.lab_completed.connect(_on_lab_completed)
	if _fridge != null and not _fridge.feeding_finished.is_connected(_on_fridge_feeding_finished):
		_fridge.feeding_finished.connect(_on_fridge_feeding_finished)

func _on_laptop_interaction_succeeded(_result: Dictionary = {}) -> void:
	if _branch == EndingBranch.NONE:
		_choose_branch(EndingBranch.LAPTOP)
	if _branch == EndingBranch.LAPTOP and _has_completed_any_lab():
		_complete_laptop_branch()

func _choose_branch(branch: EndingBranch) -> void:
	if branch == EndingBranch.NONE:
		return
	if _branch != EndingBranch.NONE and _branch != branch:
		return
	_branch = branch
	_apply_branch_side_effects()

func _apply_branch_side_effects() -> void:
	match _branch:
		EndingBranch.LAPTOP:
			_set_fridge_enabled(false)
			_set_bed_enabled(_has_completed_any_lab())
		EndingBranch.FRIDGE:
			_set_laptop_enabled(false)
			_set_bed_enabled(false)

func _on_lab_completed() -> void:
	if _branch == EndingBranch.NONE:
		_choose_branch(EndingBranch.LAPTOP)
	if _branch != EndingBranch.LAPTOP:
		return
	_complete_laptop_branch()

func _complete_laptop_branch() -> void:
	if CycleState != null:
		CycleState.mark_ate()
	_set_bed_enabled(true)
	if UIMessage != null and laptop_sleep_prompt.strip_edges() != "":
		UIMessage.show_notification(laptop_sleep_prompt)

func _on_fridge_feeding_finished() -> void:
	if _branch == EndingBranch.NONE:
		_choose_branch(EndingBranch.FRIDGE)
	if _branch != EndingBranch.FRIDGE:
		return
	_queue_bad_ending_after_fridge()

func _queue_bad_ending_after_fridge() -> void:
	if _bad_ending_queued or _ending_started:
		return
	_bad_ending_queued = true
	if bad_ending_delay_after_fridge > 0.0:
		await get_tree().create_timer(bad_ending_delay_after_fridge).timeout
	if _ending_started:
		return
	_start_bad_ending()

func _start_bad_ending() -> void:
	if _ending_started:
		return
	_ending_started = true
	_set_laptop_enabled(false)
	_set_fridge_enabled(false)
	_set_bed_enabled(false)
	if bad_ending_scene == null:
		push_warning("LevelEnd: bad_ending_scene не назначена.")
		return
	if UIMessage != null:
		await UIMessage.change_scene_with_fade(bad_ending_scene, 0.6, true)
		return
	get_tree().change_scene_to_packed(bad_ending_scene)

func _set_bed_enabled(enabled: bool) -> void:
	if _bed != null:
		_bed.set_interaction_enabled(enabled)

func _set_laptop_enabled(enabled: bool) -> void:
	if _laptop != null:
		_laptop.is_enabled = enabled

func _set_fridge_enabled(enabled: bool) -> void:
	if _fridge == null:
		return
	_fridge.set_interaction_enabled(enabled)
	_fridge.refresh_visual_state()

func _has_completed_any_lab() -> bool:
	if CycleState == null:
		return false
	return bool(CycleState.has_completed_any_lab())

func capture_checkpoint_state() -> Dictionary:
	return {
		"branch": int(_branch),
		"ending_started": _ending_started,
		"bad_ending_queued": _bad_ending_queued,
	}

func apply_checkpoint_state(state: Dictionary) -> void:
	_branch = _normalize_branch(int(state.get("branch", int(_branch))))
	_ending_started = bool(state.get("ending_started", _ending_started))
	_bad_ending_queued = bool(state.get("bad_ending_queued", _bad_ending_queued))
	_apply_branch_side_effects()

func _normalize_branch(value: int) -> int:
	match value:
		EndingBranch.LAPTOP, EndingBranch.FRIDGE:
			return value
		_:
			return EndingBranch.NONE
