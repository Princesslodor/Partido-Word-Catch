extends Node
# ============================================
# GameManager.gd
# ============================================
# This is the central "brain" for player data.
# It holds: player name, role (STUDENT/TEACHER),
# unlocked levels, coins, and per-level progress.
#
# Why is this an Autoload/Singleton?
# Because we need to access this data from ANY scene
# (login -> map -> gameplay -> settings), and there should
# only be ONE GameManager for the whole game — not a new
# one created every time a scene loads.
#
# Author: [YOUR NAME]
# Date: [DATE]
# Registered as an Autoload in: Project Settings > Autoload
# ============================================

## --- PLAYER IDENTITY ---
var player_name: String = ""          # Name of the currently logged-in player
var role: String = "STUDENT"          # "STUDENT" or "TEACHER"
var student_pin: String = ""          # 4-digit PIN a student registers with
var avatar_id: String = ""            # Which avatar card the player picked
var device_id: String = ""            # Stable per-install id used to identify this player when syncing online

## --- TEACHER ACCOUNT INFO ---
var teacher_email: String = ""
var school_name: String = ""
var grade_subject: String = ""
var teacher_class_name: String = ""
var class_code: String = ""           # Class code a student entered / a teacher generated

## --- STUDENT'S JOINED CLASS INFO (looked up from the class code) ---
var joined_teacher_name: String = ""
var joined_class_name: String = ""
var joined_grade_subject: String = ""

## --- PROGRESS ---
var unlocked_level: int = 1           # Highest level the player can currently play (default: level 1 only)
var player_coins: int = 0             # Player's total coin balance
var player_hearts: int = 4            # Lives remaining in the current gameplay session

## --- PER-LEVEL COMPLETION DATA ---
## Dictionary structure: { level_num: { "completed": bool, "best_score": int } }
## Example: { 1: {"completed": true, "best_score": 100} }
var completed_levels: Dictionary = {}

## Stars remaining on a level the player left mid-attempt (before
## finishing it), so leaving for the campaign map and coming back
## doesn't hand them a fresh 3 stars for free. Cleared once that level
## is completed - replaying a finished level starts fresh again.
## Dictionary structure: { level_num: stars_remaining }
var in_progress_stars: Dictionary = {}

## --- SETTINGS ---
var is_sound_enabled: bool = true    # Sound effects (SFX bus)
var is_music_enabled: bool = true    # Background music (Music bus)


## --- SAVE FILE LOCATION ---
## "user://" is a special Godot path that points to a safe, writable folder
## on the player's device (different from "res://" which is our project files
## and is read-only once the game is exported/built).
const SAVE_FILE_PATH: String = "user://save_data.json"



## --- LIFECYCLE ---
func _ready() -> void:
	# Checked BEFORE load_game() runs, so we can tell "no account yet"
	# (truly fresh install) apart from "an account exists but failed to
	# load" (e.g. a corrupted save file) - the two cases below handle
	# these very differently.
	var had_save_file: bool = FileAccess.file_exists(SAVE_FILE_PATH)

	load_game()

	if device_id == "":
		device_id = _generate_device_id()
		if not had_save_file:
			save_game()
		# else: a save file exists but load_game() couldn't parse it -
		# do NOT immediately overwrite it with blank defaults here. That
		# would permanently destroy whatever was in it (name, class,
		# progress) over what might just be a transient read glitch.
		# The player will get a fresh save written naturally the next
		# time they register/play, without this code actively erasing
		# a file it never even confirmed was unrecoverable.

	print("GameManager ready! Player: ", player_name, " | Unlocked level: ", unlocked_level)

	# Safety net: always flush the latest data to disk when the app is
	# closed (desktop) or backgrounded/killed (mobile), in case a screen
	# forgot to call save_game() itself.
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
	
	
## Writes the current player data to a JSON file on disk.
## Call this every time something important changes
## (coins earned, level unlocked, settings changed).
func save_game() -> void:
	# Step 1: Put all the data we want to save into one Dictionary.
	var save_data: Dictionary = {
		"player_name": player_name,
		"role": role,
		"student_pin": student_pin,
		"avatar_id": avatar_id,
		"teacher_email": teacher_email,
		"school_name": school_name,
		"grade_subject": grade_subject,
		"teacher_class_name": teacher_class_name,
		"class_code": class_code,
		"joined_teacher_name": joined_teacher_name,
		"joined_class_name": joined_class_name,
		"joined_grade_subject": joined_grade_subject,
		"device_id": device_id,
		"unlocked_level": unlocked_level,
		"player_coins": player_coins,
		"player_hearts": player_hearts,
		"completed_levels": completed_levels,
		"in_progress_stars": in_progress_stars,
		"is_sound_enabled": is_sound_enabled,
		"is_music_enabled": is_music_enabled
	}

	# Step 2: Write to a TEMP file first, then swap it into place. If the
	# app gets killed mid-write (e.g. force-stopped from the Godot editor,
	# or a crash) while writing SAVE_FILE_PATH directly, the file is left
	# half-written and unparseable - and everything in it gets treated as
	# lost forever the next time the game starts. Writing to a separate
	# temp file first means a mid-write kill only leaves behind a broken
	# temp file; the real save file is never touched until the write has
	# fully succeeded.
	var temp_path: String = SAVE_FILE_PATH + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		print("ERROR: Could not open temp save file for writing. Error code: ", FileAccess.get_open_error())
		return

	# Step 3: Convert our Dictionary into a JSON text string, and write it to the file.
	var json_text: String = JSON.stringify(save_data)
	file.store_string(json_text)
	file.close()

	# Step 4: Swap the temp file into place as the real save file.
	var dir := DirAccess.open("user://")
	if dir:
		if dir.file_exists(SAVE_FILE_PATH):
			dir.remove(SAVE_FILE_PATH)
		dir.rename(temp_path, SAVE_FILE_PATH)
	else:
		print("ERROR: Could not access user:// to finalize the save file.")
		return

	print("Game saved successfully.")

	# Opportunistic online sync: fires and forgets. If there's no internet
	# or Supabase isn't configured yet, this just fails silently and the
	# local save above (already done) stays the source of truth.
	var sync = get_node_or_null("/root/SyncManager")
	if sync:
		if role == "STUDENT" and sync.has_method("sync_student_progress"):
			sync.sync_student_progress()
		elif role == "TEACHER" and class_code != "" and sync.has_method("upsert_class"):
			sync.upsert_class(class_code, player_name, teacher_email, school_name, grade_subject, teacher_class_name, avatar_id)


## --- LOAD ---
## Reads player data back from the JSON file on disk, if it exists.
## Called automatically once, when the game starts.
func load_game() -> void:
	# Step 1: Check if a save file even exists yet (e.g. brand new player, first launch).
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found -- starting fresh (this is normal for a new player).")
		return

	# Step 2: Open the file for reading.
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("ERROR: Could not open save file for reading. Error code: ", FileAccess.get_open_error())
		return

	# Step 3: Read the whole file as text, then close it.
	var json_text: String = file.get_as_text()
	file.close()

	# Step 4: Convert the JSON text back into a Dictionary we can use.
	var parsed_result = JSON.parse_string(json_text)
	if parsed_result == null:
		print("ERROR: Save file exists but couldn't be parsed as valid JSON. It may be corrupted.")
		return

	# Step 5: Copy each value back into our variables.
	var save_data: Dictionary = parsed_result
	player_name = save_data.get("player_name", "")
	role = save_data.get("role", "STUDENT")
	student_pin = save_data.get("student_pin", "")
	avatar_id = save_data.get("avatar_id", "")
	teacher_email = save_data.get("teacher_email", "")
	school_name = save_data.get("school_name", "")
	grade_subject = save_data.get("grade_subject", "")
	teacher_class_name = save_data.get("teacher_class_name", "")
	class_code = save_data.get("class_code", "")
	joined_teacher_name = save_data.get("joined_teacher_name", "")
	joined_class_name = save_data.get("joined_class_name", "")
	joined_grade_subject = save_data.get("joined_grade_subject", "")
	device_id = save_data.get("device_id", "")
	unlocked_level = save_data.get("unlocked_level", 1)
	player_coins = save_data.get("player_coins", 0)
	player_hearts = save_data.get("player_hearts", 4)
	completed_levels = save_data.get("completed_levels", {})
	in_progress_stars = save_data.get("in_progress_stars", {})
	is_sound_enabled = save_data.get("is_sound_enabled", true)
	is_music_enabled = save_data.get("is_music_enabled", true)

	print("Game loaded successfully. Player: ", player_name, " | Unlocked level: ", unlocked_level)
	
	
	
	## --- GAMEPLAY ACTIONS ---

## Generates a random per-install id (not tied to real hardware/account),
## used to tell players apart when syncing to the online leaderboard.
func _generate_device_id() -> String:
	var chars := "abcdefghijklmnopqrstuvwxyz0123456789"
	var id := ""
	for i in range(16):
		id += chars[randi() % chars.length()]
	return id

## Sets the current player's role and saves immediately.
func set_role(new_role: String) -> void:
	role = new_role
	save_game()

# Matches the card->id mapping in avatar_selection.gd's avatar_data table.
const AVATAR_TEXTURE_PATHS: Dictionary = {
	"student_female_1": "res://StudentF1.png",
	"student_female_2": "res://StudentF2.png",
	"student_male_1": "res://StudentM1.png",
	"student_male_2": "res://StudentM2.png",
	"teacher_female_1": "res://TeacherF1.png",
	"teacher_female_2": "res://TeacherFemale2.png",
	"teacher_male_1": "res://TeacherMale1.png",
	"teacher_male_2": "res://TeacherMale2.png",
}

## Looks up the image file for a given avatar_id (e.g. "student_female_1").
## Returns "" if the id is blank or unrecognized, so callers can fall back
## to a placeholder icon instead of crashing on a bad load().
func get_avatar_texture_path(for_avatar_id: String) -> String:
	return AVATAR_TEXTURE_PATHS.get(for_avatar_id, "")

## Returns this teacher's permanent class code, generating one the first
## time it's needed. A class only ever gets one code for its whole life.
func get_or_create_class_code() -> String:
	if class_code != "":
		return class_code

	const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	const CODE_LENGTH := 6
	var code := ""
	for i in range(CODE_LENGTH):
		code += CODE_CHARS[randi() % CODE_CHARS.length()]

	class_code = code
	save_game()
	return class_code

## Adds coins to the player's total and saves immediately.
## Call this whenever a player earns coins (e.g. completing a level).
func add_coins(amount: int) -> void:
	player_coins += amount
	print("Coins added: +", amount, " | New total: ", player_coins)
	save_game()


## Marks a level as completed, updates the best score if this run was better,
## unlocks the next level if this is a new milestone, and saves immediately.
## Call this when a player finishes a level successfully.
func complete_level(level_num: int, score: int) -> void:
	# Keyed by STRING, not int - completed_levels round-trips through
	# JSON.stringify/parse_string (save_game/load_game) and Supabase's
	# JSONB completed_levels column (student login/registration restore),
	# both of which always turn dictionary keys into strings. Using an int
	# key here would never match an existing string-keyed entry after any
	# relaunch or cross-device login, silently creating a SECOND entry for
	# an already-completed level instead of updating it - double-counting
	# its stars wherever completed_levels gets summed (e.g. the teacher
	# leaderboard's points column).
	var key := str(level_num)

	# Step 1: Record or update this level's completion data.
	if completed_levels.has(key):
		# Level was already completed before -- only update if this score is better.
		var previous_best: int = completed_levels[key].get("best_score", 0)
		if score > previous_best:
			completed_levels[key]["best_score"] = score
	else:
		# First time completing this level.
		completed_levels[key] = {"completed": true, "best_score": score}

	# Step 2: Unlock the next level, but only if this level was the current highest.
	# (Prevents accidentally "un-unlocking" progress if a player replays an old level.)
	if level_num >= unlocked_level:
		unlocked_level = level_num + 1
		print("Level ", level_num + 1, " unlocked!")

	print("Level ", level_num, " completed with score: ", score)
	save_game()
	
