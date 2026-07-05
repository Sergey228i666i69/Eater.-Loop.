extends "res://tests/test_case.gd"

const DeathFadeCoordinator = preload("res://levels/game_director_death_fade_coordinator.gd")
const DEATH_FADE_COORDINATOR_PATH := "res://levels/game_director_death_fade_coordinator.gd"
const FORBIDDEN_DEATH_FADE_METHOD_PROBES := [
	"camera_coordinator.has_method(",
	"camera_coordinator.call(",
]

class FakeTweener:
	extends RefCounted

	var transitions: Array[int] = []
	var eases: Array[int] = []

	func set_trans(value: int) -> FakeTweener:
		transitions.append(value)
		return self

	func set_ease(value: int) -> FakeTweener:
		eases.append(value)
		return self

class FakeTween:
	extends RefCounted

	signal finished

	var parallel_values: Array[bool] = []
	var property_calls: Array[Dictionary] = []
	var tweeners: Array[FakeTweener] = []

	func set_parallel(value: bool) -> void:
		parallel_values.append(value)

	func tween_property(target: Object, property: NodePath, final_value: Variant, duration: float) -> FakeTweener:
		var tweener := FakeTweener.new()
		tweeners.append(tweener)
		property_calls.append({
			"target": target,
			"property": str(property),
			"final_value": final_value,
			"duration": duration,
		})
		return tweener

class FakeCameraCoordinator:
	extends RefCounted

	var has_camera_value: bool = true
	var calls: Array[Dictionary] = []

	func has_camera() -> bool:
		return has_camera_value

	func tween_to_death_pose(tween: Object, fade_time: float, tilt_deg: float, zoom_mult: float, tilt_sign: float) -> void:
		calls.append({
			"tween": tween,
			"fade_time": fade_time,
			"tilt_deg": tilt_deg,
			"zoom_mult": zoom_mult,
			"tilt_sign": tilt_sign,
		})

class CallbackProbe:
	extends RefCounted

	var completed_calls: int = 0

	func on_completed() -> void:
		completed_calls += 1

func run() -> Array[String]:
	_test_begin_fade_prepares_rect_tween_and_camera()
	_test_begin_fade_clamps_duration_and_connects_completion()
	_test_begin_fade_allows_missing_rect_or_camera()
	_test_death_fade_uses_camera_coordinator_facade_directly()
	return get_failures()

func _test_begin_fade_prepares_rect_tween_and_camera() -> void:
	var coordinator: RefCounted = DeathFadeCoordinator.new()
	var tween := FakeTween.new()
	var fade_rect := ColorRect.new()
	fade_rect.visible = false
	fade_rect.color = Color(1, 1, 1, 1)
	var camera := FakeCameraCoordinator.new()

	var started: bool = coordinator.begin_fade(tween, fade_rect, camera, 0.5, 7.0, 1.2, -1.0, Callable())

	assert_true(started, "Death fade coordinator must start with a valid tween")
	assert_true(fade_rect.visible, "Death fade must show fade rect before tweening")
	assert_eq(fade_rect.color, Color(0, 0, 0, 0), "Death fade must reset fade rect alpha before tweening")
	assert_eq(tween.parallel_values, [true], "Death fade tween must run fade and camera in parallel")
	assert_eq(tween.property_calls.size(), 1, "Death fade must tween fade rect alpha")
	if tween.property_calls.size() == 1:
		assert_eq(tween.property_calls[0]["target"], fade_rect, "Death fade must target the provided fade rect")
		assert_eq(tween.property_calls[0]["property"], "color:a", "Death fade must tween alpha")
		assert_eq(tween.property_calls[0]["final_value"], 1.0, "Death fade must end at opaque black")
		assert_eq(tween.property_calls[0]["duration"], 0.5, "Death fade must use requested duration when valid")
	assert_eq(camera.calls.size(), 1, "Death fade must delegate death camera pose tween")
	if camera.calls.size() == 1:
		assert_eq(camera.calls[0]["tween"], tween, "Death camera tween must share the fade tween")
		assert_eq(camera.calls[0]["fade_time"], 0.5, "Death camera tween must use fade duration")
		assert_eq(camera.calls[0]["tilt_deg"], 7.0, "Death camera tween must keep configured tilt")
		assert_eq(camera.calls[0]["zoom_mult"], 1.2, "Death camera tween must keep configured zoom")
		assert_eq(camera.calls[0]["tilt_sign"], -1.0, "Death camera tween must keep selected tilt sign")
	assert_eq(tween.tweeners[0].transitions, [Tween.TRANS_SINE], "Death fade alpha tween must use sine transition")
	assert_eq(tween.tweeners[0].eases, [Tween.EASE_OUT], "Death fade alpha tween must ease out")
	fade_rect.free()

func _test_begin_fade_clamps_duration_and_connects_completion() -> void:
	var coordinator: RefCounted = DeathFadeCoordinator.new()
	var tween := FakeTween.new()
	var fade_rect := ColorRect.new()
	var camera := FakeCameraCoordinator.new()
	var probe := CallbackProbe.new()

	coordinator.begin_fade(tween, fade_rect, camera, -5.0, 0.0, 1.0, 1.0, Callable(probe, "on_completed"))
	tween.finished.emit()

	assert_eq(tween.property_calls[0]["duration"], DeathFadeCoordinator.MIN_FADE_TIME, "Death fade duration must be clamped to minimum")
	assert_eq(camera.calls[0]["fade_time"], DeathFadeCoordinator.MIN_FADE_TIME, "Death camera tween must use clamped fade time")
	assert_eq(probe.completed_calls, 1, "Death fade must connect completion callback")
	fade_rect.free()

func _test_begin_fade_allows_missing_rect_or_camera() -> void:
	var coordinator: RefCounted = DeathFadeCoordinator.new()
	var tween := FakeTween.new()
	var camera := FakeCameraCoordinator.new()
	camera.has_camera_value = false

	var started: bool = coordinator.begin_fade(tween, null, camera, 0.2, 3.0, 1.1, 1.0, Callable())

	assert_true(started, "Death fade coordinator must tolerate missing optional visuals")
	assert_eq(tween.parallel_values, [true], "Death fade must still configure tween mode")
	assert_eq(tween.property_calls.size(), 0, "Missing fade rect must skip alpha tween")
	assert_eq(camera.calls.size(), 0, "Missing captured camera must skip camera tween")

func _test_death_fade_uses_camera_coordinator_facade_directly() -> void:
	var content := FileAccess.get_file_as_string(DEATH_FADE_COORDINATOR_PATH)
	assert_true(content != "", "Failed to read script: %s" % DEATH_FADE_COORDINATOR_PATH)
	for pattern in FORBIDDEN_DEATH_FADE_METHOD_PROBES:
		assert_true(
			content.find(pattern) == -1,
			"Death fade coordinator must use the stable camera coordinator facade directly: %s" % pattern
		)
