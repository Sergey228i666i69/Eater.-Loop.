extends "res://tests/test_case.gd"

const DistortionPhaseState = preload("res://levels/game_director_distortion_phase_state.gd")

func run() -> Array[String]:
	_test_activate_and_reset_phase_state()
	_test_advance_distortion_and_transition_progress()
	_test_checkpoint_restore_keeps_persistent_phase_and_clears_transient_flags()
	return get_failures()

func _test_activate_and_reset_phase_state() -> void:
	var phase: RefCounted = DistortionPhaseState.new()

	phase.activate_distortion_phase()
	assert_true(phase.is_distortion_active(), "Activated phase must enable persistent distortion")
	assert_true(phase.is_transition_active(), "Activated phase must enable transition")
	assert_true(phase.has_active_visual_effects(), "Activated phase must report active visuals")
	assert_true(not phase.is_flash_active(), "Activated phase must clear one-shot flash")
	assert_true(not phase.is_damage_flash_active(), "Activated phase must clear damage flash")

	phase.reset_for_normal_phase()
	assert_true(not phase.is_distortion_active(), "Normal reset must disable persistent distortion")
	assert_true(not phase.is_transition_active(), "Normal reset must disable transition")
	assert_true(not phase.has_active_visual_effects(), "Normal reset must clear active visual state")

func _test_advance_distortion_and_transition_progress() -> void:
	var phase: RefCounted = DistortionPhaseState.new()
	phase.activate_distortion_phase()

	var eased: float = phase.advance_distortion(1.0, 2.0)
	assert_true(absf(eased - 0.75) < 0.0001, "Distortion advance must return eased progress")
	var checkpoint: Dictionary = phase.capture_checkpoint_state()
	assert_true(absf(float(checkpoint["distortion_progress"]) - 0.5) < 0.0001, "Distortion checkpoint progress must store raw progress")

	var first_transition: Dictionary = phase.advance_transition(1.0, 2.0)
	assert_true(absf(float(first_transition["strength"]) - 0.25) < 0.0001, "Transition strength must fade from raw progress")
	assert_true(not bool(first_transition["completed"]), "Transition must stay active before progress reaches one")
	assert_true(phase.is_transition_active(), "Transition flag must stay active before completion")

	var final_transition: Dictionary = phase.advance_transition(1.0, 2.0)
	assert_eq(float(final_transition["strength"]), 0.0, "Completed transition strength must reach zero")
	assert_true(bool(final_transition["completed"]), "Transition must report completion at progress one")
	assert_true(not phase.is_transition_active(), "Completed transition must clear active flag")

func _test_checkpoint_restore_keeps_persistent_phase_and_clears_transient_flags() -> void:
	var phase: RefCounted = DistortionPhaseState.new()
	phase.set_flash_active(true)
	phase.set_damage_flash_active(true)
	phase.set_light_only_jump_active(true)

	phase.apply_checkpoint_state({
		"distortion_active": true,
		"distortion_progress": 0.3,
		"transition_active": true,
		"transition_progress": 0.4,
	})

	assert_true(phase.is_distortion_active(), "Checkpoint restore must keep persistent distortion flag")
	assert_true(phase.is_transition_active(), "Checkpoint restore must keep transition flag")
	assert_true(not phase.is_flash_active(), "Checkpoint restore must clear one-shot flash")
	assert_true(not phase.is_damage_flash_active(), "Checkpoint restore must clear damage flash")
	assert_true(not phase.is_light_only_jump_active(), "Checkpoint restore must clear light-only jump effect")
	var checkpoint: Dictionary = phase.capture_checkpoint_state()
	assert_eq(float(checkpoint["distortion_progress"]), 0.3, "Checkpoint restore must keep distortion progress")
	assert_eq(float(checkpoint["transition_progress"]), 0.4, "Checkpoint restore must keep transition progress")
