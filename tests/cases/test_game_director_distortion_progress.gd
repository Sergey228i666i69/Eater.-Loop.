extends "res://tests/test_case.gd"

const DistortionProgress = preload("res://levels/game_director_distortion_progress.gd")

func run() -> Array[String]:
	_test_advance_progress_respects_duration_and_clamps_to_one()
	_test_ease_out_curve_is_clamped_and_quadratic()
	_test_transition_strength_fades_out_quadratically()
	return get_failures()

func _test_advance_progress_respects_duration_and_clamps_to_one() -> void:
	var progress: RefCounted = DistortionProgress.new()

	assert_eq(progress.advance_progress(0.25, 0.5, 2.0), 0.5, "Progress must advance by delta divided by duration")
	assert_eq(progress.advance_progress(0.9, 1.0, 2.0), 1.0, "Progress must clamp at one")
	assert_eq(progress.advance_progress(0.2, 1.0, 0.0), 1.0, "Zero duration must complete immediately")

func _test_ease_out_curve_is_clamped_and_quadratic() -> void:
	var progress: RefCounted = DistortionProgress.new()

	assert_eq(progress.ease_out(-0.5), 0.0, "Ease-out must clamp below zero")
	assert_true(absf(progress.ease_out(0.5) - 0.75) < 0.0001, "Ease-out must use the existing quadratic curve")
	assert_eq(progress.ease_out(2.0), 1.0, "Ease-out must clamp above one")

func _test_transition_strength_fades_out_quadratically() -> void:
	var progress: RefCounted = DistortionProgress.new()

	assert_eq(progress.transition_strength(-1.0), 1.0, "Transition strength must clamp below zero to full strength")
	assert_true(absf(progress.transition_strength(0.5) - 0.25) < 0.0001, "Transition strength must fade out quadratically")
	assert_eq(progress.transition_strength(2.0), 0.0, "Transition strength must clamp above one to zero")
