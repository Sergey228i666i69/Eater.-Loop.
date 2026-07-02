# Сводка Мультиагентного Аудита

Дата: 2026-05-14.

Формат: пять read-only агентов проверили независимые срезы проекта: архитектуру и состояние, gameplay loop, интерактивы, tooling/assets/tests, repo hygiene. Исходный код аудиторы не меняли. После аудита прошли ремонтные фазы: asset tracking через Git LFS, InteractionManager, SceneContext, gameplay checkpoint fixes и стабилизация тестового раннера.

## Вердикт

Первичная проблемность аудита: **7.3/10**. Текущая проблемность после ремонтных проходов: **около 5/10**.

Репозиторий не выглядит "безнадёжным клубком": у него понятная Godot-структура, есть autoload-контуры, уже заведены тесты и часть систем оформлена лучше среднего прототипа. Первые P1/P2 из аудита закрыты, включая input/focus/checkpoint/assets, minigame input/timeout, reversible triggers, spawner conditions, базовую completion-семантику интерактивов, typed dependency/key-source/lab-id conditions, typed interaction outcomes, pause ownership tokens, scene NodePath/group-method/trigger-target/utility-path/level/fridge-authoring validators, external state-access guards, private backing для core `CycleState` flags, Godot-aware naming cleanup и первые split pass-ы крупных singleton-ов. Костыльность всё ещё заметна в поддержке: huge STU-сцены и оставшиеся крупные фасады требуют аккуратных будущих refactor-ов.

## Сводные Оценки

| Срез | Оценка проблемности | Главный диагноз |
| --- | ---: | --- |
| Архитектура и состояние | 5.2/10 | первый split singleton-ов сделан, ключевые CycleState flags заведены за private backing vars и public API |
| Gameplay loop | 4.8/10 | ключевые runtime-баги закрыты, остаются дубли и performance-risk |
| Интерактивы | 5/10 | фокус, one-shot, key-source, lab IDs, utility paths, level authoring, trigger target/property contracts, spawner и minimal typed dependency contracts исправлены |
| Tooling/assets/tests | 4/10 | LFS/assets и CI починены, export dry-run ещё не автоматизирован |
| Repo hygiene | 5/10 | архивы/debug/naming debt убраны, huge scenes остаются |

## Самые Важные P1

1. **Огромные STU-сцены требуют аккуратного scene-authoring.** Runtime paths покрыты validators, но сами `.tscn` всё ещё тяжёлые для ревью.
2. **Оставшиеся крупные фасады требуют отдельного refactor budget.** `MusicManager`, `GameDirector` и `Player` всё ещё большие; `UIMessage`, `MinigameController` backdrop/prompt/timer/gamepad registry lifecycle, death-title/stalker/overlay-layer/death-cursor/death-camera/death-retry/cycle-timer/cycle-phase/timer-node/distortion-gate/distortion-progress/distortion-overlay/distortion-phase части `GameDirector` уже получили безопасные helper split-ы.
3. **Export dry-run не автоматизирован отдельным release job.** Тесты закреплены CI, root preset проверяется suite-ом, но release artifacts пока остаются локальной ответственностью.
4. **Localization coverage можно расширять дальше по мере роста UI.** RU player-facing key coverage уже закреплён тестом; более широкий non-Russian/technical UI coverage можно расширять отдельно.

## Что Стоит Сохранить

- Локальный тестовый слой уже есть, и он не чисто декоративный.
- `MusicManager` имеет публичный фасад и тест на запрет приватного API.
- `MinigameSettings` как `Resource` - правильное направление.
- `InteractiveObject` - хорошая база для будущего централизованного `InteractionManager`.
- В проекте уже есть документация по отдельным системам, её можно расширять, а не начинать с нуля.

## Документы По Срезам

- [Архитектура, autoload и состояние](audit_architecture_state.md)
- [Игровой цикл, уровни, враги и мини-игры](audit_gameplay_loop.md)
- [Интерактивные объекты и scene contracts](audit_interactables_and_scene_contracts.md)
- [Тесты, ассеты, export и воспроизводимость](audit_tooling_assets_tests.md)
- [Гигиена репозитория](audit_repo_hygiene.md)
- [Рефакторинг-роадмап](audit_refactor_roadmap.md)
- [Content authoring guide](content_authoring_guide.md)
