# Content Authoring Guide

Этот документ - рабочий чеклист для добавления новых уровней, интерактивов, света, врагов и мини-игр. Он не заменяет аудит, а переводит уже закрытые баги в правила, чтобы новый контент не возвращал старые поломки.

## Базовое Правило

Новый контент должен проходить:

- `godot --headless --check-only -s res://tests/run_tests.gd`
- `bash tests/run_tests.sh`

Если новый контент вводит новый неявный договор между сценой и кодом, добавь маленький validator в `tests/cases/` до того, как договор начнёт жить только в памяти автора.

## Новый Уровень

1. Используй существующий `levels/cycles/level.gd`-контур, если сцена является игровой. Не добавляй локальные проверки вида `path.find("/levels/cycles/")`; классификация сцены должна идти через `SceneContext`.
2. Не правь `GameDirector` ради локальной механики уровня, пока это можно выразить интерактивом, trigger-ом, resource/config-ом или отдельным scene script.
3. Двери должны иметь resolving `target_marker`. Self-target допустим только для inert/locked двери, иначе fade-to-self снова станет runtime-багом.
4. Cycle-level scene должна иметь положительный `cycle_number`, неотрицательный `timer_duration` и хотя бы одну кровать с loadable `next_level_path`. Self-loop кровати запрещён `test_level_authoring_contracts.gd`.
5. Если включаешь стартовый hint/subtitle, текст должен быть непустым. Если задаёшь `fridge_interacted_spawn_marker_path`, путь должен резолвиться в `Node2D`.
6. Если уровень зависит от холодильника, лабораторной, еды, денег или телефона, обращайся к `CycleState`/`GameState` через публичные методы. Прямой доступ к ключевым полям запрещён архитектурным тестом.
7. Настройки игрока задавай через existing player export-поля сцены: бег через `allow_running`, `stamina_*`, `run_speed_multiplier`, фонарик через `flashlight_use_duration`, `flashlight_recharge_duration`, `flashlight_recharge_delay`, скелетные step times через `skeleton_*_step_times`. Drain/recovery/checkpoint semantics живут в `PlayerStaminaState` и `PlayerFlashlightChargeState`, key add/has/remove/checkpoint semantics живут в `PlayerInventoryState`, а arming/wrap/counter semantics скелетных шагов живут в `PlayerSkeletonStepState`; эти helper-ы покрыты тестами.
8. Для checkpoint-состояния добавляй `checkpoint_stateful` только тем объектам, которым нужен restore позиции/видимости/velocity/existence или custom state. Если объект объявляет custom `capture_checkpoint_state()` или `apply_checkpoint_state(state)`, объявляй оба метода парой; это проверяется тестом. Runtime-spawned objects требуют отдельного restore contract; сейчас factory restore безопасно разрешён только enemy/spawner сценариям через `CheckpointDynamicRestore` и `CheckpointSceneSnapshot`.
9. Если используешь `TriggerSetProperty`, configured `target_paths`/`changes` должны указывать на существующие узлы и реальные property. Чисто музыкальные/sfx trigger-ы могут не иметь target changes; target-changing trigger-ы проверяются `test_trigger_set_property_contracts.gd`.
10. Если используешь level utility scripts вроде лебёдки, corridor distortion или `TargetMonsterSpawner`, не оставляй обязательные `NodePath` в уме: текущие пути уже проверяются `test_scene_nodepath_contracts.gd`, а для новых utility scripts добавляй аналогичный focused contract.
11. Если уровень использует крупные STU-пути, добавь focused path contract рядом с `test_stu_level_path_contracts.gd` вместо надежды на ручной просмотр `.tscn`.

## Новый Интерактив

1. Наследуйся от `InteractiveObject`, если объект участвует в player interaction flow.
2. Не обрабатывай один и тот же `interact` input параллельно с `InteractionManager`. Дай manager-у выбрать объект по availability, priority и distance.
3. Для зависимостей указывай и объект, и typed condition: `COMPLETED` или `INTERACTION_REQUESTED`. Не возвращайся к старому one-shot fail-open поведению.
4. Вызывай `complete_interaction()` только после успешного outcome. Failed/cancelled/requested outcomes не должны удовлетворять completed dependency.
5. Если объект показывает prompt не из своей позиции, дай стабильный `get_prompt_world_position()` или корректный prompt anchor.
6. Если дверь требует `required_key_id`, в этой же сцене должен быть источник такого ключа: `SearchSpot.key_id`, `Key.key_id` или `Note.reward_key_id`. Если используешь `SearchKeyManager`, его `search_spots` должен быть непустым и все paths должны резолвиться.
7. Все exported `NodePath` для критичных детей должны либо быть пустыми и optional, либо резолвиться. Для новых обязательных child/path contracts добавляй проверку в `test_scene_nodepath_contracts.gd`.

## Свет, Генератор И Враги

1. Скрипт, который добавляет себя в `reactive_light_source`, обязан объявлять `is_point_lit(point: Vector2)`.
2. Скрипт, который добавляет себя в `generator_required_light` или `generator_required_lamp`, обязан объявлять `turn_on()`.
3. Лампы, прожекторы и pickup flashlight должны иметь resolving `light_node` на `PointLight2D`.
4. Врагам нельзя полагаться на скрытое знание конкретной лампы. Они должны потреблять light contracts через группу/метод или через новый typed component, если появится более строгая абстракция.
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
3. Русскоязычные player-facing строки в `text`, `prompt_text`, message export-полях, death/ending UI, note/obstacle prompts, lab dialogue exports, money reward reasons, gamepad `hints`, default gamepad hints, `UIMessage.show_*("...")` и `tr("...")` должны иметь ключ в CSV; это проверяется тестом. Технические строки без кириллицы вроде таймеров, SQL-заголовков и кнопочных цифр пока не блокируются.

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
- cycle-level metadata or bed transition contract;
- lab completion id or required lab reference contract;
- lab minigame scene contract;
- trigger target path or property contract;
- utility-level condition/spawn path contract;
- key-door source or search manager contract;
- fridge feeding/code-lock/final minigame config contract;
- state должен сохраняться в checkpoint/save;
- новый player-facing текст должен иметь localization key;
- новый runtime object должен восстанавливаться после respawn.

Validator должен быть focused: лучше маленький тест на один contract, чем большой интеграционный тест, который трудно читать и чинить.
