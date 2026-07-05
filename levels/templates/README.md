# Content Templates

`cycle_level_template.tscn` is a copy-start scene for new cycle levels. Keep it outside `levels/cycles/` so it is not treated as campaign content.

When creating a real level, duplicate the template into `levels/cycles/level_XX_name.tscn`, then update:

- `cycle_number` and `timer_duration`;
- `Player` position and room layout;
- `Bed.next_level_path`;
- optional start hint/subtitle fields;
- any new `NodePath` wiring, with a focused validator when the path is part of a new content contract.

The template is load-tested and checked by `test_level_authoring_contracts.gd`; if the base level contract changes, update this template in the same commit.
