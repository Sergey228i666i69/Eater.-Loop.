# Карта Проекта

## Godot И Entrypoint

- Движок: Godot 4.x, проект использует GL Compatibility renderer.
- Главная сцена: `res://levels/menu/main_menu.tscn`.
- Размер viewport: 1920x1080, stretch mode `canvas_items`.
- Переводы: `res://global/localization/texts.csv` импортируется в RU/EN
  `Translation` ресурсы.

## Autoload-ы

Ключевые singleton/facade из `project.godot`:

- `CycleState` - состояние цикла и phase/lab flags.
- `GameState` - состояние забега, сохранение, checkpoint, current scene path.
- `UIMessage` - fade, dialogue, notifications, scene transitions.
- `GameDirector` - таймер цикла, death screen, stalker, distortion flow.
- `SettingsManager` - настройки и audio bus bootstrap.
- `MusicManager` - весь музыкальный playback/mix/stack/chase/event flow.
- `PauseManager` - owner tokens для `get_tree().paused`.
- `InteractionPrompts` - player-facing подсказки взаимодействия.
- `InteractionManager` - выбор одного active interactable.
- `SceneContext` - классификация gameplay/menu/ending scenes.
- `StaminaBar`, `FlashlightBar` - HUD игрока.
- `CursorManager` - курсор в мини-играх и модальных состояниях.
- `MinigameController` - lifecycle мини-игр, pause/cursor/music/gamepad.

Сцены и content scripts должны относиться к этим autoload-ам как к стабильным
facade API: допускай `null` guard на отсутствие autoload-а, но не маскируй
сломанный API через `has_method/call`.

## Основные Папки

- `levels/menu/` - main menu, pause menu, settings, credits entry.
- `levels/cycles/` - playable cycle levels `level_*.tscn` и level scripts.
- `levels/templates/` - copy-start шаблон нового уровня.
- `levels/endings/` - экраны концовок и титры.
- `levels/minigames/` - контроллеры мини-игр, feeding/search/lab/gamepad UI.
- `objects/interactable/` - интерактивы, двери, холодильники, ноутбуки,
  триггеры, ключи, notes.
- `objects/interactable/templates/` - copy-start шаблоны интерактивов.
- `enemies/` - runner, stalker, light-sensitive и light-only enemies.
- `player/` - Player facade, skeleton rig, UI bars, camera/flashlight/stamina helpers.
- `global/` - общие helpers, localization, interaction manager, scene context.
- `music/` - audio assets и `music_mix_settings.tres`.
- `tests/cases/` - focused validators и runtime regression tests.
- `tools/` - export workaround, player rig previews, cutout tooling.

## Шаблоны Для Нового Контента

- `levels/templates/cycle_level_template.tscn`
- `objects/interactable/templates/basic_interactive_template.tscn`
- `objects/interactable/templates/lab_laptop_template.tscn`
- `objects/interactable/templates/feeding_fridge_template.tscn`

Новый контент лучше начинать с дубликата шаблона, а не с пустой сцены.
Шаблоны load-tested и проверяются теми же контрактами, что активный контент.

## Старые Справочники

- `../architecture_overview.md` - подробная карта facade и helper split-ов.
- `../content_authoring_guide.md` - длинный технический чеклист authoring.
- `../audio_system.md` - подробности `MusicManager`, `LevelMusic`,
  `TriggerSetProperty`.
- `../minigame_gamepad_system.md` - gamepad scheme format и Steam Deck QA.
- `../level_end_endings.md` - финальные развилки и титры.
- `../audit_*.md` - история аудита и ремонтов.
