# ToFix

Аудит от 2026-06-23 по Godot-проекту `едок.-петля`.

Цель файла - рабочий список для последующего ремонта репозитория. В него попали не только явные баги, но и места, которые повышают стоимость поддержки: fragile scene contracts, legacy-остатки, мусорные файлы, stale docs и крупные god-class scripts.

## Короткий Вердикт

Проект не выглядит разваленным. У него понятный entrypoint, явные autoload-и, рабочий локальный тестовый слой, Git LFS для ассетов, CI-проверки, `InteractionManager`, `SceneContext`, checkpoint-восстановление и набор контрактных тестов. После текущего remediation pass parser-only и полный suite проходили, полный suite содержит 114 тестов.

Основная проблема уже не в "игра не запускается", а в дальнейшей поддерживаемости:

- pause ownership, typed interaction outcomes, fade controller, minigame backdrop/prompt/timer/modal/music/gamepad-hint/gamepad-repeat/gamepad-node-resolving/gamepad-callback/gamepad-confirm-release lifecycle helpers, scene checkpoint snapshot/restore/dynamic-restore helpers, player run/stamina helper, player facing/checkpoint helper, player key inventory helper, player skeleton step timing helper, player flashlight charge/recharge helper, death-title presentation, death entry presentation setup, death fade/tween setup, death screen reset/cleanup и death sequence state уже вынесены из самых хрупких мест;
- STU/scene/utility/level/lab/fridge-authoring contracts теперь покрыты валидаторами, часть STU route/wiring paths вынесена в exported поля, но крупные сцены всё ещё дороги для ручного ревью;
- naming debt из этого списка закрыт Godot-aware rename-ами с обновлением `.import` и scene/script references, включая старый runtime-prefix `Frizzer`;
- `MusicManager`, `GameDirector`, оставшиеся visual/checkpoint glue части `Player` и STU-сцены всё ещё крупные, но оставшиеся распилы теперь являются отдельными future refactor задачами, а не открытыми runtime-долгами этого файла.

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
- Event/distortion music больше не push-ит дубликаты в stack при повторном старте того же source; source registry вынесен в `MusicScopedSourceRegistry` и автоматически освобождает scoped source при `Node.tree_exited`.
- `InteractiveObject` явно unregister-ится из `InteractionManager` при `_exit_tree`, а `InteractionManager` больше не вызывает private interaction action/focus hooks строками.
- `SearchSpot` завершает interaction после успешного нахождения ключа.
- Ending-сцены классифицируются через `SceneContext`, gameplay path fallback ограничен `level_*.tscn`, gameplay-сцены вне стандартной папки могут опираться на `gameplay_scene` group или cycle/timer root contract, и pause menu не открывается поверх концовок.
- `ending_credits.gd` уважает export `return_scene`, поэтому credits можно переиспользовать в другом menu/ending flow без правки кода.
- `tests/run_tests.sh` стал независим от cwd через `--path`.
- Stale current-state docs обновлены под `level_14_end.*` и текущий suite.
- Obstacle special-case покрыт контрактным тестом.
- Export presets проверяются static contract-тестом в suite; локальный macOS export smoke прошёл с templates, а GitHub Actions получил отдельный MacOS debug export smoke job.
- Godot UID sidecars для `.gd`/`.gdshader` теперь проверяются контрактом: новые скрипты и shader-ы не должны попадать в репозиторий без tracked `.uid`.
- Удалены `.gitignore.save`, ignored `global/export_presets.cfg`, legacy icon copies и неиспользуемый `Projector2`.
- Убран dead `CursorManager._in_game` state и пустая `laptop_money.gd` specialization-wrapper.
- Legacy-комментарии из runtime-кода очищены в `InteractiveObject`, `fridge.gd` и `laptop.gd`.
- Input-device detection централизован в `global/input_device_utils.gd` и переиспользуется `GameDirector`, `InteractionPrompts` и `MainMenu`.
- `InteractiveObject` получил typed `interaction_result`, `interaction_succeeded`, `interaction_failed`, `interaction_cancelled`; final branch и completed dependencies переведены на success outcome.
- Level scripts и `TargetMonsterSpawner` node-signal defaults переведены с legacy `interaction_finished` на typed `interaction_succeeded`; архитектурный контракт запрещает новые runtime/scene подписки на legacy signal.
- `InteractionManager` больше не вызывает `InteractiveObject._get_interact_action()` и `_set_interaction_focus()` через stringly `call`: action читается через `get_interact_action_name()`, фокус задаётся через `set_manager_focus(...)`, а архитектурный тест запрещает возврат к private string calls.
- `PauseManager` получил owner-token API; pause menu, UI notes/hints, minigames и death screen больше не восстанавливают `get_tree().paused` через локальный previous-bool.
- Scene NodePath contracts покрыты `test_scene_nodepath_contracts.gd`: критичные interactable paths, utility-level paths для лебёдки/corridor distortion/`TargetMonsterSpawner`, typed `Fridge` target у лебёдки, active content scene exported non-empty `NodePath`/`Array[NodePath]` resolving, scene-owned audio player `Music`/`Sounds` bus contract, playable level root contract, cycle-level metadata/Player instance/Player export ranges/bed transitions/bed target scene types/root exported `*_path` wiring, typed root path expectations и LevelMusic configs покрыты `test_level_authoring_contracts.gd`, lab laptop IDs/timer settings и fridge required lab IDs покрыты `test_lab_authoring_contracts.gd`, feeding/code-lock/final fridge configs покрыты `test_fridge_authoring_contracts.gd`, STU exported route/wiring paths и dynamic door targets покрыты `test_stu_level_path_contracts.gd`, configured `TriggerSetProperty` target/property/effect/music-stream wiring покрыт `test_trigger_set_property_contracts.gd`, managed `SearchSpot` typed `SearchKeyMinigame`/key/trash configs и typed `SearchKeyManager.search_spots` покрыты `test_search_key_authoring_contracts.gd`, а key-door/search-key wiring и stable scene-relative paths для checkpoint participants покрыты `test_scene_dependency_contracts.gd`.
- Content-object scripts больше не должны использовать stringly probes для стабильных collaborators: лебёдка типизирует `Fridge`, reward/utility objects вызывают `UIMessage.fade_*` через autoload facade, а `test_interaction_architecture_contracts.gd` запрещает возврат к `UIMessage.has_method(...)` и `call("apply_winch_release_state")`.
- Local helper cleanup/UI glue тоже не должны возвращаться к stringly probes: `PickupFlashlight` чистит соседние typed pickup-ы прямым helper call, а `PromptView` пишет стабильное `text` property напрямую.
- Player-dependent content/HUD/enemy detection больше не должны маскировать отсутствие Player API через `player.has_method(...)`: двери, key/note rewards, search-key minigame, лебёдка, stamina/flashlight bars и flashlight-sensitive enemies используют публичный Player facade напрямую, а архитектурный тест запрещает возврат к строковым probes.
- Reactive-light consumers больше не копируют source method probes: flashlight-sensitive и ceiling enemies читают external light через `ReactiveLightContracts.is_point_lit(...)`, а generator включает required lights через `turn_on_generator_light(...)`.
- Базовый `CycleLevel` больше не проверяет `UIMessage.is_screen_dark`/`fade_*` строками перед стартовыми субтитрами и respawn blackout; архитектурный тест фиксирует прямой facade contract для новых уровней.
- `TimedLabMinigameBase` больше не проверяет `UIMessage.show_dialogue` и `CycleState.mark_lab_completed` строками перед outcome; lab-authoring тест фиксирует прямой facade contract для новых timed-lab мини-игр.
- SQL lab mini-games больше не проверяют slot/word widgets через stringly `has_method/has_signal`: `drop_slot.tscn` и `drag_word.tscn` валидируются как typed `SqlDropSlot`/`SqlDragWord`.
- `MinigameController` больше не проверяет `UIMessage.play_fade_sequence` строкой перед start/finish transition; архитектурный тест фиксирует прямой transition facade для всех новых мини-игр.
- `MinigameModalOwnership` больше не зовёт `PauseManager`/`CursorManager` через `has_method/call`: helper принимает typed managers, а focused test запрещает возврат к stringly ownership API.
- Убраны две key-door ловушки: `level_09_crazy` больше не требует несуществующий `lebedka_key` и не держит пустой `SearchKeyManager`, а `level_12_STU_2` больше не запирает игрока в 604 через `key_6level` без источника ключа.
- Пустые target marker STU-двери, которые должны быть недоступны, явно locked; `level_13_stu_3.gd` сделал отсутствующий primary fridge path явным optional default.
- `level_13_STU_3` cafeteria fridge больше не остаётся частично настроенным: после lab-gate у него есть feeding minigame scene, face/background/music/sfx и food config.
- `test_input_actions.gd` теперь проверяет не только базовый список action-ов и light interactables, но и runtime string literals в `is_action_*`/gamepad nav wrappers, чтобы новые уровни и мини-игры не ссылались на отсутствующий InputMap action.
- Naming debt закрыт Godot-aware rename-ами: `chiken` -> `chicken`, `meet` -> `meat`, `Без названия *.png` -> descriptive background names, `toilet and bathroom` -> `toilet_bathroom`, `DoorNSTU_highevel.png` -> `DoorNSTU_highlevel.png`, `FridgeNoizeE.wav` -> `FridgeNoiseE.wav`.
- Первый god-class split закрыт: `UIMessage` вынес fade/tween state в `ui_fade_controller.gd`, `MinigameController` вынес backdrop registry/presentation в `minigame_backdrop_presenter.gd`, prompt suspend/restore lifecycle в `minigame_prompt_visibility_coordinator.gd`, timer state в `minigame_timer_state.gd`, gamepad scheme registry в `gamepad_scheme_registry.gd`, gamepad hint policy в `gamepad_hint_builder.gd`, gamepad navigation repeat state в `gamepad_navigation_repeat.gd`, gamepad node/provider resolving в `gamepad_node_resolver.gd`, gamepad callback routing в `gamepad_callback_router.gd`, gamepad confirm release gate state в `gamepad_confirm_release_gate.gd`, pause/cursor ownership в `minigame_modal_ownership.gd` и music stack lifecycle в `minigame_music_session.gd`, `MusicManager` вынес pause-reason bookkeeping в `music_pause_reason_state.gd`, stack bookkeeping в `music_stack_state.gd`, ambient suppression/pending resume state в `music_ambient_coordinator.gd`/`music_ambient_suppression_state.gd` и scoped event/distortion source registry в `music_scoped_source_registry.gd`, `GameState` вынес scene checkpoint snapshot/restore в `checkpoint_scene_snapshot.gd`, dynamic runtime restore policy в `checkpoint_dynamic_restore.gd`, `Player` вынес run/stamina state в `player_stamina_state.gd`, facing/checkpoint normalization в `player_facing_state.gd`, key inventory/checkpoint state в `player_inventory_state.gd`, skeleton step timing state в `player_skeleton_step_state.gd` и flashlight charge/recharge state в `player_flashlight_charge_state.gd`, `GameDirector` вынес death-title/glitch presentation в `game_director_death_title_presenter.gd`, death entry presentation setup в `game_director_death_entry_presenter.gd`, stalker spawn/checkpoint service в `game_director_stalker_service.gd`, overlay layer policy в `game_director_overlay_layer_coordinator.gd`, death cursor/input policy в `game_director_death_cursor_coordinator.gd`, death camera capture/restore в `game_director_death_camera_coordinator.gd`, death fade/tween setup в `game_director_death_fade_coordinator.gd`, death retry restore/darken/reload flow в `game_director_death_retry_coordinator.gd`, death screen reset/cleanup в `game_director_death_screen_reset.gd`, death sequence active/pause gate state в `game_director_death_sequence_state.gd`, cycle timer/checkpoint state в `game_director_cycle_timer_state.gd`, CycleState phase bridge в `game_director_cycle_phase_bridge.gd`, timer node lifecycle в `game_director_timer_node_coordinator.gd`, minigame distortion gate в `game_director_distortion_gate.gd`, distortion progress/easing math в `game_director_distortion_progress.gd`, distortion overlay/material actuator в `game_director_distortion_overlay_coordinator.gd` и distortion phase/checkpoint state в `game_director_distortion_phase_state.gd`.

## P2 - Системные Долги И Хрупкие Контракты

### 8. Нужен typed outcome/result слой для интерактивов

Статус: закрыто.

- `objects/interactable/interactive_object.gd` теперь эмитит `interaction_result(result)`, `interaction_succeeded(result)`, `interaction_failed(result)` и `interaction_cancelled(result)`.
- `complete_interaction()` остаётся совместимым success wrapper и по-прежнему эмитит legacy `interaction_finished`, но runtime scripts и scene authoring больше не должны подписываться на него.
- Failed/cancelled outcomes не выставляют `is_completed` и не удовлетворяют `COMPLETED` dependencies.
- `InteractionResultBuilder` нормализует `payload` в Dictionary для reward/item/branch data и сохраняет совместимые top-level custom keys.
- `DependencyCondition.COMPLETED` слушает typed success outcome, а `INTERACTION_REQUESTED` остаётся attempt-level unlock.
- `level_11_end.gd` выбирает laptop branch только по typed `interaction_succeeded`; final scene wiring проверяет реальные `Laptop`/`Fridge`/`Bed` paths и `bad_ending_scene`.
- `level_07_doors.gd`, `level_11_stu_1.gd`, `level_13_stu_3.gd` и node-signal defaults `TargetMonsterSpawner` теперь используют typed `interaction_succeeded`; `test_interaction_architecture_contracts.gd` запрещает новые legacy subscriptions.
- `test_stu_level_path_contracts.gd` фиксирует level 07 Hall2 fridge/door paths и post-fridge lock layout, чтобы eaten/fridge state не превращался в silent no-op после переименования узлов.
- Контракт покрыт `tests/cases/test_interactive_dependency_conditions.gd` и `tests/cases/test_level11_end_flow_contracts.gd`.

### 9. Владение `get_tree().paused` размазано по singleton-ам

Статус: закрыто.

- `levels/menu/pause_manager.gd` теперь владеет pause tokens через `request_pause(...)`, `release_pause(...)`, `release_all_pauses_for(...)` и `clear_all_pause_requests()`.
- Pause menu, `UIMessage` notes/hints, `MinigameController` и death screen в `GameDirector` запрашивают/освобождают свои owner tokens.
- `UIMessage.change_scene_with_fade(..., unpause_after=true)` очищает все pause requests для выхода в меню/ending transitions.
- `Bed._try_sleep` больше не делает ручной fade перед `UIMessage.change_scene_with_fade_delay(...)`: next scene валидируется до затемнения, а transition идёт одним общим UIMessage path.
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
- `levels/minigames/gamepad/gamepad_runtime.gd` больше не держит node/provider resolving и focusable filtering напрямую: это вынесено в `levels/minigames/gamepad/gamepad_node_resolver.gd` и покрыто `tests/cases/test_gamepad_node_resolver.gd`.
- `levels/minigames/gamepad/gamepad_runtime.gd` больше не держит callback lookup/invoke/consumed semantics напрямую: это вынесено в `levels/minigames/gamepad/gamepad_callback_router.gd` и покрыто `tests/cases/test_gamepad_callback_router.gd`.
- `levels/minigames/gamepad/gamepad_runtime.gd` больше не держит confirm release gate state напрямую: это вынесено в `levels/minigames/gamepad/gamepad_confirm_release_gate.gd` и покрыто `tests/cases/test_gamepad_confirm_release_gate.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит pause/cursor ownership state напрямую: это вынесено в typed `levels/minigames/minigame_modal_ownership.gd` и покрыто `tests/cases/test_minigame_modal_ownership.gd`.
- `levels/minigames/minigame_controller.gd` больше не держит minigame music pushed/stream/stop-on-finish state напрямую: это вынесено в `levels/minigames/minigame_music_session.gd` и покрыто `tests/cases/test_minigame_music_session.gd`.
- `levels/game_director.gd` больше не держит death-title sequence, readable glitch layout и material factory: это вынесено в `levels/game_director_death_title_presenter.gd`.
- `levels/game_director.gd` больше не держит stalker spawn/checkpoint service, overlay layer policy, death cursor/input policy, death camera capture/restore, death entry presentation setup, death fade/tween setup, death retry restore/darken/reload flow, death screen reset/cleanup, cycle timer/checkpoint state, CycleState phase bridge, timer node lifecycle, minigame distortion gate, distortion progress/easing math, distortion overlay/material actuator и distortion phase/checkpoint state напрямую: это вынесено в отдельные `game_director_*` helper-ы с focused tests.
- `MusicManager` facade оставлен стабильным: он уже защищён private-API тестом, mix-offset policy вынесена в `MusicMixSettings`, base/chase pause reason bookkeeping вынесен в `MusicPauseReasonState`, stack bookkeeping вынесен в `MusicStackState`, ambient suppression source tracking и pending-resume request вынесены в `MusicAmbientCoordinator`/`MusicAmbientSuppressionState`, а event/distortion source lifecycle вынесен в `MusicScopedSourceRegistry` с `tree_exited` cleanup; оставшийся playback/crossfade refactor лучше делать отдельной задачей с audio-regression focus.
- `Fridge` больше не держит code-lock scene adapter напрямую: создание lock scene и `code_value`/legacy `target_code` wiring вынесены в `FridgeCodeLockSession`.
- `Fridge` больше не держит feeding minigame setup напрямую: config check, typed `FeedingMinigame` scene instantiation и `setup_game` wiring вынесены в `FridgeFeedingSession`.
- `Fridge` больше не держит post-feeding world hooks напрямую: cycle marks, chase cleanup, teleport и checkpoint/autosave fallback вынесены в `FridgeCompletionSession`.
- `CheckpointSceneSnapshot` больше не держит dynamic runtime restore policy напрямую: allowlist, restore metadata, parent resolution, scene instantiation и fail-closed reject неразрешённых scene paths вынесены в `CheckpointDynamicRestore`.
- Оставшаяся крупность `GameDirector`, `MusicManager` и visual/checkpoint glue частей `Player` теперь зафиксирована как future architecture refactor, а не открытый долг этого remediation списка.

### 11. Scene validators нужно расширить на NodePath/child-name contracts

Статус: закрыто.

- `tests/cases/test_scene_nodepath_contracts.gd` валидирует active content scenes: exported non-empty `NodePath`/`Array[NodePath]` values resolve, unlocked/key doors require resolving targets, blockpost keeps `TouchArea` and `PassageBlocker/CollisionShape2D`, money interactables resolve typed `Level12MoneySystem`, key exported visual/light/audio paths resolve, scene-owned `AudioStreamPlayer`/`AudioStreamPlayer2D` nodes explicitly use `Music` or `Sounds`, а utility-level paths лебёдки, corridor distortion и `TargetMonsterSpawner` condition sources не могут silently сломаться. Лебёдка дополнительно требует, чтобы `fridge_path` резолвился именно в `Fridge`, а архитектурный тест запрещает возвращать content-object glue к `has_method/call` для стабильных collaborators including `Level12MoneySystem` money API, spawner state-facade checks и generator light activation. Door retarget marker fields, которые резолвятся от другой двери, остаются в focused `test_stu_level_path_contracts.gd`. `tests/cases/test_trigger_set_property_contracts.gd` отдельно валидирует configured trigger target paths/property names, требует хотя бы один property/sfx/music effect и `music_stream` для replace/event-start music actions. `tests/cases/test_scene_dependency_contracts.gd` проверяет, что required key doors имеют источник ключа в той же сцене, `SearchKeyManager.search_spots` непустой и resolving в `SearchSpot`, checkpoint participants имеют стабильный scene-relative path без generated `@...` segments, а typed scene config overrides для door/interactable defaults не возвращаются к `null`.
- `tests/cases/test_level_authoring_contracts.gd` валидирует cycle-level metadata, ровно один Player instance, безопасные диапазоны Player export-полей движения/выносливости/фонарика/шагов, наличие bed transition, loadable `next_level_path`, отсутствие bed self-loop, target scene type только cycle-level/ending, root-level conditional respawn paths, root exported `*_path` resolving/type expectations, непустой текст включённых стартовых hint/subtitle и `LevelMusic` stream/fade config.
- `tests/cases/test_lab_authoring_contracts.gd` валидирует lab laptop `time_limit`/`penalty_time`, timed-lab minigame scene contract, уникальные `lab_completion_id` там, где сцена требует явные lab IDs, и соответствие `Fridge.required_lab_completion_ids` реальным ноутбукам в той же сцене.
- `tests/cases/test_sql_minigame_authoring_contracts.gd` валидирует typed `SqlDropSlot`/`SqlDragWord` scene contract и запрещает SQL minigames возвращать slot/word glue к method probes.
- `tests/cases/test_fridge_authoring_contracts.gd` валидирует active level feeding/code-lock/final fridge configs, включая typed `FeedingMinigame` scenes, typed `FinalFeedMinigame` scene, typed `FoodItem` food scenes, face/background и code-lock scene.
- `tests/cases/test_search_key_authoring_contracts.gd` валидирует managed `SearchSpot` configs: minigame scene instantiates as `SearchKeyMinigame`, key texture is set, trash textures are non-empty Texture2D entries, trash range is sane, and minigame keeps `SearchArea/KeyButton` plus `SearchArea/TrashContainer`. `SearchSpot` now calls `SearchKeyMinigame.setup(...)` and `get_layout_state()` through typed API instead of `has_method` probes, while `SearchKeyManager` owns the successful-spot listener and marks sibling spots searched-empty itself.
- `tests/cases/test_stu_level_path_contracts.gd` валидирует STU exported route/wiring paths and dynamic door targets.
- `tests/cases/test_localization_contracts.gd` теперь покрывает больше player-facing export-полей и script literals: death/ending UI, note/obstacle prompts, timed lab dialogue exports, key names, money reward reasons, gamepad hints, default gamepad hints, запрет новых ASCII phrase translit keys для русских строк, static `.tscn` non-Cyrillic text contract и прямые GDScript UI call-literals.
- STU doors with intentionally empty targets are now explicitly locked.
- Null override cleanup частично закрыт без bulk Godot reserialization: inherited door/interactable defaults вроде `is_locked`, `required_key_id`, `interact_area_node`, `target_marker` и `one_shot` теперь явно сериализованы как `false`, `""` или `NodePath("")`, а тест запрещает возвращать эти typed config-поля к `null`. Optional resource-null overrides вроде `door_texture = null` оставлены как явное отсутствие ассета.

### 12. STU-уровни слишком завязаны на имена этажей и детей

Статус: закрыто на уровне runtime contracts.

- `tests/cases/test_stu_level_path_contracts.gd` фиксирует STU floor/room paths, fridge paths, exported level-12 wiring paths and dynamic redirect targets before future scene edits.
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
- `MusicScopedSourceRegistry` владеет source metadata, mirror dictionary и `tree_exited` callback wiring для event/distortion music.
- `reset_base_music_state()` чистит event/distortion source registry.
- Regression покрыт в `tests/cases/test_musicmanager_priority_resume_runtime.gd`.

### 16. `InteractiveObject` нет явно unregister-ится из `InteractionManager` при `_exit_tree`

Статус: закрыто.

- `objects/interactable/interactive_object.gd` получил `_exit_tree()` cleanup: dependency disconnect, unregister из `InteractionManager`, сброс player/focus/prompt. Manager-facing action/focus API стал публичным, чтобы центральный input flow не зависел от private string calls.
- Regression покрыт в `tests/cases/test_interaction_manager_focus.gd`.

### 17. `SearchSpot` не выставляет `complete_interaction()` после найденного ключа

Статус: закрыто.

- `objects/interactable/search_spot/search_spot.gd` вызывает `complete_interaction()` после успешного key discovery.
- Контракт зависимостей покрыт в `tests/cases/test_interaction_completion_contracts.gd`.

### 18. `Obstacle` обходит нормальную InteractiveObject-архитектуру

Статус: закрыто контрактом.

- `Obstacle` оставлен как `StaticBody2D` + `InteractArea`, потому что это collision-blocker, а не обычный `Area2D` interactable.
- Runtime-код `Obstacle` типизирует `$InteractArea` как `InteractiveObject` и отключает его через прямой `set_interaction_enabled(false)`, без fallback-а на `has_method("set_interaction_enabled")`.
- `tests/cases/test_obstacle_interaction_contract.gd` проверяет, что `$InteractArea` сохраняет `InteractiveObject` contract, не регистрируется как обычный focused candidate и press-clear flow освобождает obstacle после нужного числа нажатий.
- `tests/cases/test_interaction_architecture_contracts.gd` запрещает возвращать stringly method probe для этого stable child contract.

### 19. Ending scenes и pause classification непоследовательны

Статус: закрыто.

- Ending-сцены оформлены как отдельный `SceneContext` type (`ending_scene`, `res://levels/endings/`).
- `levels/menu/pause_manager.gd` блокирует pause menu поверх menu/ending scenes.
- `ending_screen.gd` и `ending_credits.gd` маркируют себя как ending scenes; локальный blocker в credits оставлен как страховка.
- Regression покрыт в `tests/cases/test_scene_context_pause_classification.gd`.

### 20. CI/export smoke для presets

Статус: закрыто на уровне обычного suite + локального smoke.

- `tests/cases/test_export_presets_contract.gd` проверяет, что `export_presets.cfg` парсится, содержит preset и не уводит `export_path` наружу из repo-local `exports/`.
- Полный локальный smoke `mkdir -p /tmp/eater-loop-ci-export-smoke && godot --headless --path . --export-debug "MacOS" /tmp/eater-loop-ci-export-smoke/EaterLoop.app` прошёл с exit code `0` на машине с installed templates.
- GitHub Actions теперь дополнительно ставит export templates и запускает `godot --headless --path . --export-debug "MacOS" exports/ci/EaterLoop.app` после зелёного runtime suite.
- Signed/notarized release export всё ещё остаётся отдельной release-задачей; CI smoke проверяет, что preset и ресурсы собираются в debug artifact.

### 21. `tests/run_tests.sh` зависит от запуска из root

Статус: закрыто.

- `tests/run_tests.sh` вычисляет project root относительно себя и запускает Godot с `--path "$PROJECT_ROOT"`.
- `tests/README.md` обновлён: helper можно запускать из любого cwd.

### 22. Документация местами stale

Статус: закрыто.

- `docs/audit_tooling_assets_tests.md` обновлён под текущий suite: `OK: all tests passed (114)`.
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
