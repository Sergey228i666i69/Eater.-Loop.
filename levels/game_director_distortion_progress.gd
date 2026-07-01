extends RefCounted

func advance_progress(current_progress: float, delta: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	if current_progress < 1.0:
		return min(1.0, current_progress + (delta / duration))
	return current_progress

func ease_out(progress: float) -> float:
	var clamped := clampf(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - clamped, 2.0)

func transition_strength(progress: float) -> float:
	var clamped := clampf(progress, 0.0, 1.0)
	return pow(1.0 - clamped, 2.0)
