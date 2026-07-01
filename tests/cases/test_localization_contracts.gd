extends "res://tests/test_case.gd"

const LOCALIZATION_CSV := "res://global/localization/texts.csv"
const SOURCE_DIRS: Array[String] = [
    "res://levels",
    "res://objects",
    "res://player",
    "res://enemies",
    "res://global"
]
const TEXT_EXTENSIONS: Array[String] = [".gd", ".tscn", ".csv"]
const MOJIBAKE_MARKERS: Array[String] = ["Ð", "Ñ", "�"]
const PLAYER_FACING_PROPERTIES: Array[String] = [
    "access_granted_message",
    "already_collected_message",
    "already_given_message",
    "cleared_message",
    "completed_message",
    "door_locked_message",
    "esc_exit_hint_text",
    "lab_required_message",
    "laptop_sleep_prompt",
    "locked_message",
    "no_bedroom_light_message",
    "not_ate_message",
    "not_enough_money_message",
    "pickup_message",
    "prompt_text",
    "reward_message",
    "searched_empty_message",
    "sleep_message_template",
    "start_hint_text",
    "start_subtitle_text",
    "talk_message",
    "text"
]
const PLAYER_FACING_CALL_MARKERS: Array[String] = [
    "UIMessage.show_dialogue(",
    "UIMessage.show_hint(",
    "UIMessage.show_notification(",
    "tr("
]

func run() -> Array[String]:
    _test_localization_csv_is_complete()
    _test_runtime_text_sources_have_no_mojibake()
    _test_player_facing_text_has_localization_keys()
    return get_failures()

func _test_localization_csv_is_complete() -> void:
    assert_true(FileAccess.file_exists(LOCALIZATION_CSV), "Missing localization CSV: %s" % LOCALIZATION_CSV)
    var file := FileAccess.open(LOCALIZATION_CSV, FileAccess.READ)
    if file == null:
        fail("Failed to open localization CSV: %s" % LOCALIZATION_CSV)
        return

    var header := file.get_csv_line()
    if header.size() < 3:
        fail("Localization CSV header must contain keys, ru and en columns")
        return
    assert_eq(header[0].strip_edges(), "keys", "Localization CSV column 1 must be keys")
    assert_eq(header[1].strip_edges(), "ru", "Localization CSV column 2 must be ru")
    assert_eq(header[2].strip_edges(), "en", "Localization CSV column 3 must be en")

    var seen_keys := {}
    var row_index := 1
    while not file.eof_reached():
        row_index += 1
        var row := file.get_csv_line()
        if _is_blank_row(row):
            continue
        if row.size() < 3:
            fail("Localization row %d must contain keys, ru and en values" % row_index)
            continue

        var key := row[0].strip_edges()
        var ru := row[1].strip_edges()
        var en := row[2].strip_edges()
        assert_true(key != "", "Localization row %d has an empty key" % row_index)
        assert_true(ru != "", "Localization row %d has an empty ru value for key: %s" % [row_index, key])
        assert_true(en != "", "Localization row %d has an empty en value for key: %s" % [row_index, key])
        if key != "":
            assert_true(not seen_keys.has(key), "Duplicate localization key: %s" % key)
            seen_keys[key] = true
        _assert_no_mojibake(key, "Localization key on row %d" % row_index)
        _assert_no_mojibake(ru, "Localization ru value on row %d" % row_index)
        _assert_no_mojibake(en, "Localization en value on row %d" % row_index)

func _test_runtime_text_sources_have_no_mojibake() -> void:
    for root in SOURCE_DIRS:
        for extension in TEXT_EXTENSIONS:
            for path in utils.list_files(root, extension, [], []):
                var text := FileAccess.get_file_as_string(path)
                _assert_no_mojibake(text, path)

func _test_player_facing_text_has_localization_keys() -> void:
    var keys := _load_localization_keys()
    if keys.is_empty():
        return
    for root in SOURCE_DIRS:
        for extension in [".gd", ".tscn"]:
            for path in utils.list_files(root, extension, [], []):
                _assert_player_facing_text_has_key(path, keys)

func _assert_player_facing_text_has_key(path: String, keys: Dictionary) -> void:
    var text := FileAccess.get_file_as_string(path)
    assert_true(text != "", "Failed to read runtime text source: %s" % path)
    if text == "":
        return
    var lines := text.split("\n")
    for line_index in range(lines.size()):
        var line := String(lines[line_index])
        var stripped := line.strip_edges()
        if stripped.begins_with("#"):
            continue
        _assert_property_line_has_key(path, line_index + 1, line, keys)
        if path.ends_with(".gd"):
            _assert_call_line_has_key(path, line_index + 1, line, keys)

func _assert_property_line_has_key(path: String, line_number: int, line: String, keys: Dictionary) -> void:
    var equals_index := line.find("=")
    if equals_index == -1:
        return
    var property_name := _extract_property_name(line.substr(0, equals_index).strip_edges())
    if not PLAYER_FACING_PROPERTIES.has(property_name):
        return
    for value in _extract_quoted_strings(line.substr(equals_index + 1)):
        _assert_localization_key_exists(path, line_number, value, keys)

func _assert_call_line_has_key(path: String, line_number: int, line: String, keys: Dictionary) -> void:
    var has_player_facing_call := false
    for marker in PLAYER_FACING_CALL_MARKERS:
        if line.find(marker) != -1:
            has_player_facing_call = true
            break
    if not has_player_facing_call:
        return
    for value in _extract_quoted_strings(line):
        _assert_localization_key_exists(path, line_number, value, keys)

func _assert_localization_key_exists(path: String, line_number: int, value: String, keys: Dictionary) -> void:
    var normalized := value.strip_edges()
    if normalized == "" or not _has_cyrillic(normalized):
        return
    assert_true(keys.has(normalized), "Player-facing text must have localization CSV key: %s:%d -> %s" % [path, line_number, normalized])

func _load_localization_keys() -> Dictionary:
    var keys := {}
    var file := FileAccess.open(LOCALIZATION_CSV, FileAccess.READ)
    if file == null:
        return keys
    file.get_csv_line()
    while not file.eof_reached():
        var row := file.get_csv_line()
        if _is_blank_row(row) or row.size() < 1:
            continue
        var key := row[0].strip_edges()
        if key != "":
            keys[key] = true
    return keys

func _extract_property_name(raw_name: String) -> String:
    var name := raw_name
    var colon_index := name.find(":")
    if colon_index != -1:
        name = name.substr(0, colon_index).strip_edges()
    var parts := name.split(" ", false)
    if parts.size() > 0:
        name = parts[parts.size() - 1]
    return name.strip_edges()

func _extract_quoted_strings(value: String) -> Array[String]:
    var results: Array[String] = []
    var start := value.find("\"")
    while start != -1:
        var current := ""
        var escaped := false
        var closed := false
        for index in range(start + 1, value.length()):
            var character := value.substr(index, 1)
            if escaped:
                current += _unescape_character(character)
                escaped = false
            elif character == "\\":
                escaped = true
            elif character == "\"":
                results.append(current)
                start = value.find("\"", index + 1)
                closed = true
                break
            else:
                current += character
        if not closed:
            break
    return results

func _unescape_character(character: String) -> String:
    match character:
        "n":
            return "\n"
        "t":
            return "\t"
        "\"":
            return "\""
        "\\":
            return "\\"
        _:
            return character

func _has_cyrillic(value: String) -> bool:
    for index in range(value.length()):
        var codepoint := value.unicode_at(index)
        if codepoint >= 0x0400 and codepoint <= 0x04FF:
            return true
    return false

func _is_blank_row(row: PackedStringArray) -> bool:
    if row.size() == 0:
        return true
    for cell in row:
        if cell.strip_edges() != "":
            return false
    return true

func _assert_no_mojibake(value: String, location: String) -> void:
    for marker in MOJIBAKE_MARKERS:
        if value.find(marker) != -1:
            fail("%s contains mojibake marker: %s" % [location, marker])
            return
