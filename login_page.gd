extends Control

# --- EXPORT VARIABLES ---
@export_file("*.tscn") var campaign_map_scene: String = "res://campaign_map_screen.tscn"
@export_file("*.tscn") var teacher_dashboard_scene: String = "res://teacher_dashboard.tscn"
@export_file("*.tscn") var avatar_selection_scene: String = "res://avatar_selection.tscn"

# --- SCENE NODES ---
@onready var game_logo = %GameLogo if has_node("%GameLogo") else $GameLogo
@onready var role_selection = $RoleSelectionContainer if has_node("RoleSelectionContainer") else null
@onready var login_form = $LoginFormContainer if has_node("LoginFormContainer") else null
@onready var student_code_container = $ClassCodeContainer if has_node("ClassCodeContainer") else null
@onready var teacher_register_form = $TeacherCreateAccount if has_node("TeacherCreateAccount") else null
@onready var student_registration = $StudentRegistration if has_node("StudentRegistration") else null
@onready var back_button = $BackButton if has_node("BackButton") else null
@onready var class_joined_popup = $ClassJoinedPopup if has_node("ClassJoinedPopup") else null
@onready var student_welcome_back = $StudentWelcomeBack if has_node("StudentWelcomeBack") else null

# Buttons sa Role Selection
@onready var student_card = $RoleSelectionContainer/StudentCard/VBoxContainer/Button if has_node("RoleSelectionContainer/StudentCard/VBoxContainer/Button") else null
@onready var teacher_card = $RoleSelectionContainer/TeacherCard/VBoxContainer/Button if has_node("RoleSelectionContainer/TeacherCard/VBoxContainer/Button") else null

# Login Form Elements
@onready var title_label = $LoginFormContainer/MarginContainer/VBoxContainer/TitleLabel if has_node("LoginFormContainer/MarginContainer/VBoxContainer/TitleLabel") else null
@onready var login_button = $LoginFormContainer/MarginContainer/VBoxContainer/Spacer/LoginButton if has_node("LoginFormContainer/MarginContainer/VBoxContainer/Spacer/LoginButton") else null
@onready var register_here_button = $LoginFormContainer/MarginContainer/VBoxContainer/RegisterRow/RegisterButton if has_node("LoginFormContainer/MarginContainer/VBoxContainer/RegisterRow/RegisterButton") else null
@onready var login_email_input: LineEdit = $LoginFormContainer/MarginContainer/VBoxContainer/FieldContainer/LineEdit if has_node("LoginFormContainer/MarginContainer/VBoxContainer/FieldContainer/LineEdit") else null
@onready var login_status_label: Label = $LoginFormContainer/MarginContainer/VBoxContainer/Spacer/LoginStatusLabel if has_node("LoginFormContainer/MarginContainer/VBoxContainer/Spacer/LoginStatusLabel") else null
@onready var forgot_password_button: Button = $LoginFormContainer/MarginContainer/VBoxContainer/OptionRow/Button if has_node("LoginFormContainer/MarginContainer/VBoxContainer/OptionRow/Button") else null

# Student Class Code Field
@onready var class_code_input: LineEdit = $ClassCodeContainer/EnterCodeContainer/ClassCodeEdit if has_node("ClassCodeContainer/EnterCodeContainer/ClassCodeEdit") else null
@onready var join_class_button: Button = $ClassCodeContainer/EnterCodeContainer/Button if has_node("ClassCodeContainer/EnterCodeContainer/Button") else null
@onready var join_status_label: Label = $ClassCodeContainer/EnterCodeContainer/JoinStatusLabel if has_node("ClassCodeContainer/EnterCodeContainer/JoinStatusLabel") else null

# Student Welcome Back Elements (returning student who already joined a class)
@onready var welcome_back_greeting_label: Label = $StudentWelcomeBack/Card/GreetingLabel if has_node("StudentWelcomeBack/Card/GreetingLabel") else null
@onready var welcome_back_continue_button: Button = $StudentWelcomeBack/Card/ContinueButton if has_node("StudentWelcomeBack/Card/ContinueButton") else null
@onready var welcome_back_not_you_button: Button = $StudentWelcomeBack/Card/NotYouButton if has_node("StudentWelcomeBack/Card/NotYouButton") else null

# Teacher Create Account Fields
@onready var teacher_name_input: LineEdit = $TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer/NameInput if has_node("TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer/NameInput") else null
@onready var teacher_email_input: LineEdit = $TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer2/EmailInput if has_node("TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer2/EmailInput") else null
@onready var teacher_school_input: LineEdit = $TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer4/SchoolNameInput if has_node("TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer4/SchoolNameInput") else null
@onready var teacher_grade_subject_input: LineEdit = get_node_or_null("TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer5/Grade_Subject TaughtInput")
@onready var teacher_class_name_input: LineEdit = $TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer6/ClassNameInput if has_node("TeacherCreateAccount/MarginContainer/VBoxContainer/FieldContainer6/ClassNameInput") else null

var current_role: String = "STUDENT"

func _ready():
	_show_role_selection_screen()
	_connect_signals()

func _connect_signals():
	if student_card and not student_card.pressed.is_connected(_on_student_selected):
		student_card.pressed.connect(_on_student_selected)

	if teacher_card and not teacher_card.pressed.is_connected(_on_teacher_selected):
		teacher_card.pressed.connect(_on_teacher_selected)

	if back_button:
		if back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.disconnect(_on_back_button_pressed)
		back_button.pressed.connect(_on_back_button_pressed)

	if login_button and not login_button.pressed.is_connected(_on_teacher_login_pressed):
		login_button.pressed.connect(_on_teacher_login_pressed)

	if register_here_button and not register_here_button.pressed.is_connected(_on_register_here_pressed):
		register_here_button.pressed.connect(_on_register_here_pressed)

	if forgot_password_button and not forgot_password_button.pressed.is_connected(_on_forgot_password_pressed):
		forgot_password_button.pressed.connect(_on_forgot_password_pressed)

	if welcome_back_continue_button and not welcome_back_continue_button.pressed.is_connected(_on_welcome_back_continue_pressed):
		welcome_back_continue_button.pressed.connect(_on_welcome_back_continue_pressed)

	if welcome_back_not_you_button and not welcome_back_not_you_button.pressed.is_connected(_on_welcome_back_not_you_pressed):
		welcome_back_not_you_button.pressed.connect(_on_welcome_back_not_you_pressed)

	if student_code_container:
		_bind_join_class_btn(student_code_container)

	if teacher_register_form:
		_bind_teacher_submit_btn(teacher_register_form)

	if class_joined_popup and class_joined_popup.has_signal("continue_pressed"):
		if not class_joined_popup.continue_pressed.is_connected(_on_class_joined_continued):
			class_joined_popup.continue_pressed.connect(_on_class_joined_continued)

func _bind_join_class_btn(node: Node):
	if node is Button or node is TextureButton:
		if not node.pressed.is_connected(_on_join_class_pressed):
			node.pressed.connect(_on_join_class_pressed)
	for child in node.get_children():
		_bind_join_class_btn(child)

func _bind_teacher_submit_btn(node: Node):
	if node is Button or node is TextureButton:
		if not node.pressed.is_connected(_on_teacher_create_account_pressed):
			node.pressed.connect(_on_teacher_create_account_pressed)
	for child in node.get_children():
		_bind_teacher_submit_btn(child)

# --- NAVIGATION FUNCTIONS ---

func _hide_all_screens():
	if role_selection: role_selection.hide()
	if login_form: login_form.hide()
	if student_code_container: student_code_container.hide()
	if teacher_register_form: teacher_register_form.hide()
	if student_registration: student_registration.hide()
	if back_button: back_button.hide()
	if class_joined_popup: class_joined_popup.hide()
	if student_welcome_back: student_welcome_back.hide()

func _show_role_selection_screen():
	_hide_all_screens()
	if role_selection: role_selection.show()
	if game_logo: game_logo.show()

func _show_student_class_code_screen():
	_hide_all_screens()
	if game_logo: game_logo.hide()
	if student_code_container: student_code_container.show()
	if back_button: back_button.show()

func _show_student_welcome_back_screen():
	_hide_all_screens()
	if game_logo: game_logo.hide()
	var gm = get_node_or_null("/root/GameManager")
	var saved_name: String = gm.player_name if gm and "player_name" in gm and gm.player_name != "" else "there"
	if welcome_back_greeting_label:
		welcome_back_greeting_label.text = "Hi, " + saved_name + "!"
	if student_welcome_back:
		student_welcome_back.show()
	if back_button: back_button.show()

func _show_student_registration_screen():
	_hide_all_screens()
	if game_logo: game_logo.hide()
	if back_button: back_button.show()
	if student_registration:
		student_registration.show()
		student_registration.move_to_front()
		if student_registration.has_method("show_registration"):
			student_registration.show_registration()

func show_class_joined_popup(joined_class: String = "", teacher: String = ""):
	_hide_all_screens()
	if game_logo: game_logo.hide()
	if class_joined_popup:
		class_joined_popup.show()
		class_joined_popup.move_to_front()
		if class_joined_popup.has_method("setup_and_show"):
			class_joined_popup.setup_and_show(joined_class, teacher)
func _show_teacher_login_screen():
	_hide_all_screens()
	if game_logo: game_logo.hide()
	if title_label: title_label.text = "WELCOME TEACHER!"
	if login_form: login_form.show()
	if back_button: back_button.show()

func _show_teacher_register_screen():
	_hide_all_screens()
	if game_logo: game_logo.hide()
	if teacher_register_form: teacher_register_form.show()
	if back_button: back_button.show()

# --- ACTION EVENTS ---

func _on_student_selected():
	current_role = "STUDENT"

	var gm = get_node_or_null("/root/GameManager")
	var already_joined: bool = gm != null \
		and gm.role == "STUDENT" \
		and gm.class_code != "" \
		and gm.player_name != "" \
		and gm.avatar_id != ""

	if already_joined:
		_show_student_welcome_back_screen()
		return

	_save_role_to_gm("STUDENT")
	_show_student_class_code_screen()

func _on_welcome_back_continue_pressed():
	get_tree().change_scene_to_file(campaign_map_scene if campaign_map_scene != "" else "res://campaign_map_screen.tscn")

func _on_welcome_back_not_you_pressed():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		# Clear identity AND progress - this device is about to belong to a
		# different student, who shouldn't inherit the previous student's
		# coins, unlocked levels, or completed-level history.
		gm.set("player_name", "")
		gm.set("class_code", "")
		gm.set("student_pin", "")
		gm.set("avatar_id", "")
		gm.set("joined_teacher_name", "")
		gm.set("joined_class_name", "")
		gm.set("joined_grade_subject", "")
		gm.set("unlocked_level", 1)
		gm.set("player_coins", 0)
		gm.set("player_hearts", 4)
		gm.set("completed_levels", {})
		if gm.has_method("save_game"):
			gm.save_game()

	_save_role_to_gm("STUDENT")
	_show_student_class_code_screen()

func _on_teacher_selected():
	current_role = "TEACHER"
	_save_role_to_gm("TEACHER")
	_show_teacher_login_screen()

func _on_register_here_pressed():
	_show_teacher_register_screen()

func _on_forgot_password_pressed():
	# There's no real password check yet - Login only verifies the email
	# against the teacher's account, so there's nothing to "reset" yet.
	_show_login_status("No password needed - just use your email.")

# Pagkatapos mag-enter ng Class Code, dadaan muna sa Registration Panel
func _on_join_class_pressed():
	var typed_code: String = class_code_input.text.strip_edges() if class_code_input else ""
	if typed_code == "":
		_show_join_status("Enter your teacher's class code.")
		return

	var sync = get_node_or_null("/root/SyncManager")
	if not sync or not sync.has_method("find_class_by_code"):
		_show_join_status("Joining isn't available right now.")
		return

	_show_join_status("Checking...")
	if join_class_button: join_class_button.disabled = true

	sync.find_class_by_code(typed_code, func(class_row):
		if join_class_button: join_class_button.disabled = false

		if class_row == null:
			_show_join_status("No internet connection. Try again.")
			return
		if not (class_row is Dictionary):
			_show_join_status("No class found with that code.")
			return

		_show_join_status("")
		_save_role_to_gm("STUDENT")
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.set("class_code", typed_code)
			gm.set("joined_teacher_name", str(class_row.get("teacher_name", "")))
			gm.set("joined_class_name", str(class_row.get("teacher_class_name", "")))
			gm.set("joined_grade_subject", str(class_row.get("grade_subject", "")))
			if gm.has_method("save_game"):
				gm.save_game()
		_show_student_registration_screen()
	)

func _show_join_status(message: String) -> void:
	if not join_status_label:
		return
	join_status_label.text = message
	join_status_label.visible = message != ""

func _on_class_joined_continued():
	_change_to_avatar_selection()

func _change_to_avatar_selection():
	var target = avatar_selection_scene if avatar_selection_scene != "" else "res://avatar_selection.tscn"
	get_tree().change_scene_to_file(target)

func _on_teacher_login_pressed():
	var typed_email: String = login_email_input.text.strip_edges() if login_email_input else ""
	if typed_email == "":
		_show_login_status("Enter your registered email.")
		return

	var sync = get_node_or_null("/root/SyncManager")
	if not sync or not sync.has_method("find_class_by_email"):
		_show_login_status("Login isn't available right now.")
		return

	_show_login_status("Checking...")
	if login_button: login_button.disabled = true

	sync.find_class_by_email(typed_email, func(class_row):
		if login_button: login_button.disabled = false

		if class_row == null:
			_show_login_status("No internet connection. Try again.")
			return
		if not (class_row is Dictionary):
			_show_login_status("No account found with that email.")
			return

		_show_login_status("")
		_save_role_to_gm("TEACHER")
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.set("player_name", str(class_row.get("teacher_name", "")))
			gm.set("teacher_email", typed_email)
			gm.set("school_name", str(class_row.get("school_name", "")))
			gm.set("grade_subject", str(class_row.get("grade_subject", "")))
			gm.set("teacher_class_name", str(class_row.get("teacher_class_name", "")))
			gm.set("class_code", str(class_row.get("class_code", "")))
			if gm.has_method("save_game"):
				gm.save_game()
		if teacher_dashboard_scene != "":
			get_tree().change_scene_to_file(teacher_dashboard_scene)
	)

func _show_login_status(message: String) -> void:
	if not login_status_label:
		return
	login_status_label.text = message
	login_status_label.visible = message != ""

func _on_teacher_create_account_pressed():
	_save_role_to_gm("TEACHER")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if teacher_name_input and teacher_name_input.text.strip_edges() != "":
			gm.set("player_name", teacher_name_input.text.strip_edges())
		if teacher_email_input:
			gm.set("teacher_email", teacher_email_input.text.strip_edges())
		if teacher_school_input:
			gm.set("school_name", teacher_school_input.text.strip_edges())
		if teacher_grade_subject_input:
			gm.set("grade_subject", teacher_grade_subject_input.text.strip_edges())
		if teacher_class_name_input:
			gm.set("teacher_class_name", teacher_class_name_input.text.strip_edges())
		if gm.has_method("get_or_create_class_code"):
			gm.get_or_create_class_code()
		if gm.has_method("save_game"):
			gm.save_game()
	if teacher_dashboard_scene != "":
		get_tree().change_scene_to_file(teacher_dashboard_scene)

func _on_back_button_pressed():
	if student_registration and student_registration.is_visible_in_tree():
		_show_student_class_code_screen()
		return
	if teacher_register_form and teacher_register_form.is_visible_in_tree():
		_show_teacher_login_screen()
		return
	_show_role_selection_screen()

func _save_role_to_gm(role: String):
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_method("set_role"):
			gm.set_role(role)
		elif "current_role" in gm:
			gm.current_role = role
