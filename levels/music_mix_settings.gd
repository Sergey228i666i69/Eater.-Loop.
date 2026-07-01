class_name MusicMixSettings
extends Resource

## Настройки микса для типов музыки (дБ оффсеты).

const MIX_AMBIENT := "ambient"
const MIX_DISTORTION := "distortion"
const MIX_EVENT := "event"
const MIX_CHASE := "chase"
const MIX_MINIGAME := "minigame"
const MIX_PAUSE := "pause"
const MIX_MENU := "menu"
const MIN_VOLUME_DB := -80.0
const MAX_VOLUME_DB := 6.0

@export_range(-40.0, 20.0, 0.1) var ambient_db_offset: float = -6.0
@export_range(-40.0, 20.0, 0.1) var distortion_db_offset: float = 0.0
@export_range(-40.0, 20.0, 0.1) var event_db_offset: float = 0.0
@export_range(-40.0, 20.0, 0.1) var chase_db_offset: float = 0.0
@export_range(-40.0, 20.0, 0.1) var minigame_db_offset: float = 0.0
@export_range(-40.0, 20.0, 0.1) var pause_db_offset: float = 0.0
@export_range(-40.0, 20.0, 0.1) var menu_db_offset: float = 0.0

func resolve_volume_db(category: String, base_volume_db: float) -> float:
	return clampf(base_volume_db + get_category_offset_db(category), MIN_VOLUME_DB, MAX_VOLUME_DB)

func get_category_offset_db(category: String) -> float:
	match category:
		MIX_AMBIENT:
			return ambient_db_offset
		MIX_DISTORTION:
			return distortion_db_offset
		MIX_EVENT:
			return event_db_offset
		MIX_CHASE:
			return chase_db_offset
		MIX_MINIGAME:
			return minigame_db_offset
		MIX_PAUSE:
			return pause_db_offset
		MIX_MENU:
			return menu_db_offset
	return 0.0
