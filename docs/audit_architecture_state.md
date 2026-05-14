# Архитектура, Autoload И Состояние

Оценка проблемности среза: **6.5/10**.

## Что Сейчас Работает Нормально

- Main scene задана явно в [`project.godot`](../project.godot), около строк 18-24.
- Autoload-и перечислены централизованно: `GameState`, `CycleState`, `GameDirector`, `MinigameController`, `MusicManager`, `UIMessage` и другие.
- Есть тесты на autoload/main scene/scene load/private API usage.
- `MusicManager`, несмотря на размер, имеет публичный фасад и уже защищён тестом от прямого вызова приватных методов.
- `MinigameSettings` оформлен как `Resource`, что лучше, чем полностью свободные Dictionary-конфиги.

## P1: Определение Игровой Сцены Через Строку Пути

Несколько глобальных систем решают, является ли текущая сцена игровой, через поиск `"/levels/cycles/"` в пути.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd), около строки 429.
- [`player/ui_message.gd`](../player/ui_message.gd), около строки 525.
- [`levels/minigames/cursor_manager.gd`](../levels/minigames/cursor_manager.gd), около строки 26.

Практический риск: если playable-сцена окажется вне `levels/cycles`, intro/debug/bonus-level будет вести себя как меню. Это silent failure: код не упадёт, просто не включит нужные игровые правила.

Ремонт: ввести явный `SceneContext`, `LevelRegistry`, группу `gameplay_scene` или ресурс-метаданные уровня.

## P1: Глобальное Состояние Слишком Открыто

`GameState` и `CycleState` содержат публичные поля, к которым код обращается напрямую и через методы вперемешку.

Примеры:

- [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строки 8: `last_scene_path`, `has_active_run`, `flashlight_unlocked`.
- [`levels/cycles/cycle_state.gd`](../levels/cycles/cycle_state.gd), около строки 16: `phase`, `ate_this_cycle`, `lab_done`.
- [`levels/menu/main_menu.gd`](../levels/menu/main_menu.gd), около строки 121: fallback к прямым полям.

Практический риск: состояние можно изменить в обход валидации, сигналов и инвариантов. При росте проекта это превращается в трудно воспроизводимые регрессии.

Ремонт: закрывать поля за методами, сигналами и typed contract-ами; reflective `get()` использовать только для debug/compat слоёв.

## P2: `GameDirector` Перегружен

`GameDirector` смешивает:

- таймер цикла;
- distortion;
- stalker spawn;
- death/retry UI;
- checkpoint integration;
- cursor/overlay coordination;
- mini-game hooks;
- music scene sync.

Агенты ссылались на `_process`, death/retry flow и overlay-layer magic numbers в [`levels/game_director.gd`](../levels/game_director.gd), около строк 144, 537, 983.

Риск не в том, что класс прямо сейчас сломан, а в цене изменений: любая новая механика уровня может задеть смерть, чекпоинт, музыку или курсор.

Ремонт: вынести death/checkpoint, distortion/stalker и overlay/cursor coordination в отдельные сервисы.

## P2: `UIMessage` Стал Service Locator

`UIMessage` отвечает не только за UI-сообщения:

- субтитры;
- записки;
- prompts;
- fade transitions;
- смену сцен;
- SFX;
- регистрацию модулей;
- сохранение текущей игровой сцены через path-check.

Примеры: [`player/ui_message.gd`](../player/ui_message.gd), около строк 65, 415, 460.

Ремонт: разделить message/prompt layer, transition service и scene navigation.

## P2: Checkpoint System Хороша По Идее, Но Ломка По Контракту

Snapshot собирает `checkpoint_stateful` участников и сохраняет relative path. При apply, если ноды нет в свежей сцене, она пропускается.

Примеры:

- [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строки 314: сбор snapshot.
- [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строки 341: apply по relative path.

Для простых статичных объектов это нормально. Для динамических врагов, runtime-spawn и переименованных узлов это ломко.

Ремонт: добавить стабильный checkpoint id, factory/restore contract для динамических сущностей и тест на missing participant.

## P2: Локализация Неполная

Найдены:

- mojibake в [`global/localization/texts.csv`](../global/localization/texts.csv), около строки 3;
- транслит-ключи в том же CSV, около строки 32;
- hardcoded русские строки вне CSV, например в [`objects/interactable/projector2/projector2.gd`](../objects/interactable/projector2/projector2.gd), около строки 164;
- hardcoded prompt в [`objects/interactable/flashlight/pickup_flashlight.tscn`](../objects/interactable/flashlight/pickup_flashlight.tscn), около строки 33.

Риск: английская локаль получит русские fallback-и или битый текст.

Ремонт: добавить localization completeness test и запретить новые player-facing строки без ключа.

## Мелкие Smells

- `CursorManager` вычисляет `_in_game`, но `_update_mouse_mode` его фактически не использует.
- `ending_credits.gd` имеет export `return_scene`, но resolver всегда возвращает main menu.
- `Bed._try_sleep` делает ручной fade и затем вызывает scene-change с fade delay.
- Первичный аудит находил `level_09_сrazy.tscn` с кириллической `с`; файл переименован в `level_09_crazy.tscn`.
