# Игровой Цикл, Уровни, Враги И Мини-Игры

Оценка проблемности среза: **7/10**.

## Карта Цикла

Основной поток держится на autoload-состоянии и level scripts:

1. Уровень стартует через [`levels/cycles/level.gd`](../levels/cycles/level.gd), около строки 52.
2. `GameDirector` на смене сцены запускает таймер/искажение: [`levels/game_director.gd`](../levels/game_director.gd), около строки 427.
3. Холодильник отмечает `ate`/`fridge_interacted` и делает checkpoint: [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строки 267.
4. Кровать переводит на следующий уровень: [`objects/interactable/bed/bed.gd`](../objects/interactable/bed/bed.gd), около строки 63.

## Resolved: Sleep/Wake Spawn-Флаг Теряется

`Bed` вызывает `CycleState.queue_sleep_spawn()`, но затем перед сменой сцены через `UIMessage` вызывается `GameState.next_cycle()`. `next_cycle()` сбрасывает `CycleState`, а reset чистит `pending_sleep_spawn`.

Файлы:

- [`objects/interactable/bed/bed.gd`](../objects/interactable/bed/bed.gd), около строки 63.
- [`player/ui_message.gd`](../player/ui_message.gd), около строки 514.
- [`levels/cycles/cycle_state.gd`](../levels/cycles/cycle_state.gd), около строки 232.

Практический эффект: следующий `Bed._ready()` почти всегда не увидит pending wake spawn и не проиграет wake SFX/событие.

Статус: закрыто. `GameState.next_cycle()` переносит pending sleep spawn через reset cycle-state, а `test_level_checkpoint_spawn.gd` фиксирует контракт.

## Resolved: Чекпоинты Не Восстанавливают Динамических Врагов

Изначально `GameState` сохранял пути `checkpoint_stateful` нод, но при apply пропускал отсутствующие ноды. После ремонта checkpoint entry для runtime enemy хранит `scene_path`, `parent_path`, `node_name` и snapshot, а restore пересоздаёт отсутствующую dynamic-ноду перед применением snapshot.

Файлы:

- [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строк 314 и 366.
- [`objects/environment/smart/target/target.gd`](../objects/environment/smart/target/target.gd), около строки 222.
- [`levels/game_director.gd`](../levels/game_director.gd), около строки 1040.

Также `TargetMonsterSpawner` запоминает spawned enemy и восстанавливает его локально, а `GameDirector` сохраняет/восстанавливает spawned stalker snapshot.

Покрытие: `test_respawn_checkpoint_restore.gd` проверяет обычный scene snapshot, dynamic enemy recreation и `TargetMonsterSpawner` restore без дублей.

## Resolved: После Концовки Run Не Закрывается

Credits возвращают в меню и ставят только meta-флаг дисклеймера, но не вызывают `GameState.reset_run()`. Главное меню включает Continue по `has_active_run`/`last_scene_path`.

Файлы:

- [`levels/endings/ending_credits.gd`](../levels/endings/ending_credits.gd), около строки 195.
- [`levels/menu/main_menu.gd`](../levels/menu/main_menu.gd), около строки 121.

Практический эффект: после хорошей/плохой концовки можно получить Continue в старый финальный run.

Статус: закрыто минимально. Credits сбрасывают active run через `GameState.reset_run()`, а тест фиксирует, что Continue не остаётся привязанным к финальному run.

## Resolved: Потолочный Враг Игнорирует Лампы

В [`enemies/light_ceiling/enemy_ceiling.gd`](../enemies/light_ceiling/enemy_ceiling.gd), около строки 110, проверка `is_point_lit` стоит после `continue` внутри ветки `if not has_method`. Поэтому этот блок фактически недостижим.

Практический эффект: игрок ожидает светочувствительное поведение, но конкретный враг не замораживается лампой.

Статус: закрыто. Проверка света вынесена в достижимую ветку; focused light contract покрыт тестами.

## P2: Мини-Игры Не Блокируют Общий Interact

`InteractiveObject._unhandled_input()` продолжает слушать `interact`, если игрок в зоне. `MinigameController` обрабатывает cancel/gamepad, но не ставит глобальный запрет интерактов.

Файлы:

- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строки 109.
- [`levels/minigames/minigame_controller.gd`](../levels/minigames/minigame_controller.gd), около строки 73.
- [`project.godot`](../project.godot), около строки 109: пересечение input actions.

Практический эффект: во время мини-игры можно повторно дернуть холодильник, дверь, кровать или другой интерактив.

Ремонт: `InteractionManager` должен спрашивать `MinigameController.is_active()` и consume input.

## P2: Таймаут Мини-Игры Может Спамить События

Когда `_time_left <= 0`, `minigame_time_expired` эмитится каждый кадр, если `auto_finish_on_timeout=false`.

Файл: [`levels/minigames/minigame_controller.gd`](../levels/minigames/minigame_controller.gd), около строки 346.

Некоторые лабы защищаются своим `_is_finished`, например [`levels/minigames/labs/sql/sql_minigame.gd`](../levels/minigames/labs/sql/sql_minigame.gd), около строки 149, но это хрупкий контракт.

Ремонт: одноразовый `_timeout_emitted` внутри controller.

## P2: Холодильник Fail-Open

Если `minigame_scene` или `food_scenes` не назначены, холодильник сразу вызывает `_finish_feeding_logic()` и засчитывает еду.

Файлы:

- [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строк 211 и 267.

Практический эффект: production misconfiguration превращается в бесплатный прогресс.

Ремонт: fail-closed с явной ошибкой в debug/test и безопасным player-facing отказом в release.

## P2/P3: Дублирование И Мёртвый Прогресс

- `running_unlocked` сохраняется в [`levels/cycles/game_state.gd`](../levels/cycles/game_state.gd), около строки 14, но player смотрит на scene-export `allow_running` в [`player/player.gd`](../player/player.gd), около строки 203.
- Door/fridge redirects размазаны по нескольким level scripts: `level_07_doors.gd`, `level_11_stu_1.gd`, `level_13_stu_3.gd`.
- Движение/анимация частично дублируются между player, runner, stalker и light-sensitive enemies.

## Риски Производительности

- `enemy_flashlight_base` каждый physics frame сканирует `reactive_light_source` и probe-точки.
- Stalker регулярно строит door route через двери и raycasts.
- Некоторые враги грузят animation frames в `_ready()` через файловую систему.

На маленьких сценах это терпимо, но на плотных уровнях может дать статтер.
