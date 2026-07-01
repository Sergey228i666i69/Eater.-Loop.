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
4. Если уровень зависит от холодильника, лабораторной, еды, денег или телефона, обращайся к `CycleState`/`GameState` через публичные методы. Прямой доступ к ключевым полям запрещён архитектурным тестом.
5. Для checkpoint-состояния используй `checkpoint_stateful` только у объектов, которые реально умеют `capture_checkpoint_state()` и `apply_checkpoint_state(state)`. Runtime-spawned objects требуют отдельного restore contract; сейчас он безопасно покрыт для enemy/spawner сценариев.
6. Если уровень использует крупные STU-пути, добавь focused path contract рядом с `test_stu_level_path_contracts.gd` вместо надежды на ручной просмотр `.tscn`.

## Новый Интерактив

1. Наследуйся от `InteractiveObject`, если объект участвует в player interaction flow.
2. Не обрабатывай один и тот же `interact` input параллельно с `InteractionManager`. Дай manager-у выбрать объект по availability, priority и distance.
3. Для зависимостей указывай и объект, и typed condition: `COMPLETED` или `INTERACTION_REQUESTED`. Не возвращайся к старому one-shot fail-open поведению.
4. Вызывай `complete_interaction()` только после успешного outcome. Failed/cancelled/requested outcomes не должны удовлетворять completed dependency.
5. Если объект показывает prompt не из своей позиции, дай стабильный `get_prompt_world_position()` или корректный prompt anchor.
6. Все exported `NodePath` для критичных детей должны либо быть пустыми и optional, либо резолвиться. Для новых обязательных child/path contracts добавляй проверку в `test_scene_nodepath_contracts.gd`.

## Свет, Генератор И Враги

1. Скрипт, который добавляет себя в `reactive_light_source`, обязан объявлять `is_point_lit(point: Vector2)`.
2. Скрипт, который добавляет себя в `generator_required_light` или `generator_required_lamp`, обязан объявлять `turn_on()`.
3. Лампы, прожекторы и pickup flashlight должны иметь resolving `light_node` на `PointLight2D`.
4. Врагам нельзя полагаться на скрытое знание конкретной лампы. Они должны потреблять light contracts через группу/метод или через новый typed component, если появится более строгая абстракция.

## Мини-Игры

1. Для обычной timed lab логики начинай с `timed_lab_minigame_base.gd`.
2. Для gamepad/Steam Deck поведения следуй [`minigame_gamepad_system.md`](minigame_gamepad_system.md).
3. Если мини-игра должна завершать лабораторную, передавай стабильный `lab_completion_id`, чтобы несколько лабораторных на одном цикле не схлопывались в один глобальный `lab_done`.
4. Timeout, cancel и fail-forward должны быть одноразовыми. Повторное закрытие мини-игры не должно выдавать деньги, еду или completion второй раз.

## Локализация И Текст

1. Новый player-facing текст добавляй в `global/localization/texts.csv` с заполненными `keys`, `ru` и `en`.
2. Не копируй строки из браузера/мессенджера без проверки кодировки. `test_localization_contracts.gd` ловит mojibake в CSV и runtime text sources.
3. Hardcoded русские строки ещё существуют исторически, но новый контент лучше сразу вести через `tr(...)` и CSV key, чтобы потом можно было ужесточить validator без массовой археологии.

## Ассеты И Export

1. Source assets и `.import` должны быть tracked. Бинарные ассеты идут через Git LFS.
2. После fresh clone нужен `git lfs install && git lfs pull`.
3. Export paths должны оставаться внутри `exports/`; это проверяет `test_export_presets_contract.gd`.
4. Перед release-выводами дополнительно запускай реальный export smoke на машине с Godot templates. CI пока проверяет preset contract, но не собирает release artifact автоматически.

## Когда Добавлять Validator

Добавляй validator, если новое правило можно сформулировать как:

- required child name or `NodePath`;
- required group/method contract;
- scene script должен явно задать condition/config;
- state должен сохраняться в checkpoint/save;
- новый player-facing текст должен иметь localization key;
- новый runtime object должен восстанавливаться после respawn.

Validator должен быть focused: лучше маленький тест на один contract, чем большой интеграционный тест, который трудно читать и чинить.
