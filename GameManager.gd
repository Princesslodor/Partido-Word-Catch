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

## --- LIFECYCLE ---
func _ready() -> void:
	# In the next step, this is where we'll LOAD saved data
	# from a file (user://save_data.json) when the app starts.
	print("GameManager ready! Player: ", player_name, " | Unlocked level: ", unlocked_level)
