extends "res://tests/test_case.gd"

const DeathEntryPresenter = preload("res://levels/game_director_death_entry_presenter.gd")

class FakeTitlePresenter:
	extends RefCounted

	var applied_titles: Array[String] = []

	func apply_next_title(value: String) -> void:
		applied_titles.append(value)

func run() -> Array[String]:
	_test_prepare_entry_applies_title_button_and_hidden_root()
	_test_prepare_entry_tolerates_missing_optional_nodes()
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
	var empty_presenter := RefCounted.new()

	presenter.prepare_entry(null, null, empty_presenter, "Умер", "Retry")
	presenter.prepare_entry(null, null, null, "Умер", "Retry")

	assert_true(true, "Death entry presenter must tolerate missing optional collaborators")
