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

func run() -> Array[String]:
    _test_localization_csv_is_complete()
    _test_runtime_text_sources_have_no_mojibake()
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
