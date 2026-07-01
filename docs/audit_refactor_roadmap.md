# Рефакторинг-Роадмап

Этот документ сортирует найденные проблемы не по папкам, а по порядку ремонта. Приоритеты основаны на мультиагентном аудите от 2026-05-14.

## Фаза 0: Стабилизировать Текущее Состояние

Цель: вернуть доверие к тестам и локальному запуску.

1. ~~Починить `test_light_adds_directional_contract.gd`.~~
2. ~~Расследовать ранее замеченный bedroom ambient failure.~~ Полный suite сейчас зелёный.
3. ~~Разобраться с `ObjectDB instances leaked at exit`.~~ Async runtime-тесты теперь дожидаются своих transition states, runner делает короткий drain.
4. ~~Вернуть или заменить `lamp_switch`.~~ Лампа и старый проектор используют `interact`.
5. ~~Расширить `test_input_actions.gd`.~~ Тест проверяет реальные light-interactable actions.

Definition of done: `godot --headless --check-only -s res://tests/run_tests.gd` и `bash tests/run_tests.sh` проходят локально.

## Фаза 1: Воспроизводимость Репозитория

Цель: fresh clone должен иметь понятный путь к запуску.

1. ~~Выбрать asset policy.~~ Выбран Git LFS.
2. ~~Пересмотреть `.gitignore`.~~ Source assets и `.import` больше не игнорируются.
3. ~~Нормализовать `export_presets.cfg`.~~ Root preset tracked, export paths repo-local.
4. ~~Убрать локальные пути вида `../Documents/EaterLoopExport/...`.~~
5. ~~Добавить CI workflow с Godot 4.6.1, import, parser check, full tests.~~ `.github/workflows/godot-tests.yml` делает checkout с LFS, `git lfs pull`, parser check и full suite.

Definition of done: проект можно склонировать на чистую машину и получить одинаковый test result по документированной инструкции и CI workflow.

## Фаза 2: Критические Gameplay-Баги

Цель: убрать баги, которые меняют прогресс игрока.

1. ~~Починить `queue_sleep_spawn()` / `GameState.next_cycle()` ordering.~~
2. ~~При входе в credits закрывать или архивировать активный run.~~
3. ~~Исправить ceiling enemy light check.~~
4. ~~Сделать checkpoint restore для dynamic spawned threats.~~ Runtime enemies, `TargetMonsterSpawner` и stalker restore покрыты тестами.
5. ~~Сделать checkpoint-state для level-12 money и student reward flags.~~
6. ~~Закрыть fridge fail-open: отсутствие minigame/food config не должно засчитывать еду.~~

Definition of done: каждый пункт имеет focused test или scene validation.

## Фаза 3: InteractionManager

Цель: один input press должен активировать ровно один выбранный объект.

1. ~~Ввести `InteractionManager`.~~
2. ~~У каждого интерактива должны быть priority/distance/availability.~~
3. ~~Подсказку показывает manager, а не множество объектов одновременно.~~
4. ~~Manager должен проверять активную мини-игру.~~
5. ~~Частично разделить outcomes.~~
   - interaction requested;
   - interaction succeeded;
   - completed forever.
   One-shot fail-open закрыт через `_should_auto_complete_after_interact()` и явное `complete_interaction()` на успехе у двери, холодильника, ноутбука и блокпоста. Dependency contract различает `COMPLETED` и `INTERACTION_REQUESTED`; `InteractiveObject` дополнительно получил `interaction_result`, `interaction_succeeded`, `interaction_failed` и `interaction_cancelled`, а failed/cancelled outcomes не удовлетворяют completed dependencies.
6. ~~Перевести dependency с прямого `InteractiveObject.is_completed` на typed conditions.~~ Минимально закрыто через `DependencyCondition`.

Definition of done: overlapping Area2D больше не вызывает несколько интерактов одним нажатием; success/failure/cancel outcomes выражены typed-сигналами и покрыты контрактными тестами.

7. ~~Централизовать владение `get_tree().paused`.~~ Закрыто через owner-token API в `PauseManager`: pause menu, notes/hints, pause-game minigames и death screen больше не восстанавливают локальный previous-bool.

## Фаза 4: Scene Contracts И Validators

Цель: ловить сломанные NodePath/group/method contracts до runtime.

1. ~~Добавить validators для required child nodes.~~ Закрыто для critical interactables через `test_scene_nodepath_contracts.gd`.
2. ~~Проверять groups/methods вроде `reactive_light_source`, `turn_on`, `is_point_lit`.~~ Runtime scripts, которые добавляют себя в эти группы, теперь обязаны объявлять нужные методы.
3. ~~Проверять missing/broken NodePath.~~ Закрыто для active level/interactable scenes and STU hardcoded paths.
4. ~~Проверять checkpoint participants: capture/apply, stable id, dynamic restore.~~ Базовый и dynamic restore покрыты.
5. ~~Проверять базовый localization CSV/mojibake contract.~~ `test_localization_contracts.gd` проверяет колонки `keys`/`ru`/`en`, пустые значения и mojibake в runtime text sources.
6. Проверять localization keys для всех player-facing строк.

Definition of done: типовые ошибки сцен падают тестом, а не silently no-op. Крупный visual/DRY-разбор STU-сцен теперь можно делать отдельным scene-authoring refactor поверх этих validators.

## Фаза 5: Разрезать God Objects

Цель: уменьшить blast radius будущих изменений.

1. `GameDirector`:
   - ~~death-title/glitch presentation;~~ вынесено в `game_director_death_title_presenter.gd`.
   - ~~stalker spawn/checkpoint service;~~ вынесено в `game_director_stalker_service.gd`.
   - death/checkpoint lifecycle service: death camera capture/restore вынесен в `game_director_death_camera_coordinator.gd`, retry checkpoint restore/darken policy вынесена в `game_director_death_retry_coordinator.gd`; локальный UI cleanup/reload tail ещё в директоре.
   - distortion service: minigame gate/pending activation state вынесен в `game_director_distortion_gate.gd`, progress/easing math вынесен в `game_director_distortion_progress.gd`, overlay/material actuator вынесен в `game_director_distortion_overlay_coordinator.gd`, phase/checkpoint state вынесен в `game_director_distortion_phase_state.gd`, cycle timer/checkpoint state вынесен в `game_director_cycle_timer_state.gd`; CycleState phase bridge ещё в директоре.
   - ~~overlay layer policy;~~ вынесено в `game_director_overlay_layer_coordinator.gd`.
   - ~~death cursor/input coordinator;~~ вынесено в `game_director_death_cursor_coordinator.gd`.
2. `UIMessage`:
   - message/prompt UI;
   - ~~fade transition tween/token state;~~ вынесено в `ui_fade_controller.gd`.
   - scene navigation.
3. `MusicManager`:
   - оставить публичный фасад;
   - вынести data/layout/magic constants в resources.
4. `MinigameController`:
   - ~~backdrop registry/presentation;~~ вынесено в `minigame_backdrop_presenter.gd`.
   - timer/pause/music/gamepad lifecycle можно дробить отдельными tested slices.
5. `Fridge`:
   - отделить lock/code/minigame/story hooks.

Definition of done: новые уровни не требуют править глобальный директор для локальных интерактивов.

## Resolved: Scene Context

Path-based checks вида `path.find("/levels/cycles/")` вынесены в `SceneContext`. Уровни и меню маркируются группами, а fallback по пути остался только централизованным.

## Фаза 6: Repo Hygiene

Цель: сделать дерево проекта спокойным и предсказуемым.

1. ~~Вынести или удалить `archive(trash)` и test/old/save runtime-сцены.~~
2. ~~Нормализовать самый опасный naming.~~ `level_09_сrazy.tscn`, `chiken`, `meet`, `Без названия *.png`, `toilet and bathroom`, `DoorNSTU_highevel.png` и `FridgeNoizeE.wav` исправлены с обновлением ссылок.
3. Разбить huge `.tscn` на reusable scene instances.
4. ~~Убрать debug `print()` или заменить logger-ом.~~ Runtime `print()` заменён на `print_verbose()`, архитектурный тест запрещает новые raw `print()`.
5. Вынести magic numbers/strings в constants/resources.

Definition of done: `rg "trash|old|test"` по runtime-папкам не находит активной археологии без явного whitelist.
