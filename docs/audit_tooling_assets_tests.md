# Тесты, Ассеты, Export И Воспроизводимость

Оценка проблемности среза: **8/10**.

## Проверки На Момент Аудита

- Godot: `4.6.1.stable`.
- `godot --headless --check-only -s res://tests/run_tests.gd` прошёл.
- Первичный финальный прогон `bash tests/run_tests.sh` завершался с exit code `1`.
- После ремонтных проходов parser-only и полный suite проходят; текущий полный suite содержит 114 тестов.
- Tooling-агент ранее видел exit code `2` и 2 failures; после создания документации повторно воспроизводился 1 failure. После последующих runtime-ремонтов эти падения не воспроизводятся.
- Первичный полный export/build не запускался, чтобы не писать в output paths и импорт-кэш; после ремонта добавлен CI debug export smoke.

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

Статус: закрыто на уровне репозитория. Выбран Git LFS, source assets и `.import` tracked, root `export_presets.cfg` tracked, а CI делает checkout с LFS, `git lfs pull`, runtime suite и отдельный MacOS debug export smoke.

## Resolved: Полный Тестовый Suite Красный

Изначальный аудит фиксировал красный `bash tests/run_tests.sh`:

1. `test_light_adds_directional_contract.gd`: старый проектор светит назад. Проверка около строки 38.

Этот блок закрыт: projector direction исправлен, bedroom ambient failure не воспроизводится, а `ObjectDB instances leaked at exit` ушёл после ожидания async transition states в runtime-тестах и короткого drain в `tests/run_tests.gd`.

Tooling-агент ранее также наблюдал `test_audio_menu_to_level01_bedroom_runtime.gd`: ambient playback не остановлен при bedroom suppression, проверка около строки 46. Последующие полные прогоны это не воспроизводят, поэтому пункт остался историческим наблюдением, а не текущим known failure.

Текущий expected result: `bash tests/run_tests.sh` завершается `OK: all tests passed (114)`.

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

Релизный апгрейд, который остаётся вне CI smoke: signed/notarized distributable. Debug export теперь проверяется автоматически после тестов.

Текущий static export smoke покрыт обычным suite: `tests/cases/test_export_presets_contract.gd` проверяет, что `export_presets.cfg` парсится и все `export_path` остаются repo-local. Локальный `mkdir -p /tmp/eater-loop-ci-export-smoke && godot --headless --path . --export-debug "MacOS" /tmp/eater-loop-ci-export-smoke/EaterLoop.app` на машине с templates прошёл с exit code `0`, а GitHub Actions повторяет debug export в `exports/ci/EaterLoop.app`.

## Resolved: CI-Like Слой Есть, Но Был Неполный

Есть:

- [`tests/run_tests.gd`](../tests/run_tests.gd);
- [`tests/run_tests.sh`](../tests/run_tests.sh);
- 114 тестов.

Добавлено:

- [`.github/workflows/godot-tests.yml`](../.github/workflows/godot-tests.yml), который делает checkout с LFS, `git lfs pull`, ставит Godot 4.6.1, запускает parser-only и full suite.
- Отдельный `export-smoke` job в том же workflow, который ставит export templates и запускает MacOS debug export после зелёного test job.
- Рекурсивный test discovery под `tests/cases/**`, чтобы новые проверки можно было раскладывать по подпапкам.
- Project-config contract для main scene, включённых editor plugins и configured translations.
- Input action contract для required actions, light interactable actions и runtime string literals в `is_action_*` / gamepad nav wrappers.
- Resource UID contract для tracked `.gd`/`.gdshader` sidecars и уникальности `uid://` значений.
- Localization contract для CSV-колонок `keys`/`ru`/`en`, пустых значений, mojibake в runtime text sources, запрета новых ASCII phrase translit keys для русских строк, CSV-key/technical-exception проверки статических non-Cyrillic `.tscn` player-facing строк, прямых non-Cyrillic GDScript call-literals в `UIMessage.show_*("...")` / `tr("...")` и RU player-facing key coverage, включая custom/default gamepad hints.
- Gamepad binding contract теперь сам находит scripts with `MinigameController.set_gamepad_scheme(self, ...)` и требует cleanup, чтобы новые мини-игры не выпадали из проверки.
- Gamepad callback router regression для lookup/invoke/consumed semantics пользовательских схем мини-игр.
- Gamepad confirm-release gate regression для защиты мини-игр от подтверждения, зажатого до старта runtime.
- MinigameController UI transition facade contract запрещает возвращать start/finish fade к stringly `UIMessage.has_method/call` probes.
- Minigame modal ownership contract запрещает возвращать pause/cursor ownership к stringly `PauseManager`/`CursorManager` method probes.
- Typed interaction signal subscription contract запрещает runtime/scene authoring подписываться на legacy `interaction_finished`; новые level redirects и signal-driven spawner defaults используют `interaction_succeeded`.
- InteractionManager public API contract запрещает центральному input flow возвращаться к private string calls `_get_interact_action` / `_set_interaction_focus`; manager должен использовать `InteractiveObject.get_interact_action_name()` и `set_manager_focus(...)`.
- CycleLevel UI facade contract запрещает возвращать стартовые subtitle/respawn blackout к stringly `UIMessage.has_method/call` probes.
- SceneContext classification contract для gameplay path fallback, cycle/timer root contract, `gameplay_scene` group и ending pause-blocking.
- Level authoring contract для cycle metadata, single Player instance, Player export ranges, configured bed transitions, bed target scene type, conditional respawn paths, LevelMusic configs и включённых стартовых текстов.
- Lab authoring contract для lab laptop timer settings, timed-lab minigame scene contract, explicit lab IDs и fridge required-lab references.
- TimedLabMinigameBase UI facade contract запрещает возвращать outcome dialogue к stringly `UIMessage.has_method/call` probes.
- Fridge authoring contract для feeding/code-lock/final fridge configs, typed `FeedingMinigame` scenes, typed `FinalFeedMinigame` scene, food scenes, face/background и code-lock scene.
- Generic active content scene contract для exported non-empty `NodePath`/`Array[NodePath]` values.
- Scene-owned audio player bus contract для explicit `Music`/`Sounds` на `AudioStreamPlayer`/`AudioStreamPlayer2D`.
- Utility-level NodePath contract для лебёдки, corridor distortion и `TargetMonsterSpawner` condition/spawn paths.
- Content-object stringly collaborator contract для запрета `UIMessage.has_method(...)` и method-string winch/fridge glue там, где уже есть стабильный facade/typed class.
- Trigger target/property/effect/music-stream contract для configured `TriggerSetProperty` и `PropertyChange`.
- Key-door/search-key contract для required key sources, resolving typed `SearchKeyManager.search_spots` и managed `SearchSpot` typed `SearchKeyMinigame`/key/trash configs.
- Scene typed override hygiene contract для явных door/interactable defaults вместо inherited `null`.
- Checkpoint participant stable-path contract для active scenes: custom checkpoint nodes must resolve to non-empty scene-relative paths without generated `@...` segments.
- Checkpoint scene snapshot contract для dynamic runtime participants и removed participant state.
- Checkpoint dynamic restore helper contract для enemy-only factory restore allowlist, captured parent/name metadata, restoration target parent и fail-closed reject неразрешённых scene paths.
- Interaction result builder contract для typed Dictionary payload, metadata/source/player preservation и защиты payload от alias-мутаций.
- GameDirector death screen reset helper contract для скрытия death UI, очистки fade/focus override и освобождения camera/cursor/pause owners.
- GameDirector death sequence state contract для idempotent start, pause owner tracking и reset без silent pause leak.
- GameDirector death entry presenter contract для подготовки death title sequence, retry button text и hidden root перед fade.
- GameDirector death fade coordinator contract для fade rect alpha tween, duration clamp, completion callback и camera tween delegation.
- GameDirector death retry coordinator flow contract для checkpoint prepare, blackout/darken, owner release и deferred reload order.
- Music pause reason state contract для нескольких независимых base/chase pause owners.
- Music ambient suppression state contract для bedroom/ambient-silent source tracking, stale weakref cleanup и `tree_exited` callback wiring.
- Music scoped source registry contract и MusicManager scoped source cleanup regression для event/distortion music, чтобы удалённые trigger/controller nodes не оставляли приоритетную музыку в registry/stack.
- Player stamina state contract для run drain/recovery/unlimited/checkpoint semantics.
- Player facing state contract для direction normalization и checkpoint restore без zero-scale facing.
- Player inventory state contract для key add/has/remove normalization, dedupe и checkpoint round-trip.
- Player skeleton step state contract для first-sample arming, clip wrap step crossing и reset semantics.
- Player flashlight charge state contract для drain/recharge/instant-full/checkpoint semantics.

Ограничения:

- shell helper вычисляет project root относительно себя и запускает Godot с `--path`, поэтому может запускаться не из корня.

Статус после P3 hygiene pass: CI через runtime suite проверяет export presets static contract, project config и localization hygiene/key coverage для русскоязычных player-facing строк, включая custom/default gamepad hints, запрет новых ASCII phrase translit keys, static `.tscn` non-Cyrillic text contract и прямые GDScript UI call-literals; отдельный CI job запускает MacOS debug export smoke с установленными templates. Signed/notarized release artifact можно добавить позже как release-hardening, но presets и базовая собираемость больше не остаются локальной догадкой.
