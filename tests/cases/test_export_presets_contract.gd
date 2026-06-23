extends "res://tests/test_case.gd"

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"

func run() -> Array[String]:
	var config := ConfigFile.new()
	var error := config.load(EXPORT_PRESETS_PATH)
	assert_eq(error, OK, "export_presets.cfg must parse as a ConfigFile")
	if error != OK:
		return get_failures()

	var preset_count := 0
	for section in config.get_sections():
		if not _is_preset_section(section):
			continue
		preset_count += 1
		var export_path := str(config.get_value(section, "export_path", ""))
		assert_true(export_path.begins_with("exports/"), "%s export_path must stay under repo-local exports/: %s" % [section, export_path])
		assert_true(export_path.find("../") == -1, "%s export_path must not escape the repository: %s" % [section, export_path])
		assert_true(not export_path.begins_with("/"), "%s export_path must not be absolute: %s" % [section, export_path])
		assert_true(export_path.find("Documents/") == -1, "%s export_path must not point at a developer-local Documents folder: %s" % [section, export_path])

	assert_true(preset_count > 0, "export_presets.cfg must contain at least one export preset")
	return get_failures()

func _is_preset_section(section: String) -> bool:
	if not section.begins_with("preset."):
		return false
	return not section.ends_with(".options")
