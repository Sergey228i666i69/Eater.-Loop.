# Тесты, Ассеты, Export И Воспроизводимость

Оценка проблемности среза: **8/10**.

## Проверки На Момент Аудита

- Godot: `4.6.1.stable`.
- `godot --headless --check-only -s res://tests/run_tests.gd` прошёл.
- Финальный прогон `bash tests/run_tests.sh` завершился с exit code `1`.
- Tooling-агент ранее видел exit code `2` и 2 failures; после создания документации повторно воспроизвёлся 1 failure. Поэтому bedroom ambient suppression ниже отмечен как ранее замеченный, но не подтверждённый финальным прогоном.
- Полный export/build не запускался, чтобы не писать в output paths и импорт-кэш.

## Resolved: Fresh Clone/CI Почти Наверняка Не Воспроизводит Игру

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

Статус: закрыто на уровне репозитория. Выбран Git LFS, source assets и `.import` tracked, root `export_presets.cfg` tracked, а CI делает checkout с LFS и `git lfs pull`.

## Resolved: Полный Тестовый Suite Красный

Изначальный аудит фиксировал красный `bash tests/run_tests.sh`:

1. `test_light_adds_directional_contract.gd`: старый проектор светит назад. Проверка около строки 38.

Этот блок закрыт: projector direction исправлен, bedroom ambient failure не воспроизводится, а `ObjectDB instances leaked at exit` ушёл после ожидания async transition states в runtime-тестах и короткого drain в `tests/run_tests.gd`.

Tooling-агент ранее также наблюдал `test_audio_menu_to_level01_bedroom_runtime.gd`: ambient playback не остановлен при bedroom suppression, проверка около строки 46. Финальный прогон после документации это не воспроизвёл, поэтому пункт нужно расследовать как возможный flaky/state-order bug, а не считать текущим единственным подтверждённым падением.

Текущий expected result: `bash tests/run_tests.sh` завершается `OK: all tests passed (51)`.

## Resolved: `lamp_switch` Удалён Из Input Map, Но Код Его Использует

В текущем `project.godot` после `toggle_flashlight` сразу идёт `run`; `lamp_switch` отсутствует. Ранее старые лампа и проектор возвращали это действие.

Файлы:

- [`project.godot`](../project.godot), около строки 180.
- [`objects/interactable/lamp/lamp.gd`](../objects/interactable/lamp/lamp.gd), около строки 99.
- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd), около строки 77.
- [`tests/cases/test_input_actions.gd`](../tests/cases/test_input_actions.gd), около строки 12: тест не требует `lamp_switch`.

Статус: лампа и старый проектор переведены на существующий `interact`; input contract закреплён тестом.

## Resolved: Export Hygiene Слабая

Изначально `export_presets.cfg` был локальным/игнорируемым, а export path указывал наружу из репозитория. Сейчас root `export_presets.cfg` tracked, export paths ведут в `exports/`, а shell helper больше не называет `.app`-экспорт DMG.

Файлы:

- [`.gitignore`](../.gitignore), около строки 4.
- [`export_presets.cfg`](../export_presets.cfg), около строки 11.
- [`tools/macos_dmg_fix/export_macos_dmg.sh`](../tools/macos_dmg_fix/export_macos_dmg.sh), около строк 20 и 24.

Оставшийся ремонт: добавить export dry-run, если понадобится проверять release artifacts автоматически.

## Resolved: CI-Like Слой Есть, Но Был Неполный

Есть:

- [`tests/run_tests.gd`](../tests/run_tests.gd);
- [`tests/run_tests.sh`](../tests/run_tests.sh);
- 51 тест.

Добавлено:

- [`.github/workflows/godot-tests.yml`](../.github/workflows/godot-tests.yml), который делает checkout с LFS, `git lfs pull`, ставит Godot 4.6.1, запускает parser-only и full suite.

Ограничения:

- discovery тестов нерекурсивный только по `tests/cases`;
- shell helper требует запуск из корня, потому что не задаёт `--path`.

Оставшийся ремонт:

1. добавить optional export dry run;
2. сделать runner независимым от cwd, если тесты нужно запускать не из корня проекта.
