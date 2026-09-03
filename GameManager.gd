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

## --- PROGRESS ---
var unlocked_level: int = 1           # Highest level the player can currently play (default: level 1 only)
var player_coins: int = 0             # Player's total coin balance

## --- PER-LEVEL COMPLETION DATA ---
## Dictionary structure: { level_num: { "completed": bool, "best_score": int } }
## Example: { 1: {"completed": true, "best_score": 100} }
var completed_levels: Dictionary = {}

## --- SETTINGS ---
var is_sound_enabled: bool = true


## --- SAVE FILE LOCATION ---
## "user://" is a special Godot path that points to a safe, writable folder
## on the player's device (different from "res://" which is our project files
## and is read-only once the game is exported/built).
const SAVE_FILE_PATH: String = "user://save_data.json"



## --- LIFECYCLE ---
func _ready() -> void:
	# In the next step, this is where we'll LOAD saved data
	# from a file (user://save_data.json) when the app starts.
	load_game()
	print("GameManager ready! Player: ", player_name, " | Unlocked level: ", unlocked_level)
	
	
## Writes the current player data to a JSON file on disk.
## Call this every time something important changes
## (coins earned, level unlocked, settings changed).
func save_game() -> void:
	# Step 1: Put all the data we want to save into one Dictionary.
	var save_data: Dictionary = {
		"player_name": player_name,
		"role": role,
		"unlocked_level": unlocked_level,
		"player_coins": player_coins,
		"completed_levels": completed_levels,
		"is_sound_enabled": is_sound_enabled
	}

	# Step 2: Open the save file for writing (this creates the file if it doesn't exist yet).
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		# This means the file couldn't be opened -- print an error so we notice.
		print("ERROR: Could not open save file for writing. Error code: ", FileAccess.get_open_error())
		return

	# Step 3: Convert our Dictionary into a JSON text string, and write it to the file.
	var json_text: String = JSON.stringify(save_data)
	file.store_string(json_text)
	file.close()

	print("Game saved successfully.")


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
	unlocked_level = save_data.get("unlocked_level", 1)
	player_coins = save_data.get("player_coins", 0)
	completed_levels = save_data.get("completed_levels", {})
	is_sound_enabled = save_data.get("is_sound_enabled", true)

	print("Game loaded successfully. Player: ", player_name, " | Unlocked level: ", unlocked_level)
	
	
	
	## --- GAMEPLAY ACTIONS ---

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
	# Step 1: Record or update this level's completion data.
	if completed_levels.has(level_num):
		# Level was already completed before -- only update if this score is better.
		var previous_best: int = completed_levels[level_num].get("best_score", 0)
		if score > previous_best:
			completed_levels[level_num]["best_score"] = score
	else:
		# First time completing this level.
		completed_levels[level_num] = {"completed": true, "best_score": score}

	# Step 2: Unlock the next level, but only if this level was the current highest.
	# (Prevents accidentally "un-unlocking" progress if a player replays an old level.)
	if level_num >= unlocked_level:
		unlocked_level = level_num + 1
		print("Level ", level_num + 1, " unlocked!")

	print("Level ", level_num, " completed with score: ", score)
	save_game()
	
