# Звук И Ассеты

## Музыка

Фоновая музыка уровня обычно настраивается через `LevelMusic`.

1. Добавь `AudioStream` в проект, например в `music/`.
2. Открой уровень.
3. Найди или добавь узел `LevelMusic`.
4. В поле `stream` выбери трек.
5. Настрой `play_on_ready`, `continue_on_level_change`, `fade_time`,
   `volume_db`.

Не ставь музыку напрямую в случайный `AudioStreamPlayer`, если это фон уровня:
проект использует общий `MusicManager`.

## Звуковые Эффекты

Для SFX:

- используй bus `Sounds`;
- держи звуки рядом с объектом или в понятной доменной папке;
- проверяй громкость в игре, а не только в preview.

Если в сцене есть `AudioStreamPlayer` или `AudioStreamPlayer2D`, выбери bus
`Sounds` для эффектов или `Music` для музыкального helper-а. Оставлять `Master`
для контентной сцены нельзя.

## TriggerSetProperty И Музыка

Trigger может:

- заглушить музыку;
- вернуть громкость;
- запустить event music;
- остановить event music;
- выключить/включить ambient.

Главная идея: вход и выход должны быть парой. Например:

- duck -> restore;
- event start -> event stop;
- pause all -> resume all;
- ambient off -> ambient on.

Если trigger запускает новый трек, назначь `music_stream`.

## Картинки И Импорт

1. Положи картинку в подходящую папку проекта.
2. Открой Godot и дождись импорта.
3. Убедись, что появился `.import`.
4. Используй картинку в Sprite2D, TextureRect или ресурсе.

Нельзя коммитить только `.png` без `.import`, если Godot создал import-файл.

## Скрипты И Shader UID

Для новых `.gd` и `.gdshader` Godot создаёт `.uid` sidecar. Если его нет:

```bash
godot --headless --path . --import
```

После этого добавляй нужный `.uid` вместе с файлом.

## Git LFS

Большие бинарные ассеты идут через Git LFS. После clone всегда выполняй:

```bash
git lfs install
git lfs pull
```

Если картинка или звук выглядят как маленький текстовый pointer, LFS не
подтянул настоящий файл.

## Чеклист

- Музыка уровня назначена через `LevelMusic`.
- SFX стоят на bus `Sounds`.
- Музыкальные player-узлы стоят на bus `Music`.
- У новых ассетов есть `.import`.
- У новых скриптов/shader-ов есть `.uid`.
- В игре звук слышен с нормальной громкостью.
