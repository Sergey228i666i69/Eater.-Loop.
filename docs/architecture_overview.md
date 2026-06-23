# Обзор архитектуры проекта

Документ фиксирует текущие технические границы проекта: кто за что отвечает,
какие API считаются публичными и какие инварианты должны сохраняться при
рефакторинге.

## 1. Карта autoload-модулей

- `GameState` (`res://levels/cycles/game_state.gd`)
  Хранит состояние текущего забега/цикла, флаги прогресса и данные сохранения.
- `GameDirector` (`res://levels/game_director.gd`)
  Оркестрация времени цикла, фаз искажений, death-screen, спавн сталкера.
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
- Схема геймпада задаётся через `set_gamepad_scheme`/`clear_gamepad_scheme`.
- Timed lab-мини-игры наследуются от `res://levels/minigames/labs/timed_lab_minigame_base.gd`.
- Общий timed-lab helper отвечает за таймер, cleanup, стандартный outcome и post-line для успеха/провала.

### 2.5 Текстовый UI-контур

- `UIMessage` остаётся единой facade-точкой экранного текста.
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
