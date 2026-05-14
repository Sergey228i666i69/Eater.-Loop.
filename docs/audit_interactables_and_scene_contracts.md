# Интерактивные Объекты И Scene Contracts

Оценка проблемности среза: **6/10**.

## Диагноз

База `InteractiveObject` полезная, но вокруг неё выросла сеть неявных контрактов: кто-то ждёт `is_completed`, кто-то слушает сигнал, кто-то ищет ребёнка по имени, кто-то требует группу или метод `turn_on`. Самые опасные fail-open случаи уже закрыты, но система всё ещё держится на дисциплине сцен.

## P1: Dependency-Система Стала Безопаснее, Но Контракт Ломкий

`InteractiveObject` всё ещё ждёт `dependency_object.is_completed` и `interaction_finished`, но два опасных класса багов закрыты. Конкретный softlock из `level_04_findkey`, где `SearchSpot` с `door_key` зависел от двери `ToBedroom`, которая сама требовала `door_key`, закрыт: search spots больше не завязаны на эту дверь, а `test_scene_dependency_contracts.gd` ловит такие key-door циклы.

Второй закрытый fail-open: `one_shot` больше не означает "завершить после любой попытки". База вызывает `_should_auto_complete_after_interact()`, а `Door`, `Fridge`, `Laptop` и `Blockpost` запрещают авто-завершение и сами вызывают `complete_interaction()` только после успешного перехода, еды, лабораторной или оплаты. Это закреплено в `test_interaction_completion_contracts.gd`.

Файлы:

- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строк 73 и 216.
- [`objects/interactable/door/door.gd`](../objects/interactable/door/door.gd), около строки 60.
- [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строки 153.
- [`objects/interactable/notebook/laptop.gd`](../objects/interactable/notebook/laptop.gd), около строки 149.
- [`objects/interactable/level12/blockpost/blockpost.gd`](../objects/interactable/level12/blockpost/blockpost.gd), около строки 35.
- [`levels/cycles/level_04_findkey.tscn`](../levels/cycles/level_04_findkey.tscn), около строки 1725.

Оставшийся практический риск: зависимости всё ещё смотрят на один общий `is_completed`, хотя разным объектам нужны разные outcome-ы: attempted, succeeded, completed forever.

Следующий ремонт: разделить `interaction_requested`, `interaction_succeeded`, `completed_forever`; зависимости должны смотреть на явный outcome.

## Resolved: Нет Единого Фокуса Интерактива

Каждый `InteractiveObject` сам слушает `_unhandled_input`. Если игрок стоит в нескольких Area2D, одно нажатие может активировать несколько объектов.

Файл: [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строк 109 и 123.

Особенно опасно для:

- дверей;
- холодильника;
- ноутбука;
- ламп;
- прожекторов;
- кровати.

Статус: закрыто. `InteractionManager` выбирает один объект по availability, priority, distance и порядку входа, показывает одну подсказку и consume-ит input. Поведение покрыто `test_interaction_manager_focus.gd`.

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

## Resolved: `TriggerSetProperty` Слишком Универсален

`TriggerSetProperty` меняет любые свойства через `Variant value`. По умолчанию `one_shot=true`, поэтому enter+exit сценарий мог сработать на входе и уже не восстановить состояние на выходе.

Файлы:

- [`objects/interactable/trigger/trigger_set_property.gd`](../objects/interactable/trigger/trigger_set_property.gd), около строк 5 и 94.
- [`objects/interactable/trigger/property_change.gd`](../objects/interactable/trigger/property_change.gd), около строки 21.

Статус: закрыто минимально. Найденный reversible trigger в `level_06_corridordistortion` теперь явно `one_shot=false`, а `test_scene_dependency_contracts.gd` запрещает `affect_on_exit=true` без `one_shot=false`. Более крупный ремонт всё ещё полезен: разделить one-shot и reversible trigger на разные typed components.

## P2: Свет, Генератор И Враги Завязаны На Строковые Группы

Лампа, фонарик, старый проектор и `Projector2` сами добавляют себя в `reactive_light_source`. Генератор ищет `generator_required_light`/`lamp` и вызывает `turn_on`.

Файлы:

- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 77.
- [`objects/interactable/lamp/lamp.gd`](../objects/interactable/lamp/lamp.gd), около строки 64.
- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd), около строки 77.
- [`objects/interactable/projector2/projector2.gd`](../objects/interactable/projector2/projector2.gd), около строки 162.

Практический риск: строка группы или имя метода меняется - контракт ломается без явной ошибки.

Ремонт: light/power interface component, validator на groups/methods, единый input contract для родственных источников света.

## Resolved: `TargetMonsterSpawner` Конфигурируется Слишком Неявно

Изначально spawner по умолчанию ждал `CycleState.ate_this_cycle == true`, а в `level_11_STU_1` инстанс задавал только `enemy_scene`, так что условие спавна было скрыто в дефолтах скрипта/сцены.

Файлы:

- [`objects/environment/smart/target/target.gd`](../objects/environment/smart/target/target.gd), около строк 28 и 98.
- [`levels/cycles/level_11_STU_1.tscn`](../levels/cycles/level_11_STU_1.tscn), около строки 8557.

Статус: закрыто минимально. `TargetMonsterSpawner` получил `condition_configured`, реальный инстанс в `level_11_STU_1` явно задаёт `ate_this_cycle == true`, а `test_scene_dependency_contracts.gd` запрещает spawner-ы с `enemy_scene`, которые не подтвердили условие.
