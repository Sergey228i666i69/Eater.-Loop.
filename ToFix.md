# ToFix

Аудит от 2026-06-23 по Godot-проекту `едок.-петля`.

Цель файла - рабочий список для последующего ремонта репозитория. В него попали не только явные баги, но и места, которые повышают стоимость поддержки: fragile scene contracts, legacy-остатки, мусорные файлы, stale docs и крупные god-class scripts.

## Короткий Вердикт

Проект не выглядит разваленным. У него понятный entrypoint, явные autoload-и, рабочий локальный тестовый слой, Git LFS для ассетов, CI-проверки, `InteractionManager`, `SceneContext`, checkpoint-восстановление и набор контрактных тестов. После текущего remediation pass parser-only и полный suite проходили, полный suite содержит 93 теста.

Основная проблема уже не в "игра не запускается", а в дальнейшей поддерживаемости:

- pause ownership, typed interaction outcomes, fade controller, minigame backdrop/prompt/timer/modal/music/gamepad-hint/gamepad-repeat lifecycle helpers и death-title presentation уже вынесены из самых хрупких мест;
- STU/scene/utility/level/lab/fridge-authoring contracts теперь покрыты валидаторами, но крупные сцены всё ещё дороги для ручного ревью;
- naming debt из этого списка закрыт Godot-aware rename-ами с обновлением `.import` и scene/script references;
- `MusicManager`, `GameDirector`, `Player` и STU-сцены всё ещё крупные, но оставшиеся распилы теперь являются отдельными future refactor задачами, а не открытыми runtime-долгами этого файла.

Оценка проблемности после закрытия этого списка: примерно 5/10. Это поддерживаемый проект с рабочими тестами; исходные P1-регрессии и найденные здесь P2/P3-долги закрыты, а оставшаяся цена поддержки в основном связана с будущими крупными scene-authoring и architecture refactor-ами.

## P0

Подтверждённых P0-блокеров не найдено.

## P1

Открытых P1 после remediation pass не осталось.

Закрыто:

- Лампа больше не показывает legacy `Q`: prompt переведён на текущий `interact`, добавлена проверка в `test_lamp_generator_requirement.gd`.
- STU `Door(To204)` больше не даёт player-facing fade-to-self: hall-двери явно locked, `Door` fail-closed на self-target, добавлены runtime и scene-contract тесты.
- Финальная развилка `level_11_end` больше не выбирается на raw attempt: laptop/fridge ветки выбираются на success-сигналы, добавлен `test_level11_end_flow_contracts.gd`.
- `level_11_end` получил checkpoint state для `_branch`, `_ending_started`, `_bad_ending_queued`, а `GameState` умеет сохранять scene root participant `"."`.
- `UIMessage.show_hint()` больше не перезаписывает исходную pause-state при повторном pausing hint, добавлен regression test.
- Fade в `UIMessage` унифицирован через один token/tween path; cancelled fade больше не может позже перезаписать экран.
- Chase music pause получил reason-map для menu/global/minigame, и закрытие pause menu больше не снимает minigame pause.
- LLM glitch minigame теперь явно оформлена как intentionally fail-forward, а не случайно невыигрываемая.
- Фонарик больше не переключается во время black-screen/fade transitions и blocked movement.
- Event/distortion music больше не push-ит дубликаты в stack при повторном старте того же source.
- `InteractiveObject` явно unregister-ится из `InteractionManager` при `_exit_tree`.
- `SearchSpot` завершает interaction после успешного нахождения ключа.
- Ending-сцены классифицируются через `SceneContext`, и pause menu не открывается поверх концовок.
- `tests/run_tests.sh` стал независим от cwd через `--path`.
- Stale current-state docs обновлены под `level_14_end.*` и текущий suite.
- Obstacle special-case покрыт контрактным тестом.
- Export presets проверяются static contract-тестом в suite; локальный macOS export smoke прошёл с templates.
- Удалены `.gitignore.save`, ignored `global/export_presets.cfg`, legacy icon copies и неиспользуемый `Projector2`.
- Убран dead `CursorManager._in_game` state и пустая `laptop_money.gd` specialization-wrapper.
- Legacy-комментарии из runtime-кода очищены в `InteractiveObject`, `fridge.gd` и `laptop.gd`.
- Input-device detection централизован в `global/input_device_utils.gd` и переиспользуется `GameDirector`, `InteractionPrompts` и `MainMenu`.
- `InteractiveObject` получил typed `interaction_result`, `interaction_succeeded`, `interaction_failed`, `interaction_cancelled`; final branch и completed dependencies переведены на success outcome.
- `PauseManager` получил owner-token API; pause menu, UI notes/hints, minigames и death screen больше не восстанавливают `get_tree().paused` через локальный previous-bool.
- Scene NodePath contracts покрыты `test_scene_nodepath_contracts.gd`: критичные interactable paths, utility-level paths для лебёдки/corridor distortion/`TargetMonsterSpawner`, cycle-level metadata/bed transitions/root exported paths покрыты `test_level_authoring_contracts.gd`, lab laptop IDs/timer settings и fridge required lab IDs покрыты `test_lab_authoring_contracts.gd`, feeding/code-lock/final fridge configs покрыты `test_fridge_authoring_contracts.gd`, STU hardcoded paths и dynamic door targets покрыты `test_stu_level_path_contracts.gd`, configured `TriggerSetProperty` target/property wiring покрыт `test_trigger_set_property_contracts.gd`, а key-door/search-key wiring покрыт `test_scene_dependency_contracts.gd`.
- Убраны две key-door ловушки: `level_09_crazy` больше не требует несуществующий `lebedka_key` и не держит пустой `SearchKeyManager`, а `level_12_STU_2` больше не запирает игрока в 604 через `key_6level` без источника ключа.
- Пустые target marker STU-двери, которые должны быть недоступны, явно locked; `level_13_stu_3.gd` сделал отсутствующий primary fridge path явным optional default.
- `level_13_STU_3` cafeteria fridge больше не остаётся частично настроенным: после lab-gate у него есть feeding minigame scene, face/background/music/sfx и food config.
- Naming debt закрыт Godot-aware rename-ами: `chiken` -> `chicken`, `meet` -> `meat`, `Без названия *.png` -> descriptive background names, `toilet and bathroom` -> `toilet_bathroom`, `DoorNSTU_highevel.png` -> `DoorNSTU_highlevel.png`, `FridgeNoizeE.wav` -> `FridgeNoiseE.wav`.
- Первый god-class split закрыт: `UIMessage` вынес fade/tween state в `ui_fade_controller.gd`, `MinigameController` вынес backdrop registry/presentation в `minigame_backdrop_presenter.gd`, prompt suspend/restore lifecycle в `minigame_prompt_visibility_coordinator.gd`, timer state в `minigame_timer_state.gd`, gamepad scheme registry в `gamepad_scheme_registry.gd`, gamepad hint policy в `gamepad_hint_builder.gd`, gamepad navigation repeat state в `gamepad_navigation_repeat.gd`, pause/cursor ownership в `minigame_modal_ownership.gd` и music stack lifecycle в `minigame_music_session.gd`, `GameDirector` вынес death-title/glitch presentation в `game_director_death_title_presenter.gd`, stalker spawn/checkpoint service в `game_director_stalker_service.gd`, overlay layer policy в `game_director_overlay_layer_coordinator.gd`, death cursor/input policy в `game_director_death_cursor_coordinator.gd`, death camera capture/restore в `game_director_death_camera_coordinator.gd`, death retry restore/darken policy в `game_director_death_retry_coordinator.gd`, cycle timer/checkpoint state в `game_director_cycle_timer_state.gd`, CycleState phase bridge в `game_director_cycle_phase_bridge.gd`, timer node lifecycle в `game_director_timer_node_coordinator.gd`, minigame distortion gate в `game_director_distortion_gate.gd`, distortion progress/easing math в `game_director_distortion_progress.gd`, distortion overlay/material actuator в `game_director_distortion_overlay_coordinator.gd` и distortion phase/checkpoint state в `game_director_distortion_phase_state.gd`.

## P2 - Системные Долги И Хрупкие Контракты

### 8. Нужен typed outcome/result слой для интерактивов

Статус: закрыто.

- `objects/interactable/interactive_object.gd` теперь эмитит `interaction_result(result)`, `interaction_succeeded(result)`, `interaction_failed(result)` и `interaction_cancelled(result)`.
- `complete_interaction()` остаётся совместимым success wrapper и по-прежнему эмитит legacy `interaction_finished`.
- Failed/cancelled outcomes не выставляют `is_completed` и не удовлетворяют `COMPLETED` dependencies.
- `DependencyCondition.COMPLETED` слушает typed success outcome, а `INTERACTION_REQUESTED` остаётся attempt-level unlock.
- `level_11_end.gd` выбирает laptop branch по `interaction_succeeded`, с fallback только для старых объектов без typed signal.
- Контракт покрыт `tests/cases/test_interactive_dependency_conditions.gd` и `tests/cases/test_level11_end_flow_contracts.gd`.

### 9. Владение `get_tree().paused` размазано по singleton-ам

Статус: закрыто.

- `levels/menu/pause_manager.gd` теперь владеет pause tokens через `request_pause(...)`, `release_pause(...)`, `release_all_pauses_for(...)` и `clear_all_pause_requests()`.
- Pause menu, `UIMessage` notes/hints, `MinigameController` и death screen в `GameDirector` запрашивают/освобождают свои owner tokens.
- `UIMessage.change_scene_with_fade(..., unpause_after=true)` очищает все pause requests для выхода в меню/ending transitions.
- Regression покрыт `tests/cases/test_pause_manager_tokens.gd`: два владельца, hint поверх другого owner-а, minigame finish при активном внешнем owner-е.

### 10. `GameDirector`, `UIMessage`, `MinigameController`, `MusicManager`, `Player` остаются слишком крупными

Статус: закрыто первым безопасным split pass.

- `player/ui_message.gd` больше не владеет fade tween/token state напрямую: это вынесено в `player/ui_fade_controller.gd`, а публичный `UIMessage` facade сохранён.
- `levels/minigames/minigame_controller.gd` больше не держит backdrop registry/fullscreen-backdrop detection: это вынесено в `levels/minigames/minigame_backdrop_presenter.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит prompt suspend/restore target lifecycle напрямую: это вынесено в `levels/minigames/minigame_prompt_visibility_coordinator.gd` и покрыто `tests/cases/test_minigame_prompt_visibility_coordinator.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит timer state напрямую: это вынесено в `levels/minigames/minigame_timer_state.gd` и покрыто `tests/cases/test_minigame_timer_state.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит registry зарегистрированных gamepad-схем напрямую: это вынесено в `levels/minigames/gamepad/gamepad_scheme_registry.gd` и покрыто `tests/cases/test_gamepad_scheme_registry.gd`.
- `levels/minigames/gamepad/gamepad_runtime.gd` больше не держит player-facing gamepad hint policy напрямую: это вынесено в `levels/minigames/gamepad/gamepad_hint_builder.gd` и покрыто `tests/cases/test_gamepad_hint_builder.gd`.
- `levels/minigames/gamepad/gamepad_runtime.gd` больше не держит navigation repeat/hold state напрямую: это вынесено в `levels/minigames/gamepad/gamepad_navigation_repeat.gd` и покрыто `tests/cases/test_gamepad_navigation_repeat.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит pause/cursor ownership state напрямую: это вынесено в `levels/minigames/minigame_modal_ownership.gd` и покрыто `tests/cases/test_minigame_modal_ownership.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит minigame music pushed/stream/stop-on-finish state напрямую: это вынесено в `levels/minigames/minigame_music_session.gd` и покрыто `tests/cases/test_minigame_music_session.gd`.
- `levels/game_director.gd` больше не держит death-title sequence, readable glitch layout и material factory: это вынесено в `levels/game_director_death_title_presenter.gd`.
- `levels/game_director.gd` больше не держит stalker spawn/checkpoint service, overlay layer policy, death cursor/input policy, death camera capture/restore, death retry restore/darken/reload policy, cycle timer/checkpoint state, CycleState phase bridge, timer node lifecycle, minigame distortion gate, distortion progress/easing math, distortion overlay/material actuator и distortion phase/checkpoint state напрямую: это вынесено в отдельные `game_director_*` helper-ы с focused tests.
- `MusicManager` facade оставлен стабильным: он уже защищён private-API тестом, а mix-offset policy вынесена в `MusicMixSettings`; рискованный широкий audio-stack refactor лучше делать отдельной задачей с audio-regression focus.
- `Fridge` больше не держит code-lock scene adapter напрямую: создание lock scene и `code_value`/legacy `target_code` wiring вынесены в `FridgeCodeLockSession`.
- `Fridge` больше не держит feeding minigame setup напрямую: config check, scene instantiation, `minigame_finished` contract и `setup_game` wiring вынесены в `FridgeFeedingSession`.
- `Fridge` больше не держит post-feeding world hooks напрямую: cycle marks, chase cleanup, teleport и checkpoint/autosave fallback вынесены в `FridgeCompletionSession`.
- Оставшаяся крупность `GameDirector`, `MusicManager` и `Player` теперь зафиксирована как future architecture refactor, а не открытый долг этого remediation списка.

### 11. Scene validators нужно расширить на NodePath/child-name contracts

Статус: закрыто.

- `tests/cases/test_scene_nodepath_contracts.gd` валидирует active level/interactable scenes: unlocked/key doors require resolving targets, blockpost keeps `TouchArea` and `PassageBlocker/CollisionShape2D`, money interactables resolve money systems, key exported visual/light/audio paths resolve, а utility-level paths лебёдки, corridor distortion и `TargetMonsterSpawner` condition sources не могут silently сломаться. `tests/cases/test_trigger_set_property_contracts.gd` отдельно валидирует configured trigger target paths and property names. `tests/cases/test_scene_dependency_contracts.gd` проверяет, что required key doors имеют источник ключа в той же сцене, а `SearchKeyManager.search_spots` непустой и resolving.
- `tests/cases/test_level_authoring_contracts.gd` валидирует cycle-level metadata, наличие bed transition, loadable `next_level_path`, отсутствие bed self-loop, root-level conditional respawn paths и непустой текст включённых стартовых hint/subtitle.
- `tests/cases/test_lab_authoring_contracts.gd` валидирует lab laptop `time_limit`/`penalty_time`, timed-lab minigame scene contract, уникальные `lab_completion_id` там, где сцена требует явные lab IDs, и соответствие `Fridge.required_lab_completion_ids` реальным ноутбукам в той же сцене.
- `tests/cases/test_fridge_authoring_contracts.gd` валидирует active level feeding/code-lock/final fridge configs, включая minigame signals/setup methods, food scenes, face/background и code-lock scene.
- `tests/cases/test_stu_level_path_contracts.gd` валидирует STU exported/hardcoded paths and dynamic door target constants.
- `tests/cases/test_localization_contracts.gd` теперь покрывает больше player-facing export-полей: death/ending UI, note/obstacle prompts, timed lab dialogue exports, key names и money reward reasons.
- STU doors with intentionally empty targets are now explicitly locked.
- Null override cleanup intentionally left out: tests now guard behavior first, and bulk Godot reserialization remains separate from gameplay fixes.

### 12. STU-уровни слишком завязаны на имена этажей и детей

Статус: закрыто на уровне runtime contracts.

- `tests/cases/test_stu_level_path_contracts.gd` фиксирует STU floor/room paths, fridge paths and dynamic redirect targets before future scene edits.
- `level_13_stu_3.gd` no longer advertises a nonexistent `6thLevel/604/InteractableObjects/Fridge` as default; `primary_fridge_path` is explicit optional and `secondary_fridge_path` remains required.
- Empty-target STU doors that are not traversal doors are locked in `level_11_STU_1.tscn`, `level_12_STU_2.tscn` and `level_13_STU_3.tscn`.
- Large STU scene decomposition was deliberately not done in this pass: with validators in place, it can now be a separate visual/scene-authoring refactor instead of a hidden runtime correctness risk.

### 13. LLM glitch minigame выглядит намеренно или случайно невыигрываемой

Статус: закрыто.

- Дизайн зафиксирован как intentionally fail-forward: `levels/minigames/labs/LLM/llm_minigame_glitch.gd` использует named constants для max progress и success threshold.
- `_ready()` явно держит `complete_lab_on_failure = true`.
- Контракт покрыт `tests/cases/test_llm_glitch_fail_forward_contract.gd`.

### 14. Фонарик можно переключать во время black screen / door fade

Статус: закрыто.

- `player/player.gd` блокирует `_toggle_flashlight()` при `_is_movement_blocked()` или `_is_screen_dark()`.
- Regression покрыт в `tests/cases/test_cycle_state_flashlight_unlock.gd`.
- Light-sensitive runtime tests теперь явно сбрасывают black-screen state в setup, чтобы не зависеть от предыдущих fade-сцен.

### 15. `MusicManager.start_event_music()` / `start_distortion_music()` могут push-ить один source повторно

Статус: закрыто.

- `levels/music_manager.gd` теперь не делает повторный `push_music` для уже активного event/distortion source.
- `reset_base_music_state()` чистит event/distortion source registry.
- Regression покрыт в `tests/cases/test_musicmanager_priority_resume_runtime.gd`.

### 16. `InteractiveObject` нет явно unregister-ится из `InteractionManager` при `_exit_tree`

Статус: закрыто.

- `objects/interactable/interactive_object.gd` получил `_exit_tree()` cleanup: dependency disconnect, unregister из `InteractionManager`, сброс player/focus/prompt.
- Regression покрыт в `tests/cases/test_interaction_manager_focus.gd`.

### 17. `SearchSpot` не выставляет `complete_interaction()` после найденного ключа

Статус: закрыто.

- `objects/interactable/search_spot/search_spot.gd` вызывает `complete_interaction()` после успешного key discovery.
- Контракт зависимостей покрыт в `tests/cases/test_interaction_completion_contracts.gd`.

### 18. `Obstacle` обходит нормальную InteractiveObject-архитектуру

Статус: закрыто контрактом.

- `Obstacle` оставлен как `StaticBody2D` + `InteractArea`, потому что это collision-blocker, а не обычный `Area2D` interactable.
- `tests/cases/test_obstacle_interaction_contract.gd` проверяет, что `$InteractArea` сохраняет `InteractiveObject` contract, не регистрируется как обычный focused candidate и press-clear flow освобождает obstacle после нужного числа нажатий.

### 19. Ending scenes и pause classification непоследовательны

Статус: закрыто.

- Ending-сцены оформлены как отдельный `SceneContext` type (`ending_scene`, `res://levels/endings/`).
- `levels/menu/pause_manager.gd` блокирует pause menu поверх menu/ending scenes.
- `ending_screen.gd` и `ending_credits.gd` маркируют себя как ending scenes; локальный blocker в credits оставлен как страховка.
- Regression покрыт в `tests/cases/test_scene_context_pause_classification.gd`.

### 20. CI не проверяет export presets dry-run

Статус: закрыто на уровне обычного suite + локального smoke.

- `tests/cases/test_export_presets_contract.gd` проверяет, что `export_presets.cfg` парсится, содержит preset и не уводит `export_path` наружу из repo-local `exports/`.
- Полный локальный smoke `godot --headless --path . --export-debug "MacOS" /tmp/eater-loop-export-smoke/EaterLoop.app` прошёл с exit code `0` на машине с installed templates.
- Отдельный full export job в GitHub Actions остаётся возможным release-hardening, но presets больше не остаются непроверенными.

### 21. `tests/run_tests.sh` зависит от запуска из root

Статус: закрыто.

- `tests/run_tests.sh` вычисляет project root относительно себя и запускает Godot с `--path "$PROJECT_ROOT"`.
- `tests/README.md` обновлён: helper можно запускать из любого cwd.

### 22. Документация местами stale

Статус: закрыто.

- `docs/audit_tooling_assets_tests.md` обновлён под текущий suite: `OK: all tests passed (93)`.
- `docs/level_end_endings.md` обновлён под `res://levels/cycles/level_14_end.tscn`, `level_14_end.gd` и inherited `level_11_end.gd`.
- `docs/architecture_overview.md` дополнил текущие контракты SceneContext/pause, music idempotency, flashlight transition blocking и новые regression-тесты.

## P3 - Гигиена, Legacy И Мусор

### 23. Удалить tracked `.gitignore.save`

Статус: закрыто.

- Tracked `.gitignore.save` удалён.

### 24. Решить судьбу локального ignored `global/export_presets.cfg`

Статус: закрыто.

- Ignored локальный `global/export_presets.cfg` удалён из рабочей копии.
- Canonical tracked preset остаётся в root `export_presets.cfg`.

### 25. Проверить и удалить/переименовать duplicate legacy icons

Статус: закрыто.

- Canonical icons, реально используемые `project.godot`, оставлены: `global/macos_icon.icns`, `global/windows_icon.ico`.
- Неиспользуемые legacy copies `global/Иконка_предварительно.icns` и `global/Иконка_предварительно.ico` удалены.

### 26. Нормализовать naming debt через Godot rename

Статус: закрыто.

- `levels/minigames/search_key/**/Без названия *.png` переименованы в descriptive background names.
- `levels/minigames/feeding/food/chiken` переименован в `chicken`.
- `levels/minigames/feeding/food/meet` и `food_meet.tscn` переименованы в `meat` / `food_meat.tscn`.
- `objects/environment/sprites/toilet and bathroom` переименован в `toilet_bathroom`.
- `objects/interactable/door/sprites/DoorNSTU_highevel.png` переименован в `DoorNSTU_highlevel.png`.
- `objects/interactable/fridge/audio/FridgeNoizeE.wav` переименован в `FridgeNoiseE.wav`.
- Scene/script references и `.import` metadata обновлены; поиск по старым runtime-путям пустой.

### 27. Почистить legacy-комментарии и flags

Статус: закрыто для найденных runtime-комментариев.

- `InteractiveObject` очищен от `СТАРЫЕ`/`НОВЫЕ`/`НОВЫЙ СИГНАЛ`-комментариев.
- `fridge.gd` и `laptop.gd` больше не содержат комментарии про "старый скрипт/код".
- `unlock_on_dependency_interaction` оставлен как backward-compatible inspector flag; его removal лучше делать вместе с полноценным typed outcome/result слоем из P2.8.

### 28. Решить судьбу `Projector` vs `Projector2`

Статус: закрыто.

- Canonical implementation: `objects/interactable/projector/projector.gd` + `projector.tscn`, уже покрыт input/directional light tests.
- `objects/interactable/projector2/` удалён как неиспользуемая параллельная реализация.

### 29. Убрать или задействовать `CursorManager._in_game`

Статус: закрыто.

- Dead `_in_game` state удалён из `levels/minigames/cursor_manager.gd`.
- `set_in_game(...)` оставлен как compatibility API для внешних callers, но `GameDirector` больше не вызывает его для scene sync.

### 30. Дедуплицировать input-device detection

Статус: закрыто.

- Общая логика keyboard/mouse/gamepad/Sony detection вынесена в `global/input_device_utils.gd`.
- `levels/game_director.gd`, `levels/interaction_prompts.gd` и `levels/menu/main_menu.gd` используют один helper вместо локальных копий.
- Контракт покрыт `tests/cases/test_input_device_utils.gd`.

### 31. Проверить пустые specialization wrappers

Статус: закрыто.

- Пустой `objects/interactable/level12/notebook/laptop_money.gd` удалён.
- `laptop_money.tscn` оставлен как scene-specific inherited scene от `laptop_STU.tscn` с overrides `prompt_text` и `reward_on_work_completion`.

## Что Не Трогать Без Отдельной Задачи

- Не удалять Git LFS и tracked source assets: LFS сейчас выглядит настроенным правильно.
- Не делать новые массовые rename ассетов в одном коммите с gameplay fixes.
- Не продолжать широкий распил `MusicManager`/`GameDirector` без отдельной audio/runtime-regression задачи.
- Не менять historical audit docs как историю, если не решено, что они являются current-state документацией.
- Не убирать `MusicManager` public facade: тесты и код уже опираются на него как на стабильную внешнюю точку.
