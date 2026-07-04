extends "res://tests/test_case.gd"

const MusicStackStateScript = preload("res://levels/music_stack_state.gd")


func run() -> Array[String]:
	_test_push_pop_updates_caller_owned_entries()
	_test_removal_filters_by_stream_and_source_id()
	_test_clear_and_empty_pop_are_safe()
	return get_failures()


func _test_push_pop_updates_caller_owned_entries() -> void:
	var mirror: Array[Dictionary] = []
	var state = MusicStackStateScript.new(mirror)
	var stream := AudioStreamGenerator.new()
	var entry := {
		"stream": stream,
		"volume_db": -12.0,
		"source_id": 7,
		"source_kind": "event",
		"position": 2.5,
		"was_playing": true
	}

	state.push(entry)

	assert_eq(state.size(), 1, "Stack state must track pushed entries")
	assert_eq(mirror.size(), 1, "Stack state must update caller-owned mirror array")
	entry["source_id"] = 99
	assert_eq(int(mirror[0].get("source_id", 0)), 7, "Stack state must own a copy of pushed entries")

	var popped := state.pop()
	assert_eq(popped.get("stream", null), stream, "Stack state must pop the last pushed stream")
	assert_eq(int(popped.get("source_id", 0)), 7, "Stack state must preserve source id metadata")
	assert_true(mirror.is_empty(), "Popping must update caller-owned mirror array")


func _test_removal_filters_by_stream_and_source_id() -> void:
	var mirror: Array[Dictionary] = []
	var state = MusicStackStateScript.new(mirror)
	var stream_a := AudioStreamGenerator.new()
	var stream_b := AudioStreamGenerator.new()
	var stream_c := AudioStreamGenerator.new()

	state.push({"stream": stream_a, "source_id": 1})
	state.push({"stream": stream_b, "source_id": 2})
	state.push({"stream": stream_a, "source_id": 3})
	state.push({"stream": stream_c, "source_id": 4})

	state.remove_by_stream(stream_a)

	assert_eq(mirror.size(), 2, "Removing by stream must remove every matching entry")
	assert_eq(mirror[0].get("stream", null), stream_b, "Removing by stream must preserve unrelated entries")
	assert_eq(mirror[1].get("stream", null), stream_c, "Removing by stream must preserve later unrelated entries")

	state.remove_by_source_id(4)

	assert_eq(mirror.size(), 1, "Removing by source id must remove matching entries")
	assert_eq(int(mirror[0].get("source_id", 0)), 2, "Removing by source id must preserve unrelated entries")

	state.remove_by_stream(null)
	state.remove_by_source_id(0)
	assert_eq(mirror.size(), 1, "Null stream and source id 0 removals must be no-ops")


func _test_clear_and_empty_pop_are_safe() -> void:
	var mirror: Array[Dictionary] = []
	var state = MusicStackStateScript.new(mirror)

	assert_true(state.is_empty(), "New stack state must start empty")
	assert_true(state.pop().is_empty(), "Popping an empty stack must return an empty entry")

	state.push({"source_id": 5})
	state.clear()

	assert_true(state.is_empty(), "Clear must empty the stack state")
	assert_true(mirror.is_empty(), "Clear must update caller-owned mirror array")
