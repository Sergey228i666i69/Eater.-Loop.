# Интерактивные Объекты И Scene Contracts

Оценка проблемности среза: **7/10**.

## Диагноз

База `InteractiveObject` полезная, но вокруг неё выросла сеть неявных контрактов: кто-то ждёт `is_completed`, кто-то слушает сигнал, кто-то ищет ребёнка по имени, кто-то требует группу или метод `turn_on`. Это пока работает за счёт дисциплины сцен, но уже даёт реальные gameplay-ловушки.

## P1: Dependency-Система Может Запирать Прогресс

`InteractiveObject` ждёт `dependency_object.is_completed` и `interaction_finished`, но `Door` при успешном использовании не всегда вызывает `complete_interaction()`. В `level_04_findkey` несколько `SearchSpot` завязаны на дверь `ToBedroom`.

Файлы:

- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строк 73 и 216.
- [`objects/interactable/door/door.gd`](../objects/interactable/door/door.gd), около строки 60.
- [`levels/cycles/level_04_findkey.tscn`](../levels/cycles/level_04_findkey.tscn), около строки 1725.

Практический эффект: поиск ключа может остаться навсегда заблокированным, хотя игрок уже выполнил ожидаемое действие.

Ремонт: разделить `interaction_requested`, `interaction_succeeded`, `completed_forever`; зависимости должны смотреть на явный outcome.

## P1: Нет Единого Фокуса Интерактива

Каждый `InteractiveObject` сам слушает `_unhandled_input`. Если игрок стоит в нескольких Area2D, одно нажатие может активировать несколько объектов.

Файл: [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строк 109 и 123.

Особенно опасно для:

- дверей;
- холодильника;
- ноутбука;
- ламп;
- прожекторов;
- кровати.

Ремонт: единый `InteractionManager`, который выбирает один объект по priority/distance, показывает одну подсказку и consume-ит input.

## Resolved: Деньги Level 12 Плохо Переживают Чекпоинты

Изначально `Level12MoneySystem` хранил `_money`, но не входил в `checkpoint_stateful` и не имел `capture_checkpoint_state` / `apply_checkpoint_state`. `StudentMoneyNPC` хранил `_reward_given`, но не сохранял это состояние поверх базового `is_completed`.

Файлы:

- [`objects/interactable/level12/money/level12_money_system.gd`](../objects/interactable/level12/money/level12_money_system.gd), около строки 13.
- [`objects/interactable/level12/money/level12_money_system.tscn`](../objects/interactable/level12/money/level12_money_system.tscn), около строки 5.
- [`objects/interactable/level12/student/student_money_npc.gd`](../objects/interactable/level12/student/student_money_npc.gd), около строки 11.
- [`levels/cycles/level_12_STU_2.tscn`](../levels/cycles/level_12_STU_2.tscn), около строки 8802.

Статус: закрыто. Money system и student reward flags сохраняются/восстанавливаются; поведение покрыто `test_level12_money_system.gd` и `test_level12_student_reward.gd`.

## P2: Жёсткая Связь С Именами Дочерних Узлов

Пример: `generator.gd` ищет `AudioStreamPlayer2D` и `AnimatedSprite2D`, но `generator.tscn` содержит только `CollisionShape2D` и `Sprite2D`. Звук/анимация silently no-op.

Файлы:

- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 18.
- [`objects/interactable/generator/generator.tscn`](../objects/interactable/generator/generator.tscn), около строки 9.
- [`objects/interactable/door/door.gd`](../objects/interactable/door/door.gd), около строки 48.

Похожий паттерн встречается у дверей, ламп, ноутбуков, холодильника и прожекторов.

Ремонт: exported `NodePath`, required-node validation tests, typed child references или composition components.

## P2: `TriggerSetProperty` Слишком Универсален

`TriggerSetProperty` меняет любые свойства через `Variant value`. По умолчанию `one_shot=true`, поэтому enter+exit сценарий может сработать на входе и уже не восстановить состояние на выходе.

Файлы:

- [`objects/interactable/trigger/trigger_set_property.gd`](../objects/interactable/trigger/trigger_set_property.gd), около строк 5 и 94.
- [`objects/interactable/trigger/property_change.gd`](../objects/interactable/trigger/property_change.gd), около строки 21.

Ремонт: разделить one-shot и reversible trigger, добавить типизированные property changes и тест на enter/exit restore.

## P2: Свет, Генератор И Враги Завязаны На Строковые Группы

Лампа, фонарик, старый проектор и `Projector2` сами добавляют себя в `reactive_light_source`. Генератор ищет `generator_required_light`/`lamp` и вызывает `turn_on`.

Файлы:

- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 77.
- [`objects/interactable/lamp/lamp.gd`](../objects/interactable/lamp/lamp.gd), около строки 64.
- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd), около строки 77.
- [`objects/interactable/projector2/projector2.gd`](../objects/interactable/projector2/projector2.gd), около строки 162.

Практический риск: строка группы или имя метода меняется - контракт ломается без явной ошибки.

Ремонт: light/power interface component, validator на groups/methods, единый input contract для родственных источников света.

## P2: `TargetMonsterSpawner` Конфигурируется Слишком Неявно

По умолчанию spawner ждёт `CycleState.ate_this_cycle == true`. В `level_11_STU_1` инстанс задаёт только `enemy_scene`, значит условие спавна скрыто в дефолтах скрипта/сцены.

Файлы:

- [`objects/environment/smart/target/target.gd`](../objects/environment/smart/target/target.gd), около строк 28 и 98.
- [`levels/cycles/level_11_STU_1.tscn`](../levels/cycles/level_11_STU_1.tscn), около строки 8557.

Ремонт: сделать trigger condition явным в уровне или вынести условия в resource.
