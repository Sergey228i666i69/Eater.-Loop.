# AGENTS.md

## Назначение

Этот файл - короткий навигатор по репозиторию Godot-проекта `едок.-петля` и результатам мультиагентного аудита от 2026-05-14. Он держится в пределах короткой справки, а подробности вынесены в отдельные документы в `docs/`.

## Документы Аудита

- [Сводка мультиагентного аудита](docs/audit_multiagent_summary.md)
- [Архитектура, autoload и состояние](docs/audit_architecture_state.md)
- [Игровой цикл, уровни, враги и мини-игры](docs/audit_gameplay_loop.md)
- [Интерактивные объекты и scene contracts](docs/audit_interactables_and_scene_contracts.md)
- [Тесты, ассеты, export и воспроизводимость](docs/audit_tooling_assets_tests.md)
- [Гигиена репозитория, naming и мусор](docs/audit_repo_hygiene.md)
- [Рефакторинг-роадмап](docs/audit_refactor_roadmap.md)
- [Content authoring guide](docs/content_authoring_guide.md)

## Короткая Оценка

Текущая проблемность после ремонтных проходов: **около 5/10**. Первичный аудит 2026-05-14 оценивал проект на **7.3/10**.

Это не разваленный проект: entrypoint понятен, autoload-и явно заведены, есть локальный тестовый слой и часть архитектурных контрактов уже проверяется. После ремонтных проходов закрыты главные runtime-дыры: input света, фокус интерактивов, run-finish, checkpoint-сценарии, asset tracking, minigame input/timeout, one-shot completion, reversible triggers, явные spawner conditions, typed dependency/key-source/lab-id conditions, typed interaction outcomes, pause ownership tokens, scene NodePath/group-method/trigger-target/utility-path/level/fridge-authoring validators, localization CSV/mojibake/RU player-facing key contracts, project-config contracts, внешний доступ к ключевым `GameState`/`CycleState` полям и private backing для core `CycleState` flags. Naming debt из аудита нормализован, а `UIMessage`, `MinigameController`, death-title/stalker/overlay/cursor/death-camera/death-retry/cycle-timer/cycle-phase/timer-node/distortion-gate/distortion-progress/distortion-overlay/distortion-phase части `GameDirector` получили helper split-ы. Но проект всё ещё дорог в поддержке: уровни завязаны на NodePath/имена детей, `MusicManager`/`GameDirector`/`Player` остаются крупными фасадами, а huge STU-сцены остаются дорогими для ревью.

## Главные Риски

1. **Fresh clone стал воспроизводимее, но требует Git LFS.** Ассеты и `*.import` теперь tracked, root `export_presets.cfg` tracked, бинарники идут через LFS. После clone нужен `git lfs install && git lfs pull`.
2. **Полный тестовый прогон зелёный на момент последней проверки.** `bash tests/run_tests.sh` проходил с 85 тестами без `ObjectDB instances leaked at exit`.
3. **Runtime-входы света переведены на `interact`.** Старый `lamp_switch` больше не нужен лампе и старому прожектору.
4. **Главные gameplay-баги закрыты.** Sleep/wake-флаг переживает переход цикла, run закрывается после титров, потолочный враг снова учитывает лампы, деньги level 12 и runtime-spawned threats сохраняются в checkpoint, холодильник fail-closed, minigame timeout одноразовый.
5. **Интерактивы централизованы через `InteractionManager`.** Одно нажатие выбирает один объект по доступности, приоритету и расстоянию.
6. **Dependency-система интерактивов стала typed.** Key-door цикл и прежний one-shot fail-open закрыты тестами: дверь, холодильник, ноутбук и блокпост теперь завершаются только после успешного outcome. Базовый `InteractiveObject` различает `COMPLETED` и `INTERACTION_REQUESTED` и эмитит `interaction_result`, `interaction_succeeded`, `interaction_failed`, `interaction_cancelled`.
7. **Scene/trigger/spawner/config/state contracts укреплены тестами.** `SceneContext` запрещает локальные path-checks, reversible triggers обязаны быть `one_shot=false`, configured `TriggerSetProperty`/`PropertyChange` target paths должны резолвиться и указывать на реальные свойства, key-doors должны иметь источник ключа в той же сцене, `SearchKeyManager.search_spots` должен быть непустым и resolving, utility-level paths для лебёдки, corridor distortion и `TargetMonsterSpawner` condition sources должны резолвиться, cycle-level metadata/bed transitions/exported root paths должны быть валидны, lab laptops должны иметь валидные timer settings и timed-lab minigame scenes, required lab IDs должны ссылаться на реальные ноутбуки, feeding/code-lock/final холодильники должны иметь полный minigame contract, spawner-ы с `enemy_scene` обязаны явно подтверждать condition и читать state-флаги через публичные методы, runtime light-группы обязаны иметь нужные методы, включённые editor plugins должны иметь `plugin.cfg`, configured translations должны грузиться как `Translation`, death/ending/note/obstacle/lab/money player-facing exports должны иметь localization keys, а внешние runtime-скрипты должны ходить к ключевым `CycleState` полям через публичные методы.
8. **Большие singleton/god-classes стали лучше, но не исчезли.** `UIMessage` вынес fade state в `UIFadeController`, `MinigameController` вынес backdrop presentation в `MinigameBackdropPresenter`, `GameDirector` вынес death-title/glitch presentation в `GameDirectorDeathTitlePresenter`, stalker spawn/checkpoint logic в `GameDirectorStalkerService`, overlay layer policy в `GameDirectorOverlayLayerCoordinator`, death cursor/input policy в `GameDirectorDeathCursorCoordinator`, death camera capture/restore в `GameDirectorDeathCameraCoordinator`, death retry restore/darken policy в `GameDirectorDeathRetryCoordinator`, cycle timer/checkpoint state в `GameDirectorCycleTimerState`, CycleState phase bridge в `GameDirectorCyclePhaseBridge`, timer node lifecycle в `GameDirectorTimerNodeCoordinator`, minigame distortion gate в `GameDirectorDistortionGate`, distortion progress/easing math в `GameDirectorDistortionProgress`, distortion overlay/material actuator в `GameDirectorDistortionOverlayCoordinator` и distortion phase/checkpoint state в `GameDirectorDistortionPhaseState`; `MusicManager` делегирует mix-offset policy в `MusicMixSettings`, `Fridge` вынес code-lock adapter в `FridgeCodeLockSession`, feeding setup в `FridgeFeedingSession` и post-feeding world hooks в `FridgeCompletionSession`, но остальной audio facade, `GameDirector` и `Player` всё ещё требуют осторожных future refactor-ов.
9. **Уровни и объекты сильно завязаны на NodePath и имена детей.** Переименование узла может silently выключить звук, анимацию, двери, fridge-flow или scripted wiring.
10. **Крупная археология удалена.** `archive(trash)` и `level_NSTU_test.tscn` убраны, активный `level_09_сrazy.tscn` переименован в `level_09_crazy.tscn`.

## Оценки По Срезам

- Архитектура и состояние: **5.2/10** проблемности.
- Gameplay loop, уровни, враги, мини-игры: **4.8/10**.
- Интерактивы и scene contracts: **5/10**.
- Тесты, ассеты, export, CI hygiene: **4/10**.
- Repo hygiene и maintainability: **5/10**.

## Что В Проекте Хорошо

- Main scene и autoload-и явно заданы в `project.godot`.
- Есть локальный тест-раннер и 85 тестов.
- Тесты уже проверяют autoload-и, main scene, project config, localization CSV/mojibake hygiene, RU player-facing localization key coverage, cycle/lab/fridge authoring contracts, загрузку сцен и запрет использования приватного API `MusicManager`.
- `MusicManager` большой, но имеет осмысленный публичный фасад, а mix-offset policy уже живёт в `MusicMixSettings`.
- `MinigameSettings` как `Resource` лучше, чем полностью ad-hoc Dictionary-конфиги.
- `InteractiveObject` уже является полезной базовой точкой для lock/dependency/one-shot/minigame поведения.

## Команды Проверки

- Parser-only: `godot --headless --check-only -s res://tests/run_tests.gd`
- Полный локальный suite: `bash tests/run_tests.sh`

На момент последней проверки parser-only проходил, а полный suite проходил с 85 тестами. Перед релизными выводами или крупным рефакторингом нужно перепроверить текущее состояние командой выше.

## Правила Работы Для Агентов

- Перед изменениями проверь ветку: не работай напрямую в `main`; если текущая ветка `main`, создай ветку с префиксом `codex/`.
- Не трогай чужие незакоммиченные изменения без явной просьбы.
- Для чтения используй `rg`/`rg --files`.
- Для ручных правок используй `apply_patch`.
- После meaningful code changes обновляй релевантную документацию.
- Если полный suite зелёный после твоей работы, создай коммит с понятным названием.
- Если suite красный из-за уже известных проблем, явно укажи это в финальном отчёте.

## Первый Ремонтный Порядок

1. Продолжить аккуратный распил `MusicManager`, оставшегося `GameDirector` и `Player` только tested slices.
2. Продолжить DRY-разбор крупных STU-сцен на reusable scene instances.
3. Расширять localization validator на non-Russian/technical UI labels, если эта зона начнёт активно меняться.
4. Добавить отдельный export dry-run job, если понадобится проверять release artifacts автоматически.
