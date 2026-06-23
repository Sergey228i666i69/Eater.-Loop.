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
- Внутренние helper-и крупных фасадов:
  `GameDirectorDeathTitlePresenter`, `MinigameBackdropPresenter`, `UIFadeController`.
  Они не являются публичными autoload API и используются для снижения размера
  `GameDirector`, `MinigameController` и `UIMessage` без смены внешних вызовов.

## 2. Ключевые контуры

### 2.1 Переходы сцен

- Меню/интеракции переключают сцену через `UIMessage.change_scene_with_fade*`.
- При переходе в игровую сцену `GameDirector` перенастраивает фазу/таймер.
- `GameState` обновляет путь текущей сцены для продолжения забега.
- Тип сцены определяется через `SceneContext`: gameplay, menu и ending имеют отдельные группы/path-классификацию.
- `PauseManager` не открывает pause menu поверх menu/ending scenes.

### 2.2 Музыкальный контур

- Любая музыка должна идти через `MusicManager`.
- Сценовые `LevelMusic`-узлы вызывают только публичные методы `MusicManager`.
- Trigger-зоны управляют музыкой через `TriggerSetProperty` действиями `music_on_*`.

### 2.3 Pause-Контур

- `PauseManager` является владельцем `get_tree().paused` для модальных игровых систем.
- Модальные системы должны использовать `request_pause(owner, reason)` и `release_pause(owner, reason)`, а не локально восстанавливать previous bool.
- Pause menu, notes/hints, pause-game minigames и death screen держат отдельные owner tokens.
- `clear_all_pause_requests()` допустим для hard transition-ов вроде выхода в меню через `change_scene_with_fade(..., unpause_after=true)`.

### 2.4 Контур мини-игр

- Мини-игра регистрируется в `MinigameController.start_minigame(...)`.
- Игра/пауза/cursor/music синхронизируются централизованно в контроллере.
- Backdrop registry/fullscreen backdrop detection вынесены в `MinigameBackdropPresenter`.
- Схема геймпада задаётся через `set_gamepad_scheme`/`clear_gamepad_scheme`.
- Timed lab-мини-игры наследуются от `res://levels/minigames/labs/timed_lab_minigame_base.gd`.
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
- `complete_interaction(...)` является success wrapper и сохраняет legacy `interaction_finished`; failed/cancelled outcomes не должны выставлять `is_completed`.
- Включение/отключение объекта делается через `set_interaction_enabled(...)`, а не прямой раздельной правкой prompt/input флагов.
- Запуск/attach мини-игр делается через `attach_minigame(...)` или `start_managed_minigame(...)`.
- Если зависимость не выполнена, базовый `InteractiveObject` обязан показать `locked_message`, если наследник не переопределил это поведение явно.

### 2.7 Контур input-device detection

- Определение keyboard/mouse/gamepad input-kind должно идти через `InputDeviceUtils`.
- `InteractionPrompts` может отличать Sony gamepad для player-facing button prompt-ов.
- `GameDirector` и `MainMenu` используют тот же helper для переключения input mode и navigation mode.
- Новые проверки устройств не должны дублировать local deadzone/name/GUID эвристики в сценовых скриптах.

### 2.8 Контур визуального рига героя

- `player/player.tscn` является активной skeleton-only сценой игрока; старый png/sequential-sprite вариант сохранён в sprite-only `player/LEGASY-ANIMATIONS-CHARACTER.tscn`.
- `PlayerSkeletonRig` инстансится из `res://player/player_skeleton_rig.tscn` и держит видимые tight-crop `Sprite2D` cutout-части из `Andry.png` как детей костей; cutout-ы кистей, предплечий, таза, бедер и голеней очищены от фрагментов закрывающих их штанов/тела/руки, thigh-слои не владеют поясом/верхом таза, а нижний `VisualSeamFill` является узкой внутренней полосой ткани и не должен нести руки, боковые штанины, статичные ноги или ступни; его нижняя часть fade-ится до голени, чтобы в крайних фазах шага не появлялась вертикальная статичная штанина. Head-cutout берётся source-based маской из исходной головы Андрея: верх головы/волосы не должен быть диагонально срезан, а нижняя левая зона не должна тащить плечо или угол футболки на кости головы. Малые `covers/`-слои на плечах, локтях, коленях и лодыжках прикрывают просветы между сегментами при движении.
- Имена костей рига считаются контрактом для skeletal animation клипов: `Hips`, `Spine`, `Chest`, `Head`, `Front*`, `Back*` и `FlashlightMount`.
- `player.gd` зеркалит риг вместе с направлением игрока, чтобы bone-based skin не расходился с текущим разворотом героя.
- `SkeletonAnimationPlayer` внутри рига держит loop-клипы `idle`, `walk` и `light_run` с cubic-интерполяцией bone-tracks; `idle` даёт лёгкое дыхание корпуса и кистей, а `player.gd` переключает клипы по фактическому движению.
- Размах `walk`/`light_run` намеренно сдержанный: риг построен из фото-cutout частей, поэтому тесты держат нижнюю и верхнюю границу torso/neck counter-sway, leg-swing, foot-lift, foot-roll, foot-stride и мягкого arm/wrist follow-through. Ноги читают шаг, а руки двигаются меньше, чтобы не показывать скрытые на исходной фотографии участки как отдельные оторванные куски.
- Внутренние `Visual*` слои рига не должны иметь отрицательный `z_index`: back-части остаются позади передних частей по порядку отрисовки, но не уходят ниже объектов уровня, которые находятся за игроком.
- Для передней руки используется гибридный порядок слоёв: `VisualFrontUpperArm` находится под корпусом, чтобы torso закрывал фото-шов плеча, а `VisualFrontForearm`/`VisualFrontHand` остаются над корпусом вместе с фонариком. Верх `front_forearm.png` должен fade-иться под верхнюю руку, иначе при ходьбе он читается как жёстко наклеенный прямоугольный elbow-crop.
- Back-leg anchor держится ближе к центру таза, чем исходная широкая разметка ног, чтобы задняя штанина читалась как второй шаг, но не вылезала сбоку прямоугольным фото-блоком.
- У `VisualBackThigh` внешний край слегка taper-ится alpha-каналом: слой остаётся цельной второй ногой, но крайние walk/light_run фазы не должны читать его как жёсткий прямоугольный обрез.
- Фонарик является отдельным cutout-слоем из `AndryWithFlashlight.png` на `FlashlightMount`; его ручка дорисована как цельный скрытый под ладонью сегмент, а слой рендерится под передней кистью, чтобы рука перекрывала середину фонарика как на исходнике. `VisualFlashlight` посажен чуть выше и правее старого offset, потому что внутри texture есть прозрачный верх; видимая ручка должна проходить через зону хвата, а не висеть ниже пальцев. Те же кости и анимации используются для варианта с фонариком и без него.
- Skeleton-only звуки шагов привязаны к contact-time внутри `walk`/`light_run`, а не к независимому таймеру; тест рига сверяет эти таймкоды с нижним краем alpha-пикселей стоп.
- Для дорисовки скрытых частей cutout-ов использовать контролируемый image-edit/inpaint пакет, а не blind text-to-image: `python3 tools/player_cutout_inpaint/build_player_cutout_inpaint_package.py --target front_thigh --out-dir /tmp/andry-cutout-inpaint`. Инструмент кладёт `edit_canvas`, `mask`, `reference_sheet`, `prompt` и `metadata`; существующие visible pixels заперты чёрной частью маски, а белая область даётся только рядом с прозрачным недостающим фрагментом.
- Для визуального QA рига использовать `python3 tools/player_rig_preview/export_player_rig_montage.py --output /tmp/andry_player_rig_montage.png`; для варианта с фонариком добавить `--flashlight`. Инструмент снимает реальные Godot transforms и собирает монтаж поз, включая обе фазы `idle`; для проверки loop-плавности можно экспортировать последовательность на общем canvas: `--sequence-animation walk --output /tmp/andry_walk.gif`.
- Для проверки сценного z-order использовать `python3 tools/player_rig_preview/export_player_rig_scene_context.py --flashlight --output /tmp/andry_player_rig_scene_context.png`. Этот preview сортирует отдельные `Visual*` части по effective z-index, кладёт настоящую дверь за игроком и foreground-стул перед ним, чтобы ловить регрессии, где рука или нога снова уходят за объект позади персонажа.
- Все игровые уровни продолжают ссылаться на `res://player/player.tscn`, поэтому получают новый skeleton-only вариант без точечной замены instances.

## 3. Границы API (важно)

- Внешний код не должен обращаться к приватным `MusicManager._*`.
- Внешний код не должен обращаться к приватным `InteractiveObject._*`.
- Для расчёта итоговой громкости категории использовать публичный
  `MusicManager.resolve_mix_volume_db(...)`.
- Сцены/объекты вызывают только публичные методы autoload-модулей.
- Для специальных death-screen веток используется публичный override-point `CycleLevel.handle_custom_death_screen() -> bool`, без `has_method/call` по строке.
- Чтение/запись runtime-флагов `GameState` должно идти через публичные getter/mutator/consume методы, а не через разрозненные прямые правки полей там, где уже есть API.
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
- Устранена гонка при sync-громкости в кроссфейде базовой музыки.
- Добавлены runtime-тесты для перехода `menu -> level_01_start` и synthetic race.
- Добавлен архитектурный тест, запрещающий внешние вызовы `MusicManager._*`.
- Добавлены публичные UI-каналы `UIMessage.show_dialogue(...)` и `UIMessage.show_notification(...)`.
- Интерактивные зависимости/мини-игры унифицированы вокруг публичного API `InteractiveObject`.
- Лабораторные мини-игры сведены к общему timed-lab base/helper без изменения геймплейной семантики.
- Добавлены архитектурные тесты на запрет private-coupling к `InteractiveObject` и stringly custom death handler.
- Эти изменения не меняют игровой процесс и затрагивают только подкапотную часть.
- Добавлена классификация ending-сцен в `SceneContext` и единое blocking-правило для pause menu поверх концовок.
- Добавлены regression-тесты для music overlay idempotency, flashlight transition blocking, SearchSpot completion, InteractionManager cleanup и fail-forward LLM glitch contract.
- Input-device detection вынесен в `InputDeviceUtils`, а `GameDirector`, `InteractionPrompts` и `MainMenu` переведены на общий helper.
- `InteractiveObject` получил typed outcome/result слой; completed dependencies и финальная laptop-ветка опираются на success outcome.
- `PauseManager` получил owner-token API; UIMessage, MinigameController, pause menu и death screen больше не восстанавливают `get_tree().paused` через локальный previous-bool.
- Добавлены scene-contract validators для critical NodePath/child contracts и отдельные STU path contracts.
- Naming debt закрыт Godot-aware rename-ами с обновлением `.import` и scene/script references.
- `UIMessage`, `MinigameController` и death-title часть `GameDirector` получили facade-preserving helper split-ы.
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
