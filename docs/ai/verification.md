# Проверка И Воспроизводимость

## Команды

Parser-only:

```bash
godot --headless --check-only -s res://tests/run_tests.gd
```

Полный suite:

```bash
bash tests/run_tests.sh
```

Helper `tests/run_tests.sh` можно запускать из любого cwd. Он уважает
`GODOT_BIN`, если Godot лежит не в `PATH`:

```bash
GODOT_BIN=/path/to/Godot bash tests/run_tests.sh
```

## Что Запускать

- Документы без code/scene changes: минимум проверить ссылки/пути и `git diff --check`.
- Изменение `.gd`, `.tscn`, `project.godot`, `.import`, `.uid`, localization,
  export или test contracts: parser-only и полный suite.
- Asset/path rename: импорт Godot, parser-only и полный suite.
- Release/export выводы: полный suite плюс export smoke или ручной release export.

## Fresh Clone

После clone:

```bash
git lfs install
git lfs pull
```

Без LFS часть ассетов будет pointer-файлами, и сцены могут грузиться некорректно.

## Import И UID Drift

Если после rename/path work текстовые ссылки выглядят верно, но Godot продолжает
искать старый ресурс, возможен stale UID/import cache.

Рабочий порядок:

```bash
rm -f .godot/uid_cache.bin
godot --headless --path . --import
godot --headless --check-only -s res://tests/run_tests.gd
bash tests/run_tests.sh
```

Коммить только нужные `.uid`, `.import` и content files. Не добавляй весь
`.godot/`.

## CI И Export

- `export_presets.cfg` tracked в корне.
- Export paths должны быть repo-local внутри `exports/`.
- CI делает MacOS debug export smoke после тестов.
- Signed/notarized release build остаётся отдельным ручным release-процессом.
- Для локальной macOS DMG проблемы Godot 4.6 используй
  `tools/macos_dmg_fix/run_godot_with_dmg_fix.sh` или
  `tools/macos_dmg_fix/export_macos_dmg.sh`.

## Перед Коммитом

1. Проверь `git status --short`.
2. Убедись, что staged только твои файлы.
3. Запусти нужные проверки.
4. Если полный suite зелёный - создай коммит.
5. Если suite не зелёный, зафиксируй точную команду, ошибку и какие файлы были
   вне твоего изменения.
