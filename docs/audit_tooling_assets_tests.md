# Тесты, Ассеты, Export И Воспроизводимость

Оценка проблемности среза: **8/10**.

## Проверки На Момент Аудита

- Godot: `4.6.1.stable`.
- `godot --headless --check-only -s res://tests/run_tests.gd` прошёл.
- Финальный прогон `bash tests/run_tests.sh` завершился с exit code `1`.
- Tooling-агент ранее видел exit code `2` и 2 failures; после создания документации повторно воспроизвёлся 1 failure. Поэтому bedroom ambient suppression ниже отмечен как ранее замеченный, но не подтверждённый финальным прогоном.
- Полный export/build не запускался, чтобы не писать в output paths и импорт-кэш.

## P1: Fresh Clone/CI Почти Наверняка Не Воспроизводит Игру

`.gitignore` исключает:

- `*.translation`;
- `export_presets.cfg`;
- `*.import`;
- почти все `*.png`, `*.jpg`, `*.wav`, `*.mp3`, `*.ogg`.

Но сцены массово ссылаются на эти ресурсы.

Примеры:

- [`.gitignore`](../.gitignore), около строк 3-11.
- [`levels/menu/main_menu.tscn`](../levels/menu/main_menu.tscn), около строки 5.
- [`levels/cycles/level_01_start.tscn`](../levels/cycles/level_01_start.tscn), около строки 3.
- [`objects/interactable/projector/projector.tscn`](../objects/interactable/projector/projector.tscn), около строки 4.

Статический аудит нашёл 387 уникальных `res://` ссылок на ассеты; 381 из них существуют локально, но не tracked. Это означает, что локальная машина богаче Git-репозитория.

Ремонт:

1. выбрать Git LFS/tracked assets или documented external asset pack;
2. зафиксировать bootstrap-инструкцию;
3. добавить проверку fresh clone/resource existence в CI.

## P1: Полный Тестовый Suite Красный

Финальный прогон `bash tests/run_tests.sh` падал с 1 failure:

1. `test_light_adds_directional_contract.gd`: старый проектор светит назад. Проверка около строки 38.

Также в конце был `ObjectDB instances leaked at exit`.

Tooling-агент ранее также наблюдал `test_audio_menu_to_level01_bedroom_runtime.gd`: ambient playback не остановлен при bedroom suppression, проверка около строки 46. Финальный прогон после документации это не воспроизвёл, поэтому пункт нужно расследовать как возможный flaky/state-order bug, а не считать текущим единственным подтверждённым падением.

Ремонт: сначала починить projector direction, затем отдельно стабилизировать/подтвердить bedroom ambient test.

## P1: `lamp_switch` Удалён Из Input Map, Но Код Его Использует

В текущем `project.godot` после `toggle_flashlight` сразу идёт `run`; `lamp_switch` отсутствует. Но старые лампа и проектор возвращают это действие.

Файлы:

- [`project.godot`](../project.godot), около строки 180.
- [`objects/interactable/lamp/lamp.gd`](../objects/interactable/lamp/lamp.gd), около строки 99.
- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd), около строки 77.
- [`tests/cases/test_input_actions.gd`](../tests/cases/test_input_actions.gd), около строки 12: тест не требует `lamp_switch`.

Практический эффект: объект может ждать action, которого нет в Input Map.

Ремонт: либо вернуть action, либо перевести объекты на существующий `interact`; тест должен собирать required actions из `_get_interact_action()`.

## P2: Export Hygiene Слабая

`export_presets.cfg` есть локально, но игнорируется. Путь export завязан на локальный `../Documents/EaterLoopExport/...`. Скрипт `export_macos_dmg.sh` читает первый `export_path` и пишет "DMG exported", хотя дефолтный путь сейчас `.app`, не `.dmg`.

Файлы:

- [`.gitignore`](../.gitignore), около строки 4.
- [`export_presets.cfg`](../export_presets.cfg), около строки 11.
- [`tools/macos_dmg_fix/export_macos_dmg.sh`](../tools/macos_dmg_fix/export_macos_dmg.sh), около строк 20 и 24.

Ремонт:

- либо трекать export presets;
- либо генерировать CI-safe preset из template;
- убрать локальные абсолютные/личные пути;
- сделать export script честным по типу артефакта.

## P2: CI-Like Слой Есть, Но Неполный

Есть:

- [`tests/run_tests.gd`](../tests/run_tests.gd);
- [`tests/run_tests.sh`](../tests/run_tests.sh);
- около 48 тестов.

Не найдено:

- `.github/workflows`;
- `Makefile`;
- `justfile`.

Ограничения:

- discovery тестов нерекурсивный только по `tests/cases`;
- shell helper требует запуск из корня, потому что не задаёт `--path`.

Ремонт:

1. добавить GitHub Actions или другой CI runner;
2. фиксировать Godot 4.6.1;
3. запускать import/parser check/full tests;
4. добавить optional export dry run;
5. сделать runner независимым от cwd.
