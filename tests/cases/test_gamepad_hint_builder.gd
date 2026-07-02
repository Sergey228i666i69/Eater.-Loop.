extends "res://tests/test_case.gd"

const GamepadHintBuilder = preload("res://levels/minigames/gamepad/gamepad_hint_builder.gd")


func run() -> Array[String]:
	_test_focus_mode_uses_defaults_without_mutating_custom_hints()
	_test_pick_place_without_selection_uses_pick_defaults()
	_test_pick_place_with_selection_uses_place_and_section_hints()
	return get_failures()


func _test_focus_mode_uses_defaults_without_mutating_custom_hints() -> void:
	var builder := GamepadHintBuilder.new()
	var custom_hints := {"confirm": "Сделать", "secondary": "Доп. действие"}
	var scheme := {"hints": custom_hints}

	var hints := builder.build(scheme, "focus", null, [], [], true)
	hints["confirm"] = "changed"

	assert_eq(custom_hints.get("confirm"), "Сделать", "Builder must not mutate custom hint dictionaries")
	assert_eq(builder.build(scheme, "focus", null, [], [], true).get("confirm"), "Сделать", "Focus mode must preserve custom confirm hint")
	assert_eq(builder.build({}, "focus", null, [], [], false).get("confirm"), "Подтвердить", "Focus mode must provide a default confirm hint")
	assert_eq(builder.build({}, "focus", null, [], [], false).get("cancel"), "Выход", "Focus mode must provide a default cancel hint")


func _test_pick_place_without_selection_uses_pick_defaults() -> void:
	var builder := GamepadHintBuilder.new()

	var hints := builder.build({}, "pick_place", null, [], [], false)

	assert_eq(hints.get("confirm"), "Выбрать", "Pick-place mode without source must prompt source selection")
	assert_eq(hints.get("cancel"), "Выход", "Pick-place mode without source must keep exit cancel hint")
	assert_true(not hints.has("tab_left"), "Pick-place mode without source must not show section tabs")
	assert_true(not hints.has("tab_right"), "Pick-place mode without source must not show section tabs")


func _test_pick_place_with_selection_uses_place_and_section_hints() -> void:
	var builder := GamepadHintBuilder.new()
	var source := Node.new()
	var target := Node.new()

	var hints := builder.build({}, "pick_place", source, [source], [target], false)

	assert_eq(hints.get("confirm"), "Поместить", "Pick-place mode with source must prompt placement")
	assert_eq(hints.get("cancel"), "Отменить выбор", "Pick-place mode with source must expose cancel-selection hint")
	assert_eq(hints.get("tab_left"), "Секция", "Pick-place mode with both sections must expose left section tab")
	assert_eq(hints.get("tab_right"), "Секция", "Pick-place mode with both sections must expose right section tab")

	source.free()
	target.free()
