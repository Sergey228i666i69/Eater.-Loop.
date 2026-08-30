# Проверка, Сборка И Частые Проблемы

## Быстрая Проверка

Для проверки синтаксиса и загрузки тестового раннера:

```bash
godot --headless --check-only -s res://tests/run_tests.gd
```

Для полной проверки:

```bash
bash tests/run_tests.sh
```

Полный suite важен перед коммитом, релизом или после изменений в сценах,
локализации, ассетах, мини-играх и переходах.

## Что Проверяют Тесты

Тесты не проходят игру целиком, но ловят много поломок:

- main scene и autoload-и;
- загрузку сцен и скриптов;
- input actions;
- NodePath в сценах;
- двери, ключи, холодильники, лабораторные;
- музыку и audio buses;
- локализацию и битые кодировки;
- checkpoint restore;
- gamepad-схемы мини-игр;
- export presets.

## Если Godot Не Находится

Можно указать путь к Godot:

```bash
GODOT_BIN=/path/to/Godot bash tests/run_tests.sh
```

## Если После Переименования Сцена Ищет Старый Файл

Иногда Godot cache держит старый UID.

1. Закрой Godot.
2. Выполни:

```bash
rm -f .godot/uid_cache.bin
godot --headless --path . --import
```

3. Открой проект снова.
4. Запусти тесты.

Не добавляй `.godot/` в коммит.

## Если Нет Ассетов После Clone

Проверь Git LFS:

```bash
git lfs install
git lfs pull
```

После этого открой проект в Godot и дождись импорта.

## macOS DMG Export

Если Godot не может создать DMG на macOS с ошибкой про `hdiutil create`, в
проекте есть workaround:

```bash
tools/macos_dmg_fix/run_godot_with_dmg_fix.sh
```

После запуска Godot через этот скрипт экспортируй macOS preset как обычно.

Для терминала:

```bash
tools/macos_dmg_fix/export_macos_dmg.sh
```

или с путём:

```bash
tools/macos_dmg_fix/export_macos_dmg.sh /absolute/path/MyBuild.dmg
```

## Debug Export И Release

CI проверяет debug export, чтобы preset и ресурсы были живыми. Это не то же
самое, что финальный release.

Для настоящего релиза на macOS отдельно нужны:

- правильные export templates;
- подпись;
- notarization;
- ручная проверка готового приложения.

## Частые Ошибки И Что Делать

`Parser error`

- Открой указанный `.gd` файл.
- Проверь строку из ошибки.
- Запусти parser-only ещё раз.

`Resource not found`

- Проверь путь в Inspector.
- Проверь, что файл реально существует.
- После rename попробуй пересобрать import cache.

`Localization test failed`

- Найди строку из ошибки.
- Добавь key, ru и en в `global/localization/texts.csv`.
- Убедись, что нет битой кодировки.

`Input action missing`

- Открой Project Settings -> Input Map.
- Добавь action, который указан в ошибке.
- Назначь клавишу/кнопку.

`NodePath contract failed`

- Открой указанную сцену.
- Найди поле path в Inspector.
- Перетащи правильный узел из Scene tree в это поле.

`Audio bus failed`

- Открой сцену.
- Найди `AudioStreamPlayer` или `AudioStreamPlayer2D`.
- Поставь bus `Sounds` или `Music`.
