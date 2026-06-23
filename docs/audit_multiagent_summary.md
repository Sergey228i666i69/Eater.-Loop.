# Сводка Мультиагентного Аудита

Дата: 2026-05-14.

Формат: пять read-only агентов проверили независимые срезы проекта: архитектуру и состояние, gameplay loop, интерактивы, tooling/assets/tests, repo hygiene. Исходный код аудиторы не меняли. После аудита прошли ремонтные фазы: asset tracking через Git LFS, InteractionManager, SceneContext, gameplay checkpoint fixes и стабилизация тестового раннера.

## Вердикт

Первичная проблемность аудита: **7.3/10**. Текущая проблемность после ремонтных проходов: **5.6/10**.

Репозиторий не выглядит "безнадёжным клубком": у него понятная Godot-структура, есть autoload-контуры, уже заведены тесты и часть систем оформлена лучше среднего прототипа. Первые P1/P2 из аудита закрыты, включая input/focus/checkpoint/assets, minigame input/timeout, reversible triggers, spawner conditions, базовую completion-семантику интерактивов, typed dependency conditions и typed interaction outcomes. Костыльность всё ещё заметна в поддержке: крупные singleton-и, NodePath/name contracts и огромные сцены остаются главными источниками риска.

## Сводные Оценки

| Срез | Оценка проблемности | Главный диагноз |
| --- | ---: | --- |
| Архитектура и состояние | 5.8/10 | singleton-и и CycleState public fields ещё открыты |
| Gameplay loop | 4.8/10 | ключевые runtime-баги закрыты, остаются дубли и performance-risk |
| Интерактивы | 5/10 | фокус, one-shot, trigger, spawner и minimal typed dependency contracts исправлены |
| Tooling/assets/tests | 4/10 | LFS/assets и CI починены, export dry-run ещё не автоматизирован |
| Repo hygiene | 5.8/10 | архивы/debug убраны, huge scenes и naming debt остаются |

## Самые Важные P1

1. **Scene contracts всё ещё слишком хрупкие.** Key-door цикл, one-shot fail-open, reversible trigger risk, typed dependency conditions и typed result/outcome model закрыты, но NodePath/group/child-name контракты пока держатся на точечных тестах.
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
