extends RefCounted

func has_callback(scheme: Dictionary, name: String) -> bool:
	if not scheme.has(name):
		return false
	var callback: Variant = scheme.get(name, Callable())
	return callback is Callable and (callback as Callable).is_valid()

func invoke_callback(scheme: Dictionary, name: String, args: Array = []) -> bool:
	if not has_callback(scheme, name):
		return false
	call_callback(scheme, name, args)
	return true

func invoke_callback_consumed(scheme: Dictionary, name: String, args: Array = []) -> bool:
	if not has_callback(scheme, name):
		return false
	var result = call_callback(scheme, name, args)
	if typeof(result) == TYPE_BOOL:
		return bool(result)
	return true

func call_callback(scheme: Dictionary, name: String, args: Array = []) -> Variant:
	if not has_callback(scheme, name):
		return null
	var callback := scheme.get(name, Callable()) as Callable
	return callback.callv(args)
