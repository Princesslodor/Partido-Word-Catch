extends Control

@onready var dashboard: Control = $Dashboard
@onready var create_classcode: Control = $CreateClasscode
@onready var students: Control = $Students
@onready var leaderboard: Control = $Leaderboard
@onready var back_button: TextureButton = $BackButton

@onready var create_class_code_button: Button = $Dashboard/Control3/Panel/CreateClassCodeButton
@onready var student_button: Button = $Dashboard/Control3/Panel/StudentButton
@onready var leaderboard_button: Button = $Dashboard/Control3/Panel/LeaderboardButton

@onready var class_code_edit: LineEdit = $CreateClasscode/CodeGeneratorPanel/ClassCodeEdit
@onready var copy_code_button: Button = $CreateClasscode/CodeGeneratorPanel/CopyCodeButton
@onready var generate_new_code_button: Button = $CreateClasscode/CodeGeneratorPanel/GenerateNewCodeButton

@onready var profile_name_label: Label = $TeacherProfilePanel/Label
@onready var greeting_name_label: Label = $Dashboard/GreetingPanel/GreetingLabel2
@onready var grade_label: Label = $CreateClasscode/Panel/GradeLabel
@onready var teacher_label: Label = $CreateClasscode/Panel/TeacherLabel

func _ready() -> void:
	_load_teacher_info()
	_show_dashboard()
	_connect_signals()
	# The class code is permanent once generated - there's nothing to regenerate.
	if generate_new_code_button:
		generate_new_code_button.hide()

func _load_teacher_info() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	var display_name: String = gm.get("player_name") if "player_name" in gm else ""
	if display_name != "":
		if profile_name_label: profile_name_label.text = display_name
		if greeting_name_label: greeting_name_label.text = display_name + "!"
		if teacher_label: teacher_label.text = "Teacher: " + display_name

	var grade_subject: String = gm.get("grade_subject") if "grade_subject" in gm else ""
	if grade_subject != "" and grade_label:
		grade_label.text = grade_subject

	if class_code_edit and gm.has_method("get_or_create_class_code"):
		class_code_edit.text = gm.get_or_create_class_code()

func _connect_signals() -> void:
	if create_class_code_button and not create_class_code_button.pressed.is_connected(_on_create_class_code_pressed):
		create_class_code_button.pressed.connect(_on_create_class_code_pressed)
	if student_button and not student_button.pressed.is_connected(_on_student_button_pressed):
		student_button.pressed.connect(_on_student_button_pressed)
	if leaderboard_button and not leaderboard_button.pressed.is_connected(_on_leaderboard_button_pressed):
		leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if copy_code_button and not copy_code_button.pressed.is_connected(_on_copy_code_pressed):
		copy_code_button.pressed.connect(_on_copy_code_pressed)

func _hide_all_pages() -> void:
	if dashboard: dashboard.hide()
	if create_classcode: create_classcode.hide()
	if students: students.hide()
	if leaderboard: leaderboard.hide()

func _show_dashboard() -> void:
	_hide_all_pages()
	if dashboard: dashboard.show()
	if back_button: back_button.hide()

func _on_create_class_code_pressed() -> void:
	_hide_all_pages()
	if create_classcode: create_classcode.show()
	if back_button: back_button.show()

func _on_student_button_pressed() -> void:
	_hide_all_pages()
	if students: students.show()
	if back_button: back_button.show()

func _on_leaderboard_button_pressed() -> void:
	_hide_all_pages()
	if leaderboard: leaderboard.show()
	if back_button: back_button.show()

func _on_back_pressed() -> void:
	_show_dashboard()

func _on_copy_code_pressed() -> void:
	if class_code_edit:
		DisplayServer.clipboard_set(class_code_edit.text)
