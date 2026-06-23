# ToFix

Аудит от 2026-06-23 по Godot-проекту `едок.-петля`.

Цель файла - рабочий список для последующего ремонта репозитория. В него попали не только явные баги, но и места, которые повышают стоимость поддержки: fragile scene contracts, legacy-остатки, мусорные файлы, stale docs и крупные god-class scripts.

## Короткий Вердикт

Проект не выглядит разваленным. У него понятный entrypoint, явные autoload-и, рабочий локальный тестовый слой, Git LFS для ассетов, CI-проверки, `InteractionManager`, `SceneContext`, checkpoint-восстановление и набор контрактных тестов. После input-device pass parser-only и полный suite проходили, полный suite содержит 60 тестов.

Основная проблема уже не в "игра не запускается", а в поддерживаемости и краевых состояниях:

- несколько singleton-ов одновременно владеют pause/fade/music состояниями;
- интерактивы получили typed outcome/result слой, но крупные владельцы pause/fade/music состояний всё ещё пересекаются;
- STU-уровни и крупные сцены сильно завязаны на `NodePath`, имена детей и serialized overrides;
- часть файловой гигиены и naming debt всё ещё отстала от текущего состояния;
- крупные классы остаются дорогими для ревью и регрессий.

Оценка проблемности после текущего аудита: примерно 5.5-6/10. Это поддерживаемый проект с рабочими тестами; исходные P1-регрессии закрыты, открытыми остаются P2/P3-долги.

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
- Stale current-state docs обновлены под `level_14_end.*` и suite из 60 тестов.
- Obstacle special-case покрыт контрактным тестом.
- Export presets проверяются static contract-тестом в suite; локальный macOS export smoke прошёл с templates.
- Удалены `.gitignore.save`, ignored `global/export_presets.cfg`, legacy icon copies и неиспользуемый `Projector2`.
- Убран dead `CursorManager._in_game` state и пустая `laptop_money.gd` specialization-wrapper.
- Legacy-комментарии из runtime-кода очищены в `InteractiveObject`, `fridge.gd` и `laptop.gd`.
- Input-device detection централизован в `global/input_device_utils.gd` и переиспользуется `GameDirector`, `InteractionPrompts` и `MainMenu`.
- `InteractiveObject` получил typed `interaction_result`, `interaction_succeeded`, `interaction_failed`, `interaction_cancelled`; final branch и completed dependencies переведены на success outcome.

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

Evidence:

- `levels/menu/pause_manager.gd`
- `player/ui_message.gd`
- `levels/minigames/minigame_controller.gd`
- `levels/game_director.gd`

Что сделать:

- сделать владельческий Pause API или pause tokens;
- запретить прямое "restore previous bool" в модальных системах;
- добавить тесты на пересечения: hint + pause menu, minigame + pause menu, death screen + fade.

### 10. `GameDirector`, `UIMessage`, `MinigameController`, `MusicManager`, `Player` остаются слишком крупными

Evidence:

- `levels/game_director.gd`: 1181 строка.
- `levels/music_manager.gd`: 1105 строк.
- `levels/minigames/minigame_controller.gd`: 739 строк.
- `player/ui_message.gd`: 573 строки.
- `player/player.gd`: 569 строк.

Что сделать:

- сначала закрыть P1/P2 contracts, потом дробить без большого косметического рефактора;
- `GameDirector`: вынести death UI, damage/distortion FX, stalker/chase orchestration, checkpoint bridge;
- `UIMessage`: разделить notifications/subtitles, notes/hints, fade transitions, scene navigation, prompt bridge;
- `MusicManager`: оставить публичный facade, но вынести base stack, ambient suppression, chase, event/distortion, pause menu;
- `MinigameController`: отделить lifecycle, timer, pause/cursor/prompts, music, transitions, gamepad runtime.

### 11. Scene validators нужно расширить на NodePath/child-name contracts

Evidence:

- Level scripts и interactables держатся на exported/hardcoded `NodePath`.
- `Door` ждёт `target_marker`, `Sprite2D`, `Number`.
- `Blockpost` ждёт `TouchArea` и `PassageBlocker/CollisionShape2D`.
- Fridge/laptop/lamp/projector ждут конкретные дочерние имена или exported paths.
- В `.tscn` много serialized `target_marker = null`, `one_shot = null`, `interact_area_node = null`.

Что сделать:

- добавить validators для обязательных paths/groups/methods;
- отдельно валидировать STU doors, level end paths, checkpoint participants;
- null overrides чистить только после проверки, что Godot не вернёт их автоматически.

### 12. STU-уровни слишком завязаны на имена этажей и детей

Evidence:

- `levels/cycles/level_11_stu_1.gd`
- `levels/cycles/level_12_stu_2.gd`
- `levels/cycles/level_13_stu_3.gd`
- большие сцены `level_11_STU_1.tscn`, `level_12_STU_2.tscn`, `level_13_STU_3.tscn` по 8500-9200 строк.

Что сделать:

- постепенно выносить повторяющиеся блоки в reusable scene instances;
- заменить `1thLevel`/`2thLevel`/`6thLevel`/`7thLevel`-style paths на data-driven resolver или группы;
- не делать массовый scene rewrite без validator-подушки.

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

- `docs/audit_tooling_assets_tests.md` обновлён под текущий suite: `OK: all tests passed (60)`.
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

Примеры:

- `levels/minigames/search_key/**/Без названия *.png`
- `levels/minigames/feeding/food/chiken`
- `levels/minigames/feeding/food/meet`
- `objects/environment/sprites/toilet and bathroom`
- `objects/interactable/door/sprites/DoorNSTU_highevel.png`
- `objects/interactable/fridge/audio/FridgeNoizeE.wav`

Что сделать:

- переименовывать только через Godot-aware flow, чтобы обновились `.import` и scene references;
- не смешивать массовый rename с gameplay fixes.

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
- `set_in_game(...)` оставлен как compatibility API для `GameDirector`, но больше не хранит лишнее состояние.

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
- Не делать массовый rename ассетов в одном коммите с gameplay fixes.
- Не дробить god-classes до закрытия P1/P2 contracts: иначе легко размазать баги по новым файлам.
- Не менять historical audit docs как историю, если не решено, что они являются current-state документацией.
- Не убирать `MusicManager` public facade: тесты и код уже опираются на него как на стабильную внешнюю точку.
