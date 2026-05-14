# Гигиена Репозитория, Naming И Мусор

Оценка проблемности среза: **7/10**.

## Диагноз

Главная проблема не в том, что проект "не запускается прямо сейчас" на текущей машине. Главная проблема в том, что репозиторий плохо воспроизводится и быстро копит археологию: старые сцены, test-сцены в runtime-дереве, раздутая структура уровней, inconsistent naming и debug leftovers.

## P1: Локальные Ассеты Не Соответствуют Git-Состоянию

Git почти не трекает аудио/изображения, но сцены и скрипты на них ссылаются.

Примеры:

- [`.gitignore`](../.gitignore), около строки 11.
- [`player/player.tscn`](../player/player.tscn), около строки 4.
- [`levels/music_manager.gd`](../levels/music_manager.gd), около строки 34.
- [`objects/interactable/fridge/fridge.tscn`](../objects/interactable/fridge/fridge.tscn), около строки 8.

Это дублирует tooling-проблему, но для repo hygiene она особенно важна: состояние "у автора работает" не равно состоянию "репозиторий содержит проект".

## P2: В Git Лежит Явный Архив/Мусор

Отслеживаются файлы вроде:

- `levels/cycles/archive(trash)/level_04_old_trash.tscn`;
- `level_test_enemies.tscn`;
- `trashhh.tscn`;
- `level_07_doors_save.tscn`;
- `level_NSTU_test.tscn`.

Smoke-тесты сознательно исключают `archive` и `trash` в [`tests/cases/test_scenes_load.gd`](../tests/cases/test_scenes_load.gd), около строки 4. Это значит, что файлы находятся в репозитории, но их здоровье не является частью качества проекта.

Ремонт: удалить из активного дерева, вынести в branch/tag, или явно оформить как архив с отдельной политикой.

## P2: Сцены Очень Крупные

Самые крупные `.tscn`, найденные агентом:

- `level_12_STU_2.tscn`: 9233 строки;
- `level_13_STU_3.tscn`: 8727 строк;
- `level_11_STU_1.tscn`: 8595 строк;
- `level_NSTU_test.tscn`: 8578 строк.

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
- `level_09_сrazy.tscn` с визуально подозрительной кириллической `с`;
- `chiken`;
- `meet`;
- `Frizzer`;
- `FridgeNoizeE.wav`.

Практический риск: поиск, ручные пути, case-sensitive файловые системы и командная строка будут периодически наказывать проект.

Ремонт: lowercase snake_case, без lookalike-кириллицы, без `trash/test/old` в runtime paths.

## P2: Дублируется Паттерн Прожектора

Старый `projector.gd` и новый `projector2.gd` оба держат:

- питание;
- группы `reactive_light_source`;
- звук;
- `is_point_lit`;
- toggle;
- checkpoint-state.

Файлы:

- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd).
- [`objects/interactable/projector2/projector2.gd`](../objects/interactable/projector2/projector2.gd).

Ремонт: один базовый light-source/power component и разные scene skins/config resources.

## P3: Debug Leftovers

Найдены production `print()`/debug leftovers.

Примеры:

- [`levels/game_director.gd`](../levels/game_director.gd), около строки 218.
- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строки 95.
- [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строки 300.
- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 29.

Ремонт: centralized logger с уровнями, либо убрать шум из runtime.

## P3: Magic Strings/Numbers

Примеры:

- `999.0` как sentinel в [`levels/music_manager.gd`](../levels/music_manager.gd), около строки 70.
- `-80.0` как mute volume.
- длинный death text и layout tables прямо в [`levels/game_director.gd`](../levels/game_director.gd), около строки 122.

Ремонт: named constants/resources.

