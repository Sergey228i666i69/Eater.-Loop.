extends RefCounted

var _music_pushed: bool = false
var _music_is_stream: bool = false
var _music_stop_on_finish: bool = false
var _music_fade_time: float = 0.3


func configure(fade_time: float, stop_on_finish: bool) -> void:
	_music_fade_time = fade_time
	_music_stop_on_finish = stop_on_finish


func setup(music_manager, stream: AudioStream, volume_db: float, suspend_music: bool) -> void:
	if music_manager == null:
		_music_is_stream = false
		return
	_music_is_stream = stream != null
	if stream == null and not suspend_music:
		return
	_music_pushed = true
	if stream != null:
		music_manager.start_minigame_music(stream, volume_db)
		return
	music_manager.push_music(null, _music_fade_time)


func restore(music_manager) -> void:
	if music_manager == null:
		return
	if not _music_pushed:
		return
	if _music_is_stream:
		music_manager.pop_music(0.0)
		_clear_pushed_state()
		return
	if _music_stop_on_finish:
		music_manager.stop_music(_music_fade_time)
	music_manager.pop_music(_music_fade_time)
	_clear_pushed_state()


func stop(music_manager, fade_time: float = -1.0) -> void:
	if music_manager == null:
		return
	if not _music_pushed:
		return
	if _music_is_stream:
		music_manager.stop_minigame_music()
		return
	music_manager.stop_music(_resolve_fade_time(fade_time))


func update(
	music_manager,
	stream: AudioStream,
	volume_db: float,
	fade_time: float,
	mix_name: String,
	source_id: int,
	source_kind: String
) -> void:
	if music_manager == null:
		return
	var target_fade := _resolve_fade_time(fade_time)
	if not _music_pushed:
		_music_pushed = true
		_music_is_stream = true
		music_manager.start_minigame_music(stream, volume_db)
		return
	var mixed_volume := float(music_manager.resolve_mix_volume_db(mix_name, volume_db))
	music_manager.play_music(stream, target_fade, mixed_volume, 0.0, 999.0, source_id, source_kind)


func is_pushed() -> bool:
	return _music_pushed


func is_stream() -> bool:
	return _music_is_stream


func _resolve_fade_time(fade_time: float) -> float:
	return _music_fade_time if fade_time < 0.0 else fade_time


func _clear_pushed_state() -> void:
	_music_pushed = false
	_music_is_stream = false
