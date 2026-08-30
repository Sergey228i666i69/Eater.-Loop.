# Архитектурные Контракты

## Facade API Вместо Случайных Узлов

Стабильные autoload/facade вызываются напрямую:

- `GameState`, `CycleState`
- `UIMessage`
- `GameDirector`
- `MusicManager`
- `PauseManager`
- `MinigameController`
- `InteractionManager`, `InteractionPrompts`
- `SceneContext`, `CursorManager`

Разрешён `if UIMessage != null:` или аналогичный guard. Не разрешён паттерн
`UIMessage.has_method("fade_out")` для стабильного API: если метод исчез,
это должен увидеть тест или parser, а не тихий runtime no-op.

## Запрет Private Coupling

Внешний код не должен вызывать:

- приватные методы `MusicManager._*`;
- приватные методы `InteractiveObject._*`;
- приватные поля `GameState`/`CycleState`, если уже есть public getter/mutator;
- helper state внутри `GameDirector`, `Player`, `MinigameController`, если есть
  facade wrapper.

Приватный метод можно менять без обратной совместимости. Зависимость на него -
архитектурный дефект.

## SceneContext И Переходы Сцен

- Gameplay определяется через `SceneContext`, group `gameplay_scene`, typed
  `CycleLevel` root contract или разрешённый path fallback `levels/cycles/level_*.tscn`.
- Menu и ending scenes имеют отдельную классификацию.
- `PauseManager` не должен открываться поверх menu/ending scenes.
- Scene transitions идут через `UIMessage.change_scene_with_fade*`.
- `Bed.next_level_path` должен вести только в cycle-level или ending scene.

## Pause Ownership

`PauseManager` владеет `get_tree().paused`.

- Используй `request_pause(owner, reason)` и `release_pause(owner, reason)`.
- Не сохраняй локальный previous paused bool в модальных системах.
- Pause menu, notes/hints, death screen и мини-игры должны иметь отдельные
  owner tokens.
- Hard transitions могут делать `clear_all_pause_requests()`.

## Music Ownership

- Вся музыка проходит через `MusicManager`.
- Level ambient запускается через `LevelMusic`.
- SFX идут в bus `Sounds`.
- Scene-owned `AudioStreamPlayer`/`AudioStreamPlayer2D` должны явно иметь bus
  `Music` или `Sounds`.
- Event/distortion/chase sources лучше передавать как scene-owned `Node`, чтобы
  registry cleaned up на `tree_exited`.
- Для категории громкости используй `MusicManager.resolve_mix_volume_db(...)`,
  а не private mix helpers.

## Interaction Flow

- `InteractionManager` выбирает один объект по availability, priority и distance.
- Объект должен наследоваться от `InteractiveObject`, если участвует в player
  interaction flow.
- Manager-facing API:
  - `get_interact_action_name()`
  - `set_manager_focus(...)`
- Внутренние override points вроде `_get_interact_action()` не вызываются
  внешним кодом.
- Новые подписки используют typed signals:
  - `interaction_result`
  - `interaction_succeeded`
  - `interaction_failed`
  - `interaction_cancelled`
- Legacy `interaction_finished` остаётся совместимым success wrapper, но новый
  runtime/scene authoring не должен на него опираться.

## Minigame Flow

- Запуск идёт через `MinigameController.start_minigame(...)` или managed helpers
  интерактива.
- Pause/cursor/music/prompt lifecycle задаётся `MinigameSettings`, а не локальной
  ручной логикой.
- Start/finish fade transitions идут через `UIMessage.play_fade_sequence(...)`.
- Gamepad схемы задаются через `set_gamepad_scheme` и снимаются через
  `clear_gamepad_scheme`.
- Timed lab minigames наследуются от `TimedLabMinigameBase`.

## Player Facade

Сцены ожидают настоящий `Player` из `res://player/player.tscn`.

- Cycle-level scene должна иметь ровно один Player instance.
- **Основная анимация**: Покадровая спрайтовая анимация (`AnimatedSprite2D` со спрайтами `ezgif-frame-*.png`).
- **Скелетный риг**: `player_skeleton_rig.tscn` — архивный неудачный эксперимент, не используемый на уровнях.
- Ключи, stamina, flashlight, physics toggles и point-lit checks вызываются
  через публичный Player API.
- Не добавляй `player.has_method(...)` fallback, если сцена по contract обязана
  иметь Player.

## Текст И Локализация

- Новый player-facing текст добавляй в `global/localization/texts.csv`.
- Русские строки, death/ending UI, prompts, note/obstacle/lab/money тексты,
  gamepad hints и прямые `UIMessage.show_*("...")`/`tr("...")` должны иметь key.
- Не добавляй ASCII translit phrase keys для русских строк.
- Технические исключения допустимы только там, где validator явно это разрешает.

## Checkpoint И Dynamic Restore

- `checkpoint_stateful` ставь только объектам, которым нужен restore состояния.
- Если объект объявляет `capture_checkpoint_state()`, он должен объявлять и
  `apply_checkpoint_state(state)`.
- Checkpoint participants должны иметь стабильный scene-relative path без
  generated `@...` segments.
- Runtime restore fail-closed и разрешён только allowlisted runtime scenes.
