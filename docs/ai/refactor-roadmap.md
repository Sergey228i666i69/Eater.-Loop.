# Риски И Roadmap Рефакторинга

## Текущий Риск

Проект после repair pass не развален, но остаётся дорогим в поддержке.

Главные источники стоимости:

- крупные STU-сцены и route-heavy `.tscn`;
- NodePath/child-name wiring;
- оставшиеся крупные facade-классы `MusicManager`, `GameDirector`, `Player`;
- крупный visual rig игрока;
- player-facing text coverage, если UI будет активно расти.

## Правильный Стиль Рефакторинга

Резать только tested slices:

1. Найди одну coherent responsibility.
2. Сохрани публичный facade API.
3. Вынеси helper/state object.
4. Добавь focused test на helper и regression на facade, если риск runtime.
5. Обнови docs.
6. Запусти parser-only и полный suite.

Так уже безопасно выносились fade state, minigame backdrop/prompt/timer/gamepad
helpers, checkpoint snapshot/dynamic restore, player stamina/facing/inventory/
flashlight helpers и части death/distortion flow.

## Приоритеты

1. Продолжать распил `MusicManager`, оставшегося `GameDirector` и `Player`
   только маленькими проверяемыми slices.
2. Разбирать большие STU-сцены на reusable scene instances после добавления
   validators на новые boundaries.
3. Расширять localization validator, когда меняется зона UI с multi-line или
   сложными GDScript expressions.
4. Для release держать отдельный signed/notarized процесс; CI smoke не равен
   финальному distributable.

## Когда Не Рефакторить

- Если задача чисто контентная и решается настройкой шаблона.
- Если нет focused теста на поведение.
- Если в тех же файлах есть чужие dirty changes, которые нельзя отделить.
- Если новый helper не уменьшает реальную сложность.

## Документы, Которые Надо Синхронизировать

- `docs/ai/*` - нормативные правила для агентов.
- `docs/human/*` - инструкции для людей.
- Старые `docs/*.md`, если меняется описанная там система.
- `tests/README.md`, если меняется runner или смысл тестов.
- `structure.txt`, если меняется заметная структура проекта.
