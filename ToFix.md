# ToFix

Аудит от 2026-06-23 по Godot-проекту `едок.-петля`.

Цель файла - рабочий список для последующего ремонта репозитория. В него попали не только явные баги, но и места, которые повышают стоимость поддержки: fragile scene contracts, legacy-остатки, мусорные файлы, stale docs и крупные god-class scripts.

## Короткий Вердикт

Проект не выглядит разваленным. У него понятный entrypoint, явные autoload-и, рабочий локальный тестовый слой, Git LFS для ассетов, CI-проверки, `InteractionManager`, `SceneContext`, checkpoint-восстановление и набор контрактных тестов. На момент аудита parser-only и полный suite проходили, полный suite содержит 53 теста.

Основная проблема уже не в "игра не запускается", а в поддерживаемости и краевых состояниях:

- несколько singleton-ов одновременно владеют pause/fade/music состояниями;
- интерактивы всё ещё различают только "попытку" и "завершено", но не полноценный outcome/result;
- STU-уровни и крупные сцены сильно завязаны на `NodePath`, имена детей и serialized overrides;
- часть документации и файловой гигиены отстала от текущего состояния;
- крупные классы остаются дорогими для ревью и регрессий.

Оценка проблемности после текущего аудита: примерно 5.5-6/10. Это поддерживаемый проект с рабочими тестами, но с несколькими P1/P2-рисками, которые лучше закрывать до новых больших фич.

## P0

Подтверждённых P0-блокеров не найдено.

## P1 - Вероятные Игровые Баги И Пользовательские Регрессии

### 1. Лампа показывает старую клавишу `Q`, хотя реально слушает `interact`

Evidence:

- `objects/interactable/lamp/lamp.gd`: `_get_interact_action()` возвращает `"interact"`.
- `project.godot`: `interact` назначен на `E`, `Space` и gamepad confirm.
- `levels/interaction_prompts.gd`: `DEFAULT_LAMP_ON_TEXT` / `DEFAULT_LAMP_OFF_TEXT` всё ещё говорят `Q`.
- `objects/interactable/lamp/lamp.gd`: fallback prompt тоже говорит `Q`.

Что сделать:

- заменить lamp prompt на текущий `interact`-текст или общий prompt-renderer;
- добавить тест, что light interactables не показывают несуществующий action;
- проверить старый `projector`/`projector2`, чтобы не осталось похожей рассинхронизации.

### 2. В STU-сценах есть player-facing doors с `target_marker = NodePath(".")`

Evidence:

- `levels/cycles/level_11_STU_1.tscn`
- `levels/cycles/level_12_STU_2.tscn`
- `levels/cycles/level_13_STU_3.tscn`
- `objects/interactable/door/door.gd`: дверь берёт `marker.global_position` без self-target guard.
- `enemies/stalker/enemy_stalker.gd` уже считает self-reference невалидным для своей логики.

Риск: игрок может получить fade-to-self/no-op переход или placeholder-интерактив вместо осмысленной двери.

Что сделать:

- решить, что это должно быть: locked door, non-interactive blocker или реальный marker;
- добавить validator/test: player door не может иметь `target_marker = "."`;
- отдельно проверить, что такие двери не участвуют в подсказках как обычные проходы.

### 3. Финальная развилка выбирает ветку на `interaction_requested`, а не на успешный outcome

Evidence:

- `levels/cycles/level_11_end.gd`: laptop/fridge branch выбирается в `_on_laptop_interaction_requested` / `_on_fridge_interaction_requested`.
- `objects/interactable/interactive_object.gd`: `interaction_requested` испускается до `_on_interact()`.
- fridge/laptop outcomes асинхронные и могут завершиться позже, failed/cancelled или вообще не дойти до success.

Риск: первый клик по холодильнику или ноутбуку может зафиксировать ending branch до реального успеха.

Что сделать:

- перевести выбор ветки на успешный сигнал: `feeding_finished`, lab completion или новый outcome/result;
- добавить regression test: failed/cancelled attempt не фиксирует финальную ветку;
- после исправления проверить зависимости bed/fridge/laptop в `level_11_end`.

### 4. Ending branch state в `level_11_end` не checkpointed

Evidence:

- `levels/cycles/level_11_end.gd`: `_branch`, `_ending_started`, `_bad_ending_queued` живут только в runtime-полях.
- В файле нет `capture_checkpoint_state()` / `apply_checkpoint_state()`.

Риск: retry/checkpoint/death window внутри финального flow может потерять выбранную ветку или очередь bad ending.

Что сделать:

- либо запретить checkpoint/death window в этом flow;
- либо добавить checkpoint state для branch/ending flags;
- покрыть тестом восстановление после выбора laptop/fridge ветки.

### 5. `UIMessage.show_hint()` может оставить игру на паузе при повторном hint

Evidence:

- `player/ui_message.gd`: `show_hint()` каждый раз перезаписывает `_hint_prev_paused = get_tree().paused`.
- Если второй pausing hint показан поверх первого, previous state станет `true`.
- `hide_hint()` восстановит `get_tree().paused = true`, хотя до первого hint игра могла быть unpaused.

Что сделать:

- сделать hint ownership/token или не перезаписывать previous pause state при уже открытом hint;
- добавить тест на два последовательных `show_hint(..., pause_game=true)` и один `hide_hint()`;
- проверить похожие паттерны в notes/death/minigame modal flow.

### 6. Fade в `UIMessage` управляется разными tween-моделями

Evidence:

- `player/ui_message.gd`: `fade_out()` / `fade_in()` создают локальные tweens.
- `play_fade_sequence()` / `set_screen_dark()` управляют только `_fade_tween`.

Риск: старый локальный tween может позже перезаписать alpha/mouse_filter нового перехода.

Что сделать:

- унифицировать fade API через один текущий tween/token;
- все public fade methods должны предсказуемо отменять предыдущий fade;
- добавить тест на overlapping fade transitions.

### 7. Chase music pause не имеет reason-map, в отличие от base music

Evidence:

- `levels/music_manager.gd`: base music имеет `_base_pause_reasons`.
- Chase music держит pause в одном `_runner_global_paused`.
- `start_pause_menu_music()` и `MinigameController.start_minigame()` оба вызывают `pause_chase_music()`.
- `stop_pause_menu_music()` вызывает `resume_chase_music()` без проверки, что minigame ещё активна.

Риск: при пересечении pause menu и minigame chase music может возобновиться слишком рано.

Что сделать:

- сделать для chase music reason-map/token model;
- добавить тест "minigame active + pause menu close не возобновляет chase";
- синхронизировать это с будущим общим Pause API.

## P2 - Системные Долги И Хрупкие Контракты

### 8. Нужен typed outcome/result слой для интерактивов

Evidence:

- `objects/interactable/interactive_object.gd`: есть только `interaction_requested` и `interaction_finished`.
- `DependencyCondition` различает `COMPLETED` и `INTERACTION_REQUESTED`, но не success/failure/cancelled/result payload.

Что сделать:

- ввести `interaction_succeeded` или `interaction_result(result)` с типом outcome;
- мигрировать final branch, dependencies и future unlocks на result, а не на raw attempt;
- оставить `interaction_requested` только для UI/analytics/attempt-level поведения.

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

Evidence:

- `levels/minigames/labs/LLM/llm_minigame_glitch.gd`: `_progress` clamp до `0.96`.
- Успех требует `_progress >= 1.0`.
- timeout завершает failure.
- `TimedLabMinigameBase.complete_lab_on_failure` по умолчанию `true`.

Что сделать:

- решить дизайн: minigame intentionally unwinnable или должна иметь редкий win path;
- если intentionally unwinnable, покрыть fail-forward тестом и явно задокументировать;
- если должна быть выигрываемой, исправить progress/success threshold.

### 14. Фонарик можно переключать во время black screen / door fade

Evidence:

- `player/player.gd`: движение блокируется при dark screen.
- `_toggle_flashlight()` проверяет minigame/charge, но не dark screen/transition.
- `objects/interactable/door/door.gd`: дверь выключает physics, но не input.

Что сделать:

- заблокировать `toggle_flashlight` при dark screen, door transition или movement blocked;
- добавить regression test.

### 15. `MusicManager.start_event_music()` / `start_distortion_music()` могут push-ить один source повторно

Evidence:

- `levels/music_manager.gd`: event/distortion start вызывают `push_music`.
- Явной защиты от повторного старта того же source не видно.

Что сделать:

- добавить idempotency guard для active event/distortion source;
- покрыть тестом повторный start/stop, чтобы stack не восстанавливал тот же event как previous.

### 16. `InteractiveObject` нет явно unregister-ится из `InteractionManager` при `_exit_tree`

Evidence:

- registration/unregistration идёт через body enter/exit.
- При удалении объекта в зоне prompt/focus чистится лениво prune-логикой.

Что сделать:

- добавить `_exit_tree` cleanup;
- покрыть тестом удаление focused interactable while player in range.

### 17. `SearchSpot` не выставляет `complete_interaction()` после найденного ключа

Evidence:

- `objects/interactable/search_spot/search_spot.gd`: при success + `has_key` меняет `has_key`/`is_searched_empty`, но не вызывает `complete_interaction()`.

Сейчас прямой зависимости на search spot не найдено, поэтому это P2, а не P1.

Что сделать:

- определить outcome: `complete_interaction()` на успешном ключе или отдельный `key_found`;
- зафиксировать контракт тестом до появления новых dependencies.

### 18. `Obstacle` обходит нормальную InteractiveObject-архитектуру

Evidence:

- `objects/interactable/obstacle/obstacle.gd`: не наследует `InteractiveObject`, а динамически навешивает `interactive_object.gd` на `$InteractArea`.

Что сделать:

- мигрировать на обычное наследование/scene composition;
- либо явно покрыть этот special-case контрактными тестами.

### 19. Ending scenes и pause classification непоследовательны

Evidence:

- `ending_credits` вручную блокирует pause.
- `ending_screen` похожего блока не имеет.
- `SceneContext` классифицирует gameplay/menu, но endings требуют явного решения.

Что сделать:

- решить, endings это отдельный scene type или menu-like scenes;
- добавить тест, что pause menu не открывается поверх всех ending-сцен.

### 20. CI не проверяет export presets dry-run

Evidence:

- `.github/workflows/godot-tests.yml`: ставит Godot и гоняет parser/full tests.
- Export templates не ставятся, `export_presets.cfg` не проверяется реальным export/dry-run.

Что сделать:

- добавить optional release/export smoke job;
- хотя бы проверять, что presets parse и paths repo-local.

### 21. `tests/run_tests.sh` зависит от запуска из root

Evidence:

- `tests/run_tests.sh` вызывает `godot --headless -s res://tests/run_tests.gd` без `--path`.

Что сделать:

- вычислять project root относительно скрипта;
- запускать Godot с `--path "$PROJECT_ROOT"`;
- обновить `tests/README.md`.

### 22. Документация местами stale

Evidence:

- `docs/audit_tooling_assets_tests.md`: expected suite всё ещё `OK: all tests passed (51)`, сейчас 53.
- `docs/level_end_endings.md`: ссылается на `res://levels/cycles/level_end.tscn` и `level_end.gd`, текущие файлы называются иначе.

Что сделать:

- обновить docs после первых фактических исправлений;
- не править старые audit docs как "историю", если их смысл именно historical snapshot, но current-state docs должны быть точными.

## P3 - Гигиена, Legacy И Мусор

### 23. Удалить tracked `.gitignore.save`

Evidence:

- `.gitignore.save` tracked, выглядит как забытый backup.
- Внутри устаревший ignore `export/`, тогда текущая `.gitignore` использует `/exports/` и другие актуальные paths.

### 24. Решить судьбу локального ignored `global/export_presets.cfg`

Evidence:

- Файл есть в рабочей копии, но игнорируется.
- Содержит старый внешний export path `../Documents/Тест экспорт/Едок Петля.app`.

Что сделать:

- удалить из рабочей копии, если он не нужен;
- либо переименовать/перенести как явный sample вне Godot resource confusion.

### 25. Проверить и удалить/переименовать duplicate legacy icons

Evidence:

- `global/macos_icon.icns` и `global/Иконка_предварительно.icns` имеют одинаковый LFS object id.
- `global/windows_icon.ico` и `global/Иконка_предварительно.ico` выглядят как новая/старая пара.

Что сделать:

- оставить только canonical icon paths, которые реально используются export presets;
- удалить или архивировать legacy copies отдельным коммитом.

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

Примеры:

- `InteractiveObject`: комментарии `СТАРЫЕ`, `НОВЫЕ`, `НОВЫЙ СИГНАЛ`.
- `fridge.gd`: комментарии про "старый скрипт".
- `laptop.gd`: `unlock_on_dependency_interaction` как legacy-флаг поверх enum dependency.

Что сделать:

- оставить только стабильные комментарии, которые объясняют контракт;
- убрать историю ремонта из runtime-кода.

### 28. Решить судьбу `Projector` vs `Projector2`

Evidence:

- В проекте живут две параллельные модели похожего светового интерактива.

Что сделать:

- выбрать canonical implementation;
- старую оставить только если она реально нужна для конкретной сцены;
- покрыть input/power/prompt contract тестом.

### 29. Убрать или задействовать `CursorManager._in_game`

Evidence:

- `_in_game` обновляется, но не участвует в `_update_mouse_mode`.

Что сделать:

- удалить как dead state;
- либо вернуть в mouse mode decision, если он должен влиять на курсор.

### 30. Дедуплицировать input-device detection

Evidence:

- похожая логика есть в `GameDirector`, `InteractionPrompts`, `MainMenu`.

Что сделать:

- вынести общий helper/service для keyboard/gamepad/Sony/Xbox detection;
- особенно полезно перед исправлением prompt-клавиш.

### 31. Проверить пустые specialization wrappers

Evidence:

- `objects/interactable/level12/notebook/laptop_money.gd` выглядит как пустая specialization-обёртка.

Что сделать:

- удалить, если она не нужна;
- либо явно документировать, что это scene-specific alias для инспектора/будущего поведения.

## Что Не Трогать Без Отдельной Задачи

- Не удалять Git LFS и tracked source assets: LFS сейчас выглядит настроенным правильно.
- Не делать массовый rename ассетов в одном коммите с gameplay fixes.
- Не дробить god-classes до закрытия P1/P2 contracts: иначе легко размазать баги по новым файлам.
- Не менять historical audit docs как историю, если не решено, что они являются current-state документацией.
- Не убирать `MusicManager` public facade: тесты и код уже опираются на него как на стабильную внешнюю точку.
