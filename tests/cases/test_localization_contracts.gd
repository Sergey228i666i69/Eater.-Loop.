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
    "death_retry_text",
    "death_title_text",
    "door_locked_message",
    "ending_text",
    "esc_exit_hint_text",
    "failure_dialogue_text",
    "interact_message",
    "key_name",
    "lab_required_message",
    "laptop_sleep_prompt",
    "locked_message",
    "no_bedroom_light_message",
    "not_ate_message",
    "not_enough_money_message",
    "pickup_message",
    "prompt_hold_text",
    "prompt_press_text",
    "prompt_text",
    "required_key_name",
    "reward_message",
    "reward_reason",
    "reward_subtitle",
    "searched_empty_message",
    "sleep_message_template",
    "start_hint_text",
    "start_subtitle_text",
    "success_dialogue_text",
    "talk_message",
    "text"
]
const PLAYER_FACING_CALL_MARKERS: Array[String] = [
    "UIMessage.show_dialogue(",
    "UIMessage.show_hint(",
    "UIMessage.show_notification(",
    "tr("
]
const PLAYER_FACING_LITERAL_FILES: Array[String] = [
    "res://levels/minigames/gamepad/gamepad_hint_builder.gd"
]
const ALLOWED_TECHNICAL_PLAYER_FACING_TEXT := {
    "res://levels/minigames/labs/sql/sql_minigame.tscn": {
        "SQL Editor - Query_Console_1.sql": true,
        "Line 1, Col 1 | UTF-8 | SQL": true
    },
    "res://levels/minigames/labs/sql/sql_minigame_glitch.tscn": {
        "SQL Editor - Query_Console_1.sql": true,
        "Line 1, Col 1 | UTF-8 | SQL": true
    }
}

func run() -> Array[String]:
    _test_localization_csv_is_complete()
    _test_localization_keys_do_not_use_translit_phrase_keys()
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

func _test_localization_keys_do_not_use_translit_phrase_keys() -> void:
    var file := FileAccess.open(LOCALIZATION_CSV, FileAccess.READ)
    if file == null:
        fail("Failed to open localization CSV: %s" % LOCALIZATION_CSV)
        return
    file.get_csv_line()
    var row_index := 1
    while not file.eof_reached():
        row_index += 1
        var row := file.get_csv_line()
        if _is_blank_row(row) or row.size() < 3:
            continue
        var key := row[0].strip_edges()
        var ru := row[1].strip_edges()
        if _looks_like_translit_phrase_key(key, ru):
            fail("Localization key looks like a transliterated phrase; use Russian source text or a semantic id: row %d -> %s" % [row_index, key])

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
    var gamepad_hints_depth := -1
    for line_index in range(lines.size()):
        var line := String(lines[line_index])
        var stripped := line.strip_edges()
        if stripped.begins_with("#"):
            continue
        gamepad_hints_depth = _update_gamepad_hints_depth(stripped, gamepad_hints_depth)
        _assert_property_line_has_key(path, line_index + 1, line, keys)
        if path.ends_with(".gd"):
            _assert_call_line_has_key(path, line_index + 1, line, keys)
            if PLAYER_FACING_LITERAL_FILES.has(path):
                _assert_all_line_literals_have_key(path, line_index + 1, line, keys)
            if gamepad_hints_depth >= 0:
                _assert_gamepad_hint_line_has_key(path, line_index + 1, line, keys)

func _assert_property_line_has_key(path: String, line_number: int, line: String, keys: Dictionary) -> void:
    var equals_index := line.find("=")
    if equals_index == -1:
        return
    var property_name := _extract_property_name(line.substr(0, equals_index).strip_edges())
    if not PLAYER_FACING_PROPERTIES.has(property_name):
        return
    var require_non_cyrillic_key := path.ends_with(".tscn")
    for value in _extract_quoted_strings(line.substr(equals_index + 1)):
        _assert_localization_key_exists(path, line_number, value, keys, require_non_cyrillic_key)

func _assert_call_line_has_key(path: String, line_number: int, line: String, keys: Dictionary) -> void:
    for marker in PLAYER_FACING_CALL_MARKERS:
        var from := 0
        while true:
            var marker_index := line.find(marker, from)
            if marker_index == -1:
                break
            var call_literal := _extract_first_call_literal(line, marker, marker_index)
            if call_literal != "":
                _assert_localization_key_exists(path, line_number, call_literal, keys, true)
            from = marker_index + marker.length()

func _assert_gamepad_hint_line_has_key(path: String, line_number: int, line: String, keys: Dictionary) -> void:
    var colon_index := line.find(":")
    if colon_index == -1:
        return
    var raw_key := line.substr(0, colon_index).strip_edges()
    if _extract_quoted_strings(raw_key).size() != 1:
        return
    for value in _extract_quoted_strings(line.substr(colon_index + 1)):
        _assert_localization_key_exists(path, line_number, value, keys)

func _assert_all_line_literals_have_key(path: String, line_number: int, line: String, keys: Dictionary) -> void:
    for value in _extract_quoted_strings(line):
        _assert_localization_key_exists(path, line_number, value, keys)

func _assert_localization_key_exists(path: String, line_number: int, value: String, keys: Dictionary, require_non_cyrillic_key: bool = false) -> void:
    var normalized := value.strip_edges()
    if normalized == "":
        return
    if _has_cyrillic(normalized):
        assert_true(keys.has(normalized), "Player-facing text must have localization CSV key: %s:%d -> %s" % [path, line_number, normalized])
        return
    if not require_non_cyrillic_key:
        return
    if not _requires_non_cyrillic_localization_key(path, normalized):
        return
    assert_true(keys.has(normalized), "Non-Cyrillic player-facing text must have localization CSV key or be an explicit technical exception: %s:%d -> %s" % [path, line_number, normalized])

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

func _extract_first_call_literal(line: String, marker: String, marker_index: int) -> String:
    var start := line.find("\"", marker_index + marker.length())
    if start == -1:
        return ""
    var prefix := line.substr(marker_index + marker.length(), start - marker_index - marker.length()).strip_edges()
    if prefix != "":
        return ""
    var current := ""
    var escaped := false
    for index in range(start + 1, line.length()):
        var character := line.substr(index, 1)
        if escaped:
            current += _unescape_character(character)
            escaped = false
        elif character == "\\":
            escaped = true
        elif character == "\"":
            return current
        else:
            current += character
    return ""

func _update_gamepad_hints_depth(stripped_line: String, current_depth: int) -> int:
    var next_depth := current_depth
    if current_depth < 0 and stripped_line.find("\"hints\"") != -1 and stripped_line.find("{") != -1:
        next_depth = 0
    if next_depth < 0:
        return next_depth
    next_depth += _count_char(stripped_line, "{")
    next_depth -= _count_char(stripped_line, "}")
    if next_depth <= 0:
        return -1
    return next_depth

func _count_char(value: String, needle: String) -> int:
    var count := 0
    var index := value.find(needle)
    while index != -1:
        count += 1
        index = value.find(needle, index + 1)
    return count

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

func _looks_like_translit_phrase_key(key: String, ru: String) -> bool:
    if key == "" or not _has_cyrillic(ru):
        return false
    if _has_cyrillic(key):
        return false
    if key.find(" ") == -1:
        return false
    return _has_ascii_letter(key)

func _has_ascii_letter(value: String) -> bool:
    for index in range(value.length()):
        var codepoint := value.unicode_at(index)
        if (codepoint >= 65 and codepoint <= 90) or (codepoint >= 97 and codepoint <= 122):
            return true
    return false

func _requires_non_cyrillic_localization_key(path: String, value: String) -> bool:
    if not _has_ascii_letter(value):
        return false
    if value.find("%") != -1:
        return false
    if ALLOWED_TECHNICAL_PLAYER_FACING_TEXT.has(path):
        var allowed_values: Dictionary = ALLOWED_TECHNICAL_PLAYER_FACING_TEXT[path]
        if allowed_values.has(value):
            return false
    return true

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
