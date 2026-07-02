extends "res://tests/test_case.gd"

const DeathTitlePresenter := preload("res://levels/game_director_death_title_presenter.gd")

func run() -> Array[String]:
	_test_default_death_title_uses_locale()
	_test_death_sequence_titles_use_locale()
	return get_failures()

func _test_default_death_title_uses_locale() -> void:
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en_US")

	var fixture := _build_presenter_fixture()
	var presenter: RefCounted = fixture["presenter"]
	var label: Label = fixture["label"]
	presenter.apply_title("Умер", false)
	assert_eq(label.text, "Died", "Death title presenter must localize default title text")
	fixture["owner"].free()
	TranslationServer.set_locale(original_locale)

func _test_death_sequence_titles_use_locale() -> void:
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en_US")

	var fixture := _build_presenter_fixture()
	var presenter: RefCounted = fixture["presenter"]
	var label: Label = fixture["label"]
	presenter.apply_next_title("Умер")
	assert_eq(label.text, "Made a mistake", "Death title sequence must localize non-glitch titles")

	for _index in range(6):
		presenter.apply_next_title("Умер")
	presenter.apply_next_title("Умер")
	assert_true(label.text.find("I will never deserve forgiveness.") != -1, "Death title sequence must localize the penance glitch title")
	assert_true(label.text.find("\n") != -1, "Penance death title must stay readable as two lines")
	fixture["owner"].free()
	TranslationServer.set_locale(original_locale)

func _build_presenter_fixture() -> Dictionary:
	var owner := Node.new()
	var label := Label.new()
	var background := Control.new()
	owner.add_child(label)
	owner.add_child(background)
	return {
		"owner": owner,
		"label": label,
		"background": background,
		"presenter": DeathTitlePresenter.new(owner, label, background),
	}
