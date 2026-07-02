# Архитектура, Autoload И Состояние

Оценка проблемности среза: **6.5/10**.

## Что Сейчас Работает Нормально

- Main scene задана явно в [`project.godot`](../project.godot), около строк 18-24.
- Autoload-и перечислены централизованно: `GameState`, `CycleState`, `GameDirector`, `MinigameController`, `MusicManager`, `UIMessage` и другие.
- Есть тесты на autoload/main scene/scene load/private API usage.
- `MusicManager`, несмотря на размер, имеет публичный фасад и уже защищён тестом от прямого вызова приватных методов.
- `MinigameSettings` оформлен как `Resource`, что лучше, чем полностью свободные Dictionary-конфиги.

## Resolved: Определение Игровой Сцены Через Строку Пути

Несколько глобальных систем решают, является ли текущая сцена игровой, через поиск `"/levels/cycles/"` в пути.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd), около строки 429.
- [`player/ui_message.gd`](../player/ui_message.gd), около строки 525.
- [`levels/minigames/cursor_manager.gd`](../levels/minigames/cursor_manager.gd), около строки 26.

Практический риск: если playable-сцена окажется вне `levels/cycles`, intro/debug/bonus-level будет вести себя как меню. Это silent failure: код не упадёт, просто не включит нужные игровые правила.

Статус: исправлено через `SceneContext`, группы `gameplay_scene` / `menu_scene` и архитектурный тест, запрещающий новые локальные `path.find("/levels/cycles/")` проверки вне `SceneContext`.

## P1: Глобальное Состояние Слишком Открыто

`GameState` и `CycleState` содержат публичные поля, к которым код обращается напрямую и через методы вперемешку.

Примеры:

- [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строки 8: `last_scene_path`, `has_active_run`, `flashlight_unlocked`.
- [`levels/cycles/cycle_state.gd`](../levels/cycles/cycle_state.gd), около строки 16: `phase`, `ate_this_cycle`, `lab_done`.
- [`levels/menu/main_menu.gd`](../levels/menu/main_menu.gd), около строки 121: раньше имел fallback к прямым полям, теперь использует публичные методы `GameState`.

Практический риск: состояние можно изменить в обход валидации, сигналов и инвариантов. При росте проекта это превращается в трудно воспроизводимые регрессии.

Статус: частично исправлено. Внешний доступ к ключевым полям `GameState` и `CycleState` запрещён архитектурным тестом, runtime-потребители `CycleState.phase`, lab/phone/flashlight flags и pending-флагов переведены на public read methods, а core `CycleState` flags заведены за private backing vars. `electricity_on` пока оставлен как публичное property с setter/signal, но для чтения добавлен публичный `is_electricity_on()`.

## P2: `GameDirector` Перегружен

`GameDirector` смешивает:

- таймер цикла;
- distortion;
- stalker spawn;
- death/retry UI;
- checkpoint integration;
- cursor/overlay coordination;
- mini-game hooks;
- music scene sync.

Агенты ссылались на `_process`, death/retry flow и overlay-layer magic numbers в [`levels/game_director.gd`](../levels/game_director.gd), около строк 144, 537, 983.

Риск не в том, что класс прямо сейчас сломан, а в цене изменений: любая новая механика уровня может задеть смерть, чекпоинт, музыку или курсор.

Статус: частично разгружен. Pause ownership для death screen закрыт через owner-token API `PauseManager`, death-title sequence/glitch layout/material factory вынесены в `levels/game_director_death_title_presenter.gd`, stalker spawn/find/capture/restore вынесен в `levels/game_director_stalker_service.gd`, overlay layer policy вынесена в `levels/game_director_overlay_layer_coordinator.gd`, death cursor/input policy вынесена в `levels/game_director_death_cursor_coordinator.gd`, death camera capture/restore вынесен в `levels/game_director_death_camera_coordinator.gd`, death retry restore/darken policy вынесена в `levels/game_director_death_retry_coordinator.gd`, cycle timer/checkpoint state вынесен в `levels/game_director_cycle_timer_state.gd`, CycleState phase bridge вынесен в `levels/game_director_cycle_phase_bridge.gd`, timer node lifecycle вынесен в `levels/game_director_timer_node_coordinator.gd`, minigame distortion gate вынесен в `levels/game_director_distortion_gate.gd`, distortion progress/easing math вынесен в `levels/game_director_distortion_progress.gd`, distortion overlay/material actuator вынесен в `levels/game_director_distortion_overlay_coordinator.gd`, а distortion phase/checkpoint state вынесен в `levels/game_director_distortion_phase_state.gd`; новые helper-ы покрыты отдельными тестами. Сам класс всё ещё владеет локальным death UI cleanup/reload tail.

Следующий ремонт: если потребуется, выносить reload-tail death UI lifecycle отдельными tested slices.

## P2: `UIMessage` Стал Service Locator

`UIMessage` отвечает не только за UI-сообщения:

- субтитры;
- записки;
- prompts;
- fade transitions;
- смену сцен;
- SFX;
- регистрацию модулей;
- сохранение текущей игровой сцены через path-check.

Примеры: [`player/ui_message.gd`](../player/ui_message.gd), около строк 65, 415, 460.

Статус: notes/hints больше не восстанавливают `get_tree().paused` через локальный previous-bool, а используют pause tokens `PauseManager`. Fade/tween/token state вынесен в `player/ui_fade_controller.gd`, при этом публичный `UIMessage` facade сохранён. Остальная перегрузка UI/navigation/prompts остаётся.

Ремонт: разделить message/prompt layer, transition service и scene navigation.

## P2: Checkpoint System Стал Надёжнее, Но Контракт Всё Ещё Нужен

Snapshot собирает `checkpoint_stateful` участников и сохраняет relative path. После ремонта runtime-created enemy-ноды дополнительно сохраняют dynamic restore descriptor (`scene_path`, `parent_path`, `node_name`) и могут быть пересозданы при apply. Scene snapshot/restore логика вынесена из `GameState` в `CheckpointSceneSnapshot`, а `GameState` оставлен стабильным фасадом для capture/apply. Custom checkpoint API у content scripts теперь проверяется как пара: если script объявляет `capture_checkpoint_state()` или `apply_checkpoint_state(state)`, он должен объявить оба метода.

Примеры:

- [`levels/cycles/checkpoint_scene_snapshot.gd`](../levels/cycles/checkpoint_scene_snapshot.gd), около строки 3: сбор participant paths.
- [`levels/cycles/checkpoint_scene_snapshot.gd`](../levels/cycles/checkpoint_scene_snapshot.gd), около строки 24: capture/apply по relative path и dynamic restore.
- [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строки 314: фасадные делегаты checkpoint scene state.

Для простых статичных объектов это нормально; для динамических врагов стало безопаснее и покрыто `test_checkpoint_scene_snapshot.gd` плюс интеграционными respawn-тестами. Оставшаяся ломкость: переименованные узлы, не-enemy runtime objects и scene contracts без validator-а.

Следующий ремонт: добавить stable checkpoint ids/validators для важных сценовых участников и явно документировать, какие runtime classes имеют право на factory restore.

## P2: Локализация Частично Закрыта

Изначально были найдены:

- mojibake в [`global/localization/texts.csv`](../global/localization/texts.csv), около строки 3, и в LLM glitch minigame;
- транслит-ключи в том же CSV, около строки 32;
- hardcoded русские строки вне CSV, например в [`objects/interactable/flashlight/pickup_flashlight.tscn`](../objects/interactable/flashlight/pickup_flashlight.tscn), около строки 33;
- hardcoded prompt в [`objects/interactable/flashlight/pickup_flashlight.tscn`](../objects/interactable/flashlight/pickup_flashlight.tscn), около строки 33.

Риск: английская локаль получит русские fallback-и или битый текст.

Статус: mojibake исправлен, а [`tests/cases/test_localization_contracts.gd`](../tests/cases/test_localization_contracts.gd) проверяет CSV-колонки `keys`/`ru`/`en`, пустые значения, mojibake в runtime text sources и наличие CSV-ключей у русскоязычных player-facing строк в сценах/скриптах. Оставшийся ремонт: постепенно заменить транслит-ключи и решить, нужно ли блокировать non-Russian/technical UI labels тем же validator-ом.

## Мелкие Smells

- `CursorManager` больше не держит dead `_in_game` state; внешний `set_in_game(...)` оставлен как compatibility API, но `GameDirector` больше не вызывает его для scene sync.
- `ending_credits.gd` имеет export `return_scene`, но resolver всегда возвращает main menu.
- `Bed._try_sleep` делает ручной fade и затем вызывает scene-change с fade delay.
- Первичный аудит находил `level_09_сrazy.tscn` с кириллической `с`; файл переименован в `level_09_crazy.tscn`.
