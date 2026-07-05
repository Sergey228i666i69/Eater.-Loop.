extends "res://tests/test_case.gd"

const AMBIENT_STREAM_PATH := "res://music/InsideAmbient.wav"
const DISTORTION_STREAM_PATH := "res://music/StressMusic.wav"
const EVENT_STREAM_PATH := "res://music/UniversityMusic.wav"
const MUSIC_MANAGER_PATH := "res://levels/music_manager.gd"

func run() -> Array[String]:
	assert_true(MusicManager != null, "MusicManager autoload is missing")
	if MusicManager == null:
		return get_failures()
	assert_true(_ensure_music_manager_players(), "MusicManager players must be initialized")
	if not _ensure_music_manager_players():
		return get_failures()

	var ambient_stream := load(AMBIENT_STREAM_PATH) as AudioStream
	var distortion_stream := load(DISTORTION_STREAM_PATH) as AudioStream
	var event_stream := load(EVENT_STREAM_PATH) as AudioStream
	assert_true(ambient_stream != null, "Ambient test stream failed to load")
	assert_true(distortion_stream != null, "Distortion test stream failed to load")
	assert_true(event_stream != null, "Event test stream failed to load")
	if ambient_stream == null or distortion_stream == null or event_stream == null:
		return get_failures()

	await _test_pending_ambient_does_not_override_distortion(ambient_stream, distortion_stream)
	await _test_event_and_distortion_music_start_are_idempotent(event_stream, distortion_stream)
	await _test_scoped_music_sources_cleanup_on_tree_exit(ambient_stream, event_stream, distortion_stream)
	_test_mix_settings_resource_resolves_category_offsets()
	_test_pause_resume_restores_playback_position()
	_test_chase_pause_reasons_do_not_resume_while_minigame_paused()
	await _test_chase_sources_cleanup_on_tree_exit(event_stream)
	_cleanup_music_manager()
	return get_failures()

func _test_pending_ambient_does_not_override_distortion(ambient_stream: AudioStream, distortion_stream: AudioStream) -> void:
	_cleanup_music_manager()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	MusicManager.play_ambient_music(ambient_stream, 0.0)
	await tree.process_frame
	MusicManager.set_ambient_music_suppressed(self, true, 0.0)
	await tree.process_frame
	assert_eq(MusicManager.get("_pending_ambient_stream"), ambient_stream, "Ambient stream must stay queued while suppression is active")

	MusicManager.start_distortion_music(self, distortion_stream, 0.0)
	await tree.process_frame
	MusicManager.set_ambient_music_suppressed(self, false, 0.0)
	await tree.process_frame
	await tree.process_frame

	assert_eq(MusicManager.get_current_stream(), distortion_stream, "Pending ambient must not replace active distortion music")
	assert_eq(String(MusicManager.get("_current_source_kind")), MusicManager.SOURCE_KIND_DISTORTION, "Distortion source kind must stay active until distortion music stops")
	assert_eq(MusicManager.get("_pending_ambient_stream"), ambient_stream, "Ambient stream must remain pending until higher-priority music stops")

	MusicManager.stop_distortion_music(self, 0.0)
	await tree.process_frame
	await tree.process_frame
	assert_eq(MusicManager.get_current_stream(), ambient_stream, "Pending ambient must resume after distortion music stops")
	assert_eq(String(MusicManager.get("_current_source_kind")), MusicManager.SOURCE_KIND_AMBIENT, "Ambient source kind must restore after distortion music stops")

func _test_event_and_distortion_music_start_are_idempotent(event_stream: AudioStream, distortion_stream: AudioStream) -> void:
	_cleanup_music_manager()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var source := Node.new()
	tree.root.add_child(source)
	await tree.process_frame

	MusicManager.start_event_music(source, event_stream, 0.0, 999.0, 0.25)
	await tree.process_frame
	var stack_after_first_event: int = MusicManager.get("_stack").size()
	MusicManager.start_event_music(source, event_stream, 0.0, 999.0, 0.5)
	await tree.process_frame
	assert_eq(MusicManager.get("_stack").size(), stack_after_first_event, "Repeated start_event_music for the same source must not push duplicate stack entries")
	MusicManager.stop_event_music(source, 0.0)
	await tree.process_frame
	assert_true(not MusicManager.get("_event_sources").has(source.get_instance_id()), "Event source must unregister after stop_event_music")

	MusicManager.start_distortion_music(source, distortion_stream, 0.0)
	await tree.process_frame
	var stack_after_first_distortion: int = MusicManager.get("_stack").size()
	MusicManager.start_distortion_music(source, distortion_stream, 0.0)
	await tree.process_frame
	assert_eq(MusicManager.get("_stack").size(), stack_after_first_distortion, "Repeated start_distortion_music for the same source must not push duplicate stack entries")
	MusicManager.stop_distortion_music(source, 0.0)
	await tree.process_frame
	assert_true(not MusicManager.get("_distortion_sources").has(source.get_instance_id()), "Distortion source must unregister after stop_distortion_music")

	source.queue_free()
	await tree.process_frame
	_cleanup_music_manager()

func _test_scoped_music_sources_cleanup_on_tree_exit(ambient_stream: AudioStream, event_stream: AudioStream, distortion_stream: AudioStream) -> void:
	_cleanup_music_manager()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	MusicManager.play_ambient_music(ambient_stream, 0.0)
	await tree.process_frame
	var event_source := Node.new()
	tree.root.add_child(event_source)
	await tree.process_frame
	var event_source_id := event_source.get_instance_id()
	MusicManager.start_event_music(event_source, event_stream, 0.0, 999.0, 0.0)
	await tree.process_frame
	assert_true(MusicManager.get("_event_sources").has(event_source_id), "Event source must register while its node is alive")
	assert_eq(String(MusicManager.get("_current_source_kind")), MusicManager.SOURCE_KIND_EVENT, "Event music must become the active source before tree-exit cleanup")

	event_source.queue_free()
	await tree.process_frame
	await tree.process_frame

	assert_true(not MusicManager.get("_event_sources").has(event_source_id), "Event source must unregister automatically when its node exits the tree")
	assert_eq(MusicManager.get_current_stream(), ambient_stream, "Event source tree exit must release the scoped stack entry")
	assert_eq(String(MusicManager.get("_current_source_kind")), MusicManager.SOURCE_KIND_AMBIENT, "Ambient source kind must restore after event source tree exit")

	var distortion_source := Node.new()
	tree.root.add_child(distortion_source)
	await tree.process_frame
	var distortion_source_id := distortion_source.get_instance_id()
	MusicManager.start_distortion_music(distortion_source, distortion_stream, 0.0)
	await tree.process_frame
	assert_true(MusicManager.get("_distortion_sources").has(distortion_source_id), "Distortion source must register while its node is alive")
	assert_eq(String(MusicManager.get("_current_source_kind")), MusicManager.SOURCE_KIND_DISTORTION, "Distortion music must become the active source before tree-exit cleanup")

	distortion_source.queue_free()
	await tree.process_frame
	await tree.process_frame

	assert_true(not MusicManager.get("_distortion_sources").has(distortion_source_id), "Distortion source must unregister automatically when its node exits the tree")
	assert_eq(MusicManager.get_current_stream(), ambient_stream, "Distortion source tree exit must release the scoped stack entry")
	assert_eq(String(MusicManager.get("_current_source_kind")), MusicManager.SOURCE_KIND_AMBIENT, "Ambient source kind must restore after distortion source tree exit")
	_cleanup_music_manager()

func _test_mix_settings_resource_resolves_category_offsets() -> void:
	var settings := load("res://music/music_mix_settings.tres") as MusicMixSettings
	assert_true(settings != null, "Music mix settings resource must load")
	if settings == null:
		return
	assert_eq(settings.get_category_offset_db(MusicManager.MIX_AMBIENT), -16.5, "Ambient mix offset must come from the resource")
	assert_eq(settings.get_category_offset_db("unknown"), 0.0, "Unknown mix categories must not change volume")
	assert_eq(settings.resolve_volume_db(MusicManager.MIX_MENU, 20.0), 6.0, "Mix resolver must clamp loud output")
	assert_eq(settings.resolve_volume_db(MusicManager.MIX_AMBIENT, 0.0), -16.5, "Mix resolver must apply category offsets")
	assert_eq(MusicManager.resolve_mix_volume_db(MusicManager.MIX_AMBIENT, 0.0), -16.5, "MusicManager public mix facade must delegate to MusicMixSettings")

func _test_pause_resume_restores_playback_position() -> void:
	var script_text := FileAccess.get_file_as_string(MUSIC_MANAGER_PATH)
	assert_true(script_text != "", "Failed to read music_manager.gd")
	if script_text == "":
		return
	assert_true(script_text.find("_base_pause_position = resume_position_override if resume_position_override >= 0.0 else _get_playback_position(player)") != -1, "Pause path must store an explicit playback position before stopping the base player")
	assert_true(script_text.find("player.play()\n\t_seek_if_possible(player, resume_position)") != -1, "Resume path must restart the base player and seek back to the stored position")
	assert_true(script_text.find("_base_pause_position = 0.0") != -1, "Resume path must clear the stored paused position after restoring playback")

func _test_chase_pause_reasons_do_not_resume_while_minigame_paused() -> void:
	_cleanup_music_manager()
	MusicManager.pause_chase_music(0.0, MusicManager.CHASE_PAUSE_REASON_MENU)
	MusicManager.pause_chase_music(0.0, MusicManager.CHASE_PAUSE_REASON_MINIGAME)

	assert_true(bool(MusicManager.get("_runner_global_paused")), "Chase music must be globally paused while any pause reason is active")

	MusicManager.resume_chase_music(0.0, MusicManager.CHASE_PAUSE_REASON_MENU)
	var reasons: Dictionary = MusicManager.get("_runner_global_pause_reasons")
	assert_true(bool(MusicManager.get("_runner_global_paused")), "Closing pause menu must not resume chase music while minigame pause remains active")
	assert_true(reasons.has(MusicManager.CHASE_PAUSE_REASON_MINIGAME), "Minigame chase pause reason must remain after menu pause resumes")

	MusicManager.resume_chase_music(0.0, MusicManager.CHASE_PAUSE_REASON_MINIGAME)
	assert_true(not bool(MusicManager.get("_runner_global_paused")), "Chase music may resume only after the final pause reason is cleared")

func _test_chase_sources_cleanup_on_tree_exit(chase_stream: AudioStream) -> void:
	_cleanup_music_manager()
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "SceneTree is not available")
	if tree == null:
		return

	var first_source := Node.new()
	var second_source := Node.new()
	tree.root.add_child(first_source)
	tree.root.add_child(second_source)
	await tree.process_frame
	var first_id := first_source.get_instance_id()
	var second_id := second_source.get_instance_id()

	MusicManager.set_chase_music_source(first_source, true, chase_stream, -7.0, 0.0)
	MusicManager.set_chase_music_source(second_source, true, chase_stream, -3.0, 0.0)
	await tree.process_frame
	assert_true(MusicManager.is_chase_active(), "Chase music must be active while chase sources are registered")
	assert_eq(int(MusicManager.get("_runner_active_source_id")), first_id, "First chase source must keep priority before it exits")

	first_source.queue_free()
	await tree.process_frame
	await tree.process_frame
	var sources_after_first_exit: Dictionary = MusicManager.get("_runner_sources")
	assert_true(not sources_after_first_exit.has(first_id), "Exited chase source must unregister automatically")
	assert_true(sources_after_first_exit.has(second_id), "Second chase source must remain registered after first source exits")
	assert_eq(int(MusicManager.get("_runner_active_source_id")), second_id, "Chase music must switch to the next source after active source exits")
	assert_true(MusicManager.is_chase_active(), "Chase music must stay active while a second source remains")

	second_source.queue_free()
	await tree.process_frame
	await tree.process_frame
	assert_true(not MusicManager.is_chase_active(), "Chase music must stop after the final source exits")
	assert_eq(int(MusicManager.get("_runner_active_source_id")), 0, "Chase active source id must reset after the final source exits")

func _cleanup_music_manager() -> void:
	if MusicManager == null:
		return
	MusicManager.set_ambient_music_suppressed(self, false, 0.0)
	MusicManager.clear_chase_music_sources(0.0)
	MusicManager.clear_stack()
	MusicManager.reset_base_music_state()

func _ensure_music_manager_players() -> bool:
	var from_player: AudioStreamPlayer = MusicManager.get("_player_a") as AudioStreamPlayer
	var to_player: AudioStreamPlayer = MusicManager.get("_player_b") as AudioStreamPlayer
	if from_player != null and to_player != null:
		return true
	if MusicManager.has_method("_ready"):
		MusicManager.call("_ready")
	from_player = MusicManager.get("_player_a") as AudioStreamPlayer
	to_player = MusicManager.get("_player_b") as AudioStreamPlayer
	return from_player != null and to_player != null
