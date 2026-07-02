extends "res://tests/test_case.gd"

const UID_EXTENSIONS: Array[String] = [".gd", ".gdshader"]
const EXCLUDE_DIRS: Array[String] = [".godot", "addons"]

func run() -> Array[String]:
	_test_scripts_and_shaders_have_tracked_uid_sidecars()
	return get_failures()

func _test_scripts_and_shaders_have_tracked_uid_sidecars() -> void:
	var seen_uids: Dictionary = {}
	var resource_count := 0
	for extension in UID_EXTENSIONS:
		for path in utils.list_files("res://", extension, EXCLUDE_DIRS):
			resource_count += 1
			_assert_uid_sidecar(path, seen_uids)

	assert_true(resource_count > 0, "UID contract must find scripts or shaders to validate")

func _assert_uid_sidecar(resource_path: String, seen_uids: Dictionary) -> void:
	var uid_path := resource_path + ".uid"
	assert_true(FileAccess.file_exists(uid_path), "Resource must keep a sidecar UID file: %s" % uid_path)
	if not FileAccess.file_exists(uid_path):
		return
	var uid := FileAccess.get_file_as_string(uid_path).strip_edges()
	assert_true(uid.begins_with("uid://"), "Resource UID file must contain a Godot uid:// value: %s" % uid_path)
	if not uid.begins_with("uid://"):
		return
	assert_true(not seen_uids.has(uid), "Resource UID must be unique: %s is reused by %s and %s" % [uid, seen_uids.get(uid, ""), resource_path])
	seen_uids[uid] = resource_path
