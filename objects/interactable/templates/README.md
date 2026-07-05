# Interactable Templates

`basic_interactive_template.tscn` is a copy-start scene for simple interactables.

When creating a real object, duplicate it into a domain folder under `objects/interactable/`, then update:

- the root script if the object needs behavior beyond `InteractiveObject`;
- `prompt_text` and localization keys for any player-facing text;
- `CollisionShape2D` size and position;
- `Sprite2D` texture or a richer visual subtree;
- `one_shot`, dependency fields, and result payload helpers when the object affects other content.

The template keeps the stable root/child shape that the interaction system expects. If the base interaction contract changes, update this template and `test_scene_nodepath_contracts.gd` together.
