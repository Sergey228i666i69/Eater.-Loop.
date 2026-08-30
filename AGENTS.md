# AGENTS.md

## Назначение

Этот файл - короткий вход для агентов в Godot-проект `едок.-петля`.
Подробные агентские правила и контракты живут только в `docs/ai/`.

## Читать Сначала

1. [AI README](docs/ai/README.md)
2. [Правила работы агента](docs/ai/agent-operating-rules.md)
3. [Карта проекта](docs/ai/project-map.md)
4. [Архитектурные контракты](docs/ai/architecture-contracts.md)
5. [Контракты добавления контента](docs/ai/content-authoring-contracts.md)
6. [Проверка и воспроизводимость](docs/ai/verification.md)
7. [Риски и roadmap рефакторинга](docs/ai/refactor-roadmap.md)

## Жёсткие Правила

- Перед изменениями проверь ветку: не работай напрямую в `main`; если текущая ветка `main`, создай ветку с префиксом `codex/`.
- Не трогай чужие незакоммиченные изменения без явной просьбы.
- Для чтения используй `rg`/`rg --files`.
- Для ручных правок используй `apply_patch`.
- После meaningful code changes обновляй релевантную документацию.
- Если полный suite зелёный после твоей работы, создай коммит с понятным названием.
- Если suite красный из-за уже известных проблем, явно укажи это в финальном отчёте.

## Команды Проверки

- Parser-only: `godot --headless --check-only -s res://tests/run_tests.gd`
- Полный локальный suite: `bash tests/run_tests.sh`
