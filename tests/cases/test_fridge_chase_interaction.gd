extends "res://tests/test_case.gd"

class FridgeProbe:
	extends "res://objects/interactable/fridge/fridge.gd"

	var feeding_started: bool = false

	func _is_chase_active() -> bool:
		return true

	func _start_feeding_process() -> void:
		feeding_started = true

class TeleportFridgeProbe:
	extends "res://objects/interactable/fridge/fridge.gd"

	var chase_cleared: bool = false

	func _clear_chase_after_teleport_success() -> void:
		chase_cleared = true

class LegacyCodeLockProbe:
	extends Node

	var target_code: String = ""

const FridgeScript := preload("res://objects/interactable/fridge/fridge.gd")
const FridgeCodeLockSessionScript := preload("res://objects/interactable/fridge/fridge_code_lock_session.gd")
const CODE_LOCK_SCENE := preload("res://levels/minigames/ui/code_lock.tscn")

func run() -> Array[String]:
	_test_fridge_is_not_blocked_during_chase()
	_test_teleport_fridge_clears_chase_state()
	_test_misconfigured_fridge_does_not_grant_food()
	_test_code_lock_session_applies_access_code()
	return get_failures()

func _test_fridge_is_not_blocked_during_chase() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return

	CycleState.reset_cycle_state()

	var fridge := FridgeProbe.new()
	fridge.require_access_code = false
	fridge.require_lab_completion = false
	fridge.call("_on_interact")
	
	assert_true(fridge.feeding_started, "Fridge interaction should proceed even if chase is active")
	fridge.free()

func _test_teleport_fridge_clears_chase_state() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return

	CycleState.reset_cycle_state()

	var fridge := TeleportFridgeProbe.new()
	fridge.enable_teleport = true
	fridge.call("_finish_feeding_logic")

	assert_true(fridge.chase_cleared, "Teleporting fridge must stop chase state after successful feeding")
	fridge.free()

func _test_misconfigured_fridge_does_not_grant_food() -> void:
	assert_true(CycleState != null, "CycleState autoload is missing")
	if CycleState == null:
		return
	CycleState.reset_cycle_state()
	var fridge := FridgeScript.new()
	fridge.minigame_scene = null
	fridge.food_scenes = []
	fridge.call("_start_feeding_process")
	assert_true(not bool(CycleState.has_eaten_this_cycle()), "Misconfigured fridge must fail closed instead of marking food as eaten")
	fridge.free()
	CycleState.reset_cycle_state()

func _test_code_lock_session_applies_access_code() -> void:
	var lock_instance: Node = FridgeCodeLockSessionScript.create_lock_instance(CODE_LOCK_SCENE, "2718")
	assert_true(lock_instance != null, "Fridge code-lock helper must instantiate the configured scene")
	if lock_instance != null:
		assert_eq(str(lock_instance.get("code_value")), "2718", "Fridge code-lock helper must configure current code_value contract")
		lock_instance.free()

	var legacy_lock := LegacyCodeLockProbe.new()
	FridgeCodeLockSessionScript.apply_access_code(legacy_lock, "3141")
	assert_eq(legacy_lock.target_code, "3141", "Fridge code-lock helper must keep the legacy target_code fallback")
	legacy_lock.free()
