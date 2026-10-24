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
# supabase_schema.sql, then supabase_hardening.sql, in the Supabase SQL
# Editor once (in that order). supabase_hardening.sql also lists the
# Google sign-in settings to turn on in the Supabase dashboard.
#
# SECURITY: every call below goes through a Postgres function
# (/rest/v1/rpc/<name>), not a direct table query. That's on purpose -
# see supabase_hardening.sql for why: the anon key below is meant to be
# public (it's committed in this repo), so Row Level Security on the
# `classes` and `students` tables denies direct access entirely, and each
# function here exposes only the exact narrow slice of data its one job
# needs (never a teacher's email, never a pupil's PIN).
#
# Teachers sign in with Google (see GOOGLE SIGN-IN below). Teacher calls
# carry that signed-in session instead of the anon key, and the database
# only shows a class's students to the teacher who owns it.
# ============================================

const SUPABASE_URL: String = "https://uufsrfizpvgjuipkpqzv.supabase.co"
const SUPABASE_ANON_KEY: String = "sb_publishable_7rWRg70DOh-DPu6xUy5XWg_61DHfI7_"

const REQUEST_TIMEOUT: float = 15.0

## last_error is set to this when the database refuses a PIN check
## because of too many wrong tries (supabase_hardening.sql's
## login_attempts). The pupil lookups below then call back with "locked".
const LOCKED_OUT: String = "too_many_attempts"

## Short human-readable reason the most recent failed request failed, so
## screens can show it to the user instead of a generic "no internet" -
## that's the only way to see what's actually going wrong on a device we
## can't attach a debugger to.
var last_error: String = ""

func _result_to_text(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "can't resolve host"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "can't connect"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS handshake error"
		HTTPRequest.RESULT_TIMEOUT:
			return "timed out"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "connection error"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "no response"
		HTTPRequest.RESULT_SUCCESS:
			return "http "
		_:
			return "error code " + str(result)

func is_configured() -> bool:
	return SUPABASE_URL != "" and SUPABASE_ANON_KEY != ""

## bearer: a signed-in teacher's access token, or "" to send the anon key.
func _headers(extra: Array = [], bearer: String = "") -> PackedStringArray:
	var headers: Array = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + (bearer if bearer != "" else SUPABASE_ANON_KEY),
		"Content-Type: application/json",
	]
	headers.append_array(extra)
	return PackedStringArray(headers)

## Creates a throwaway HTTPRequest node so concurrent calls don't collide,
## and cleans it up once the response (or failure) comes back.
func _request(path: String, method: int, body: String = "", extra_headers: Array = [], bearer: String = "") -> HTTPRequest:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)
	var full_url := SUPABASE_URL + path
	var send_err := http.request(full_url, _headers(extra_headers, bearer), method, body)
	if send_err != OK:
		last_error = "couldn't start request (code " + str(send_err) + ")"
		push_warning("SyncManager: request() failed to even start for %s - error code %s" % [full_url, send_err])
		# request() failing synchronously means request_completed will NEVER
		# fire on its own - callers (who connect to it right after this
		# function returns) would otherwise wait forever. Fire it ourselves,
		# deferred so it happens after callers have had a chance to connect.
		http.call_deferred("emit_signal", "request_completed", HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	http.request_completed.connect(func(result, response_code, _h, resp_body: PackedByteArray):
		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			last_error = _result_to_text(result) + (str(response_code) if result == HTTPRequest.RESULT_SUCCESS else "")
			push_warning("SyncManager: request to %s failed - result=%s response_code=%s body=%s" % [
				full_url, result, response_code, resp_body.get_string_from_utf8()
			])
	)
	return http

## --- RPC HELPER ---
## POSTs to a Postgres function via PostgREST (/rest/v1/rpc/<function_name>)
## and JSON-decodes the response body. Every function in supabase_hardening.sql
## is called this way instead of querying `classes`/`students` directly - see
## the SECURITY note at the top of this file. Calls back with the decoded
## value on success (an Array for a function that RETURNS TABLE, a bare
## bool/String/etc. for one that returns a scalar, or null for RETURNS VOID),
## or `null` if the request itself couldn't complete.
##
## as_teacher = true sends the signed-in teacher's session instead of the
## anon key (refreshing it first if it's about to expire), and calls back
## with null if no teacher is signed in.
##
## Every callback in this file is only called if it's still valid: a reply
## can arrive after the screen that asked has closed (e.g. the player already
## moved on), and calling into a freed screen is an error.
func _call_rpc(function_name: String, params: Dictionary, on_result: Callable, as_teacher: bool = false) -> void:
	if not is_configured():
		if on_result.is_valid(): on_result.call(null)
		return
	if not as_teacher:
		_send_rpc(function_name, params, on_result, "")
		return
	ensure_teacher_session(func(ok: bool):
		if not ok:
			if last_error == "":
				last_error = "not signed in"
			if on_result.is_valid(): on_result.call(null)
			return
		_send_rpc(function_name, params, on_result, _access_token)
	)

func _send_rpc(function_name: String, params: Dictionary, on_result: Callable, bearer: String) -> void:
	var body := JSON.stringify(params)
	var http := _request("/rest/v1/rpc/" + function_name, HTTPClient.METHOD_POST, body, [], bearer)
	http.request_completed.connect(func(result, response_code, _h, resp_body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			# Runs after _request()'s own failure handler (connected first),
			# so this more specific reason wins.
			if resp_body.get_string_from_utf8().contains(LOCKED_OUT):
				last_error = LOCKED_OUT
			if on_result.is_valid(): on_result.call(null)
			return
		if resp_body.size() == 0:
			# RETURNS VOID functions (e.g. sync_student_progress) reply 204
			# with an empty body - nothing to decode, and no caller reads
			# this value.
			if on_result.is_valid(): on_result.call(null)
			return
		if on_result.is_valid(): on_result.call(JSON.parse_string(resp_body.get_string_from_utf8()))
	)

## --- GOOGLE SIGN-IN (teachers, via Supabase Auth) ---
## Uses OAuth's PKCE flow with a loopback redirect, which needs no Android
## plugin or deep-link setup:
##   1. Open Supabase's Google sign-in page in the phone's browser, asking
##      it to send the browser back to http://127.0.0.1:43821/auth/callback.
##   2. While the browser is out, this node listens on that port.
##   3. After the teacher picks their Google account, the browser lands on
##      that address - i.e. on this app - carrying a one-time `code`. The
##      app answers with a "you can go back to the game" page.
##   4. The code plus the secret verifier that never left this phone are
##      swapped for a session (access token + refresh token).
## On Android the game is paused while the browser is in front, so the
## loopback address is served from its own thread: the browser gets its
## page right away instead of loading until the teacher switches back.
## The page tells the teacher to press the phone's Back button, which
## closes the tab and returns to the game. (A link that opens the app from
## the browser would need a deep-link intent filter in the Android
## manifest, i.e. a Gradle build.) The code is swapped for a session once
## the game is running again.
##
## Supabase dashboard setup is listed at the top of supabase_hardening.sql
## (enable the Google provider, and allow OAUTH_REDIRECT_URL as a
## Redirect URL).
const AUTH_SESSION_PATH: String = "user://auth_session.json"
const OAUTH_PORT: int = 43821
const OAUTH_REDIRECT_URL: String = "http://127.0.0.1:43821/auth/callback"
const OAUTH_TIMEOUT_MS: int = 5 * 60 * 1000

var _access_token: String = ""
var _refresh_token: String = ""
var _expires_at: int = 0                 # Unix seconds
## The signed-in teacher's Google email and name ("" when signed out).
var teacher_user_email: String = ""
var teacher_display_name: String = ""

var _oauth_server: TCPServer = null
var _oauth_thread: Thread = null
var _oauth_mutex: Mutex = Mutex.new()
var _oauth_stop: bool = false            # guarded by _oauth_mutex
var _oauth_params = null                 # guarded by _oauth_mutex; the callback's query once it arrives
var _oauth_verifier: String = ""
var _oauth_on_result: Callable = Callable()
var _oauth_deadline_ms: int = 0

var _refreshing: bool = false
var _refresh_waiters: Array = []

func _ready() -> void:
	set_process(false)
	_load_session()
	# Keep networking (and the offline retry below) running even while a
	# level pauses the scene tree.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var retry_timer := Timer.new()
	retry_timer.wait_time = OFFLINE_RETRY_SECONDS
	retry_timer.timeout.connect(retry_pending_sync)
	add_child(retry_timer)
	retry_timer.start()
	# Upload anything left over from an offline session as soon as the app
	# opens (deferred so GameManager has finished loading the save file).
	call_deferred("retry_pending_sync")

func _notification(what: int) -> void:
	# Coming back to the app is a good moment to try again - the phone may
	# have got its connection back while the game was in the background.
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		retry_pending_sync()

func has_teacher_session() -> bool:
	return _refresh_token != ""

func _base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

## Opens Google sign-in in the browser. Calls back with (ok: bool,
## message: String) - message is "" on success, otherwise a short reason
## to show the teacher.
func sign_in_with_google(on_result: Callable) -> void:
	if not is_configured():
		if on_result.is_valid(): on_result.call(false, "Sign-in isn't set up yet.")
		return
	_stop_oauth_listener()

	_oauth_server = TCPServer.new()
	var err := _oauth_server.listen(OAUTH_PORT, "127.0.0.1")
	if err != OK:
		_oauth_server = null
		if on_result.is_valid(): on_result.call(false, "Couldn't start sign-in (code " + str(err) + "). Close other apps and try again.")
		return

	_oauth_verifier = _base64url(Crypto.new().generate_random_bytes(32))
	var challenge := _base64url(_oauth_verifier.sha256_buffer())
	_oauth_on_result = on_result
	_oauth_deadline_ms = Time.get_ticks_msec() + OAUTH_TIMEOUT_MS
	# Built here because the server thread can't load resources.
	_oauth_logo_data_uri()
	_oauth_stop = false
	_oauth_params = null
	_oauth_thread = Thread.new()
	_oauth_thread.start(_oauth_serve)
	set_process(true)

	var url := SUPABASE_URL + "/auth/v1/authorize?provider=google" \
		+ "&redirect_to=" + OAUTH_REDIRECT_URL.uri_encode() \
		+ "&code_challenge=" + challenge \
		+ "&code_challenge_method=s256"
	OS.shell_open(url)

func _process(_delta: float) -> void:
	if _oauth_server == null:
		set_process(false)
		return
	if Time.get_ticks_msec() > _oauth_deadline_ms:
		_finish_oauth(false, "Sign-in timed out. Please try again.")
		return

	_oauth_mutex.lock()
	var params = _oauth_params
	_oauth_mutex.unlock()
	if params == null:
		return

	var code: String = params.get("code", "")
	if code == "":
		var reason: String = params.get("error_description", params.get("error", ""))
		_finish_oauth(false, "Sign-in was cancelled." + (" (" + reason + ")" if reason != "" else ""))
		return
	var verifier := _oauth_verifier
	# Stop listening but keep _oauth_on_result for _exchange_auth_code().
	_close_oauth_server()
	_exchange_auth_code(code, verifier)

## Runs on _oauth_thread: answers the browser on the loopback address,
## even while the game itself is paused in the background, and hands the
## callback's query to _process() through _oauth_params.
func _oauth_serve() -> void:
	while true:
		_oauth_mutex.lock()
		var stop := _oauth_stop
		_oauth_mutex.unlock()
		if stop:
			return
		if not _oauth_server.is_connection_available():
			OS.delay_msec(50)
			continue
		var peer := _oauth_server.take_connection()
		var request_text := _read_oauth_request(peer)
		if request_text == "":
			peer.disconnect_from_host()
			continue
		var params = _handle_oauth_request(peer, request_text)
		if params != null:
			_oauth_mutex.lock()
			_oauth_params = params
			_oauth_mutex.unlock()
			return

## Reads one HTTP request head from the browser (gives up after 5 s).
func _read_oauth_request(peer: StreamPeerTCP) -> String:
	var buf := PackedByteArray()
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return ""
		var available := peer.get_available_bytes()
		if available > 0:
			var chunk: Array = peer.get_data(available)
			if chunk[0] == OK:
				buf.append_array(chunk[1])
			var text := buf.get_string_from_utf8()
			if text.contains("\r\n\r\n"):
				return text
		else:
			OS.delay_msec(10)
	return ""

## Handles one HTTP request the browser sent to the loopback address.
## Returns the callback's query parameters, or null if this wasn't the
## callback (e.g. the browser asking for /favicon.ico).
func _handle_oauth_request(peer: StreamPeerTCP, request_text: String):
	var request_line := request_text.get_slice("\r\n", 0)
	var target := request_line.get_slice(" ", 1)
	if not target.begins_with("/auth/callback"):
		_send_oauth_page(peer, "404 Not Found", "")
		return null

	var params := {}
	var query := target.get_slice("?", 1) if target.contains("?") else ""
	for pair in query.split("&", false):
		params[pair.get_slice("=", 0)] = pair.get_slice("=", 1).replace("+", " ").uri_decode()

	if str(params.get("code", "")) == "":
		_send_oauth_page(peer, "200 OK", "Hindi natuloy ang pag-sign in.", "Pindutin ang Back ng phone para bumalik sa Partido Word Catch, at subukan muli.", false)
	else:
		_send_oauth_page(peer, "200 OK", "Naka-sign in ka na!", "Pindutin ang Back ng phone para bumalik sa Partido Word Catch.", true)
	return params

## The page the teacher's browser lands on after picking their Google
## account. Styled like the game (cream card, green/red accents) with the
## game logo inlined, since the browser can't load anything from res://.
func _send_oauth_page(peer: StreamPeerTCP, status: String, title: String, detail: String = "", ok: bool = true) -> void:
	var html := ""
	if title != "":
		var logo := _oauth_logo_uri
		var accent := "#4e7c38" if ok else "#b31c1c"
		html = "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" \
			+ "<title>Partido Word Catch</title><style>" \
			+ "body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;" \
			+ "font-family:Nunito,'Segoe UI',Roboto,sans-serif;background:linear-gradient(180deg,#8fd3f4 0%,#cdeccf 55%,#e9d6a3 100%)}" \
			+ ".card{box-sizing:border-box;background:#fff8ee;border:3px solid #bd6213;border-radius:24px;box-shadow:0 10px 30px rgba(0,0,0,.18);" \
			+ "max-width:420px;width:calc(100% - 32px);padding:28px 24px 32px;text-align:center;animation:pop .45s ease-out}" \
			+ ".logo{width:80%;max-width:300px;height:auto}" \
			+ ".badge{width:72px;height:72px;border-radius:50%;margin:8px auto 12px;display:flex;align-items:center;justify-content:center;" \
			+ "color:#fff;font-size:42px;font-weight:800;background:" + accent + ";animation:pop .5s .2s ease-out both}" \
			+ "h1{margin:0 0 8px;font-size:26px;color:" + accent + "}p{margin:0;font-size:17px;color:#7a6e65;line-height:1.4}" \
			+ ".back{display:inline-block;margin-top:18px;padding:10px 22px;border-radius:999px;border:2px dashed " + accent + ";color:" + accent + ";" \
			+ "font-size:18px;font-weight:800}" \
			+ "@keyframes pop{0%{transform:scale(.6);opacity:0}70%{transform:scale(1.06);opacity:1}100%{transform:scale(1)}}" \
			+ "</style></head><body><div class=\"card\">" \
			+ ("<img class=\"logo\" alt=\"Partido Word Catch\" src=\"" + logo + "\">" if logo != "" else "<h2>Partido Word Catch</h2>") \
			+ "<div class=\"badge\">" + ("&#10003;" if ok else "!") + "</div>" \
			+ "<h1>" + title.xml_escape() + "</h1><p>" + detail.xml_escape() + "</p>" \
			+ "<div class=\"back\">&#9664; Back</div>" \
			+ "</div></body></html>"
	var body := html.to_utf8_buffer()
	var head := "HTTP/1.1 %s\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [status, body.size()]
	peer.put_data(head.to_utf8_buffer())
	peer.put_data(body)
	peer.disconnect_from_host()

var _oauth_logo_uri: String = ""

## logo2.png as a data: URI (scaled down, made once). Read through the
## imported texture rather than the .png file, which isn't in exported builds.
func _oauth_logo_data_uri() -> String:
	if _oauth_logo_uri == "" and ResourceLoader.exists("res://logo2.png"):
		var tex := load("res://logo2.png") as Texture2D
		var img := tex.get_image() if tex else null
		if img:
			if img.is_compressed():
				img.decompress()
			if img.get_width() > 480:
				img.resize(480, int(480.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_LANCZOS)
			_oauth_logo_uri = "data:image/png;base64," + Marshalls.raw_to_base64(img.save_png_to_buffer())
	return _oauth_logo_uri

func _exchange_auth_code(code: String, verifier: String) -> void:
	var body := JSON.stringify({"auth_code": code, "code_verifier": verifier})
	var http := _request("/auth/v1/token?grant_type=pkce", HTTPClient.METHOD_POST, body)
	http.request_completed.connect(func(result, response_code, _h, resp_body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			_finish_oauth(false, "Couldn't finish signing in (" + last_error + "). Please try again.")
			return
		var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
		if not (parsed is Dictionary) or str(parsed.get("refresh_token", "")) == "":
			_finish_oauth(false, "Couldn't finish signing in. Please try again.")
			return
		_apply_session(parsed)
		_finish_oauth(true, "")
	)

func _finish_oauth(ok: bool, message: String) -> void:
	var callback := _oauth_on_result
	_stop_oauth_listener()
	if callback.is_valid():
		if callback.is_valid(): callback.call(ok, message)

func _close_oauth_server() -> void:
	if _oauth_thread != null:
		_oauth_mutex.lock()
		_oauth_stop = true
		_oauth_mutex.unlock()
		_oauth_thread.wait_to_finish()
		_oauth_thread = null
	_oauth_params = null
	if _oauth_server != null:
		_oauth_server.stop()
		_oauth_server = null
	_oauth_verifier = ""
	set_process(false)

func _stop_oauth_listener() -> void:
	_close_oauth_server()
	_oauth_on_result = Callable()

## Stores a session returned by /auth/v1/token (sign-in or refresh).
func _apply_session(data: Dictionary) -> void:
	_access_token = str(data.get("access_token", ""))
	_refresh_token = str(data.get("refresh_token", ""))
	_expires_at = int(Time.get_unix_time_from_system()) + int(data.get("expires_in", 3600))
	var user = data.get("user", {})
	if user is Dictionary:
		teacher_user_email = str(user.get("email", ""))
		var meta = user.get("user_metadata", {})
		if meta is Dictionary:
			teacher_display_name = str(meta.get("full_name", meta.get("name", "")))
	_save_session()

func _save_session() -> void:
	var file := FileAccess.open(AUTH_SESSION_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SyncManager: couldn't save the teacher sign-in session.")
		return
	file.store_string(JSON.stringify({
		"access_token": _access_token,
		"refresh_token": _refresh_token,
		"expires_at": _expires_at,
		"email": teacher_user_email,
		"name": teacher_display_name,
	}))

func _load_session() -> void:
	if not FileAccess.file_exists(AUTH_SESSION_PATH):
		return
	var file := FileAccess.open(AUTH_SESSION_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	_access_token = str(parsed.get("access_token", ""))
	_refresh_token = str(parsed.get("refresh_token", ""))
	_expires_at = int(parsed.get("expires_at", 0))
	teacher_user_email = str(parsed.get("email", ""))
	teacher_display_name = str(parsed.get("name", ""))

func _clear_session() -> void:
	_access_token = ""
	_refresh_token = ""
	_expires_at = 0
	teacher_user_email = ""
	teacher_display_name = ""
	if FileAccess.file_exists(AUTH_SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTH_SESSION_PATH))

## Signs the teacher out on this phone (and tells Supabase, best-effort).
func sign_out() -> void:
	_stop_oauth_listener()
	if _access_token != "" and is_configured():
		var http := _request("/auth/v1/logout", HTTPClient.METHOD_POST, "", [], _access_token)
		http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	_clear_session()

## Calls back with true once there's a usable access token, refreshing it
## first if it expires within a minute. Calls back with false if no
## teacher is signed in or the refresh failed. A refresh token Supabase
## rejects (revoked, expired) signs the teacher out; a refresh that only
## failed for lack of internet keeps the session for next time. Several
## calls during one refresh share it, since Supabase rotates the refresh
## token on every use.
func ensure_teacher_session(on_ready: Callable) -> void:
	if _refresh_token == "":
		if on_ready.is_valid(): on_ready.call(false)
		return
	if _access_token != "" and int(Time.get_unix_time_from_system()) < _expires_at - 60:
		if on_ready.is_valid(): on_ready.call(true)
		return
	_refresh_waiters.append(on_ready)
	if _refreshing:
		return
	_refreshing = true
	var body := JSON.stringify({"refresh_token": _refresh_token})
	var http := _request("/auth/v1/token?grant_type=refresh_token", HTTPClient.METHOD_POST, body)
	http.request_completed.connect(func(result, response_code, _h, resp_body: PackedByteArray):
		http.queue_free()
		var ok := false
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
			if parsed is Dictionary and str(parsed.get("access_token", "")) != "":
				_apply_session(parsed)
				ok = true
		elif result == HTTPRequest.RESULT_SUCCESS and response_code >= 400 and response_code < 500:
			_clear_session()
			last_error = "signed out, please sign in again"
		_refreshing = false
		var waiters := _refresh_waiters.duplicate()
		_refresh_waiters.clear()
		for waiter in waiters:
			if (waiter as Callable).is_valid(): (waiter as Callable).call(ok)
	)

## --- CLASS LOOKUPS ---
## Shared helper for the "find one class row" functions below: each RPC
## returns an Array (possibly empty, since they RETURN TABLE), so this
## turns that into the same three-way result every caller already expects:
## the class row (Dictionary) if a match exists, `false` if the lookup
## succeeded but nothing matched, or `null` if the lookup itself couldn't
## complete (offline/unconfigured/error/not signed in).
func _find_class_via_rpc(function_name: String, params: Dictionary, on_result: Callable, as_teacher: bool = false) -> void:
	_call_rpc(function_name, params, func(parsed):
		if parsed == null:
			if on_result.is_valid(): on_result.call(null)
		elif parsed is Array and parsed.size() > 0:
			if on_result.is_valid(): on_result.call(parsed[0])
		else:
			if on_result.is_valid(): on_result.call(false)
	, as_teacher)

## Looks up a class by the code a student typed to join it.
func find_class_by_code(class_code: String, on_result: Callable) -> void:
	if not is_configured() or class_code.strip_edges() == "":
		if on_result.is_valid(): on_result.call(null)
		return
	_find_class_via_rpc("find_class_by_code", {"p_class_code": class_code.strip_edges()}, on_result)

## --- TEACHER CLASS (needs a Google sign-in) ---
## The signed-in teacher's own class: a Dictionary, `false` if they
## haven't created one yet, or `null` if the lookup couldn't complete.
## A class registered before Google sign-in existed is matched by its
## email the first time (see supabase_hardening.sql's _claim_legacy_class).
func teacher_get_my_class(on_result: Callable) -> void:
	_find_class_via_rpc("teacher_get_my_class", {}, on_result, true)

## Creates the signed-in teacher's class the first time (the database
## picks the class code) and updates its details after that. The email
## always comes from the Google sign-in. Calls back with the class code
## (String), or null if it couldn't be saved.
func teacher_save_my_class(teacher_name: String, school_name: String, grade_subject: String, teacher_class_name: String, avatar_id: String, on_result: Callable) -> void:
	_call_rpc("teacher_save_my_class", {
		"p_teacher_name": teacher_name,
		"p_school_name": school_name,
		"p_grade_subject": grade_subject,
		"p_teacher_class_name": teacher_class_name,
		"p_avatar_id": avatar_id,
	}, func(parsed):
		if on_result.is_valid(): on_result.call(parsed if parsed is String and parsed != "" else null)
	, true)

## --- STUDENT PROGRESS SYNC ---
## True while a students-table upsert is in flight. Guards against a subtle
## race: save_game() can call sync_student_progress() twice in quick
## succession (e.g. a wrong answer costs a star then a heart, each its own
## save), and each call is its own independent HTTP request with no
## sequencing. Under real network jitter, the EARLIER (now-stale) request's
## response can land after the LATER one, so its upsert runs last and
## overwrites the newer data - the teacher's leaderboard would then show
## outdated coins/progress until the next sync. Coalescing concurrent calls
## into a single in-flight request, plus one guaranteed trailing resync,
## means only one upsert for this student is ever in flight at a time, so
## there's nothing left to arrive out of order.
var _progress_sync_in_flight: bool = false
var _progress_resync_pending: bool = false

## --- OFFLINE PLAY ---
## Gameplay never waits for the network: GameManager.save_game() writes to
## the phone first and sets pending_sync. Until an upload is accepted, this
## node retries every OFFLINE_RETRY_SECONDS, when the app is reopened or
## brought back to the front, and on the next save - so progress made with
## no internet shows up for the teacher automatically once it's back.
const OFFLINE_RETRY_SECONDS: float = 30.0

func retry_pending_sync() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.pending_sync and not _progress_sync_in_flight:
		sync_student_progress()

## Pushes this device's current GameManager progress up for the teacher to
## see. The PIN travels over HTTPS; supabase_hardening.sql's version of
## this function hashes it with bcrypt before it touches disk, and refuses
## the update if it doesn't match the PIN the account already has.
func sync_student_progress() -> void:
	if not is_configured():
		return

	var gm = get_node_or_null("/root/GameManager")
	if not gm or gm.role != "STUDENT" or gm.class_code == "" or gm.device_id == "":
		return

	if _progress_sync_in_flight:
		_progress_resync_pending = true
		return
	_progress_sync_in_flight = true

	var body := JSON.stringify({
		"p_device_id": gm.device_id,
		"p_class_code": gm.class_code,
		"p_player_name": gm.player_name if gm.player_name != "" else "Student",
		"p_pin": gm.student_pin,
		"p_avatar_id": gm.avatar_id,
		"p_unlocked_level": gm.unlocked_level,
		"p_player_coins": gm.player_coins,
		"p_completed_levels": gm.completed_levels,
	})
	# Not _call_rpc(): that reports success and failure of a RETURNS VOID
	# function the same way (null), and here we need to know which it was.
	var http := _request("/rest/v1/rpc/sync_student_progress", HTTPClient.METHOD_POST, body)
	http.request_completed.connect(func(result, response_code, _h, _resp_body):
		http.queue_free()
		_progress_sync_in_flight = false
		if _progress_resync_pending:
			# Progress changed while this upload was out - send the newer
			# data, and leave pending_sync set until that one lands.
			_progress_resync_pending = false
			sync_student_progress()
			return
		var reached_server: bool = result == HTTPRequest.RESULT_SUCCESS
		if reached_server and response_code >= 200 and response_code < 300:
			gm.mark_synced()
		elif reached_server and response_code >= 400 and response_code < 500 				and response_code != 408 and response_code != 429:
			# The server answered and refused (e.g. PIN mismatch): retrying
			# the same data would only be refused again. The progress stays
			# on this phone and goes up with the next save.
			push_warning("SyncManager: progress upload refused (http %s) - not retrying" % response_code)
			gm.mark_synced()
		# Otherwise (no internet, timeout, server error) pending_sync stays
		# set and the retry timer tries again.
	)

## --- CROSS-DEVICE STUDENT LOGIN ---
## Looks up an existing student account by exact name + PIN (a student only
## ever belongs to one class, so there's no need to also ask for the class
## code - it comes back as part of the matched row instead). Calls back
## with the student row (Dictionary) if a match exists, `false` if the
## lookup succeeded but nothing matched, "locked" if that name has had too
## many wrong PINs recently, or `null` if the lookup itself couldn't
## complete.
func find_student_account(player_name: String, pin: String, on_result: Callable) -> void:
	if not is_configured() or player_name.strip_edges() == "" or pin.strip_edges() == "":
		if on_result.is_valid(): on_result.call(null)
		return

	# No limit=1 here on purpose: name+PIN alone isn't guaranteed unique
	# across different classes, so we need to see if more than one row
	# matched before picking one - see the "ambiguous" handling below.
	_call_rpc("find_student_account", {
		"p_player_name": player_name.strip_edges(),
		"p_pin": pin.strip_edges(),
	}, func(parsed):
		if parsed == null:
			if on_result.is_valid(): on_result.call("locked" if last_error == LOCKED_OUT else null)
		elif parsed is Array and parsed.size() > 1:
			# Same name + PIN matches more than one account (likely in
			# different classes) - too ambiguous to safely log into one of
			# them automatically. Caller should ask the student to join by
			# class code instead, which scopes the lookup unambiguously.
			if on_result.is_valid(): on_result.call("ambiguous")
		elif parsed is Array and parsed.size() > 0:
			if on_result.is_valid(): on_result.call(parsed[0])
		else:
			if on_result.is_valid(): on_result.call(false)
	)

## Looks up an existing student account scoped to ONE specific class (used
## right after entering a class code, before finalizing "registration") -
## as opposed to find_student_account() above, which searches across every
## class for the standalone Login screen. Lets the class-code flow tell
## "this name+PIN already played in this class, restore them" apart from
## "this is a genuinely new student, start them at zero". Calls back with
## the student row (Dictionary) if a match exists, `false` if the lookup
## succeeded but nothing matched, "locked" after too many wrong PINs for
## that name, or `null` if it couldn't complete.
func find_student_in_class(class_code: String, player_name: String, pin: String, on_result: Callable) -> void:
	if not is_configured() or class_code.strip_edges() == "" or player_name.strip_edges() == "" or pin.strip_edges() == "":
		if on_result.is_valid(): on_result.call(null)
		return

	_call_rpc("find_student_in_class", {
		"p_class_code": class_code.strip_edges(),
		"p_player_name": player_name.strip_edges(),
		"p_pin": pin.strip_edges(),
	}, func(parsed):
		if parsed == null:
			if on_result.is_valid(): on_result.call("locked" if last_error == LOCKED_OUT else null)
		elif parsed is Array and parsed.size() > 0:
			if on_result.is_valid(): on_result.call(parsed[0])
		else:
			if on_result.is_valid(): on_result.call(false)
	)

## Re-points an existing student row at a NEW device_id, so logging into an
## account on a different phone doesn't create a second, duplicate row the
## next time that account syncs - it keeps updating the same one. Needs
## the account's PIN, so a student_id alone can't take over an account.
## Calls back with true/false for whether the claim succeeded.
func claim_student_account(student_id: String, pin: String, new_device_id: String, on_result: Callable) -> void:
	if not is_configured() or student_id == "" or pin.strip_edges() == "":
		if on_result.is_valid(): on_result.call(false)
		return

	_call_rpc("claim_student_account", {
		"p_student_id": student_id,
		"p_pin": pin.strip_edges(),
		"p_new_device_id": new_device_id,
	}, func(parsed):
		if on_result.is_valid(): on_result.call(parsed == true)
	)

## --- TEACHER LEADERBOARD FETCH ---
## Calls back with an Array of student rows (each a Dictionary), ordered by
## unlocked_level descending. Calls back with an empty array if offline,
## unconfigured, not signed in, or the class has no students yet. Only the
## class's own signed-in teacher gets rows back.
func fetch_leaderboard(class_code: String, on_result: Callable) -> void:
	if not is_configured() or class_code == "":
		if on_result.is_valid(): on_result.call([])
		return

	_call_rpc("fetch_leaderboard", {"p_class_code": class_code}, func(parsed):
		if parsed is Array:
			if on_result.is_valid(): on_result.call(parsed)
		else:
			if on_result.is_valid(): on_result.call([])
	, true)
