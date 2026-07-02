extends "res://tests/test_case.gd"

const MinigameMusicSession = preload("res://levels/minigames/minigame_music_session.gd")


class FakeMusicManager:
	extends RefCounted

	var calls: Array[Dictionary] = []

	func start_minigame_music(stream: AudioStream, volume_db: float = 999.0) -> void:
		calls.append({"method": "start_minigame_music", "stream": stream, "volume_db": volume_db})

	func push_music(stream: AudioStream, fade_time: float = -1.0) -> void:
		calls.append({"method": "push_music", "stream": stream, "fade_time": fade_time})

	func pop_music(fade_time: float = -1.0) -> void:
		calls.append({"method": "pop_music", "fade_time": fade_time})

	func stop_music(fade_time: float = -1.0) -> void:
		calls.append({"method": "stop_music", "fade_time": fade_time})

	func stop_minigame_music() -> void:
		calls.append({"method": "stop_minigame_music"})

	func resolve_mix_volume_db(mix_name: String, volume_db: float) -> float:
		calls.append({"method": "resolve_mix_volume_db", "mix_name": mix_name, "volume_db": volume_db})
		return volume_db - 2.0

	func play_music(
		stream: AudioStream,
		fade_time: float,
		volume_db: float,
		start_position: float,
		output_volume_db: float,
		source_id: int,
		source_kind: String
	) -> void:
		calls.append({
			"method": "play_music",
			"stream": stream,
			"fade_time": fade_time,
			"volume_db": volume_db,
			"start_position": start_position,
			"output_volume_db": output_volume_db,
			"source_id": source_id,
			"source_kind": source_kind
		})


func run() -> Array[String]:
	_test_stream_setup_restores_with_zero_fade_pop()
	_test_suspend_without_stream_pushes_null_and_honors_stop_on_finish()
	_test_update_uses_mix_facade_and_stop_uses_stream_stop()
	return get_failures()


func _test_stream_setup_restores_with_zero_fade_pop() -> void:
	var manager := FakeMusicManager.new()
	var session := MinigameMusicSession.new()
	var stream := AudioStreamWAV.new()

	session.configure(0.4, false)
	session.setup(manager, stream, -6.0, false)

	assert_true(session.is_pushed(), "Stream setup must mark music as pushed")
	assert_true(session.is_stream(), "Stream setup must remember dedicated minigame stream mode")
	assert_eq(manager.calls.size(), 1, "Stream setup must call MusicManager once")
	assert_eq(manager.calls[0].get("method"), "start_minigame_music", "Stream setup must use the public minigame music facade")
	assert_eq(manager.calls[0].get("stream"), stream, "Stream setup must pass the configured stream")

	session.restore(manager)
	assert_true(not session.is_pushed(), "Restore must clear pushed state")
	assert_true(not session.is_stream(), "Restore must clear stream mode")
	assert_eq(manager.calls[1].get("method"), "pop_music", "Stream restore must pop the previous music stack entry")
	assert_eq(manager.calls[1].get("fade_time"), 0.0, "Stream restore must preserve the existing zero-fade pop behavior")


func _test_suspend_without_stream_pushes_null_and_honors_stop_on_finish() -> void:
	var manager := FakeMusicManager.new()
	var session := MinigameMusicSession.new()

	session.configure(0.35, true)
	session.setup(manager, null, 999.0, true)

	assert_true(session.is_pushed(), "Suspended background music must push a stack entry")
	assert_true(not session.is_stream(), "Suspended background music must not be treated as a minigame stream")
	assert_eq(manager.calls[0].get("method"), "push_music", "Suspend setup must push a null music entry")
	assert_eq(manager.calls[0].get("stream"), null, "Suspend setup must push a null stream")
	assert_eq(manager.calls[0].get("fade_time"), 0.35, "Suspend setup must use configured fade time")

	session.restore(manager)
	assert_eq(manager.calls[1].get("method"), "stop_music", "Stop-on-finish suspend restore must stop current music first")
	assert_eq(manager.calls[1].get("fade_time"), 0.35, "Stop-on-finish must use configured fade time")
	assert_eq(manager.calls[2].get("method"), "pop_music", "Suspend restore must pop the stack after optional stop")
	assert_eq(manager.calls[2].get("fade_time"), 0.35, "Suspend restore must pop with configured fade time")


func _test_update_uses_mix_facade_and_stop_uses_stream_stop() -> void:
	var manager := FakeMusicManager.new()
	var session := MinigameMusicSession.new()
	var first_stream := AudioStreamWAV.new()
	var next_stream := AudioStreamWAV.new()

	session.configure(0.25, false)
	session.update(manager, first_stream, -3.0, -1.0, "minigame", -10, "minigame")
	assert_eq(manager.calls[0].get("method"), "start_minigame_music", "First update must start minigame music through the facade")
	assert_true(session.is_pushed(), "First update must mark the session as pushed")
	assert_true(session.is_stream(), "First update must put the session in stream mode")

	session.update(manager, next_stream, -4.0, 0.6, "minigame", -10, "minigame")
	assert_eq(manager.calls[1].get("method"), "resolve_mix_volume_db", "Second update must resolve minigame mix volume")
	assert_eq(manager.calls[2].get("method"), "play_music", "Second update must crossfade through play_music")
	assert_eq(manager.calls[2].get("stream"), next_stream, "Second update must play the new stream")
	assert_eq(manager.calls[2].get("fade_time"), 0.6, "Second update must use the explicit fade time")
	assert_eq(manager.calls[2].get("volume_db"), -6.0, "Second update must pass the resolved mix volume")
	assert_eq(manager.calls[2].get("source_id"), -10, "Second update must preserve the minigame source id")
	assert_eq(manager.calls[2].get("source_kind"), "minigame", "Second update must preserve the minigame source kind")

	session.stop(manager)
	assert_eq(manager.calls[3].get("method"), "stop_minigame_music", "Stopping stream-mode minigame music must use the dedicated stop facade")
