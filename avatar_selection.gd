extends Control

# Safe references gamit ang find_child (hahanapin nito ang node sa buong tree)
@onready var back_button: BaseButton = find_child("BackButton", true, false) as BaseButton
@onready var confirm_button: BaseButton = find_child("ConfirmButton", true, false) as BaseButton
@onready var student_container: Control = find_child("StudentAvatarContainer", true, false) as Control
@onready var teacher_container: Control = find_child("TeacherAvatarContainer", true, false) as Control
@onready var student_grid: Control = find_child("StudentAvatarGrid", true, false) as Control
@onready var teacher_grid: Control = find_child("TeacherAvatarGrid", true, false) as Control

# Dynamic Role: Gagamitin kung "STUDENT" o "TEACHER" ang kasalukuyang user
var current_role: String = "STUDENT"
var selected_avatar_id: String = ""

# Data Mapping para sa bawat Card (batay sa aktwal na pangalan ng node sa Scene Tree)
var avatar_data: Dictionary = {
	"StudentCard": {"id": "student_female_1", "role": "STUDENT"},
	"StudentCard2": {"id": "student_female_2", "role": "STUDENT"},
	"StudentCard3": {"id": "student_male_1", "role": "STUDENT"},
	"StudentCard4": {"id": "student_male_2", "role": "STUDENT"},
	"TeacherCard": {"id": "teacher_female_1", "role": "TEACHER"},
	"TeacherCard2": {"id": "teacher_female_2", "role": "TEACHER"},
	"TeacherCard3": {"id": "teacher_male_1", "role": "TEACHER"},
	"TeacherCard4": {"id": "teacher_male_2", "role": "TEACHER"}
}

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "role" in gm and gm.role != "":
		current_role = gm.role

	_setup_initial_ui()
	_connect_signals()
	_filter_avatars_by_role()

func _all_cards() -> Array:
	var cards: Array = []
	if student_grid:
		cards.append_array(student_grid.get_children())
	if teacher_grid:
		cards.append_array(teacher_grid.get_children())
	return cards

func _setup_initial_ui() -> void:
	# Wala munang naka-select sa simula, kaya dimmed lahat ng cards
	for card in _all_cards():
		if card is Button:
			card.modulate = Color(0.6, 0.6, 0.6, 1)

func _filter_avatars_by_role() -> void:
	# Ipakita lamang ang container na tumutugma sa kasalukuyang role
	if student_container:
		student_container.visible = (current_role == "STUDENT")
	if teacher_container:
		teacher_container.visible = (current_role == "TEACHER")

func _connect_signals() -> void:
	# Connect Button Click events
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)

	# Connect Grid Cards Toggled event (gamit ang Toggle Mode)
	for card in _all_cards():
		if card is Button:
			card.toggled.connect(func(toggled_on: bool): _on_avatar_toggled(card, toggled_on))

func _on_avatar_toggled(card_node: Button, toggled_on: bool) -> void:
	if toggled_on:
		var card_name = card_node.name
		if avatar_data.has(card_name):
			selected_avatar_id = avatar_data[card_name]["id"]
			print("Napiling Avatar ID: ", selected_avatar_id)

		# I-highlight ang napiling card
		card_node.modulate = Color(1, 1, 1, 1)
	else:
		# I-dim ulit kapag napalitan ng ibang card
		card_node.modulate = Color(0.6, 0.6, 0.6, 1)

func _on_confirm_pressed() -> void:
	if selected_avatar_id.is_empty():
		print("Pumili muna ng Avatar bago mag-confirm!")
		return

	print("SUCCESS! Pinal na na-save ang Avatar: ", selected_avatar_id)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set("avatar_id", selected_avatar_id)

	get_tree().change_scene_to_file("res://campaign_map_screen.tscn")

func _on_back_pressed() -> void:
	# Bumalik sa Login o Role Selection
	get_tree().change_scene_to_file("res://login_page.tscn")
