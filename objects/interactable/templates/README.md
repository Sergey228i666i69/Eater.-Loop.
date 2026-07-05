# Interactable Templates

`basic_interactive_template.tscn` is a copy-start scene for simple interactables.
`lab_laptop_template.tscn` is a copy-start scene for a timed lab laptop.
`feeding_fridge_template.tscn` is a copy-start scene for a feeding fridge with a minimal valid food/minigame config.

When creating a real object, duplicate it into a domain folder under `objects/interactable/`, then update:

- the root script if the object needs behavior beyond `InteractiveObject`;
- `prompt_text` and localization keys for any player-facing text;
- `CollisionShape2D` size and position;
- `Sprite2D` texture or a richer visual subtree;
- `one_shot`, dependency fields, and result payload helpers when the object affects other content.

The template keeps the stable root/child shape that the interaction system expects. If the base interaction contract changes, update this template and `test_scene_nodepath_contracts.gd` together.

For lab laptops, update `lab_completion_id`, `minigame_scene`, `time_limit`, and `penalty_time` after copying. For feeding fridges, update `food_scenes`, `andrey_face`, `background_texture`, sounds, and any lab/code/dependency gates in the owning level scene.
