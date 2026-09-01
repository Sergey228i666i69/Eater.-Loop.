# Архитектура Персонажа Игрока (Андрей)

## Основной Персонаж (Production)

- **`res://player/player.tscn`**: Основная рабочая сцена персонажа игрока, используемая во всех уровнях (`levels/cycles/*.tscn`) и шаблонах (`levels/templates/cycle_level_template.tscn`).
  - **Визуализация**: Покадровая спрайтовая анимация (`AnimatedSprite2D`) со спрайтами из `res://player/animations/walking/` (`ezgif-frame-001.png` .. `016.png`) и текстурой простоя `AndryWithFlashlight.png`.
  - **Камера**: `Camera2D` с масштабом `Vector2(1.75, 1.75)` и сглаживанием.
  - **Фонарик**: `PointLight2D` (`flashlight.gd`) со шкалой заряда `FlashlightBar`.
  - **Звуки шагов**: `StepAudioComponent` привязан к номерам кадров покадровой анимации.

## Эксперимент со Скелетным Ригом (Архивный неудачный эксперимент)

- **`res://player/player_skeleton_rig.tscn`**: Сцена скелетного 2D-рига (`Skeleton2D`, `Bone2D`, `SkeletonAnimationPlayer`, weighted `Polygon2D` mesh-слои).
  - **Статус**: Неудачный эксперимент по замене покадровой анимации на скелетную деформацию с нарезкой cutout-ассетов.
  - **Использование в игре**: **Не используется на игровых уровнях**. Сохранён исключительно как изолированный прототип и технический архив.
- **`res://player/player_skeleton_forearm_mesh_prototype.tscn`**: Изолированный прототип деформации предплечья для тестирования весов костей без влияния на рантайм.
- **`res://player/LEGASY-ANIMATIONS-CHARACTER.tscn`**: Историческая копия спрайтового персонажа (синхронизирована с `player.tscn`). Основной точкой входа для уровней является `player.tscn`.

## Утилиты Цветокоррекции и Анимации

- **`tools/harmonize_player_animation_palette.py`**: Скрипт автоматической цветокоррекции и выравнивания тона всех кадров анимации ходьбы (`player/animations/walking/`) по эталонному спрайту покоя (`player/AndryWithFlashlight.png`). Устраняет межкадровое мерцание и скачки гаммы между стоянием и ходьбой.
