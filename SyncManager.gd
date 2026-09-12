extends Node
# ============================================
# SyncManager.gd
# ============================================
# Talks to Supabase so a teacher's leaderboard can see student progress
# from other devices. The game is fully playable offline - every sync
# call here is fire-and-forget: if there's no internet, or Supabase
# isn't configured yet, it just fails quietly and the game keeps using
# the local save (GameManager) as the source of truth. The next
# successful sync (e.g. next time the app has internet) pushes
# whatever the local save currently has, so nothing needs a queue.
#
# SETUP: paste your Supabase project's URL and anon/public API key
# below (Project Settings > API in the Supabase dashboard), then run
# supabase_schema.sql in the Supabase SQL Editor once.
# ============================================

const SUPABASE_URL: String = "https://uufsrfizpvgjuipkpqzv.supabase.co"
const SUPABASE_ANON_KEY: String = "sb_publishable_7rWRg70DOh-DPu6xUy5XWg_61DHfI7_"

const REQUEST_TIMEOUT: float = 8.0

func is_configured() -> bool:
	return SUPABASE_URL != "" and SUPABASE_ANON_KEY != ""

func _headers(extra: Array = []) -> PackedStringArray:
	var headers: Array = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY,
		"Content-Type: application/json",
	]
	headers.append_array(extra)
	return PackedStringArray(headers)

## Creates a throwaway HTTPRequest node so concurrent calls don't collide,
## and cleans it up once the response (or failure) comes back.
func _request(path: String, method: int, body: String = "", extra_headers: Array = []) -> HTTPRequest:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)
	var full_url := SUPABASE_URL + path
	var send_err := http.request(full_url, _headers(extra_headers), method, body)
	if send_err != OK:
		push_warning("SyncManager: request() failed to even start for %s - error code %s" % [full_url, send_err])
	http.request_completed.connect(func(result, response_code, _h, resp_body: PackedByteArray):
		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			push_warning("SyncManager: request to %s failed - result=%s response_code=%s body=%s" % [
				full_url, result, response_code, resp_body.get_string_from_utf8()
			])
	)
	return http

## --- CLASS SYNC (teacher side) ---
## Upserts the class row for this teacher's permanent class code.
func upsert_class(class_code: String, teacher_name: String, teacher_email: String, school_name: String, grade_subject: String, teacher_class_name: String) -> void:
	if not is_configured() or class_code == "":
		return

	var body := JSON.stringify({
		"class_code": class_code,
		"teacher_name": teacher_name,
		"teacher_email": teacher_email,
		"school_name": school_name,
		"grade_subject": grade_subject,
		"teacher_class_name": teacher_class_name,
	})

	var http := _request("/rest/v1/classes?on_conflict=class_code", HTTPClient.METHOD_POST, body, [
		"Prefer: resolution=merge-duplicates"
	])
	http.request_completed.connect(func(_result, _code, _h, _b): http.queue_free())

## --- CLASS LOOKUPS ---
## Shared helper: finds one row in `classes` where `field` = `value`.
## Calls back with: the class row (Dictionary) if a match exists, `false` if
## the lookup succeeded but nothing matched, or `null` if the lookup itself
## couldn't complete (offline/unconfigured/error) - so callers can tell
## "no such account/code" apart from "couldn't check".
func _find_class_by(field: String, value: String, on_result: Callable) -> void:
	if not is_configured() or value.strip_edges() == "":
		on_result.call(null)
		return

	var path := "/rest/v1/classes?%s=eq.%s&limit=1" % [field, value.strip_edges().uri_encode()]
	var http := _request(path, HTTPClient.METHOD_GET)
	http.request_completed.connect(func(result, response_code, _h, body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			on_result.call(null)
			return
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Array and parsed.size() > 0:
			on_result.call(parsed[0])
		else:
			on_result.call(false)
	)

## Looks up a teacher's class by the email they typed on the Login screen.
func find_class_by_email(teacher_email: String, on_result: Callable) -> void:
	_find_class_by("teacher_email", teacher_email, on_result)

## Looks up a class by the code a student typed to join it.
func find_class_by_code(class_code: String, on_result: Callable) -> void:
	_find_class_by("class_code", class_code, on_result)

## --- STUDENT PROGRESS SYNC ---
## Pushes this device's current GameManager progress up for the teacher to see.
func sync_student_progress() -> void:
	if not is_configured():
		return

	var gm = get_node_or_null("/root/GameManager")
	if not gm or gm.role != "STUDENT" or gm.class_code == "" or gm.device_id == "":
		return

	var body := JSON.stringify({
		"device_id": gm.device_id,
		"class_code": gm.class_code,
		"player_name": gm.player_name if gm.player_name != "" else "Student",
		"avatar_id": gm.avatar_id,
		"unlocked_level": gm.unlocked_level,
		"player_coins": gm.player_coins,
		"completed_levels": gm.completed_levels,
	})

	var http := _request("/rest/v1/students?on_conflict=device_id", HTTPClient.METHOD_POST, body, [
		"Prefer: resolution=merge-duplicates"
	])
	http.request_completed.connect(func(_result, _code, _h, _b): http.queue_free())

## --- TEACHER LEADERBOARD FETCH ---
## Calls back with an Array of student rows (each a Dictionary), ordered by
## unlocked_level descending. Calls back with an empty array if offline,
## unconfigured, or the class has no students yet.
func fetch_leaderboard(class_code: String, on_result: Callable) -> void:
	if not is_configured() or class_code == "":
		on_result.call([])
		return

	var path := "/rest/v1/students?class_code=eq.%s&order=unlocked_level.desc,player_coins.desc" % class_code.uri_encode()
	var http := _request(path, HTTPClient.METHOD_GET)
	http.request_completed.connect(func(result, response_code, _h, body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			on_result.call([])
			return
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Array:
			on_result.call(parsed)
		else:
			on_result.call([])
	)
