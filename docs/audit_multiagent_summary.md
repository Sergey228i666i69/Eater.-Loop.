# Сводка Мультиагентного Аудита

Дата: 2026-05-14.

Формат: пять read-only агентов проверили независимые срезы проекта: архитектуру и состояние, gameplay loop, интерактивы, tooling/assets/tests, repo hygiene. Исходный код аудиторы не меняли. После аудита прошли ремонтные фазы: asset tracking через Git LFS, InteractionManager, SceneContext, gameplay checkpoint fixes и стабилизация тестового раннера.

## Вердикт

Общая проблемность: **7.3/10**.

Репозиторий не выглядит "безнадёжным клубком": у него понятная Godot-структура, есть autoload-контуры, уже заведены тесты и часть систем оформлена лучше среднего прототипа. Первые P1 из аудита закрыты, включая input/focus/checkpoint/assets и базовую completion-семантику интерактивов. Костыльность всё ещё заметна в поддержке: крупные singleton-и, NodePath/name contracts, отсутствие typed dependency conditions и огромные сцены остаются главными источниками риска.

## Сводные Оценки

| Срез | Оценка проблемности | Главный диагноз |
| --- | ---: | --- |
| Архитектура и состояние | 6.5/10 | singleton-и, строковые пути, публичный mutable state |
| Gameplay loop | 7/10 | ключевые runtime-баги закрыты, но система всё ещё держится на глобальном state |
| Интерактивы | 6/10 | фокус и one-shot success contract исправлены, typed dependency conditions ещё нужны |
| Tooling/assets/tests | 8/10 | LFS/assets и CI починены, export dry-run ещё не автоматизирован |
| Repo hygiene | 7/10 | архивы, huge scenes, naming-risk, debug leftovers |

## Самые Важные P1

1. **Dependency-система интерактивов всё ещё слишком общая.** Key-door цикл и one-shot fail-open закрыты, но завязанные объекты по-прежнему ждут прямой `is_completed`, а не typed condition/outcome.
2. **God objects остаются крупными.** `GameDirector`, `UIMessage`, `MinigameController`, `MusicManager` всё ещё смешивают много областей ответственности.
3. **NodePath/name contracts ломкие.** Переименование дочернего узла может silently выключить поведение.
4. **Огромные STU-сцены требуют DRY-разбора.** Scene instances и reusable contracts пока не доведены до системного уровня.
5. **Export dry-run не автоматизирован.** Тесты закреплены CI, но release artifacts пока остаются локальной ответственностью.

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
