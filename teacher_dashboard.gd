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

const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 6

func _ready() -> void:
	_show_dashboard()
	_connect_signals()

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
	if generate_new_code_button and not generate_new_code_button.pressed.is_connected(_on_generate_new_code_pressed):
		generate_new_code_button.pressed.connect(_on_generate_new_code_pressed)

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
	if class_code_edit and class_code_edit.text == "":
		_generate_class_code()

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

func _on_generate_new_code_pressed() -> void:
	_generate_class_code()

func _generate_class_code() -> void:
	if not class_code_edit:
		return
	var code := ""
	for i in range(CODE_LENGTH):
		code += CODE_CHARS[randi() % CODE_CHARS.length()]
	class_code_edit.text = code
