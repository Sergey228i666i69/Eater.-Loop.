extends RefCounted

func prepare_entry(
	death_root: CanvasItem,
	retry_button: Button,
	title_presenter: Object,
	death_title_text: String,
	localized_retry_text: String
) -> void:
	if title_presenter != null:
		title_presenter.apply_next_title(death_title_text)
	if retry_button != null:
		retry_button.text = localized_retry_text
	if death_root != null:
		death_root.visible = false
