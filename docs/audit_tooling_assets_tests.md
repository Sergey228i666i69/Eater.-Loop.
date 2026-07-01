# Тесты, Ассеты, Export И Воспроизводимость

Оценка проблемности среза: **8/10**.

## Проверки На Момент Аудита

- Godot: `4.6.1.stable`.
- `godot --headless --check-only -s res://tests/run_tests.gd` прошёл.
- Первичный финальный прогон `bash tests/run_tests.sh` завершался с exit code `1`.
- После ремонтных проходов parser-only и полный suite проходят; текущий полный suite содержит 73 теста.
- Tooling-агент ранее видел exit code `2` и 2 failures; после создания документации повторно воспроизводился 1 failure. После последующих runtime-ремонтов эти падения не воспроизводятся.
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

Tooling-агент ранее также наблюдал `test_audio_menu_to_level01_bedroom_runtime.gd`: ambient playback не остановлен при bedroom suppression, проверка около строки 46. Последующие полные прогоны это не воспроизводят, поэтому пункт остался историческим наблюдением, а не текущим known failure.

Текущий expected result: `bash tests/run_tests.sh` завершается `OK: all tests passed (73)`.

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

Оставшийся релизный апгрейд: добавить отдельный full export job, если нужно автоматически проверять сами release artifacts в CI.

Текущий static export smoke покрыт обычным suite: `tests/cases/test_export_presets_contract.gd` проверяет, что `export_presets.cfg` парсится и все `export_path` остаются repo-local. Локальный `godot --headless --path . --export-debug "MacOS" /tmp/eater-loop-export-smoke/EaterLoop.app` на машине с templates прошёл с exit code `0`.

## Resolved: CI-Like Слой Есть, Но Был Неполный

Есть:

- [`tests/run_tests.gd`](../tests/run_tests.gd);
- [`tests/run_tests.sh`](../tests/run_tests.sh);
- 73 теста.

Добавлено:

- [`.github/workflows/godot-tests.yml`](../.github/workflows/godot-tests.yml), который делает checkout с LFS, `git lfs pull`, ставит Godot 4.6.1, запускает parser-only и full suite.
- Рекурсивный test discovery под `tests/cases/**`, чтобы новые проверки можно было раскладывать по подпапкам.
- Project-config contract для main scene, включённых editor plugins и configured translations.
- Localization contract для CSV-колонок `keys`/`ru`/`en`, пустых значений и mojibake в runtime text sources.

Ограничения:

- shell helper вычисляет project root относительно себя и запускает Godot с `--path`, поэтому может запускаться не из корня.

Статус после P3 hygiene pass: CI через runtime suite проверяет export presets static contract, project config и базовую localization hygiene; локальный macOS export smoke прошёл с установленными templates. Отдельный full export job можно добавить позже как release-hardening, но presets больше не остаются непроверенными.
