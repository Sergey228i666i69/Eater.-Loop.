# Интерактивные Объекты И Scene Contracts

Оценка проблемности среза: **5/10**.

## Диагноз

База `InteractiveObject` полезная, но вокруг неё выросла сеть неявных контрактов: кто-то ждёт completion, кто-то слушает сигнал, кто-то ищет ребёнка по имени, кто-то требует группу или метод `turn_on`. Самые опасные fail-open случаи уже закрыты, dependency-контракт typed, result/outcome слой явно различает success/failure/cancel, а ключевые scene contracts теперь прикрыты валидаторами. Оставшийся риск смещён к стоимости scene-authoring: крупные сцены всё ещё тяжело ревьюить вручную.

## Resolved Minimally: Dependency-Система Стала Typed

`InteractiveObject` теперь различает `DependencyCondition.COMPLETED` и `DependencyCondition.INTERACTION_REQUESTED`. `COMPLETED` открывается после typed success outcome (`interaction_succeeded` / `complete_interaction()`), а не после raw attempt. `INTERACTION_REQUESTED` остаётся явным attempt-level unlock и не помечает сам dependent завершённым. Requested-unlock состояние сохраняется в checkpoint state.

Реальные цепочки мигрированы явно: laptop→fridge в `level_03_deepseek` и `level_05_sql` используют `INTERACTION_REQUESTED`, `NoteStory`→fridge в `level_11_STU_1` и fridge→generator в `level_12_STU_2` используют `COMPLETED`. Финальная laptop-ветка слушает `interaction_succeeded`, а legacy `interaction_finished` остаётся только совместимым success wrapper для старого кода. Сцены с `dependency_object` теперь валидируются на явный `dependency_condition`, а level scripts не должны вызывать `set_dependency_object()` без близкого `set_dependency_condition()`.

Два прежних опасных класса багов тоже закрыты. Конкретный softlock из `level_04_findkey`, где `SearchSpot` с `door_key` зависел от двери `ToBedroom`, которая сама требовала `door_key`, закрыт: search spots больше не завязаны на эту дверь, а `test_scene_dependency_contracts.gd` ловит такие key-door циклы. Тот же contract теперь проверяет, что `required_key_id` у дверей имеет источник ключа в той же сцене, а `SearchKeyManager.search_spots` непустой и resolving. Это уже поймало и закрыло два реальных scene-долга: несуществующий `lebedka_key` в `level_09_crazy` и locked `Door(In604)` с несуществующим `key_6level` в `level_12_STU_2`.

Второй закрытый fail-open: `one_shot` больше не означает "завершить после любой попытки". База вызывает `_should_auto_complete_after_interact()`, а `Door`, `Fridge`, `Laptop` и `Blockpost` запрещают авто-завершение и сами вызывают `complete_interaction()` только после успешного перехода, еды, лабораторной или оплаты. Это закреплено в `test_interaction_completion_contracts.gd`.

Файлы:

- [`objects/interactable/interactive_object.gd`](../objects/interactable/interactive_object.gd), около строк 8, 33 и 218.
- [`objects/interactable/door/door.gd`](../objects/interactable/door/door.gd), около строки 60.
- [`objects/interactable/fridge/fridge.gd`](../objects/interactable/fridge/fridge.gd), около строки 153.
- [`objects/interactable/notebook/laptop.gd`](../objects/interactable/notebook/laptop.gd), около строки 149.
- [`objects/interactable/level12/blockpost/blockpost.gd`](../objects/interactable/level12/blockpost/blockpost.gd), около строки 35.
- [`levels/cycles/level_03_deepseek.tscn`](../levels/cycles/level_03_deepseek.tscn), около строк 868 и 1123.
- [`levels/cycles/level_05_sql.tscn`](../levels/cycles/level_05_sql.tscn), около строки 1271.
- [`levels/cycles/level_11_stu_1.gd`](../levels/cycles/level_11_stu_1.gd), около строки 39.
- [`levels/cycles/level_12_stu_2.gd`](../levels/cycles/level_12_stu_2.gd), около строки 56.

Result/outcome слой введён: `interaction_result(result)` несёт outcome, success flag, source, reason/player/payload; отдельные сигналы `interaction_succeeded`, `interaction_failed`, `interaction_cancelled` позволяют не путать успешное завершение с провалом или отменой. Дверь, холодильник и ноутбук явно эмитят failed/cancelled outcomes на известных fail-closed ветках.

Оставшийся практический риск: payload-семантика пока минимальная. Если появятся зависимости на конкретный предмет или typed reward, нужно расширять result payload и валидаторы, а не возвращаться к ad-hoc флагам.

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

Пример из первичного аудита: `generator.gd` искал `AudioStreamPlayer2D` и `AnimatedSprite2D`, но `generator.tscn` содержал только `CollisionShape2D` и `Sprite2D`. Звуковой hook генератора теперь закреплён реальным `AudioStreamPlayer2D` и тестом; animation hook остаётся optional skin-частью.

Файлы:

- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 18.
- [`objects/interactable/generator/generator.tscn`](../objects/interactable/generator/generator.tscn), около строки 9.
- [`objects/interactable/door/door.gd`](../objects/interactable/door/door.gd), около строки 48.

Похожий паттерн встречается у дверей, ламп, ноутбуков, холодильника и прожекторов.

Статус: закрыто на уровне runtime contracts. `test_scene_nodepath_contracts.gd` проверяет unlocked/key door targets, blockpost child contracts, money-system paths, light/sprite/audio exported paths and teleport targets. `test_stu_level_path_contracts.gd` отдельно фиксирует STU floor/room paths и dynamic redirect targets. `test_trigger_set_property_contracts.gd` проверяет, что configured `TriggerSetProperty`/`PropertyChange` target paths резолвятся, а target nodes реально имеют указанное property.

Оставшийся authoring-долг: если сцены будут визуально дробиться на reusable instances, делать это отдельным scene-refactor после этих validators.

## Resolved: `TriggerSetProperty` Слишком Универсален

`TriggerSetProperty` меняет любые свойства через `Variant value`. По умолчанию `one_shot=true`, поэтому enter+exit сценарий мог сработать на входе и уже не восстановить состояние на выходе.

Файлы:

- [`objects/interactable/trigger/trigger_set_property.gd`](../objects/interactable/trigger/trigger_set_property.gd), около строк 5 и 94.
- [`objects/interactable/trigger/property_change.gd`](../objects/interactable/trigger/property_change.gd), около строки 21.

Статус: закрыто минимально. Найденный reversible trigger в `level_06_corridordistortion` теперь явно `one_shot=false`, а `test_scene_dependency_contracts.gd` запрещает `affect_on_exit=true` без `one_shot=false`. `test_trigger_set_property_contracts.gd` дополнительно запрещает configured target/property changes, которые silently no-op из-за пустого path, битого path или несуществующего property. Более крупный ремонт всё ещё полезен: разделить one-shot и reversible trigger на разные typed components.

## P2: Свет, Генератор И Враги Завязаны На Строковые Группы

Лампа, фонарик и canonical projector сами добавляют себя в `reactive_light_source`. Генератор ищет `generator_required_light`/`lamp` и вызывает `turn_on`.

Файлы:

- [`objects/interactable/generator/generator.gd`](../objects/interactable/generator/generator.gd), около строки 77.
- [`objects/interactable/lamp/lamp.gd`](../objects/interactable/lamp/lamp.gd), около строки 64.
- [`objects/interactable/projector/projector.gd`](../objects/interactable/projector/projector.gd), около строки 77.

Практический риск: строка группы или имя метода меняется - контракт ломается без явной ошибки.

Статус: частично закрыто validators. `test_scene_nodepath_contracts.gd` проверяет exported `light_node` у лампы, прожектора и pickup flashlight, а `test_scene_dependency_contracts.gd` запрещает runtime-скрипты, которые добавляют себя в `reactive_light_source` без `is_point_lit()` или в generator-required light-группы без `turn_on()`. Строковые группы всё ещё не так хороши, как typed light-source component, но новые световые объекты теперь не могут молча выпасть из договора.

## Resolved: `TargetMonsterSpawner` Конфигурируется Слишком Неявно

Изначально spawner по умолчанию ждал `CycleState.ate_this_cycle == true`, а в `level_11_STU_1` инстанс задавал только `enemy_scene`, так что условие спавна было скрыто в дефолтах скрипта/сцены.

Файлы:

- [`objects/environment/smart/target/target.gd`](../objects/environment/smart/target/target.gd), около строк 28 и 98.
- [`levels/cycles/level_11_STU_1.tscn`](../levels/cycles/level_11_STU_1.tscn), около строки 8557.

Статус: закрыто минимально. `TargetMonsterSpawner` получил `condition_configured`, реальный инстанс в `level_11_STU_1` явно задаёт `ate_this_cycle == true`, а `test_scene_dependency_contracts.gd` запрещает spawner-ы с `enemy_scene`, которые не подтвердили условие. State-флаги spawner теперь читаются через публичные методы `GameState`/`CycleState`, а не через raw property lookup.
