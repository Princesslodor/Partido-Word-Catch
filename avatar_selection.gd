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
# Isang babae, isang lalaki lang bawat role (2026-09-27) - inalis ang mga
# "_2" variant card mula sa Scene Tree, kaya wala na ring entry dito.
var avatar_data: Dictionary = {
	"StudentCard": {"id": "student_female_1", "role": "STUDENT"},
	"StudentCard3": {"id": "student_male_1", "role": "STUDENT"},
	"TeacherCard": {"id": "teacher_female_1", "role": "TEACHER"},
	"TeacherCard3": {"id": "teacher_male_1", "role": "TEACHER"}
}

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "role" in gm and gm.role != "":
		current_role = gm.role

	_setup_initial_ui()
	_connect_signals()
	_filter_avatars_by_role()
	_connect_sound_to_all_buttons(self)
	await get_tree().process_frame
	_center_avatar_rows()

## Positions the Female/Male card row so it sits vertically centered in the
## leftover space between the subtitle text and the Confirm button, instead
## of a fixed offset guessed ahead of time - computed here, after layout,
## from each node's REAL on-screen size, so it stays centered regardless of
## resolution or any future change to the panel/subtitle/button sizes.
func _center_avatar_rows() -> void:
	_center_one_row(student_container, student_grid)
	_center_one_row(teacher_container, teacher_grid)

func _center_one_row(container: Control, grid: Control) -> void:
	if not container or not grid:
		return
	var subtitle: Control = container.find_child("SubtitleLabel", true, false) as Control
	if not subtitle or not confirm_button:
		return
	# Everything below is compared in GLOBAL (screen) space first, since
	# grid's parent (TopBar) and confirm_button (a direct child of the
	# scene root) don't share the same local coordinate space.
	var subtitle_bottom: float = subtitle.global_position.y + subtitle.size.y
	var confirm_top: float = confirm_button.global_position.y
	var available: float = confirm_top - subtitle_bottom
	if available <= 0:
		return
	var target_top: float = subtitle_bottom + (available - grid.size.y) / 2.0
	# Convert back into the grid's own parent's local space before assigning.
	grid.position.y = target_top - grid.get_parent().global_position.y

# --- AUDIO CLICK SYSTEM ---
func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()

## Each card Button now sits inside its own VBoxContainer (paired with its
## "Female"/"Male" caption Label) so the grid's direct children are the
## VBoxContainers, not the Buttons themselves - this walks one level
## further to find the actual Button cards regardless of that wrapping.
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
		if gm.has_method("save_game"):
			gm.save_game()

	if gm and "role" in gm and gm.role == "TEACHER":
		get_tree().change_scene_to_file("res://teacher_dashboard.tscn")
	else:
		get_tree().change_scene_to_file("res://campaign_map_screen.tscn")

func _on_back_pressed() -> void:
	# Bumalik sa Login o Role Selection
	get_tree().change_scene_to_file("res://login_page.tscn")
