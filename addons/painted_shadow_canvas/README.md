# Painted Shadow Canvas 2D

Редакторский инструмент для рисования мягкой локальной темноты прямо в 2D-сцене Godot 4.6.

Вместо чёрного полупрозрачного спрайта маска работает как отрицательный (`SUB`) `PointLight2D`. Поэтому обычные `ADD`-источники света — фонарик игрока, лампы и проектор — естественно компенсируют нарисованное затемнение в освещённой области.

## Быстрый старт

1. Откройте `Project > Project Settings > Plugins` и включите **Painted Shadow Canvas 2D**.
2. Добавьте в 2D-сцену узел `PaintedShadowCanvas2D`.
3. В Inspector задайте `Canvas Size`, `Mask Resolution` и `Darkness Strength`.
4. Выделите узел. Внизу автоматически раскроется панель **Painted Shadow**.
5. Включите `Paint in 2D View` и рисуйте левой кнопкой внутри синей рамки.
6. Сохраните сцену. Маска хранится в ней как PNG-сжатый L8 snapshot.

Пока включён Paint, левая кнопка полностью принадлежит кисти и не двигает/вращает/масштабирует узлы. `Space` + drag или средняя кнопка панорамируют 2D-вид, колесо меняет масштаб. Круг кисти показывается только внутри границ холста.

Доступны пресеты `Soft Round`, `Hard Round`, `Airbrush`, режимы `Darken`/`Erase`, размер, интенсивность, мягкость, spacing, полная очистка/заливка и Undo/Redo по законченному мазку.

Подробное руководство и проектные рекомендации: [`docs/human/painted-shadow-canvas.md`](../../docs/human/painted-shadow-canvas.md).

## Структура

- `runtime/painted_shadow_canvas_2d.gd` — экспортобезопасный runtime-узел и сериализация маски.
- `runtime/painted_shadow_brush_engine.gd` — чистые операции кисти над `Image`.
- `runtime/painted_shadow_stroke_sampler.gd` — независимая от частоты mouse events сетка штампов.
- `editor/painted_shadow_dock.gd` — панель параметров кисти.
- `plugin.gd` — ввод 2D viewport, overlay и Undo/Redo.
- `runtime/painted_shadow_canvas_2d.tscn` — drag-and-drop вариант узла.

Editor plugin нужен только для рисования. Уже сохранённые `PaintedShadowCanvas2D` продолжают работать в игре и экспорте, даже если plugin выключен.

Если панель не обновилась после установки новой версии addon, один раз выключите и снова включите plugin. Панель можно свободно перетащить из нижней области в боковой dock или отдельное окно; при следующем выборе холста она автоматически раскроется и получит фокус.

## Проверка

Контракты инструмента покрыты:

- `tests/cases/test_painted_shadow_brush_engine.gd`;
- `tests/cases/test_painted_shadow_canvas_contract.gd`.

Запуск из корня проекта:

```bash
godot --headless --check-only -s res://tests/run_tests.gd
bash tests/run_tests.sh
```

Реальная pixel-проба требует не headless, а настоящий 2D renderer:

```bash
godot --path . --resolution 320x160 --rendering-method gl_compatibility \
  --script res://addons/painted_shadow_canvas/tests/painted_shadow_render_probe.gd
```

Успешный результат содержит `PAINTED_SHADOW_RENDER PASS` и завершается с кодом `0`.
