# Сводка Мультиагентного Аудита

Дата: 2026-05-14.

Формат: пять read-only агентов проверили независимые срезы проекта: архитектуру и состояние, gameplay loop, интерактивы, tooling/assets/tests, repo hygiene. Исходный код аудиторы не меняли. После аудита прошли ремонтные фазы: asset tracking через Git LFS, InteractionManager, SceneContext, gameplay checkpoint fixes и стабилизация тестового раннера.

## Вердикт

Общая проблемность: **7.3/10**.

Репозиторий не выглядит "безнадёжным клубком": у него понятная Godot-структура, есть autoload-контуры, уже заведены тесты и часть систем оформлена лучше среднего прототипа. Первые P1 из аудита закрыты, но костыльность всё ещё заметна в поддержке: крупные singleton-и, NodePath/name contracts, dependency-состояния интерактивов и огромные сцены остаются главными источниками риска.

## Сводные Оценки

| Срез | Оценка проблемности | Главный диагноз |
| --- | ---: | --- |
| Архитектура и состояние | 6.5/10 | singleton-и, строковые пути, публичный mutable state |
| Gameplay loop | 7/10 | ключевые runtime-баги закрыты, но система всё ещё держится на глобальном state |
| Интерактивы | 7/10 | фокус централизован, dependency и NodePath ломкие |
| Tooling/assets/tests | 8/10 | LFS/assets починены, CI ещё не добавлен |
| Repo hygiene | 7/10 | архивы, huge scenes, naming-risk, debug leftovers |

## Самые Важные P1

1. **CI ещё нет.** Локальный suite зелёный, но GitHub Actions/другой runner пока не закрепляет `git lfs pull`, parser check и full suite.
2. **Dependency-система интерактивов может запереть прогресс.** Дверь может не вызвать complete-state, а завязанные объекты ждут именно его.
3. **God objects остаются крупными.** `GameDirector`, `UIMessage`, `MinigameController`, `MusicManager` всё ещё смешивают много областей ответственности.
4. **NodePath/name contracts ломкие.** Переименование дочернего узла может silently выключить поведение.
5. **Огромные STU-сцены требуют DRY-разбора.** Scene instances и reusable contracts пока не доведены до системного уровня.

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
