extends Control

# Override the QuitGameButton's label per-instance - e.g. "MENU" when this
# settings menu is opened from inside a level (where it just returns to the
# campaign map, not a real app quit), left blank to keep the scene's default
# "QUIT GAME" wording elsewhere.
@export var quit_button_text: String = ""

# Shows a separate LOGOUT button (always returns to the role selection
# screen, res://login_page.tscn) alongside Quit Game - opt-in per instance
# since it isn't relevant everywhere this menu is used (e.g. mid-level).
@export var show_logout_button: bool = false

# --- SCENE NODE REFERENCES ---
@onready var close_button: BaseButton = $BackgroundOverlay/PopupBoard/CloseButton if has_node("BackgroundOverlay/PopupBoard/CloseButton") else null
@onready var quit_game_button: BaseButton = $QuitGameButton if has_node("QuitGameButton") else null
@onready var logout_button: BaseButton = $LogoutButton if has_node("LogoutButton") else null

# Custom Toggles
@onready var sound_toggle: Button = $BackgroundOverlay/PopupBoard/CustomToggle/Panel/SoundRow/SoundToggle if has_node("BackgroundOverlay/PopupBoard/CustomToggle/Panel/SoundRow/SoundToggle") else null
@onready var music_toggle: Button = $BackgroundOverlay/PopupBoard/CustomToggle/Panel/MusicRow/MusicToggle if has_node("BackgroundOverlay/PopupBoard/CustomToggle/Panel/MusicRow/MusicToggle") else null

# Account Information
@onready var name_label: Label = $BackgroundOverlay/PopupBoard/CustomToggle/AccountCard/HBoxContainer/NameLabel if has_node("BackgroundOverlay/PopupBoard/CustomToggle/AccountCard/HBoxContainer/NameLabel") else null
@onready var grade_label: Label = $BackgroundOverlay/PopupBoard/CustomToggle/AccountCard/HBoxContainer/GradeLabel if has_node("BackgroundOverlay/PopupBoard/CustomToggle/AccountCard/HBoxContainer/GradeLabel") else null
@onready var section_label: Label = $BackgroundOverlay/PopupBoard/CustomToggle/AccountCard/HBoxContainer/SectionLabel if has_node("BackgroundOverlay/PopupBoard/CustomToggle/AccountCard/HBoxContainer/SectionLabel") else null

func _ready():
	hide()
	_fix_mouse_filters()
	if quit_game_button and quit_button_text != "":
		quit_game_button.text = quit_button_text
	if logout_button:
		logout_button.visible = show_logout_button
	_connect_signals()
	_load_saved_settings()
	_load_account_info()

func _load_account_info():
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	var display_name: String = gm.player_name if "player_name" in gm and gm.player_name != "" else "-"
	if name_label:
		name_label.text = "Name: " + display_name

	# A teacher's own grade/section live in different fields than a
	# student's - joined_grade_subject/joined_class_name only describe the
	# class a STUDENT joined, which are empty for a teacher account.
	var is_teacher: bool = "role" in gm and gm.role == "TEACHER"
	var grade_subject: String
	var section: String
	if is_teacher:
		grade_subject = gm.grade_subject if "grade_subject" in gm and gm.grade_subject != "" else "-"
		section = gm.teacher_class_name if "teacher_class_name" in gm and gm.teacher_class_name != "" else "-"
	else:
		grade_subject = gm.joined_grade_subject if "joined_grade_subject" in gm and gm.joined_grade_subject != "" else "-"
		section = gm.joined_class_name if "joined_class_name" in gm and gm.joined_class_name != "" else "-"

	if grade_label:
		grade_label.text = "Grade Level: " + grade_subject
	if section_label:
		section_label.text = "Section: " + section

func _fix_mouse_filters():
	if has_node("BackgroundOverlay"):
		$BackgroundOverlay.mouse_filter = Control.MOUSE_FILTER_PASS
	if has_node("BackgroundOverlay/PopupBoard"):
		$BackgroundOverlay/PopupBoard.mouse_filter = Control.MOUSE_FILTER_PASS

func _connect_signals():
	# Navigation Signals
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	if quit_game_button and not quit_game_button.pressed.is_connected(_on_quit_pressed):
		quit_game_button.pressed.connect(_on_quit_pressed)

	if logout_button and not logout_button.pressed.is_connected(_on_logout_pressed):
		logout_button.pressed.connect(_on_logout_pressed)

	# Audio Toggle Signals
	if sound_toggle and not sound_toggle.toggle_changed.is_connected(_on_sound_toggled):
		sound_toggle.toggle_changed.connect(_on_sound_toggled)

	if music_toggle and not music_toggle.toggle_changed.is_connected(_on_music_toggled):
		music_toggle.toggle_changed.connect(_on_music_toggled)

# --- NAVIGATION LOGIC ---
func _on_close_pressed():
	hide()

func _on_quit_pressed():
	# Dynamic search para sa ExitConfirmationPopup
	var exit_popup = get_node_or_null("../ExitConfirmationPopup")
	if not exit_popup:
		exit_popup = get_tree().root.find_child("ExitConfirmationPopup", true, false)

	if exit_popup:
		if exit_popup.has_method("open_popup"):
			exit_popup.open_popup()
		else:
			exit_popup.show()
			exit_popup.move_to_front()
	else:
		print("ERROR: Hindi mahanap ang ExitConfirmationPopup node!")

func _on_logout_pressed():
	# Separate from ExitConfirmationPopup so Quit Game and Logout can have
	# different targets/behavior at the same time.
	var popup = get_node_or_null("../LogoutConfirmationPopup")
	if not popup:
		popup = get_tree().root.find_child("LogoutConfirmationPopup", true, false)

	if popup:
		if popup.has_method("open_popup"):
			popup.open_popup()
		else:
			popup.show()
			popup.move_to_front()
	else:
		print("ERROR: Hindi mahanap ang LogoutConfirmationPopup node!")

# --- AUDIO LOGIC ---
func _on_sound_toggled(is_on: bool):
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not is_on)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set("is_sound_enabled", is_on)
		if gm.has_method("save_game"):
			gm.save_game()

func _on_music_toggled(is_on: bool):
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not is_on)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set("is_music_enabled", is_on)
		if gm.has_method("save_game"):
			gm.save_game()

func _load_saved_settings():
	var gm = get_node_or_null("/root/GameManager")
	if sound_toggle and "is_on" in sound_toggle:
		sound_toggle.is_on = gm.is_sound_enabled if gm and "is_sound_enabled" in gm else true
	if music_toggle and "is_on" in music_toggle:
		music_toggle.is_on = gm.is_music_enabled if gm and "is_music_enabled" in gm else true
