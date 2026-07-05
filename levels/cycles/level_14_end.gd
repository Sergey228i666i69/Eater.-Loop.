extends "res://levels/cycles/level_11_end.gd"

func _ready() -> void:
	super._ready()
	_stop_carried_music()

func _stop_carried_music() -> void:
	if MusicManager == null:
		return
	MusicManager.clear_chase_music_sources(0.0)
	MusicManager.clear_stack()
	MusicManager.reset_base_music_state()
