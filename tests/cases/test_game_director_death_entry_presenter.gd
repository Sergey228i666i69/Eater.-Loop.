extends "res://tests/test_case.gd"

const DeathEntryPresenter = preload("res://levels/game_director_death_entry_presenter.gd")
const DEATH_ENTRY_PRESENTER_PATH := "res://levels/game_director_death_entry_presenter.gd"
const FORBIDDEN_DEATH_ENTRY_METHOD_PROBES := [
	"has_method(",
	"METHOD_APPLY_NEXT_TITLE",
	".call(METHOD_APPLY_NEXT_TITLE",
	".call(\"apply_next_title\"",
]

class FakeTitlePresenter:
	extends RefCounted

	var applied_titles: Array[String] = []

	func apply_next_title(value: String) -> void:
		applied_titles.append(value)

func run() -> Array[String]:
	_test_prepare_entry_applies_title_button_and_hidden_root()
	_test_prepare_entry_tolerates_missing_optional_nodes()
	_test_death_entry_uses_title_presenter_facade_directly()
	return get_failures()

func _test_prepare_entry_applies_title_button_and_hidden_root() -> void:
	var presenter: RefCounted = DeathEntryPresenter.new()
	var root := Control.new()
	var retry_button := Button.new()
	var title_presenter := FakeTitlePresenter.new()
	root.visible = true
	retry_button.text = "old"

	presenter.prepare_entry(root, retry_button, title_presenter, "Умер", "Retry")

	assert_eq(title_presenter.applied_titles, ["Умер"], "Death entry presenter must advance death title sequence")
	assert_eq(retry_button.text, "Retry", "Death entry presenter must use already-localized retry text")
	assert_eq(root.visible, false, "Death entry presenter must hide death root before fade")
	root.free()
	retry_button.free()

func _test_prepare_entry_tolerates_missing_optional_nodes() -> void:
	var presenter: RefCounted = DeathEntryPresenter.new()

	presenter.prepare_entry(null, null, null, "Умер", "Retry")

	assert_true(true, "Death entry presenter must tolerate missing optional collaborators")

func _test_death_entry_uses_title_presenter_facade_directly() -> void:
	var content := FileAccess.get_file_as_string(DEATH_ENTRY_PRESENTER_PATH)
	assert_true(content != "", "Failed to read script: %s" % DEATH_ENTRY_PRESENTER_PATH)
	for pattern in FORBIDDEN_DEATH_ENTRY_METHOD_PROBES:
		assert_true(
			content.find(pattern) == -1,
			"Death entry presenter must use the stable title presenter facade directly: %s" % pattern
		)
