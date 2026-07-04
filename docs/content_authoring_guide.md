# Content Authoring Guide

Этот документ - рабочий чеклист для добавления новых уровней, интерактивов, света, врагов и мини-игр. Он не заменяет аудит, а переводит уже закрытые баги в правила, чтобы новый контент не возвращал старые поломки.

## Базовое Правило

Новый контент должен проходить:

- `godot --headless --check-only -s res://tests/run_tests.gd`
- `bash tests/run_tests.sh`

Если новый контент вводит новый неявный договор между сценой и кодом, добавь маленький validator в `tests/cases/` до того, как договор начнёт жить только в памяти автора.

## Новый Уровень

1. Используй существующий `levels/cycles/level.gd`-контур, если сцена является игровой. Playable scenes в `levels/cycles/` должны называться `level_*.tscn` и иметь root-контракт `get_cycle_number()` / `get_timer_duration()`; gameplay-сцены вне этой папки должны сохранять cycle/timer root contract или явно добавляться в группу `gameplay_scene`. Non-level utility-сцены в этой папке должны быть явно allowlisted в `test_level_authoring_contracts.gd`. Не добавляй локальные проверки вида `path.find("/levels/cycles/")`; классификация сцены должна идти через `SceneContext`.
2. Не правь `GameDirector` ради локальной механики уровня, пока это можно выразить интерактивом, trigger-ом, resource/config-ом или отдельным scene script.
3. Двери должны иметь resolving `target_marker`. Self-target допустим только для inert/locked двери, иначе fade-to-self снова станет runtime-багом.
4. Cycle-level scene должна иметь ровно один Player instance из `res://player/player.tscn`; respawn, enemies, UI bars и checkpoint flow завязаны на единственный runtime `player`.
5. Cycle-level scene должна иметь положительный `cycle_number`, неотрицательный `timer_duration` и хотя бы одну кровать с loadable `next_level_path`. Self-loop кровати запрещён, а `next_level_path` должен вести только в cycle-level или ending scene; это проверяет `test_level_authoring_contracts.gd`.
6. Если включаешь стартовый hint/subtitle, текст должен быть непустым. Root-level exported `*_path` поля должны быть непустыми и резолвиться из root-сцены, кроме явно optional полей вроде `fridge_interacted_spawn_marker_path` и `primary_fridge_path`. Validator также проверяет ожидаемые типы по имени: `door` -> `Door`, `fridge` -> `Fridge`, `laptop` -> `Laptop`, `bed` -> `Bed`, `player` -> `Player`, `generator` -> `InteractiveObject`.
7. Если добавляешь `LevelMusic`, не оставляй активную музыку без `stream`: `play_on_ready=true` и stop-on-exit (`continue_on_level_change=false`) требуют `AudioStream`, а `fade_time` должен быть неотрицательным. Это проверяет `test_level_authoring_contracts.gd`.
8. Scene-owned `AudioStreamPlayer`/`AudioStreamPlayer2D` должны явно использовать `Music` или `Sounds`: эффекты ставь на `Sounds`, музыкальные helper-плееры на `Music`. `LevelMusic` делегирует воспроизведение в `MusicManager`, поэтому его bus не является авторским контрактом сцены.
9. В active content scenes любой exported непустой `NodePath` или элемент `Array[NodePath]` должен резолвиться от владельца скрипта. Если поле хранит marker path, который будет применён к другому узлу, как STU door retarget fields, покрывай его focused contract с правильным origin.
10. Если уровень зависит от холодильника, лабораторной, еды, денег или телефона, обращайся к `CycleState`/`GameState` через публичные методы. Прямой доступ к ключевым полям запрещён архитектурным тестом.
11. Настройки игрока задавай через existing player export-поля сцены: бег через `allow_running`, `stamina_*`, `run_speed_multiplier`, фонарик через `flashlight_use_duration`, `flashlight_recharge_duration`, `flashlight_recharge_delay`, скелетные step times через `skeleton_*_step_times`. Speed/run multiplier/timing values должны оставаться положительными или неотрицательными там, где `0` имеет явный смысл unlimited/instant; step indices должны быть положительными, а skeleton step times отсортированы. Drain/recovery/checkpoint semantics живут в `PlayerStaminaState` и `PlayerFlashlightChargeState`, facing checkpoint normalization живёт в `PlayerFacingState`, key add/has/remove/checkpoint semantics живут в `PlayerInventoryState`, а arming/wrap/counter semantics скелетных шагов живут в `PlayerSkeletonStepState`; эти helper-ы и scene export ranges покрыты тестами.
12. Для checkpoint-состояния добавляй `checkpoint_stateful` только тем объектам, которым нужен restore позиции/видимости/velocity/existence или custom state. Если объект объявляет custom `capture_checkpoint_state()` или `apply_checkpoint_state(state)`, объявляй оба метода парой; это проверяется тестом. Checkpoint participants должны иметь стабильный scene-relative path: не используй сгенерированные `@...` имена для таких узлов и не оставляй их анонимными. Runtime-spawned objects требуют отдельного restore contract; сейчас factory restore безопасно разрешён только enemy/spawner сценариям через `CheckpointDynamicRestore` и `CheckpointSceneSnapshot`. Restore проходит fail-closed: сцена должна инстанцироваться как allowlisted runtime node, например через root-группу `enemies` или enemy script lineage; для нового класса runtime-объектов сначала расширяй policy и добавляй focused test.
13. Если используешь `TriggerSetProperty`, configured `target_paths`/`changes` должны указывать на существующие узлы и реальные property, а сам trigger должен иметь хотя бы один property/sfx/music effect. Чисто музыкальные/sfx trigger-ы могут не иметь target changes, но music replace/event-start actions требуют `music_stream`; это проверяется `test_trigger_set_property_contracts.gd`.
14. Не оставляй inherited door/interactable config overrides как `null`: для typed defaults используй явные значения вроде `false`, `""` или `NodePath("")`. Это особенно важно для `is_locked`, `required_key_id`, `interact_area_node`, `target_marker` и `one_shot`, потому что `null` скрывает фактическую семантику сцены.
15. Если используешь level utility scripts вроде лебёдки, corridor distortion или `TargetMonsterSpawner`, не оставляй обязательные `NodePath` в уме: текущие пути уже проверяются `test_scene_nodepath_contracts.gd`, а для новых utility scripts добавляй аналогичный focused contract.
16. Для event/distortion музыки передавай scene-owned `Node` как `source` в `MusicManager.start_event_music(...)` / `start_distortion_music(...)`: manager снимет registry/stack entry при `tree_exited`, а обычный enter/exit flow всё равно должен явно вызывать stop.
17. Если уровень использует крупные STU-пути или dynamic door redirects, держи route/wiring paths в exported `NodePath`/target-полях scene script-а и добавь focused path contract рядом с `test_stu_level_path_contracts.gd` вместо надежды на ручной просмотр `.tscn`.
18. В level scripts не вызывай публичный API двери через `has_method("set_locked")` / `call("set_target_marker_path", ...)`, если путь обязан вести к двери. Типизируй узел как `Door`, а validator пусть проверяет, что exported path действительно резолвится в `Door`.
19. Финальные развилки, fridge-driven redirects и signal-driven spawner conditions должны быть typed: `laptop_path` резолвится в `Laptop`, `fridge_path` в `Fridge`, `bed_path` в `Bed`, а реакция на успешное взаимодействие идёт через `interaction_succeeded` или доменный сигнал вроде `feeding_finished`. Не подписывай новый runtime/scene authoring на legacy `interaction_finished`.
20. Если root scene script экспортирует optional wiring, называй его явно (`primary_fridge_path`, `fridge_interacted_spawn_marker_path`) и добавляй его в allowlist общего validator-а только когда пустое значение действительно является частью дизайна.

## Новый Интерактив

1. Наследуйся от `InteractiveObject`, если объект участвует в player interaction flow.
2. Не обрабатывай один и тот же `interact` input параллельно с `InteractionManager`. Дай manager-у выбрать объект по availability, priority и distance.
3. Для зависимостей указывай и объект, и typed condition: `COMPLETED` или `INTERACTION_REQUESTED`. Не возвращайся к старому one-shot fail-open поведению.
4. Вызывай `complete_interaction()` только после успешного outcome. Failed/cancelled/requested outcomes не должны удовлетворять completed dependency.
5. Для данных результата, которые могут понадобиться другим объектам (`reward_type`, `key_id`, item/reward/branch data), используй `InteractionResultBuilder.with_payload(...)`; для выдачи ключа используй готовый `InteractionResultBuilder.key_reward(key_id)`. `payload` зарезервирован как Dictionary; произвольные совместимые top-level ключи допускаются только для старых локальных данных. Если появляется новый тип reward/item/branch payload, сначала добавь constants/helper в `InteractionResultBuilder` и focused test, затем используй его в интерактивах.
6. Если объект показывает prompt не из своей позиции, дай стабильный `get_prompt_world_position()` или корректный prompt anchor.
7. Если дверь требует `required_key_id`, в этой же сцене должен быть источник такого ключа: `SearchSpot.key_id`, `Key.key_id` или `Note.reward_key_id`. Если используешь `SearchKeyManager`, его `search_spots` должен быть непустым и все paths должны резолвиться.
8. Managed `SearchSpot` должен быть полноценной точкой поиска: `minigame_scene` инстанцируется и держит `setup(config)`, `get_layout_state()`, `SearchArea/KeyButton`, `SearchArea/TrashContainer`; `key_id` непустой, `key_texture` задан, `trash_textures` непустой и `trash_min`/`trash_max` образуют валидный видимый диапазон.
9. Все exported `NodePath` для критичных детей должны либо быть пустыми и optional, либо резолвиться. Для новых обязательных child/path contracts добавляй проверку в `test_scene_nodepath_contracts.gd`.

## Свет, Генератор И Враги

1. Скрипт, который добавляет себя в reactive light contract, должен делать это через `ReactiveLightContracts.register_reactive_light_source(self)` и объявлять `is_point_lit(point: Vector2)`.
2. Скрипт, который должен включаться генератором, должен регистрироваться через `ReactiveLightContracts.register_generator_required_light(self)` / `register_generator_required_lamp(self)` и объявлять `turn_on()`.
3. Лампы, прожекторы и pickup flashlight должны иметь resolving `light_node` на `PointLight2D`.
4. Врагам нельзя полагаться на скрытое знание конкретной лампы. Они должны потреблять light contracts через `ReactiveLightContracts.get_reactive_light_sources(...)` и метод `is_point_lit(...)`.
5. `TargetMonsterSpawner` с `enemy_scene` должен явно задавать condition; node-signal/trigger-enter variants должны иметь resolving source paths, реальные signals/properties и optional spawn parent только если он действительно существует.

## Мини-Игры

1. Для обычной timed lab логики начинай с `timed_lab_minigame_base.gd`.
2. Для gamepad/Steam Deck поведения следуй [`minigame_gamepad_system.md`](minigame_gamepad_system.md).
3. Lab laptop с `minigame_scene` должен иметь положительный `time_limit`, неотрицательный `penalty_time` и scene, которая инстанцируется как `TimedLabMinigameBase` с `task_completed`, `time_limit`, `penalty_time` и `lab_completion_id`.
4. Если в одной сцене несколько разных лабораторных или холодильник задаёт `required_lab_completion_ids`, передавай стабильные и уникальные `lab_completion_id`. Required IDs холодильника должны ссылаться на ноутбуки в той же сцене; это проверяет `test_lab_authoring_contracts.gd`.
5. Feeding-холодильник с `minigame_scene` или `food_scenes` должен иметь полный config: loadable feeding scene с `minigame_finished` и `setup_game`, непустые `food_scenes`, положительный `food_count`, `andrey_face` и `background_texture`. Code-lock холодильник должен иметь непустой `access_code` и `code_lock_scene` с сигналом `unlocked`; final fridge должен иметь `final_minigame_scene` с финальным setup contract. Это проверяет `test_fridge_authoring_contracts.gd`.
6. Timeout, cancel и fail-forward должны быть одноразовыми. Повторное закрытие мини-игры не должно выдавать деньги, еду или completion второй раз.

## Локализация И Текст

1. Новый player-facing текст добавляй в `global/localization/texts.csv` с заполненными `keys`, `ru` и `en`.
2. Не копируй строки из браузера/мессенджера без проверки кодировки. `test_localization_contracts.gd` ловит mojibake в CSV и runtime text sources.
3. Русскоязычные player-facing строки в `text`, `prompt_text`, message export-полях, death/ending UI, note/obstacle prompts, lab dialogue exports, money reward reasons, gamepad `hints`, default gamepad hints, `UIMessage.show_*("...")` и `tr("...")` должны иметь ключ в CSV; это проверяется тестом. Не добавляй транслит-ключи вроде ASCII-фраз с пробелами для русских строк: используй русский source text или semantic id. Статические `.tscn` player-facing строки и прямые GDScript call-literals в `UIMessage.show_*("...")` / `tr("...")` без кириллицы тоже должны иметь CSV-key, кроме явных technical exceptions вроде SQL editor chrome.

## Ассеты И Export

1. Source assets и `.import` должны быть tracked. Бинарные ассеты идут через Git LFS.
2. После fresh clone нужен `git lfs install && git lfs pull`.
3. Новые `.gd` и `.gdshader` должны попадать в Git вместе с `.uid` sidecar; это проверяет `test_resource_uid_contracts.gd`. Если UID не создался, запусти `godot --headless --path . --import` и добавь только нужный sidecar.
4. Export paths должны оставаться внутри `exports/`; это проверяет `test_export_presets_contract.gd`.
5. CI запускает MacOS debug export smoke после тестов. Перед release-выводами дополнительно запускай signed/notarized release export на машине с нужными Apple credentials/templates.

## Когда Добавлять Validator

Добавляй validator, если новое правило можно сформулировать как:

- required child name or `NodePath`;
- required group/method contract;
- scene script должен явно задать condition/config;
- playable level scene должен иметь явный cycle/timer root contract;
- cycle-level metadata, Player instance/export ranges, LevelMusic or bed transition/target scene type contract;
- lab completion id or required lab reference contract;
- lab minigame scene contract;
- trigger target path, property, effect or music-stream contract;
- typed interaction signal subscription contract;
- exported content scene `NodePath` resolving contract;
- scene-owned audio player bus contract;
- utility-level condition/spawn path contract;
- key-door source, search manager or managed `SearchSpot` config contract;
- inherited scene override must use explicit typed defaults instead of `null`;
- fridge feeding/code-lock/final minigame config contract;
- state должен сохраняться в checkpoint/save;
- checkpoint participant должен иметь стабильный scene-relative path;
- новый player-facing текст должен иметь localization key;
- новый runtime object должен восстанавливаться после respawn.

Validator должен быть focused: лучше маленький тест на один contract, чем большой интеграционный тест, который трудно читать и чинить.
