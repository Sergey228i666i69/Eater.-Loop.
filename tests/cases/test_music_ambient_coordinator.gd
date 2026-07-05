extends "res://tests/test_case.gd"

const MusicAmbientCoordinatorScript := preload("res://levels/music_ambient_coordinator.gd")
const AMBIENT_STREAM_PATH := "res://music/InsideAmbient.wav"


func run() -> Array[String]:
	_test_pending_request_lifecycle()
	_test_suppression_sources_keep_shared_mirror()
	return get_failures()


func _test_pending_request_lifecycle() -> void:
	var stream := assert_loads(AMBIENT_STREAM_PATH) as AudioStream
	if stream == null:
		return

	var coordinator = MusicAmbientCoordinatorScript.new()
	coordinator.set_pending(stream, -16.5, 0.25)

	assert_true(coordinator.has_pending(), "Coordinator must track queued ambient requests")
	assert_eq(coordinator.pending_stream(), stream, "Pending ambient stream must be readable before consume")
	assert_eq(coordinator.pending_volume_db(), -16.5, "Pending ambient volume must be readable before consume")
	assert_eq(coordinator.pending_fade_time(), 0.25, "Pending ambient fade must be readable before consume")

	var request := coordinator.consume_pending()
	assert_eq(request.get("stream"), stream, "Consumed pending ambient request must preserve stream")
	assert_eq(float(request.get("volume_db")), -16.5, "Consumed pending ambient request must preserve volume")
	assert_eq(float(request.get("fade_time")), 0.25, "Consumed pending ambient request must preserve fade")
	assert_true(not coordinator.has_pending(), "Consumed pending ambient request must clear pending state")
	assert_eq(coordinator.pending_stream(), null, "Pending stream must reset after consume")


func _test_suppression_sources_keep_shared_mirror() -> void:
	var mirror: Dictionary = {}
	var coordinator = MusicAmbientCoordinatorScript.new(mirror)
	var source := RefCounted.new()
	var source_id := source.get_instance_id()

	assert_true(coordinator.set_suppressed(source, true), "First suppression source must activate coordinator suppression")
	assert_true(coordinator.is_suppressed(), "Coordinator must report active suppression after source registration")
	assert_true(mirror.has(source_id), "Coordinator must keep the caller-owned suppression mirror updated")

	assert_true(coordinator.set_suppressed(source, false), "Removing the final suppression source must deactivate suppression")
	assert_true(not coordinator.is_suppressed(), "Coordinator must report inactive suppression after final source removal")
	assert_true(not mirror.has(source_id), "Coordinator must remove released suppression source from caller-owned mirror")
