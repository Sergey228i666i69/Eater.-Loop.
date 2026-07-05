# Обзор архитектуры проекта

Документ фиксирует текущие технические границы проекта: кто за что отвечает,
какие API считаются публичными и какие инварианты должны сохраняться при
рефакторинге.

## 1. Карта autoload-модулей

- `GameState` (`res://levels/cycles/game_state.gd`)
  Хранит состояние текущего забега/цикла, флаги прогресса и данные сохранения.
- `GameDirector` (`res://levels/game_director.gd`)
  Оркестрация времени цикла, фаз искажений, death-screen lifecycle, спавн сталкера.
- `MusicManager` (`res://levels/music_manager.gd`)
  Единая точка управления музыкой (ambient/event/minigame/chase/pause/menu).
- `PauseManager` (`res://levels/menu/pause_manager.gd`)
  Открытие/закрытие pause-меню, pause-blockers и владелец tree-pause tokens.
- `SettingsManager` (`res://levels/menu/settings_manager.gd`)
  Аудио/видео-настройки, загрузка/сохранение `user://settings.cfg`.
- `MinigameController` (`res://levels/minigames/minigame_controller.gd`)
  Жизненный цикл мини-игр (пауза, музыка, cancel, таймер, gamepad-схемы).
- `UIMessage`, `InteractionPrompts`, `CursorManager`, `StaminaBar`, `FlashlightBar`
  UI-слой, системные подсказки, курсор и индикаторы игрока.
- `InputDeviceUtils` (`res://global/input_device_utils.gd`)
  Общий helper определения keyboard/mouse/gamepad/Sony input-событий для UI prompt-ов,
  меню и директорского input-mode state.
- `ReactiveLightContracts` (`res://global/reactive_light_contracts.gd`)
  Canonical groups, registration helpers and getters для reactive light sources
  и generator-required light contracts.
- Внутренние helper-и крупных фасадов и state services:
  `CheckpointDynamicRestore`, `GameDirectorCyclePhaseBridge`, `GameDirectorCycleTimerState`, `GameDirectorDeathCameraCoordinator`, `GameDirectorDeathCursorCoordinator`, `GameDirectorDeathRetryCoordinator`, `GameDirectorDeathScreenReset`, `GameDirectorDeathTitlePresenter`, `GameDirectorDistortionGate`, `GameDirectorDistortionOverlayCoordinator`, `GameDirectorDistortionPhaseState`, `GameDirectorDistortionProgress`, `GameDirectorOverlayLayerCoordinator`, `GameDirectorStalkerService`, `GameDirectorTimerNodeCoordinator`, `GamepadCallbackRouter`, `GamepadConfirmReleaseGate`, `GamepadHintBuilder`, `GamepadNavigationRepeat`, `GamepadNodeResolver`, `GamepadSchemeRegistry`, `MinigameBackdropPresenter`, `MinigameModalOwnership`, `MinigameMusicSession`, `MinigamePromptVisibilityCoordinator`, `MinigameTimerState`, `MusicPauseReasonState`, `UIFadeController`.
  Они не являются публичными autoload API и используются для снижения размера
  `GameDirector`, `GameState`, `MinigameController` и `UIMessage` без смены внешних вызовов.

## 2. Ключевые контуры

### 2.1 Переходы сцен

- Меню/интеракции переключают сцену через `UIMessage.change_scene_with_fade*`.
- Sleep transition у `Bed` тоже идёт через единый `UIMessage.change_scene_with_fade_delay(...)`: next scene загружается до затемнения, поэтому misconfigured bed не оставляет экран чёрным.
- `CycleLevel` использует `SceneContext`, `GameState`, `CycleState` и `UIMessage` как стабильные facade для gameplay marking, checkpoint restore/capture, default flashlight, fridge checkpoint spawn, стартовых subtitle и respawn blackout, без локальных `has_method/call` probes.
- При переходе в игровую сцену `GameDirector` перенастраивает фазу/таймер.
- `GameState` обновляет путь текущей сцены для продолжения забега.
- Тип сцены определяется через `SceneContext`: gameplay, menu и ending имеют отдельные группы/path-классификацию; gameplay также определяется по cycle/timer root contract, path fallback разрешает только playable `res://levels/cycles/level_*.tscn`, а utility-сцены в cycles должны полагаться на группы/API, если им нужна специальная классификация.
- `PauseManager` не открывает pause menu поверх menu/ending scenes.

### 2.2 Музыкальный контур

- Любая музыка должна идти через `MusicManager`.
- Сценовые `LevelMusic`-узлы вызывают только публичные методы `MusicManager`; active/start-on-ready music config должен иметь `AudioStream`.
- Scene-owned `AudioStreamPlayer`/`AudioStreamPlayer2D` должны явно использовать `Music` или `Sounds`; это ловит сцены, где эффект случайно остался на `Master`.
- Trigger-зоны управляют музыкой через `TriggerSetProperty` действиями `music_on_*`; replace/event-start actions должны иметь `music_stream`, а trigger должен содержать хотя бы один property/sfx/music effect.

### 2.3 Pause-Контур

- `PauseManager` является владельцем `get_tree().paused` для модальных игровых систем.
- Модальные системы должны использовать `request_pause(owner, reason)` и `release_pause(owner, reason)`, а не локально восстанавливать previous bool.
- Pause menu, notes/hints, pause-game minigames и death screen держат отдельные owner tokens.
- `clear_all_pause_requests()` допустим для hard transition-ов вроде выхода в меню через `change_scene_with_fade(..., unpause_after=true)`.

### 2.4 Контур мини-игр

- Мини-игра регистрируется в `MinigameController.start_minigame(...)`.
- Start/finish fade transitions мини-игр идут через стабильный `UIMessage.play_fade_sequence(...)` facade; `MinigameController` проверяет только наличие autoload-а, а не метод строкой.
- Игра/пауза/cursor/music синхронизируются централизованно в контроллере.
- Backdrop registry/fullscreen backdrop detection вынесены в `MinigameBackdropPresenter`.
- Suspend/restore lifecycle для `InteractionPrompts` вынесен в `MinigamePromptVisibilityCoordinator`.
- Timer state и одноразовый timeout-флаг вынесены в `MinigameTimerState`; `MinigameController` только эмитит публичные сигналы и решает auto-finish.
- Pause/cursor ownership state вынесен в `MinigameModalOwnership`; helper ходит к typed `PauseManager`/`CursorManager` API напрямую, а публичное поведение `pause_game`/`show_mouse_cursor` остаётся в `MinigameSettings`.
- Music stack/session state вынесен в `MinigameMusicSession`; `MinigameController` сохраняет публичные `stop_minigame_music(...)`/`update_minigame_music(...)` и ходит к `MusicManager` только через его публичный фасад.
- Registry зарегистрированных gamepad-схем вынесен в `GamepadSchemeRegistry`; контроллер сохраняет публичные `set_gamepad_scheme`/`clear_gamepad_scheme`.
- Player-facing gamepad hint policy вынесен в `GamepadHintBuilder`; `GamepadRuntime` сохраняет input/navigation/callback lifecycle.
- Gamepad hint values отображаются через `tr(...)`; русскоязычные hint strings должны иметь ключ в `global/localization/texts.csv`.
- Navigation hold/repeat timing вынесен в `GamepadNavigationRepeat`; `GamepadRuntime` только читает текущее направление и применяет repeat count к active selection.
- Node/NodePath/provider resolving для gamepad-схем вынесен в `GamepadNodeResolver`; он же централизует focusable filtering для invisible/disabled/custom nodes.
- Callback lookup/invoke/consumed semantics для gamepad-схем вынесены в `GamepadCallbackRouter`; `GamepadRuntime` сохраняет порядок игровых переходов и context assembly.
- Confirm, зажатый до старта мини-игры, фильтруется через `GamepadConfirmReleaseGate`; `GamepadRuntime` принимает подтверждение только после release/нового press.
- Схема геймпада задаётся через `set_gamepad_scheme`/`clear_gamepad_scheme`.
- Timed lab-мини-игры наследуются от `res://levels/minigames/labs/timed_lab_minigame_base.gd`.
- `TimedLabMinigameBase` показывает success/failure outcome dialogue через стабильный `UIMessage.show_dialogue(...)` facade без stringly method probes.
- Общий timed-lab helper отвечает за таймер, cleanup, стандартный outcome и post-line для успеха/провала.

### 2.5 Текстовый UI-контур

- `UIMessage` остаётся единой facade-точкой экранного текста.
- Fade tween/token state живёт во внутреннем `UIFadeController`, публичные методы
  `UIMessage.fade_out`, `fade_in`, `play_fade_sequence` и `change_scene_with_fade*`
  остаются внешней точкой интеграции.
- Публичный канал `show_dialogue(...)` используется для нижних реплик/субтитров, с опциональной озвучкой.
- Публичный канал `show_notification(...)` используется для системных сообщений, лута, дверей, блокировок и наград.
- `show_text`, `show_message`, `show_subtitle` считаются legacy-wrapper API и не должны быть основной точкой интеграции в новом коде.

### 2.6 Контур интеракций

- `InteractiveObject` является базовым публичным контрактом интеракции.
- Зависимости между интерактивными объектами задаются через `set_dependency_object(...)` вместе с явным `set_dependency_condition(...)`.
- Доступные dependency-смыслы: `COMPLETED` для typed success outcome dependency и `INTERACTION_REQUESTED` для unlock-а после попытки взаимодействия.
- Любой интерактив может эмитить `interaction_result(result)`, `interaction_succeeded(result)`, `interaction_failed(result)` и `interaction_cancelled(result)`.
- `complete_interaction(...)` является success wrapper и сохраняет legacy `interaction_finished` только для совместимости; новые runtime/scene subscriptions используют typed `interaction_succeeded`, а failed/cancelled outcomes не должны выставлять `is_completed`.
- `InteractionResultBuilder` является канонической точкой сборки result Dictionary: `payload` зарезервирован как typed Dictionary для reward/item/branch data, а top-level custom keys остаются только совместимым слоем.
- `InteractionManager` выбирает focused candidate и вызывает только публичный manager-facing API `InteractiveObject`: `get_interact_action_name()` для action name и `set_manager_focus(...)` для prompt focus. Private hooks вроде `_get_interact_action()` остаются внутренними override-точками самого интерактива.
- `SearchKeyManager.search_spots` резолвятся в `SearchSpot`; manager сбрасывает и выбирает точки через typed API, слушает successful outcome выбранной точки и закрывает sibling spots без обратного поиска manager-а из `SearchSpot`. `SearchSpot.minigame_scene` должен инстанцироваться как `SearchKeyMinigame`, поэтому setup/layout-state вызываются типизированно.
- Включение/отключение объекта делается через `set_interaction_enabled(...)`, а не прямой раздельной правкой prompt/input флагов.
- Запуск/attach мини-игр делается через `attach_minigame(...)` или `start_managed_minigame(...)`.
- Если зависимость не выполнена, базовый `InteractiveObject` обязан показать `locked_message`, если наследник не переопределил это поведение явно.
- Content-object scripts должны использовать стабильные collaborators типизированно: обязательный fridge path резолвится в `Fridge`, а `UIMessage.fade_*` вызывается через facade при `UIMessage != null`, без локальных `has_method/call` probes.

### 2.7 Контур input-device detection

- Определение keyboard/mouse/gamepad input-kind должно идти через `InputDeviceUtils`.
- `InteractionPrompts` может отличать Sony gamepad для player-facing button prompt-ов.
- `GameDirector` и `MainMenu` используют тот же helper для переключения input mode и navigation mode.
- Новые проверки устройств не должны дублировать local deadzone/name/GUID эвристики в сценовых скриптах.
- Runtime string literals в `is_action_*` и gamepad navigation wrappers считаются InputMap contract: новый action нужно добавить в `project.godot`, иначе `test_input_actions.gd` упадёт.

### 2.8 Контур визуального рига героя

- `player/player.tscn` является активной skeleton-only сценой игрока; старый png/sequential-sprite вариант сохранён в sprite-only `player/LEGASY-ANIMATIONS-CHARACTER.tscn`.
- `PlayerSkeletonRig` инстансится из `res://player/player_skeleton_rig.tscn` и держит tight-crop cutout-части из `Andry.png`; активные runtime-слои плеч, предплечий, бедер и голеней теперь рисуются root-level weighted `Polygon2D` mesh-ами (`MeshFrontForearm`, `MeshBackShin` и т.п.), привязанными к sibling `Skeleton2D`. Старые `Visual*` `Sprite2D`-узлы этих конечностей остаются в сцене как скрытые anchors/контракты, но не должны быть видимыми поверх mesh. В активном риге mesh-топология должна использовать explicit contour strip `polygons`, а не внутреннюю центральную колонку вершин: центральные internal-vertices в нативном Godot-render давали тёмные трещины между участками, хотя custom preview мог выглядеть чисто. Cutout-ы кистей, предплечий, таза, бедер и голеней очищены от фрагментов закрывающих их штанов/тела/руки; pelvis-слой не должен нести статичную переднюю кисть, torso-слой не должен нести skin-пиксели статичных боковых рук, нижнюю пижамную полосу или top-right head/chin shard, thigh-слои не владеют поясом/верхом таза и должны мягко fade-иться под футболкой, а нижний `VisualSeamFill` является узкой внутренней полосой ткани и не должен нести руки, боковые штанины, статичные ноги или ступни. Head-cutout берётся source-based маской из исходной головы Андрея: верх головы/волосы не должен быть диагонально срезан, а нижняя левая зона и нижний край не должны тащить плечо, угол футболки или shirt/collar-tail на кости головы; нижний край шеи должен alpha-fade-иться в ворот вместо жёсткой горизонтальной cutout-линии. Малые `covers/`-слои на плечах, локтях, коленях и лодыжках прикрывают просветы между сегментами при движении; `MeshFrontArmSideShadow` является узким skinned shadow-strip между передним предплечьем и торсом, чтобы закрывать native-render background slit без возврата статичной shirt-side texture-плашки. `VisualFrontAnkleCover` должен быстро fade-иться ниже манжеты, чтобы прятать seam, но не становиться статичной пижамной плитой поверх стопы. `VisualNeckCollarCover` оставлен как скрытый QA-якорь, потому что после clean head/torso cutout-ов активный cover снова читался отдельной заплаткой на горле.
- Имена костей рига считаются контрактом для skeletal animation клипов: `Hips`, `Spine`, `Chest`, `Head`, `Front*`, `Back*` и `FlashlightMount`.
- `player.gd` зеркалит риг вместе с направлением игрока, чтобы bone-based skin не расходился с текущим разворотом героя.
- `SkeletonAnimationPlayer` внутри рига держит loop-клипы `idle`, `light_idle`, `walk`, `light_walk`, `run` и `light_run` с cubic-интерполяцией bone-tracks; `idle` даёт плавное дыхание корпуса, головы и кистей, `light_idle` чуть фиксирует переднюю руку вокруг хвата фонарика, а `player.gd` переключает клипы по фактическому движению и наличию фонарика.
- Размах `walk`/`light_walk`/`run`/`light_run` держится в контролируемом коридоре: риг построен из фото-cutout частей, поэтому тесты держат нижнюю и верхнюю границу body-bounce, spine/chest/neck/head counter-sway, leg-swing, foot-lift, foot-roll, foot-stride, arm/forearm/wrist follow-through и flashlight bob. У дальней ноги намеренно сдержанный thigh/shin swing, чтобы фото-фрагменты штанин не выезжали прямоугольными плитками; `idle` тоже даёт мягкий bob фонарика вместе с дыханием руки, `run` для no-flashlight состояния свободнее работает передней рукой и пустой кистью, а `light_walk`/`light_run` удерживают фонарик с отдельным bob, но не меняют contact-time шагов. `run` и `light_run` дополнительно держат небольшой forward-bias корпуса, чтобы бег в тёмном close-up не читался как вертикальная ускоренная ходьба.
- В `run`/`light_run` передний `FrontUpperArm` имеет небольшой forward-bias при сохранённом swing range: это уменьшает фазу, где рука уходит назад и открывает прямой чёрный torso-side gap, не возвращая статичную shirt-side texture-плашку.
- Внутренние `Visual*` слои рига не должны иметь отрицательный `z_index`: back-части остаются позади передних частей по порядку отрисовки, но не уходят ниже объектов уровня, которые находятся за игроком.
- Для передней руки используется гибридный порядок слоёв: root mesh `MeshFrontUpperArm` остаётся ниже корпуса по z-index, чтобы torso закрывал фото-шов плеча, `MeshFrontArmSideShadow` остаётся ниже torso/forearm как движущийся occlusion fill, а `MeshFrontForearm` и кисть `VisualFrontHand` остаются над корпусом вместе с фонариком. Верх `front_forearm.png` должен fade-иться под верхнюю руку, иначе при ходьбе он читается как жёстко наклеенный прямоугольный elbow-crop.
- `MeshFrontUpperArm` правым контуром taper-underlap-ит torso-слой: верх/середина заходят глубже под футболку до x >= -2, а нижний край остаётся сдержанным на x >= -14. `front_upper_arm.png` держит только мягкий skin/shadow-fill на внутреннем правом крае до x <= 74, чтобы заполнять прозрачные пиксели у подмышки/бока без возвращения shirt-side texture-плашки; сама футболка остаётся выше по `z_index` и закрывает шов.
- `MeshFrontForearm` держит небольшой taper-overlap правого верхнего края под локтевым стыком: верхние right-side vertices расширены к `MeshFrontUpperArm`, но нижние vertices у хвата фонарика остаются прежней ширины. Это закрывает чёрный зазор у переднего локтя без превращения `VisualFrontElbowCover` в серую заплатку.
- Дальняя кисть рендерится активным root-level `MeshBackHand`, а старый `VisualBackHand` остаётся скрытым QA-якорем: верх mesh-а получает вес `BackForearm`, низ - `BackHand`, чтобы запястье не читалось отдельной прямоугольной плиткой при walk/light_run.
- Upper-arm cutout-ы должны держать только открытую кожу/тени руки ниже рукава; сам рукав принадлежит `VisualTorso` и shoulder-cover слоям. Если `front_upper_arm.png`/`back_upper_arm.png` снова содержат верхнюю часть футболки, этот кусок начинает вращаться вместе с рукой и выглядит как отдельная наклеенная плитка.
- Back-leg anchor держится ближе к центру таза, чем исходная широкая разметка ног, чтобы задняя штанина читалась как второй шаг, но не вылезала сбоку прямоугольным фото-блоком.
- `VisualBackLegUnderlay` оставлен как отключенный QA-якорь, но в активном рендере скрыт: после перевода ног на weighted `Polygon2D` он начал читаться как прямоугольная статичная заплатка за тазом/рукой, а lower-body continuity теперь должны держать `MeshBackThigh`/`MeshBackShin` и front leg mesh-слои.
- `VisualPelvis` тоже оставлен как отключенный QA-якорь, но не участвует в активном рендере: широкая статичная pelvis-текстура перекрывала работающие thigh-меши прямоугольным блоком, поэтому waist/lower-body continuity должна собираться из `VisualTorso` поверх weighted thigh/shin meshes.
- У `VisualBackThigh` нижние боковые края taper-ятся alpha-каналом: слой остаётся цельной второй ногой, но крайние walk/light_run фазы не должны читать его как жёсткий прямоугольный обрез.
- Фонарик является отдельным cutout-слоем из `AndryWithFlashlight.png` на `FlashlightMount`; его ручка дорисована как цельный скрытый под ладонью сегмент, а слой рендерится под передней held-кистью, чтобы рука перекрывала середину фонарика как на исходнике. `VisualFlashlight` посажен чуть выше и правее старого offset, потому что внутри texture есть прозрачный верх; видимая ручка должна проходить через зону хвата, а не висеть ниже пальцев. Основной skeleton общий, но `player.gd` выбирает `idle`/`walk`/`run` до разблокировки фонарика и `light_idle`/`light_walk`/`light_run` после неё; `FrontHand` держит два совместимых cutout-а кисти: `VisualFrontHandEmpty` из `Andry.png` для no-flashlight состояния и `VisualFrontHand` из `AndryWithFlashlight.png` для хвата фонарика. Пустая кисть дополнительно получает локальный wrist-sway на своём `Sprite2D`, а верх `front_hand_empty.png` мягко alpha-fade-ится под предплечье, чтобы no-flashlight вариант не выглядел как зафиксированный хват фонарика или прямоугольно обрезанная кисть. Не переводить пустую кисть в active `Polygon2D` без отдельного native-render pass по UV/alpha-bbox: прямоугольная геометрия этого cutout-а легко возвращает жёсткий боковой артефакт.
- Skeleton-only звуки шагов привязаны к contact-time внутри `walk`/`light_walk`/`run`/`light_run`, а не к независимому таймеру; тест рига сверяет эти таймкоды с нижним краем alpha-пикселей стоп. Foot-треки `walk`/`light_walk`/`run`/`light_run` держат промежуточные passing-ключи между контактами, чтобы стопа шла дугой без резкого рывка, но сами contact-time точки остаются прежними.
- Для дорисовки скрытых частей cutout-ов использовать контролируемый image-edit/inpaint пакет, а не blind text-to-image: `python3 tools/player_cutout_inpaint/build_player_cutout_inpaint_package.py --target front_thigh --out-dir /tmp/andry-cutout-inpaint`. Инструмент поддерживает ноги, руки, кисти и фонарик, кладёт `edit_canvas`, `mask`, `reference_sheet`, `prompt` и `metadata`; существующие visible pixels заперты чёрной частью маски, а белая область даётся только рядом с прозрачным недостающим фрагментом.
- Следующее направление улучшения качества рига - продолжать чистить source-based cutout-маски вокруг талии/ворота/кистей и расширять mesh-деформацию только через нативную Godot-render проверку. Изолированный прототип остаётся в `res://player/player_skeleton_forearm_mesh_prototype.tscn` для экспериментов с весами без риска для игрового игрока; active rig можно менять только тем подходом, который уже отрисован нативным рендером и закреплён контрактами.
- Для визуального QA рига использовать `python3 tools/player_rig_preview/export_player_rig_montage.py --runtime-motion-set --output /tmp/andry_player_rig_montage.png`, чтобы в одном montage увидеть реальные `idle`/`walk`/`run` no-flashlight состояния и `light_idle`/`light_walk`/`light_run` flashlight состояния. Для отдельных вариантов остаются `--flashlight` и `--sequence-animation walk --output /tmp/andry_walk.gif`. Инструмент снимает реальные Godot transforms и рендерит `Sprite2D`/weighted `Polygon2D` mesh-слои с bone weights; для изолированного mesh prototype использовать `--rig-path res://player/player_skeleton_forearm_mesh_prototype.tscn --animation-player-path AnimationPlayer --sequence-animation forearm_mesh_flex --sequence-frames 5 --output /tmp/andry_forearm_mesh_prototype.png`. После изменений в типах visual-слоёв дополнительно проверять нативный Godot-render активной сцены через `python3 tools/player_rig_preview/export_player_rig_native_frame.py --animation light_run --time 0.1375 --output /tmp/andry_player_rig_native_frame.png`, потому что preview-композитор может скрыть ошибки canvas-рендера.
- Для проверки сценного z-order использовать `python3 tools/player_rig_preview/export_player_rig_scene_context.py --flashlight --output /tmp/andry_player_rig_scene_context.png`. Этот preview сортирует отдельные `Visual*` части по effective z-index, кладёт настоящую дверь за игроком и foreground-стул перед ним, чтобы ловить регрессии, где рука или нога снова уходят за объект позади персонажа; без `--flashlight` sheet показывает `idle`/`walk`/`run`, а с `--flashlight` - `light_idle`/`light_walk`/`light_run`. Для проверки тёмного close-up кадра как в игровых скриншотах использовать `--dark-closeup --pose-animation light_run --pose-time 0.1375`; `--pose-animation` принимает `idle`, `light_idle`, `walk`, `light_walk`, `run` и `light_run`, а для диагностики владельца артефакта добавить `--layer-overlay`.
- Все игровые уровни продолжают ссылаться на `res://player/player.tscn`, поэтому получают новый skeleton-only вариант без точечной замены instances.
- Playable scenes в `res://levels/cycles/` должны называться `level_*.tscn` и иметь root API `get_cycle_number()` / `get_timer_duration()`; non-level utility-сцены в этой папке требуют явного allowlist в `test_level_authoring_contracts.gd`.
- Cycle-level authoring contract требует ровно один Player instance в игровой сцене: respawn, enemies, UI bars и checkpoint flow используют единственный runtime `player`.
- Тот же authoring contract валидирует диапазоны scene-level Player exports для движения, выносливости, фонарика и step timing, а также `LevelMusic` stream/fade config, чтобы новые уровни не могли тихо задать отрицательные тайминги, нулевую скорость, неупорядоченные skeleton step times или активную музыку без stream.

## 3. Границы API (важно)

- Внешний код не должен обращаться к приватным `MusicManager._*`.
- Внешний код не должен обращаться к приватным `InteractiveObject._*`.
- Для расчёта итоговой громкости категории использовать публичный
  `MusicManager.resolve_mix_volume_db(...)`.
- Category offset и clamp policy живут в `MusicMixSettings`; `MusicManager`
  только делегирует туда расчёт и сохраняет совместимый фасад.
- Base/chase pause reason bookkeeping живёт в `MusicPauseReasonState`; `MusicManager`
  синхронизирует старые private mirror-поля только для внутренней совместимости и тестов.
- Ambient suppression source tracking и pending ambient resume request живут в
  `MusicAmbientCoordinator`/`MusicAmbientSuppressionState`; это держит
  bedroom/silent-zone контракты вне основного audio facade.
- Event/distortion source-id metadata и `tree_exited` callback wiring живут в
  `MusicScopedSourceRegistry`; `MusicManager` сохраняет публичный фасад и стековую
  семантику.
- Chase source order/suppression/active-source metadata и `tree_exited` cleanup
  живут в `MusicChaseSourceRegistry`; `MusicManager` сохраняет публичный
  `set_chase_music_source(...)` facade и audio-player lifecycle.
- Сцены/объекты вызывают только публичные методы autoload-модулей.
- Для специальных death-screen веток используется публичный override-point `CycleLevel.handle_custom_death_screen() -> bool`, без `has_method/call` по строке.
- Чтение/запись runtime-флагов `GameState` должно идти через публичные getter/mutator/consume методы, а не через разрозненные прямые правки полей там, где уже есть API.
- `GameState` и `CycleState` считаются стабильными autoload-соседями: их взаимные save/checkpoint/cycle facade-вызовы идут напрямую, с `null` guard только на отсутствие autoload, без `has_method` fallback-ов.
- Приватные методы (`_...`) можно менять без обратной совместимости, поэтому
  внешние зависимости на них считаются архитектурным дефектом.

## 4. Инварианты стабильности

- Исправления не должны менять игровую логику (скорости, урон, тайминги, условия победы).
- Аудио-инвариант спальни: при старте уровня внутри `TriggerBedroomSilent` ambient
  должен быть подавлен до выхода из зоны.
- При кроссфейде базовой музыки команды синхронизации громкости должны
  применяться к фактическому целевому плееру, чтобы не возникало «протекания» звука.
- Повторный `start_event_music(...)` или `start_distortion_music(...)` для того же source не должен добавлять дубликаты в music stack.
- Включение/выключение фонарика блокируется во время black-screen/fade transitions и при заблокированном движении.

## 5. Практика тестирования

- Базовые smoke-проверки: загрузка сцен/скриптов/autoload/input.
- Runtime-регрессии: отдельные async-тесты для переходов и кадро-зависимых гонок.
- Архитектурные инварианты: тесты на отсутствие private-coupling между модулями.

## 6. Изменения (changelog)

- Добавлен публичный API микса `MusicManager.resolve_mix_volume_db(...)`.
- `MusicMixSettings` получил category offset resolver, чтобы `MusicManager` не
  держал mapping offset-полей внутри большого фасада.
- `MusicPauseReasonState` вынес reason-map для base/chase music pause из `MusicManager`
  и получил отдельный focused test.
- `FridgeCodeLockSession` вынес code-lock scene creation и access-code property
  wiring из `Fridge`, сохранив публичный scene/export contract холодильника.
- `FridgeFeedingSession` вынес feeding minigame config/instantiation/setup contract
  из `Fridge`; обычная feeding-сцена должна инстанцироваться как `FeedingMinigame`,
  а некорректная feeding scene теперь fail-closed до выдачи еды.
- `FinalEndingFridge` запускает только typed `FinalFeedMinigame`; неверная final feeding
  scene fail-closed и не засчитывает плохую ветку.
- `FridgeCompletionSession` вынес post-feeding world hooks из `Fridge`: cycle
  marks, chase cleanup, teleport и checkpoint/autosave fallback теперь тестируются отдельно.
- Устранена гонка при sync-громкости в кроссфейде базовой музыки.
- Добавлены runtime-тесты для перехода `menu -> level_01_start` и synthetic race.
- Добавлен архитектурный тест, запрещающий внешние вызовы `MusicManager._*`.
- Добавлены публичные UI-каналы `UIMessage.show_dialogue(...)` и `UIMessage.show_notification(...)`.
- Интерактивные зависимости/мини-игры унифицированы вокруг публичного API `InteractiveObject`.
- Лабораторные мини-игры сведены к общему timed-lab base/helper без изменения геймплейной семантики.
- Добавлены архитектурные тесты на запрет private-coupling к `InteractiveObject` и stringly custom death handler.
- Эти изменения не меняют игровой процесс и затрагивают только подкапотную часть.
- Добавлена классификация ending-сцен в `SceneContext` и единое blocking-правило для pause menu поверх концовок.
- Добавлены regression-тесты для music overlay idempotency, flashlight transition blocking, SearchSpot completion, InteractionManager cleanup/public action-focus API и fail-forward LLM glitch contract.
- Event/distortion music sources теперь scoped к `Node.tree_exited`: удалённый trigger/controller автоматически освобождает registry/stack entry через `MusicScopedSourceRegistry`.
- Input-device detection вынесен в `InputDeviceUtils`, а `GameDirector`, `InteractionPrompts` и `MainMenu` переведены на общий helper.
- `InteractiveObject` получил typed outcome/result слой; completed dependencies и финальная laptop-ветка опираются на success outcome.
- Level-12 money interactables (`Blockpost`, student reward, laptop reward) резолвят typed `Level12MoneySystem`; scene contracts запрещают подменять его случайным узлом с похожими методами.
- `PauseManager` получил owner-token API; UIMessage, MinigameController, pause menu и death screen больше не восстанавливают `get_tree().paused` через локальный previous-bool.
- Добавлены scene-contract validators для critical NodePath/child contracts, scene audio-bus contracts, typed interaction signal subscriptions, runtime input action literals, utility-level NodePaths, content-object typed collaborators, cycle/LevelMusic/lab/fridge/search-key-level authoring contracts, configured trigger target/property/effect/music-stream wiring, key-door/search-key wiring, checkpoint participant stable paths и отдельные STU exported route/path contracts.
- `CheckpointDynamicRestore` вынес enemy-only factory restore allowlist, dynamic restore metadata и parent resolution из `CheckpointSceneSnapshot`.
- Localization validator покрывает death/ending UI, note/obstacle prompts, timed lab dialogue exports, key names и money reward reasons; death-title presenter локализует default и sequence titles через `tr(...)`.
- Naming debt закрыт Godot-aware rename-ами с обновлением `.import` и scene/script references.
- `UIMessage`, `MinigameController` backdrop/prompt/timer/modal/music-session/gamepad-registry lifecycle, `MusicManager` pause-reason bookkeeping, `GamepadRuntime` hint/repeat/resolving/callback/confirm-release policy, CycleState phase bridge, cycle timer/checkpoint state, timer node lifecycle, death-title часть, death entry presentation setup, death fade/tween setup, death sequence state, stalker spawn/checkpoint часть, overlay layer policy, death cursor/input policy, death camera capture/restore, death retry restore/darken/reload policy, death screen reset/cleanup, minigame distortion gate, distortion progress/easing math, distortion overlay/material actuator и distortion phase/checkpoint state `GameDirector` получили facade-preserving helper split-ы.
- Добавлен скелетный `PlayerSkeletonRig` и активный skeleton-only `player.tscn`.
- `PlayerSkeletonRig` получил первые loop-клипы `idle`, `walk` и `light_run`, а `Player` начал переключать их вместе с текущей логикой движения.
- Активный `player.tscn` переведён на skeleton-only визуал, старый png-вариант сохранён в sprite-only `LEGASY-ANIMATIONS-CHARACTER.tscn`.
- Полигональный placeholder заменён на cutout-части из `Andry.png` и отдельный flashlight cutout из `AndryWithFlashlight.png`; шаги skeleton-only варианта теперь срабатывают по foot-contact точкам анимации и закреплены визуально-звуковым тестом.
- Cutout-текстуры героя обрезаны по alpha bounds, а `Visual*` позиции компенсированы в риге; это убирает full-canvas pivot-регрессию, из-за которой части тела разлетаются при bone rotation.
- Добавлен reproducible inpaint-prep инструмент для дорисовки скрытых участков cutout-частей без изменения уже видимых пикселей Андрея.
- Фонарик получил завершённую ручку в hidden-under-hand зоне, чтобы skeletal movement больше не показывал два разорванных фрагмента фонарика.
- `VisualSeamFill` пересобран как narrow internal cloth strip, чтобы за скелетными ногами больше не оставались статичные руки/ноги из исходной фотографии.
- Верхний пояс/таз убран из `VisualFrontThigh` и `VisualBackThigh`, чтобы эти cutout-ы не таскали неподвижный waistband при rotation-треках бедер.
- Back-слои рига подняты из отрицательных `z_index`, чтобы двери и другие объекты за игроком больше не отрезали руку или ногу.
- `walk`/`light_run` получили более сдержанный arm-swing и leg-stride, а cutout-ы корпуса/ног очищены от detached alpha-островков, чтобы руки и боковые фрагменты брюк не выглядели как артефакты при движении.
- Head-cutout пересобран из исходной фотографии с узкой source-based маской и прозрачным padding: голова больше не выглядит диагонально обрезанной, но плечо/угол футболки не вращаются вместе с костью головы.
- `VisualFlashlight` сдвинут внутрь front-hand grip: фонарик остаётся под кистью по z-index, но видимая ручка больше не проваливается ниже ладони из-за верхнего прозрачного padding в cutout texture.
- Нижний alpha-хвост `seam_fill.png` укорочен плавным fade, чтобы internal fill закрывал верхний зазор между ногами, но не превращался в длинную вертикальную штанину у лодыжек на walk-кадрах.
- Добавлен scene-context preview для рига с реальными room/door/chair ассетами и effective z-order сортировкой отдельных `Visual*` слоёв.
- Передняя верхняя рука переложена под torso-слой, а forearm/hand остаются поверх корпуса, чтобы уменьшить двойные плечи без обруба кисти.
- BackThigh anchor сдвинут ближе к центру таза, чтобы крайние walk/light_run фазы не показывали заднюю штанину как отдельный боковой прямоугольник.
- Внешний alpha-край `back_thigh.png` смягчён, чтобы второй шаг меньше выглядел как прямоугольный фото-фрагмент.
- Верхний alpha-край `front_forearm.png` смягчён, чтобы передняя рука в walk/light_run не показывала прямоугольный шов предплечья поверх плеча/корпуса.
- `walk` и `light_run` получили более читаемый foot-roll на обеих стопах, чтобы skeletal-анимация не выглядела как движение жёстких плоских блоков; contact-times шаговых звуков остались теми же.
- Компактный `VisualNeckCollarCover` оставлен как выключенный QA-якорь на chest-side seam: активный рендер полагается на чистые head/torso cutout-ы, потому что включённый cover снова читался отдельной заплаткой на горле.
- `front_shin.png` очищен от detached тёмного source-gap strip на правом внешнем крае, а нижний внешний край дополнительно alpha-taper-ится, чтобы walk/light_run фазы не показывали отдельный прямоугольный хвост или острый trouser-shard рядом со стопой.
- `walk`/`light_run` держат заметный body-bounce, foot-lift и arm/forearm/wrist follow-through, но thigh-swing снова ограничен под фото-cutout Андрея: в игровом масштабе движение остаётся читаемым без боковых прямоугольников штанин; шаговые contact-times сохранены прежними.
- Края skeleton `cutouts/` и `covers/` локально defringe-нуты без изменения alpha-силуэта, чтобы в тёмных сценах не проступал жёлто-синий ореол исходного вырезания. Нижний правый collar-tail у `head.png` дополнительно приглушён по alpha, чтобы серый кусок воротника не вращался вместе с головой поверх torso-слоя.
- `seam_fill.png` дополнительно укорочен выше нижней голени, чтобы idle/walk/run не показывали статичный вертикальный cloth-tail между движущимися ногами.
- `FrontHand` получил отдельный `front_hand_empty.png` из `Andry.png`: no-flashlight модель больше не использует сжатую кисть-хват от flashlight исходника, при этом скелет и анимационные клипы остаются общими.
- Края `front_hand.png`, `front_hand_empty.png` и `back_hand.png` дополнительно defringe-нуты по alpha: пальцы и складки остаются, но тёмный source-matte вокруг кистей не должен читать их отдельными наклеенными cutout-плашками.
- Нижние боковые края `back_thigh.png` дополнительно alpha-taper-нуты, чтобы второй шаг в walk/light_run не выглядел отдельной прямоугольной плашкой сбоку от основной ноги.
- `VisualFrontThigh` рендерится ниже `VisualPelvis`, а внешний левый край `front_thigh.png` alpha-taper-нут плавным hip-contour: верх бедра уходит под пояс, и крайние walk/light_run фазы больше не показывают переднюю штанину как отдельную прямоугольную плитку.
- `light_run` остаётся активнее `walk` по bounce, foot-lift, foot-roll, arm/wrist follow-through и spine sway; дополнительная читаемость лёгкого бега теперь идёт через таз и стопы, а не через широкий thigh-swing, чтобы задняя и передняя штанины не читались отрезанными блоками. Contact-times шаговых звуков сохранены на прежних 0.1375/0.4125.
- `front_upper_arm.png` очищен от бокового хвоста футболки: вместе с рукой должен вращаться только рукав/плечо, а не серый кусок корпуса, который в walk/light_run читается как дубль руки.
- Нижний hand-tail убран из `back_forearm.png`: заднее предплечье теперь taper-ится в узкое запястье, а кисть остаётся единственным владельцем `back_hand.png`, чтобы walk/light_run не показывали двойную ладонь.
- Нижний torso-tail убран из `back_upper_arm.png`: задняя верхняя рука больше не таскает серую боковую полосу футболки при повороте кости, а остаётся узким слоем рукава/руки под torso.
- Внутренний правый край `back_upper_arm.png`/`back_forearm.png` дополнительно alpha-taper-нут: в native-render кадре дальней руки он должен читаться мягкой тенью, а не прямым вертикальным надрезом между рукой и корпусом.
- Skin-пиксели статичных боковых рук удалены из `torso.png`, чтобы torso не дублировал скелетные руки при walk/light_run; внутренний край `back_shin.png` дополнительно alpha-taper-нут, чтобы дальняя голень не читалась прямым обрезанным блоком.
- Боковые edge-пиксели `torso.png` дополнительно очищены от тёмного source-matte ниже плеча: футболка должна мягко перекрывать скелетные руки, а не рисовать чёрную вертикальную щель вдоль подмышки/бока.
- Нижняя пижамная полоса удалена из `torso.png`, а верх `front_thigh.png`/`back_thigh.png` получил alpha fade-in после очищенного waistband: штаны теперь уходят под футболку мягче и не стартуют жёсткой прямоугольной полосой.
- Верх `seam_fill.png` получил короткий приглушённый waist bridge из trouser-only текстуры, чтобы под футболкой не читался чёрный прямоугольный провал; ниже bridge слой остаётся короткой полупрозрачной внутренней полосой и не возвращает старую широкую pelvis-плашку или статичную штанину между движущимися ногами.
- Боковые края `front_upper_arm.png`, `front_forearm.png`, `back_upper_arm.png`, `back_forearm.png` и обе стороны `back_shin.png` дополнительно alpha-taper/defringe-полированы: при bone rotation они должны читать мягкий фото-cutout, а не прямоугольную плашку поверх корпуса или ноги. У дальней руки `back_upper_arm.png`/`back_forearm.png` дополнительно убрана видимая тёмная edge-fringe кайма, потому что на тёмном native-render фоне она читалась как чёрная пила вдоль руки.
- Края arm-cutout-ов дополнительно очищены от почти чёрных непрозрачных source-matte пикселей, особенно на `front_upper_arm.png`: weighted `Polygon2D` деформирует текстуру, но не должен растягивать грязную тёмную кромку поверх корпуса. Левый видимый край `front_upper_arm.png` alpha-muted под строгий лимит на тёмную edge-fringe кайму, оставляя настоящую объёмную тень руки.
- Внешние контуры `front_foot.png` и `back_foot.png` defringe/alpha-soften-нуты по краю: пальцы, подошвенные тени и складки штанин остаются, но стопы не должны нести тёмную source-matte окантовку на dark native-render фоне.
- `VisualFrontElbowCover` приглушён по alpha и сдвинут ближе к forearm seam: он должен прятать резкий стык верхней руки и предплечья, но не читаться отдельным серым овалом поверх руки.
- `front_forearm.png` очищен от слабого бокового alpha-ореола, а нижний внешний контур `back_shin.png` дополнительно taper-ится по ширине: дальняя голень не должна читаться как отдельная прямоугольная плашка в поздних кадрах walk/light_run.
- `walk`/`light_run` получили промежуточные passing-ключи на position/rotation треках обеих стоп и более сдержанный swing дальней thigh/shin пары; шаговые contact-times для звуков не менялись.
- Изолированный `Polygon2D` forearm mesh prototype с внутренними vertices и двумя bone-weight наборами оставлен как QA-прототип более сложной деформации. Активный игрок использует более консервативные root-level `Polygon2D` contour-strip mesh-и без внутренних center-vertices, потому что этот вариант прошёл native-render проверку без трещин.
- Нижний контур `back_shin.png` ещё сильнее сужен alpha-taper-ом, а inpaint-prep инструмент получил arm-targets (`front_upper_arm`, `back_upper_arm`, `front_forearm`, `back_forearm`), чтобы будущая дорисовка скрытых частей рук шла через locked-pixel маски, а не свободную генерацию новой руки.
- `back_forearm.png` дополнительно очищен до skin-only предплечья: серо-синий хвост корпуса/штанов больше не должен ехать вместе с костью дальней руки и читаться как дубликат тела в walk/light_run. Контур `back_hand.png` дополнительно defringe/alpha-soften-нут, чтобы дальняя кисть на тёмном native-render фоне не читалась чёрной cutout-наклейкой.
- `idle` получил более плавный пятиключевой дыхательный цикл, а `walk`/`light_run` усилены через head counter и forearm/wrist follow-through вместо расширения leg stride: это оживляет варианты с фонариком и без фонарика, не возвращая прямоугольные артефакты штанин.
- `walk`/`light_run` получили контрактный chest counter-sway: бег стал читаться через верх корпуса, а не через дальнейшее расширение foot-stride, которое уже находится у безопасной верхней границы для фото-cutout ног.
- `FlashlightMount` получил собственный малый rotation bob в `walk` и более заметный в `light_run`: вариант с фонариком перестаёт выглядеть как полностью приклеенная к кисти горизонтальная палка, а no-flashlight вариант остаётся тем же, потому что слой фонарика скрыт.
- `VisualFrontHandEmpty` получил собственный локальный wrist-sway в `idle`/`walk`/`light_run`: no-flashlight вариант кисти теперь чуть свободнее, не меняя held-hand cutout для фонарика.
- `FlashlightMount` теперь участвует и в `idle`: маленький breathing-bob держит flashlight-вариант живым даже без движения игрока.
- `light_run` получил немного более широкий foot-stride на passing/contact keys: бег читается бодрее, но диапазон всё ещё закреплён контрактом ниже уровня, где фото-cutout штанины снова распадаются на прямоугольные блоки.
- Добавлен отдельный `run` для no-flashlight состояния: он наследует безопасную работу ног из `light_run`, но передняя рука, предплечье и пустая кисть двигаются свободнее, а `player.gd` переключается на `light_run` только когда фонарик действительно доступен.
- Добавлен отдельный `light_walk` для flashlight-состояния: обычная ходьба с фонариком чуть стабильнее держит переднюю руку, но сам фонарик получает больший bob; `player.gd` выбирает его только после разблокировки фонарика.
- `run`/`light_run` получили лёгкий forward-bias корпуса, шеи и головы без изменения foot contact-time: бег должен читаться активнее в dark close-up, не расширяя уже безопасные диапазоны ног и фонарика.
- Добавлен отдельный `light_idle` для flashlight-состояния: стоящий Андрей с фонариком держит переднюю руку и фонарик в отдельной breathing-позе, а runtime больше не показывает обычный empty-hand idle с просто включённым cutout-ом фонарика.
- Активные runtime-конечности закреплены как root-level weighted `Polygon2D` после нативной Godot-render проверки: плечи, предплечья, бёдра и голени используют explicit contour strip `polygons` без внутренних center-vertices, а старые `Visual*` Sprite2D остаются скрытыми QA-якорями.
