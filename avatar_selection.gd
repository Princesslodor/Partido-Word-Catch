extends Control

@onready var back_button: BaseButton = find_child("BackButton", true, false) as BaseButton
@onready var confirm_button: BaseButton = find_child("ConfirmButton", true, false) as BaseButton
@onready var student_container: Control = find_child("StudentAvatarContainer", true, false) as Control
@onready var teacher_container: Control = find_child("TeacherAvatarContainer", true, false) as Control
@onready var student_grid: Control = find_child("StudentAvatarGrid", true, false) as Control
@onready var teacher_grid: Control = find_child("TeacherAvatarGrid", true, false) as Control

var current_role: String = "STUDENT"
var selected_avatar_id: String = ""
var selected_avatar_path: String = ""

# Data Mapping na may hiwalay na image paths para sa Student at Teacher
var avatar_data: Dictionary = {
	"StudentCard": {
		"id": "student_female_1", 
		"role": "STUDENT", 
		"path": "res://StudentF1.png"
	},
	"StudentCard3": {
		"id": "student_male_1", 
		"role": "STUDENT", 
		"path": "res://Student.png"
	},
	"TeacherCard": {
		"id": "teacher_female_1", 
		"role": "TEACHER", 
		"path": "res://TeacherF1.png"
	},
	"TeacherCard3": {
		"id": "teacher_male_1", 
		"role": "TEACHER", 
		"path": "res://Teacher.png"
	}
}

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "role" in gm and gm.role != "":
		current_role = gm.role

	_setup_initial_ui()
	_filter_avatars_by_role()
	_connect_signals()
	_select_saved_avatar(gm)
	_connect_sound_to_all_buttons(self)
	await get_tree().process_frame
	_center_avatar_rows()

## A returning teacher (after Google sign-in) sees the avatar they picked
## before already selected, and can keep it or pick the other one.
func _select_saved_avatar(gm) -> void:
	if not gm or not "avatar_id" in gm or gm.avatar_id == "":
		return
	for card in _all_cards():
		var data: Dictionary = avatar_data.get(card.name, {})
		if data.get("id", "") == gm.avatar_id and data.get("role", "") == current_role:
			card.button_pressed = true

func _center_avatar_rows() -> void:
	_center_one_row(student_container, student_grid)
	_center_one_row(teacher_container, teacher_grid)

func _center_one_row(container: Control, grid: Control) -> void:
	if not container or not grid:
		return
	var subtitle: Control = container.find_child("SubtitleLabel", true, false) as Control
	if not subtitle or not confirm_button:
		return
	var subtitle_bottom: float = subtitle.global_position.y + subtitle.size.y
	var confirm_top: float = confirm_button.global_position.y
	var available: float = confirm_top - subtitle_bottom
	if available <= 0:
		return
	var target_top: float = subtitle_bottom + (available - grid.size.y) / 2.0
	grid.position.y = target_top - grid.get_parent().global_position.y

func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()

func _all_cards() -> Array:
	var cards: Array = []
	if student_grid:
		cards.append_array(_find_buttons(student_grid))
	if teacher_grid:
		cards.append_array(_find_buttons(teacher_grid))
	return cards

func _find_buttons(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is Button:
			found.append(child)
		else:
			found.append_array(_find_buttons(child))
	return found

func _setup_initial_ui() -> void:
	for card in _all_cards():
		if card is Button:
			card.modulate = Color(0.6, 0.6, 0.6, 1)

func _filter_avatars_by_role() -> void:
	# Itago/Ipakita ang tamang container batay sa role
	if student_container:
		student_container.visible = (current_role == "STUDENT")
	if teacher_container:
		teacher_container.visible = (current_role == "TEACHER")

func _connect_signals() -> void:
	# On a tall phone the back button stays near the top, at the same
	# height as on the other screens.
	if back_button:
		back_button.add_to_group(ScreenFit.TOP_GROUP)
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if confirm_button and not confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.connect(_on_confirm_pressed)

	for card in _all_cards():
		if card is Button:
			if not card.toggled.is_connected(_on_avatar_toggled.bind(card)):
				card.toggled.connect(func(toggled_on: bool): _on_avatar_toggled(card, toggled_on))

func _on_avatar_toggled(card_node: Button, toggled_on: bool) -> void:
	var card_name = card_node.name
	
	# Siguraduhing tumutugma ang itinuturong card sa kasalukuyang role
	if avatar_data.has(card_name):
		var card_role = avatar_data[card_name]["role"]
		if card_role != current_role:
			return

	if toggled_on:
		if avatar_data.has(card_name):
			selected_avatar_id = avatar_data[card_name]["id"]
			selected_avatar_path = avatar_data[card_name].get("path", "")
			print("Napiling Avatar ID: ", selected_avatar_id, " | Path: ", selected_avatar_path)

		# I-uncheck/dim ang ibang cards
		for other_card in _all_cards():
			if other_card != card_node:
				other_card.button_pressed = false
				other_card.modulate = Color(0.6, 0.6, 0.6, 1)

		card_node.modulate = Color(1, 1, 1, 1)
	else:
		card_node.modulate = Color(0.6, 0.6, 0.6, 1)

func _on_confirm_pressed() -> void:
	if selected_avatar_id.is_empty():
		print("Pumili muna ng Avatar bago mag-confirm!")
		return

	print("SUCCESS! Pinal na na-save ang Avatar: ", selected_avatar_id)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set("avatar_id", selected_avatar_id)
		gm.set("avatar_path", selected_avatar_path)
		if gm.has_method("save_game"):
			gm.save_game()

	if current_role == "TEACHER":
		# Save it on the teacher's class too, so students see the new one
		# (blank fields keep what the class already has).
		var sync = get_node_or_null("/root/SyncManager")
		if sync and sync.has_method("has_teacher_session") and sync.has_teacher_session():
			sync.teacher_save_my_class("", "", "", "", selected_avatar_id, Callable())
		Global.change_scene("res://teacher_dashboard.tscn")
	else:
		Global.change_scene("res://campaign_map_screen.tscn")

func _on_back_pressed() -> void:
	Global.change_scene("res://login_page.tscn")
