# Рефакторинг-Роадмап

Этот документ сортирует найденные проблемы не по папкам, а по порядку ремонта. Приоритеты основаны на мультиагентном аудите от 2026-05-14.

## Фаза 0: Стабилизировать Текущее Состояние

Цель: вернуть доверие к тестам и локальному запуску.

1. Починить `test_light_adds_directional_contract.gd`: старый projector direction сейчас не соответствует контракту.
2. Расследовать ранее замеченный `test_audio_menu_to_level01_bedroom_runtime.gd`: tooling-агент видел failure, финальный прогон после документации не воспроизвёл.
3. Разобраться с `ObjectDB instances leaked at exit`.
4. Вернуть или заменить `lamp_switch`: сейчас action отсутствует в `project.godot`, но используется лампой и старым проектором.
5. Расширить `test_input_actions.gd`, чтобы он проверял actions, реально возвращаемые `_get_interact_action()`.

Definition of done: `godot --headless --check-only -s res://tests/run_tests.gd` и `bash tests/run_tests.sh` проходят локально.

## Фаза 1: Воспроизводимость Репозитория

Цель: fresh clone должен иметь понятный путь к запуску.

1. Выбрать asset policy:
   - Git LFS/tracked assets;
   - или внешний asset pack с bootstrap-инструкцией и checksum.
2. Пересмотреть `.gitignore`: не игнорировать то, что нужно для сборки без явного bootstrap.
3. Нормализовать `export_presets.cfg`:
   - трекать безопасный preset;
   - или генерировать его из template.
4. Убрать локальные пути вида `../Documents/EaterLoopExport/...`.
5. Добавить CI workflow с Godot 4.6.1, import, parser check, full tests.

Definition of done: проект можно склонировать на чистую машину и получить одинаковый test result по документированной инструкции.

## Фаза 2: Критические Gameplay-Баги

Цель: убрать баги, которые меняют прогресс игрока.

1. Починить `queue_sleep_spawn()` / `GameState.next_cycle()` ordering.
2. При входе в credits закрывать или архивировать активный run.
3. Исправить ceiling enemy light check.
4. Сделать checkpoint restore для dynamic spawned threats.
5. Сделать checkpoint-state для level-12 money и student reward flags.
6. Закрыть fridge fail-open: отсутствие minigame/food config не должно засчитывать еду.

Definition of done: каждый пункт имеет focused test или scene validation.

## Фаза 3: InteractionManager

Цель: один input press должен активировать ровно один выбранный объект.

1. Ввести `InteractionManager`.
2. У каждого интерактива должны быть priority/distance/availability.
3. Подсказку показывает manager, а не множество объектов одновременно.
4. Manager должен проверять `MinigameController.is_active()`.
5. Разделить outcomes:
   - interaction requested;
   - interaction succeeded;
   - completed forever.
6. Перевести dependency с прямого `InteractiveObject.is_completed` на typed conditions.

Definition of done: overlapping Area2D больше не вызывает несколько интерактов одним нажатием.

## Фаза 4: Scene Contracts И Validators

Цель: ловить сломанные NodePath/group/method contracts до runtime.

1. Добавить validators для required child nodes.
2. Проверять groups/methods вроде `reactive_light_source`, `turn_on`, `is_point_lit`.
3. Проверять missing/broken NodePath.
4. Проверять checkpoint participants: capture/apply, stable id, dynamic restore.
5. Проверять localization keys для player-facing строк.

Definition of done: типовые ошибки сцен падают тестом, а не silently no-op.

## Фаза 5: Разрезать God Objects

Цель: уменьшить blast radius будущих изменений.

1. `GameDirector`:
   - death/checkpoint service;
   - distortion/stalker service;
   - overlay/cursor coordinator.
2. `UIMessage`:
   - message/prompt UI;
   - transition service;
   - scene navigation.
3. `MusicManager`:
   - оставить публичный фасад;
   - вынести data/layout/magic constants в resources.
4. `Fridge`:
   - отделить lock/code/minigame/story hooks.

Definition of done: новые уровни не требуют править глобальный директор для локальных интерактивов.

## Фаза 6: Repo Hygiene

Цель: сделать дерево проекта спокойным и предсказуемым.

1. Вынести или удалить `archive(trash)` и test/old/save runtime-сцены.
2. Нормализовать naming:
   - lowercase snake_case;
   - без lookalike-кириллицы;
   - без `trash`, `test`, `old` в runtime paths.
3. Разбить huge `.tscn` на reusable scene instances.
4. Убрать debug `print()` или заменить logger-ом.
5. Вынести magic numbers/strings в constants/resources.

Definition of done: `rg "trash|old|test"` по runtime-папкам не находит активной археологии без явного whitelist.
