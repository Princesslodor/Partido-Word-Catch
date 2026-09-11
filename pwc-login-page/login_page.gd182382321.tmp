extends Control

# Root Elements & Containers
@onready var game_logo = %GameLogo if has_node("%GameLogo") else $GameLogo
@onready var role_selection = $RoleSelectionContainer if has_node("RoleSelectionContainer") else null
@onready var login_form = $LoginFormContainer if has_node("LoginFormContainer") else null

# Navigation/Registration Containers
@onready var student_register_form = $StudentCreateAccount if has_node("StudentCreateAccount") else null
@onready var teacher_register_form = $TeacherCreateAccount if has_node("TeacherCreateAccount") else null
@onready var back_button = $BackButton if has_node("BackButton") else null

# Role Selection Buttons
@onready var student_card = $RoleSelectionContainer/StudentCard/VBoxContainer/Button if has_node("RoleSelectionContainer/StudentCard/VBoxContainer/Button") else null
@onready var teacher_card = $RoleSelectionContainer/TeacherCard/VBoxContainer/Button if has_node("RoleSelectionContainer/TeacherCard/VBoxContainer/Button") else null

# Login Form Elements
@onready var title_label = $LoginFormContainer/MarginContainer/VBoxContainer/TitleLabel if has_node("LoginFormContainer/MarginContainer/VBoxContainer/TitleLabel") else null
@onready var login_button = $LoginFormContainer/MarginContainer/VBoxContainer/LoginButton if has_node("LoginFormContainer/MarginContainer/VBoxContainer/LoginButton") else null
@onready var register_here_button = $LoginFormContainer/MarginContainer/VBoxContainer/RegisterRow/RegisterButton if has_node("LoginFormContainer/MarginContainer/VBoxContainer/RegisterRow/RegisterButton") else null

var current_role: String = "STUDENT"

func _ready():
	_show_role_selection_screen()
	_connect_signals()

func _connect_signals():
	if student_card and not student_card.pressed.is_connected(_on_student_selected):
		student_card.pressed.connect(_on_student_selected)

	if teacher_card and not teacher_card.pressed.is_connected(_on_teacher_selected):
		teacher_card.pressed.connect(_on_teacher_selected)

	if back_button and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	if register_here_button and not register_here_button.pressed.is_connected(_on_register_here_pressed):
		register_here_button.pressed.connect(_on_register_here_pressed)

# --- NAVIGATION FUNCTIONS ---

func _show_role_selection_screen():
	if role_selection: role_selection.show()
	if login_form: login_form.hide()
	if student_register_form: student_register_form.hide()
	if teacher_register_form: teacher_register_form.hide()
	if back_button: back_button.hide()
	if game_logo: game_logo.show()

func _show_login_screen(header_text: String):
	if title_label: title_label.text = header_text
	
	if role_selection: role_selection.hide()
	if student_register_form: student_register_form.hide()
	if teacher_register_form: teacher_register_form.hide()
	if login_form: login_form.show()
	if back_button: back_button.show()
	if game_logo: game_logo.hide()

func _show_register_screen():
	if role_selection: role_selection.hide()
	if login_form: login_form.hide()
	if game_logo: game_logo.hide()
	if back_button: back_button.show()

	if current_role == "TEACHER":
		if student_register_form: student_register_form.hide()
		if teacher_register_form: teacher_register_form.show()
	else:
		if teacher_register_form: teacher_register_form.hide()
		if student_register_form: student_register_form.show()

# --- ACTION EVENTS ---

func _on_student_selected():
	current_role = "STUDENT"
	_show_login_screen("WELCOME BACK!")

func _on_teacher_selected():
	current_role = "TEACHER"
	_show_login_screen("WELCOME TEACHER!")

func _on_register_here_pressed():
	_show_register_screen()

func _on_back_button_pressed():
	if (student_register_form and student_register_form.visible) or (teacher_register_form and teacher_register_form.visible):
		if current_role == "TEACHER":
			_show_login_screen("WELCOME TEACHER!")
		else:
			_show_login_screen("WELCOME BACK!")
	elif login_form and login_form.visible:
		_show_role_selection_screen()
