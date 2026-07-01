class_name FridgeCodeLockSession
extends RefCounted

static func create_lock_instance(code_lock_scene: PackedScene, access_code: String) -> Node:
	if code_lock_scene == null:
		return null
	var lock_instance := code_lock_scene.instantiate() as Node
	apply_access_code(lock_instance, access_code)
	return lock_instance

static func apply_access_code(lock_instance: Object, access_code: String) -> void:
	if lock_instance == null:
		return
	if "code_value" in lock_instance:
		lock_instance.set("code_value", access_code)
	elif "target_code" in lock_instance:
		lock_instance.set("target_code", access_code)
