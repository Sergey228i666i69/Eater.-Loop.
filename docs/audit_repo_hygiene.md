# Гигиена Репозитория, Naming И Мусор

Оценка проблемности среза на момент первичного аудита: **7/10**.

Текущий статус: крупная часть hygiene-проблем уже закрыта. `archive(trash)` и `level_NSTU_test.tscn` удалены из runtime-дерева, активный уровень с кириллической `с` переименован в `level_09_crazy.tscn`, ассеты заведены через Git LFS, root `export_presets.cfg` отслеживается, runtime `print()` запрещён архитектурным тестом.

## Диагноз

Главная проблема не в том, что проект "не запускается прямо сейчас" на текущей машине. Главная проблема в том, что репозиторий плохо воспроизводится и быстро копит археологию: старые сцены, test-сцены в runtime-дереве, раздутая структура уровней, inconsistent naming и debug leftovers.

## Resolved: Локальные Ассеты Не Соответствуют Git-Состоянию

Git почти не трекает аудио/изображения, но сцены и скрипты на них ссылаются.

Примеры:

- [`.gitignore`](../.gitignore), около строки 11.
- [`player/player.tscn`](../player/player.tscn), около строки 4.
- [`levels/music_manager.gd`](../levels/music_manager.gd), около строки 34.
- [`objects/interactable/fridge/fridge.tscn`](../objects/interactable/fridge/fridge.tscn), около строки 8.

Это было исправлено через Git LFS. После clone нужен `git lfs install && git lfs pull`.

## Resolved: В Git Лежит Явный Архив/Мусор

Отслеживаются файлы вроде:

- `levels/cycles/archive(trash)/level_04_old_trash.tscn`;
- `level_test_enemies.tscn`;
- `trashhh.tscn`;
- `level_07_doors_save.tscn`;
- `level_NSTU_test.tscn`.

Перед удалением был найден активный переход из `level_04_findkey` в архивный `level_05_keystests`; он перевязан на актуальный `level_05_sql`, после чего архивные сцены удалены.

## P2: Сцены Очень Крупные

Самые крупные `.tscn`, найденные агентом:

- `level_12_STU_2.tscn`: 9233 строки;
- `level_13_STU_3.tscn`: 8727 строк;
- `level_11_STU_1.tscn`: 8595 строк;
- `level_NSTU_test.tscn`: 8578 строк, удалён после замены тестовой ссылки на активные STU-сцены.

Практический риск: правки уровней становятся дорогими, diff тяжело ревьюить, reuse почти невозможен.

Ремонт: вынос повторяемых комнат/коридоров/интерактивных кластеров в инстансы сцен и resources.

## P2: Большие God Classes

Найдены крупные классы:

- `GameDirector`: около 1131 строк;
- `MusicManager`: около 1105 строк;
- `MinigameController`: около 735 строк;
- `UIMessage`: около 573 строк.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd).
- [`levels/music_manager.gd`](../levels/music_manager.gd).
- [`levels/minigames/minigame_controller.gd`](../levels/minigames/minigame_controller.gd).
- [`player/ui_message.gd`](../player/ui_message.gd).

Не каждый большой файл плох сам по себе, но здесь размеры совпадают со смешением обязанностей.

## P2: Naming Inconsistent И Местами Опасный

Примеры:

- `level_13_STU_3.tscn` рядом с `level_13_stu_3.gd`;
- `level_NSTU_test.tscn`;
- `level_09_crazy.tscn` теперь использует латинскую `c`;
- `chiken`;
- `meet`;
- `Frizzer`;
- `FridgeNoizeE.wav`.

Практический риск: поиск, ручные пути, case-sensitive файловые системы и командная строка будут периодически наказывать проект.

Ремонт: lowercase snake_case, без lookalike-кириллицы, без `trash/test/old` в runtime paths.

## Resolved: Дублировался Паттерн Прожектора

Ранее старый `projector.gd` и новый `projector2.gd` оба держали:

- питание;
- группы `reactive_light_source`;
- звук;
- `is_point_lit`;
- toggle;
- checkpoint-state.

Статус: `Projector2` удалён как неиспользуемая параллельная реализация. Canonical implementation остаётся:

- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd).

Направление, reactive-light group и input contract покрыты тестами старого projector implementation.

## Resolved: Debug Leftovers

Найдены production `print()`/debug leftovers.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd), около строки 218.
- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строки 95.
- [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строки 300.
- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 29.

Статус: runtime `print()` заменён на `print_verbose()`, а `test_interaction_architecture_contracts.gd` запрещает новые raw `print()` в `levels`, `objects`, `player`, `enemies` и `global`.

## P3: Magic Strings/Numbers

Примеры:

- `999.0` как sentinel в [`levels/music_manager.gd`](../levels/music_manager.gd), около строки 70.
- `-80.0` как mute volume.
- длинный death text и layout tables прямо в [`levels/game_director.gd`](../levels/game_director.gd), около строки 122.

Ремонт: named constants/resources.
