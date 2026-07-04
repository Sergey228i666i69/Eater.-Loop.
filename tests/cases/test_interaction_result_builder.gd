extends "res://tests/test_case.gd"

const InteractionResultBuilderScript = preload("res://objects/interactable/interaction_result_builder.gd")

func run() -> Array[String]:
	_test_build_adds_metadata_and_typed_payload()
	_test_key_reward_uses_canonical_payload_schema()
	_test_non_dictionary_payload_is_normalized()
	return get_failures()

func _test_build_adds_metadata_and_typed_payload() -> void:
	var source := Node.new()
	var player := Node.new()
	var raw_payload := {
		"reward_type": "key",
		"key_id": "door_key",
		"nested": {
			"count": 1
		}
	}
	var result_data := InteractionResultBuilderScript.with_payload(raw_payload, {
		"legacy_marker": "kept"
	})
	var result := InteractionResultBuilderScript.build(
		InteractiveObject.InteractionOutcome.SUCCEEDED,
		true,
		source,
		player,
		result_data
	)

	assert_eq(int(result.get(InteractionResultBuilderScript.RESULT_OUTCOME)), InteractiveObject.InteractionOutcome.SUCCEEDED, "Result must expose interaction outcome")
	assert_true(bool(result.get(InteractionResultBuilderScript.RESULT_SUCCESS)), "Result must expose success flag")
	assert_eq(result.get(InteractionResultBuilderScript.RESULT_SOURCE), source, "Result must expose source object")
	assert_eq(result.get(InteractionResultBuilderScript.RESULT_PLAYER), player, "Result must expose player when available")
	assert_eq(str(result.get("legacy_marker")), "kept", "Result must preserve custom top-level data")
	assert_true(result.get(InteractionResultBuilderScript.RESULT_PAYLOAD) is Dictionary, "Result payload must be a dictionary")

	var payload: Dictionary = result.get(InteractionResultBuilderScript.RESULT_PAYLOAD, {})
	assert_eq(str(payload.get(InteractionResultBuilderScript.PAYLOAD_REWARD_TYPE)), InteractionResultBuilderScript.REWARD_TYPE_KEY, "Payload must preserve reward type")
	assert_eq(str(payload.get(InteractionResultBuilderScript.PAYLOAD_KEY_ID)), "door_key", "Payload must preserve key id")
	var nested_payload: Dictionary = payload.get("nested", {})
	assert_eq(int(nested_payload.get("count")), 1, "Payload must preserve nested data")

	raw_payload["key_id"] = "changed"
	var raw_nested: Dictionary = raw_payload.get("nested", {})
	raw_nested["count"] = 9
	assert_eq(str(payload.get("key_id")), "door_key", "Payload must not alias the original input dictionary")
	assert_eq(int(nested_payload.get("count")), 1, "Nested payload must not alias the original input dictionary")

	source.free()
	player.free()

func _test_key_reward_uses_canonical_payload_schema() -> void:
	var result_data := InteractionResultBuilderScript.key_reward(" door_key ", {
		"legacy_marker": "kept"
	})
	var result := InteractionResultBuilderScript.build(
		InteractiveObject.InteractionOutcome.SUCCEEDED,
		true,
		null,
		null,
		result_data
	)

	assert_eq(str(result.get("legacy_marker")), "kept", "Key reward helper must preserve compatible top-level data")
	var payload: Dictionary = result.get(InteractionResultBuilderScript.RESULT_PAYLOAD, {})
	assert_eq(str(payload.get(InteractionResultBuilderScript.PAYLOAD_REWARD_TYPE)), InteractionResultBuilderScript.REWARD_TYPE_KEY, "Key reward helper must use canonical reward type")
	assert_eq(str(payload.get(InteractionResultBuilderScript.PAYLOAD_KEY_ID)), "door_key", "Key reward helper must normalize key ids")

func _test_non_dictionary_payload_is_normalized() -> void:
	var result := InteractionResultBuilderScript.build(
		InteractiveObject.InteractionOutcome.FAILED,
		false,
		null,
		null,
		{
			InteractionResultBuilderScript.RESULT_REASON: "locked",
			InteractionResultBuilderScript.RESULT_PAYLOAD: "legacy string"
		}
	)

	assert_true(not bool(result.get(InteractionResultBuilderScript.RESULT_SUCCESS)), "Failed result must expose false success flag")
	assert_eq(str(result.get(InteractionResultBuilderScript.RESULT_REASON)), "locked", "Result must preserve failure reason")
	assert_true(result.get(InteractionResultBuilderScript.RESULT_PAYLOAD) is Dictionary, "Reserved payload field must normalize to dictionary")
	var payload: Dictionary = result.get(InteractionResultBuilderScript.RESULT_PAYLOAD, {})
	assert_true(payload.is_empty(), "Non-dictionary payload data must normalize to an empty payload")
