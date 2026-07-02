# Гигиена Репозитория, Naming И Мусор

Оценка проблемности среза на момент первичного аудита: **7/10**.

Текущий статус: крупная часть hygiene-проблем уже закрыта. `archive(trash)` и `level_NSTU_test.tscn` удалены из runtime-дерева, активный уровень с кириллической `с` переименован в `level_09_crazy.tscn`, ассеты заведены через Git LFS, root `export_presets.cfg` отслеживается, runtime `print()` запрещён архитектурным тестом, а найденный naming debt нормализован Godot-aware rename-ами.

## Диагноз

Главная проблема не в том, что проект "не запускается прямо сейчас" на текущей машине. Главная проблема в том, что репозиторий плохо воспроизводится и быстро копит археологию: старые сцены, test-сцены в runtime-дереве, раздутая структура уровней, inconsistent naming и debug leftovers.

## Resolved: Локальные Ассеты Не Соответствуют Git-Состоянию

Git почти не трекает аудио/изображения, но сцены и скрипты на них ссылаются.

Примеры:

- [`.gitignore`](../.gitignore), около строки 11.
- [`player/player.tscn`](../player/player.tscn), около строки 4.
- [`levels/music_manager.gd`](../levels/music_manager.gd), около строки 34.
- [`objects/interactable/fridge/fridge.tscn`](../objects/interactable/fridge/fridge.tscn), около строки 8.

Это было исправлено через Git LFS. После clone нужен `git lfs install && git lfs pull`.

## Resolved: В Git Лежит Явный Архив/Мусор

Отслеживаются файлы вроде:

- `levels/cycles/archive(trash)/level_04_old_trash.tscn`;
- `level_test_enemies.tscn`;
- `trashhh.tscn`;
- `level_07_doors_save.tscn`;
- `level_NSTU_test.tscn`.

Перед удалением был найден активный переход из `level_04_findkey` в архивный `level_05_keystests`; он перевязан на актуальный `level_05_sql`, после чего архивные сцены удалены.

## P2: Сцены Очень Крупные

Самые крупные `.tscn`, найденные агентом:

- `level_12_STU_2.tscn`: 9233 строки;
- `level_13_STU_3.tscn`: 8727 строк;
- `level_11_STU_1.tscn`: 8595 строк;
- `level_NSTU_test.tscn`: 8578 строк, удалён после замены тестовой ссылки на активные STU-сцены.

Практический риск: правки уровней становятся дорогими, diff тяжело ревьюить, reuse почти невозможен.

Ремонт: вынос повторяемых комнат/коридоров/интерактивных кластеров в инстансы сцен и resources.

## Resolved: Первый Split Больших God Classes

Найдены крупные классы:

- `GameDirector`: было 1171 строка, стало около 844 строк + `game_director_cycle_phase_bridge.gd` + `game_director_cycle_timer_state.gd` + `game_director_death_title_presenter.gd` + `game_director_death_camera_coordinator.gd` + `game_director_death_cursor_coordinator.gd` + `game_director_death_retry_coordinator.gd` + `game_director_distortion_gate.gd` + `game_director_distortion_overlay_coordinator.gd` + `game_director_distortion_phase_state.gd` + `game_director_distortion_progress.gd` + `game_director_timer_node_coordinator.gd` + `game_director_stalker_service.gd` + `game_director_overlay_layer_coordinator.gd`;
- `MusicManager`: около 1133 строк, публичный facade оставлен стабильным;
- `MinigameController`: около 589 строк + `minigame_backdrop_presenter.gd` + `minigame_prompt_visibility_coordinator.gd` + `minigame_timer_state.gd` + `minigame_modal_ownership.gd` + `minigame_music_session.gd` + `gamepad_scheme_registry.gd`; `GamepadRuntime`: около 559 строк + `gamepad_hint_builder.gd` + `gamepad_navigation_repeat.gd`;
- `UIMessage`: стало около 589 строк + `ui_fade_controller.gd`.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd).
- [`levels/music_manager.gd`](../levels/music_manager.gd).
- [`levels/minigames/minigame_controller.gd`](../levels/minigames/minigame_controller.gd).
- [`player/ui_message.gd`](../player/ui_message.gd).

Не каждый большой файл плох сам по себе, но здесь размеры совпадали со смешением обязанностей. Безопасные pass-ы вынесли fade/tween state из `UIMessage`, backdrop registry/presentation, prompt suspend/restore lifecycle, timer state, pause/cursor ownership, minigame music stack lifecycle и gamepad scheme registry из `MinigameController`, gamepad hint policy и navigation repeat state из `GamepadRuntime`, death-title/glitch presentation, stalker spawn/checkpoint service, overlay layer policy, death cursor/input policy, death camera capture/restore, death retry restore/darken policy, cycle timer/checkpoint state, CycleState phase bridge, timer node lifecycle, minigame distortion gate, distortion progress/easing math, distortion overlay/material actuator и distortion phase/checkpoint state из `GameDirector`. Более широкий распил `MusicManager`/`GameDirector` остаётся future refactor-ом, а не hygiene-блокером текущего состояния.

## Resolved: Naming Inconsistent И Местами Опасный

Найденные опасные имена нормализованы:

- `level_09_crazy.tscn` теперь использует латинскую `c`;
- `levels/minigames/feeding/food/chiken` -> `chicken`;
- `levels/minigames/feeding/food/meet` -> `meat`;
- `food_meet.tscn` -> `food_meat.tscn`;
- `objects/environment/sprites/toilet and bathroom` -> `toilet_bathroom`;
- `DoorNSTU_highevel.png` -> `DoorNSTU_highlevel.png`;
- `FridgeNoizeE.wav` -> `FridgeNoiseE.wav`;
- search-key `Без названия *.png` backgrounds получили descriptive names.

Scene/script references и `.import` metadata обновлены вместе с файлами. Оставшиеся спорные имена вроде `Frizzer` лучше трогать только отдельным scene-authoring rename pass, если они окажутся реально вредными в текущей работе.

## Resolved: Дублировался Паттерн Прожектора

Ранее старый `projector.gd` и новый `projector2.gd` оба держали:

- питание;
- группы `reactive_light_source`;
- звук;
- `is_point_lit`;
- toggle;
- checkpoint-state.

Статус: `Projector2` удалён как неиспользуемая параллельная реализация. Canonical implementation остаётся:

- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd).

Направление, reactive-light group и input contract покрыты тестами старого projector implementation.

## Resolved: Debug Leftovers

Найдены production `print()`/debug leftovers.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd), около строки 218.
- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строки 95.
- [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строки 300.
- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 29.

Статус: runtime `print()` заменён на `print_verbose()`, а `test_interaction_architecture_contracts.gd` запрещает новые raw `print()` в `levels`, `objects`, `player`, `enemies` и `global`.

## P3: Magic Strings/Numbers

Примеры:

- `999.0` как sentinel в [`levels/music_manager.gd`](../levels/music_manager.gd), около строки 70.
- `-80.0` как mute volume.
- длинный death text и layout tables прямо в [`levels/game_director.gd`](../levels/game_director.gd), около строки 122.

Ремонт: named constants/resources.
