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

## Короткая Оценка

Текущая проблемность после ремонтных проходов: **5.6/10**. Первичный аудит 2026-05-14 оценивал проект на **7.3/10**.

Это не разваленный проект: entrypoint понятен, autoload-и явно заведены, есть локальный тестовый слой и часть архитектурных контрактов уже проверяется. После ремонтных проходов закрыты главные runtime-дыры: input света, фокус интерактивов, run-finish, checkpoint-сценарии, asset tracking, minigame input/timeout, one-shot completion, reversible triggers, явные spawner conditions и минимальные typed dependency conditions. Но проект всё ещё костыльный в поддержке: уровни завязаны на NodePath/имена детей, крупные singleton-ы смешивают области ответственности, outcome-система интерактивов остаётся неполной, а huge STU-сцены остаются дорогими для ревью.

## Главные Риски

1. **Fresh clone стал воспроизводимее, но требует Git LFS.** Ассеты и `*.import` теперь tracked, root `export_presets.cfg` tracked, бинарники идут через LFS. После clone нужен `git lfs install && git lfs pull`.
2. **Полный тестовый прогон зелёный на момент последней проверки.** `bash tests/run_tests.sh` проходил с 53 тестами без `ObjectDB instances leaked at exit`.
3. **Runtime-входы света переведены на `interact`.** Старый `lamp_switch` больше не нужен лампе и старому прожектору.
4. **Главные gameplay-баги закрыты.** Sleep/wake-флаг переживает переход цикла, run закрывается после титров, потолочный враг снова учитывает лампы, деньги level 12 и runtime-spawned threats сохраняются в checkpoint, холодильник fail-closed, minigame timeout одноразовый.
5. **Интерактивы централизованы через `InteractionManager`.** Одно нажатие выбирает один объект по доступности, приоритету и расстоянию.
6. **Dependency-система интерактивов стала typed, но всё ещё минимальная.** Key-door цикл и прежний one-shot fail-open закрыты тестами: дверь, холодильник, ноутбук и блокпост теперь завершаются только после успешного outcome. Базовый `InteractiveObject` различает `COMPLETED` и `INTERACTION_REQUESTED`, но полноценного `interaction_succeeded` / outcome-result слоя ещё нет.
7. **Scene/trigger/spawner contracts укреплены тестами.** `SceneContext` запрещает локальные path-checks, reversible triggers обязаны быть `one_shot=false`, spawner-ы с `enemy_scene` обязаны явно подтверждать condition.
8. **Большие singleton/god-classes.** `GameDirector`, `MusicManager`, `MinigameController`, `UIMessage` уже смешивают несколько разных областей ответственности.
9. **Уровни и объекты сильно завязаны на NodePath и имена детей.** Переименование узла может silently выключить звук, анимацию, двери, fridge-flow или scripted wiring.
10. **Крупная археология удалена.** `archive(trash)` и `level_NSTU_test.tscn` убраны, активный `level_09_сrazy.tscn` переименован в `level_09_crazy.tscn`.

## Оценки По Срезам

- Архитектура и состояние: **5.8/10** проблемности.
- Gameplay loop, уровни, враги, мини-игры: **4.8/10**.
- Интерактивы и scene contracts: **5/10**.
- Тесты, ассеты, export, CI hygiene: **4/10**.
- Repo hygiene и maintainability: **5.8/10**.

## Что В Проекте Хорошо

- Main scene и autoload-и явно заданы в `project.godot`.
- Есть локальный тест-раннер и 53 теста.
- Тесты уже проверяют autoload-и, main scene, загрузку сцен и запрет использования приватного API `MusicManager`.
- `MusicManager` большой, но имеет осмысленный публичный фасад.
- `MinigameSettings` как `Resource` лучше, чем полностью ad-hoc Dictionary-конфиги.
- `InteractiveObject` уже является полезной базовой точкой для lock/dependency/one-shot/minigame поведения.

## Команды Проверки

- Parser-only: `godot --headless --check-only -s res://tests/run_tests.gd`
- Полный локальный suite: `bash tests/run_tests.sh`

На момент последней проверки parser-only проходил, а полный suite проходил с 53 тестами. Перед релизными выводами или крупным рефакторингом нужно перепроверить текущее состояние командой выше.

## Правила Работы Для Агентов

- Перед изменениями проверь ветку: не работай напрямую в `main`; если текущая ветка `main`, создай ветку с префиксом `codex/`.
- Не трогай чужие незакоммиченные изменения без явной просьбы.
- Для чтения используй `rg`/`rg --files`.
- Для ручных правок используй `apply_patch`.
- После meaningful code changes обновляй релевантную документацию.
- Если полный suite зелёный после твоей работы, создай коммит с понятным названием.
- Если suite красный из-за уже известных проблем, явно укажи это в финальном отчёте.

## Первый Ремонтный Порядок

1. Разделить `GameDirector` и `UIMessage` на меньшие сервисы.
2. Довести минимальные dependency conditions до полноценного outcome/result слоя, если появятся новые типы зависимостей.
3. Продолжить validators для обязательных NodePath/group/method contracts.
4. Продолжить DRY-разбор крупных STU-сцен на reusable scene instances.
5. Добавить export dry-run, если понадобится проверять release artifacts автоматически.
