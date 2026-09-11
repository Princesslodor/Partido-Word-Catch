extends Control

# Safe references gamit ang find_child (hahanapin nito ang node sa buong tree)
@onready var back_button: Button = find_child("BackButton", true, false) as Button
@onready var confirm_button: Button = find_child("ConfirmButton", true, false) as Button
@onready var avatar_grid: Control = _get_avatar_grid()

# Dynamic Role: Gagamitin kung "STUDENT" o "TEACHER" ang kasalukuyang user
var current_role: String = "TEACHER" 
var selected_avatar_id: String = ""

# Data Mapping para sa bawat Card
var avatar_data: Dictionary = {
	"Card1": {"id": "teacher_male_1", "role": "TEACHER"},
	"Card2": {"id": "teacher_male_2", "role": "TEACHER"},
	"Card3": {"id": "teacher_female_1", "role": "TEACHER"},
	"Card4": {"id": "teacher_female_2", "role": "TEACHER"}
}

func _ready() -> void:
	_setup_initial_ui()
	_connect_signals()
	_filter_avatars_by_role()

# Helper function para mahanap ang Container kahit ano pa ang pangalan nito sa Scene Tree
func _get_avatar_grid() -> Control:
	var grid = find_child("AvatarGrid", true, false)
	if not grid:
		grid = find_child("StudentAvatarGrid", true, false)
	if not grid:
		grid = find_child("StudentAvatarContainer", true, false)
	return grid as Control

func _setup_initial_ui() -> void:
	if not avatar_grid:
		print("WARNING: Walang nahanap na Avatar Grid/Container!")
		return
		
	# Itago muna ang lahat ng Active Badges sa simula
	for card in avatar_grid.get_children():
		if card is Button:
			var active_badge = card.find_child("ActiveBadge", true, false)
			if active_badge:
				active_badge.hide()

func _filter_avatars_by_role() -> void:
	if not avatar_grid:
		return
		
	# Ipakita lamang ang cards na tumutugma sa kasalukuyang role
	for card in avatar_grid.get_children():
		if card is Button and avatar_data.has(card.name):
			if avatar_data[card.name]["role"] == current_role:
				card.show()
			else:
				card.hide()

func _connect_signals() -> void:
	# Connect Button Click events
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)

	# Connect Grid Cards Toggled event (gamit ang Toggle Mode)
	if avatar_grid:
		for card in avatar_grid.get_children():
			if card is Button:
				card.toggled.connect(func(toggled_on: bool): _on_avatar_toggled(card, toggled_on))

func _on_avatar_toggled(card_node: Button, toggled_on: bool) -> void:
	var active_badge = card_node.find_child("ActiveBadge", true, false)
	
	if toggled_on:
		var card_name = card_node.name
		if avatar_data.has(card_name):
			selected_avatar_id = avatar_data[card_name]["id"]
			print("Napiling Avatar ID: ", selected_avatar_id)
		
		# Ipakita ang "ACTIVE" badge kapag napili
		if active_badge:
			active_badge.show()
	else:
		# Itago ang "ACTIVE" badge kapag pinalitan ng ibang card
		if active_badge:
			active_badge.hide()

func _on_confirm_pressed() -> void:
	if selected_avatar_id.is_empty():
		print("Pumili muna ng Avatar bago mag-confirm!")
		return
		
	print("SUCCESS! Pinal na na-save ang Avatar: ", selected_avatar_id)
	
	# Palitan ng tamang scene path patungo sa susunod na screen
	# get_tree().change_scene_to_file("res://dashboard.tscn")

func _on_back_pressed() -> void:
	# Bumalik sa Login o Role Selection
	get_tree().change_scene_to_file("res://login_page.tscn")
