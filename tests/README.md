# Godot smoke tests

These tests are lightweight smoke checks for project health. They run headless and focus on:
- Main scene is configured and loadable.
- Project config references loadable editor plugins and translation resources.
- Autoloads exist and load.
- Core scenes load and instantiate (excluding archived/trash folders).
- All scripts compile.
- Key input actions exist and have events.
- Scene dependency contracts cover reversible triggers, target spawners, and runtime group/method expectations.
- Level authoring contracts cover cycle metadata, bed transitions, and root-level exported paths/text toggles.
- The cycle-level template under `levels/templates/` is load-tested and checked against the same minimal Player/bed/root contract.
- The basic interactable template under `objects/interactable/templates/` is load-tested and checked for its root/child interaction shape.
- Lab laptop and feeding-fridge templates are checked against the same timed-lab/fridge authoring contracts as active level content.
- Lab authoring contracts cover lab laptop timing, timed-lab minigame scenes, explicit lab IDs, and required-lab references.
- Fridge authoring contracts cover feeding, code-lock, and final-feeding scene configs.
- Architecture contracts keep external `GameState`/`CycleState` access on public methods.
- Localization CSV and runtime text sources do not contain empty required values or mojibake; RU player-facing strings, including gamepad hints, must have CSV keys.
- Runtime regressions for critical audio transitions (including menu -> level start).
- Painted-shadow addon contracts cover brush falloff/interpolation, mask persistence, and native subtractive Light2D configuration.

## Run

From the project root:

```bash
godot --headless -s res://tests/run_tests.gd
```

Or use the helper script from any working directory (respects `GODOT_BIN`):

```bash
GODOT_BIN=/path/to/Godot bash tests/run_tests.sh
```

Exit code is the number of failures (0 = success).

## Async runtime tests

- The runner supports both sync and async `run()` tests.
- Async tests are used for frame-based/runtime checks that cannot be validated by static file parsing.
- Each test has a per-test timeout in `tests/run_tests.gd` (`TEST_TIMEOUT_SECONDS`) so a hung scenario does not stall CI forever.
- Prefer keeping async tests deterministic and short (target: total suite under ~40s).

## Notes

- These are smoke tests; they do not simulate gameplay.
- Test files named `test_*.gd` are discovered recursively under `tests/cases/**`.
- Runtime tests should clean up their scene/autoload side effects before returning.
- If you add/remove core input actions, update `tests/cases/test_input_actions.gd`.
- If you add new scene folders, include them in `tests/cases/test_scenes_load.gd`.
- The dummy headless renderer cannot validate Light2D pixels. Run the addon's non-headless `painted_shadow_render_probe.gd` when changing its render path.
