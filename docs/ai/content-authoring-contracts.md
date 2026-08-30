# Контракты Добавления Контента

Этот документ - сжатая нормативная версия `../content_authoring_guide.md`.
Если нужен расширенный контекст по конкретному правилу, открой старый guide,
но перед правками сверяйся с кодом и тестами.

## Новый Уровень

Начинай с `levels/templates/cycle_level_template.tscn`.

Обязательные правила:

- Реальный playable уровень сохраняй как `levels/cycles/level_XX_name.tscn`.
- Root script должен быть `CycleLevel`.
- В сцене ровно один Player instance из `res://player/player.tscn`.
- `cycle_number` положительный.
- `timer_duration` неотрицательный.
- Есть хотя бы одна кровать с loadable `next_level_path`.
- `next_level_path` не self-loop и ведёт только в cycle-level или ending scene.
- Root exported `*_path` поля либо optional и пустые, либо резолвятся и имеют
  ожидаемый тип.
- `LevelMusic` с `play_on_ready=true` или stop-on-exit обязан иметь stream.
- Scene-owned audio players явно используют bus `Music` или `Sounds`.

Если новый уровень вводит route/wiring path, dynamic redirect, особую дверь,
лабораторную зависимость или custom checkpoint state - добавь focused validator.

## Интерактивы

Начинай с `objects/interactable/templates/basic_interactive_template.tscn`.

Правила:

- Объект в interaction flow наследуется от `InteractiveObject`.
- Взаимодействие принимает `InteractionManager`, а не локальный параллельный
  input handler.
- `complete_interaction()` вызывается только после реального success outcome.
- Dependency condition задаётся явно:
  - `COMPLETED` - unlock после success;
  - `INTERACTION_REQUESTED` - unlock после попытки.
- Для reward/item/branch data используй `InteractionResultBuilder.with_payload(...)`
  или специализированный helper.
- `set_interaction_enabled(...)` - публичный способ включать/выключать объект.
- Не подписывай новые сцены на legacy `interaction_finished`.

## Двери, Ключи И Поиск

- Дверь с `required_key_id` должна иметь источник ключа в той же сцене:
  `SearchSpot.key_id`, `Key.key_id` или `Note.reward_key_id`.
- `target_marker` должен резолвиться. Self-target допустим только для inert/locked
  двери.
- `SearchKeyManager.search_spots` непустой и каждый path ведёт к `SearchSpot`.
- Managed `SearchSpot` должен иметь:
  - typed `SearchKeyMinigame`;
  - `key_id`;
  - `key_texture`;
  - непустой `trash_textures`;
  - валидный диапазон `trash_min`/`trash_max`.

## Холодильники И Лабы

Lab laptop:

- Начинай с `objects/interactable/templates/lab_laptop_template.tscn`.
- `lab_completion_id` непустой и уникальный, когда уровень требует явные ID.
- `time_limit` положительный, `penalty_time` неотрицательный.
- `minigame_scene` инстанцируется как `TimedLabMinigameBase`.

Feeding fridge:

- Начинай с `objects/interactable/templates/feeding_fridge_template.tscn`.
- `minigame_scene` инстанцируется как `FeedingMinigame`.
- `food_scenes` непустой, каждая сцена инстанцируется как `FoodItem`.
- `food_count` положительный.
- `andrey_face` и `background_texture` заданы.

Code-lock/final fridge:

- Code-lock fridge имеет непустой `access_code` и lock scene с `unlocked`.
- Final fridge использует `FinalFeedMinigame`.
- Required lab IDs холодильника должны ссылаться на реальные ноутбуки в той же
  сцене.

## Свет, Генератор И Враги

- Reactive light source регистрируется через
  `ReactiveLightContracts.register_reactive_light_source(self)` и объявляет
  `is_point_lit(point: Vector2)`.
- Generator-required light/lamp регистрируется через соответствующий helper и
  объявляет `turn_on()`.
- Враги читают свет через `ReactiveLightContracts`, а не через локальные
  `has_method/call` probes.
- `TargetMonsterSpawner` с `enemy_scene` обязан явно задавать condition.

## Мини-Игры И Gamepad

- Timed lab logic - через `TimedLabMinigameBase`.
- Input action literals должны существовать в `project.godot`.
- Gamepad scheme:
  - регистрируется в `_ready()`;
  - снимается в `_exit_tree()`;
  - использует providers для динамических узлов.
- Не эмулируй мышь для gamepad. См. `../minigame_gamepad_system.md`.
- Timeout/cancel/fail-forward должны быть одноразовыми.

## Локализация

- Все player-facing строки добавляй в `global/localization/texts.csv`.
- Заполняй `keys`, `ru`, `en`.
- Для scene Inspector полей допускается key, совпадающий с русской строкой,
  если это уже принятая модель для текущего текста.
- Для script UI вызовов предпочитай semantic key и `tr("key")`.
- Не добавляй новые translit keys вроде `nazhmi_knopku`.

## Ассеты, Import И UID

- Source assets и `.import` должны быть tracked.
- Бинарные ассеты идут через Git LFS.
- Новые `.gd` и `.gdshader` коммить вместе с `.uid`.
- Если UID не появился, запусти `godot --headless --path . --import`.
- Export paths должны оставаться внутри `exports/`.

## Когда Добавлять Validator

Добавляй focused test, если правило можно выразить как:

- required child name or `NodePath`;
- root script/type contract;
- required group/signal/property;
- authored config должен быть непустым или typed;
- player-facing text должен иметь localization key;
- checkpoint state должен сохраняться;
- runtime object должен восстанавливаться;
- public facade не должен возвращаться к stringly private calls.
