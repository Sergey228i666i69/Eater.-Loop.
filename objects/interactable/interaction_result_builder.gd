extends RefCounted
class_name InteractionResultBuilder

const RESULT_OUTCOME := "outcome"
const RESULT_SUCCESS := "success"
const RESULT_SOURCE := "source"
const RESULT_REASON := "reason"
const RESULT_PLAYER := "player"
const RESULT_PAYLOAD := "payload"
const PAYLOAD_REWARD_TYPE := "reward_type"
const PAYLOAD_KEY_ID := "key_id"
const REWARD_TYPE_KEY := "key"

static func with_payload(payload: Dictionary, result_data: Dictionary = {}) -> Dictionary:
	var result := result_data.duplicate(true)
	result[RESULT_PAYLOAD] = payload.duplicate(true)
	return result

static func key_reward(key_id: String, result_data: Dictionary = {}) -> Dictionary:
	return with_payload({
		PAYLOAD_REWARD_TYPE: REWARD_TYPE_KEY,
		PAYLOAD_KEY_ID: key_id.strip_edges(),
	}, result_data)

static func build(outcome: int, success: bool, source: Object, player: Node, result_data: Dictionary = {}) -> Dictionary:
	var result := result_data.duplicate(true)
	result[RESULT_PAYLOAD] = _normalized_payload(result)
	result[RESULT_OUTCOME] = outcome
	result[RESULT_SUCCESS] = success
	result[RESULT_SOURCE] = source
	if player != null and not result.has(RESULT_PLAYER):
		result[RESULT_PLAYER] = player
	return result

static func _normalized_payload(result_data: Dictionary) -> Dictionary:
	var raw_payload: Variant = result_data.get(RESULT_PAYLOAD, {})
	if raw_payload is Dictionary:
		return raw_payload.duplicate(true)
	return {}
