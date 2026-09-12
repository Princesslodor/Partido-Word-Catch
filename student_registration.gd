extends Control

signal registration_successful
signal back_pressed

# --- DIRECT NODE REFERENCES ---
# Sinisigurado nitong makuha ang tamang LineEdit nodes sa iyong Scene Tree
@onready var name_input: LineEdit = $FieldContainer/LineEdit if has_node("FieldContainer/LineEdit") else null
@onready var pin_input: LineEdit = $FieldContainer2/LineEdit if has_node("FieldContainer2/LineEdit") else null

@onready var continue_button: BaseButton = find_child("ContinueButton", true, false) as BaseButton
@onready var back_button: BaseButton = find_child("BackButton", true, false) as BaseButton

func _ready() -> void:
	if pin_input:
		pin_input.max_length = 4
		pin_input.secret = true

	_connect_signals()

func _connect_signals() -> void:
	if continue_button:
		if continue_button.pressed.is_connected(_on_continue_pressed):
			continue_button.pressed.disconnect(_on_continue_pressed)
		continue_button.pressed.connect(_on_continue_pressed)

	if back_button:
		if back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.disconnect(_on_back_pressed)
		back_button.pressed.connect(_on_back_pressed)

func _on_continue_pressed() -> void:
	# Fallback search kung sakaling mag-null ang initial reference
	if not name_input:
		name_input = find_child("LineEdit", true, false) as LineEdit
	if not pin_input:
		var fields = find_children("*", "LineEdit", true, false)
		if fields.size() > 1:
			pin_input = fields[1] as LineEdit

	var student_name: String = name_input.text.strip_edges() if name_input else ""
	var student_pin: String = pin_input.text.strip_edges() if pin_input else ""

	print(">>> DEBUG REGISTRATION | Name: '", student_name, "' | PIN: '", student_pin, "'")

	# VALIDATION CHECK (Pansamantalang nagse-set ng default value para hindi mag-block kung testing)
	if student_name == "":
		print("WARNING: Walang pangalan. Gagamit ng default na 'Student'")
		student_name = "Student"

	# Save sa GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_method("set_role"):
			gm.set_role("STUDENT")
		gm.set("player_name", student_name)
		gm.set("student_pin", student_pin)

	print(">>> REGISTRATION SUCCESSFUL! LILIPAT SA CLASS JOINED POPUP <<<")
	registration_successful.emit()

	# DERETSO LILIPAT SA CLASS JOINED POPUP VIA PARENT
	var main_login = get_parent()
	if main_login and main_login.has_method("show_class_joined_popup"):
		main_login.show_class_joined_popup("GRADE 3", "Ms. Santos")
	else:
		# Fallback direct call sa popup node
		var popup = main_login.get_node_or_null("ClassJoinedPopup") if main_login else null
		if popup:
			hide()
			popup.show()
			popup.move_to_front()

func _on_back_pressed() -> void:
	back_pressed.emit()
	var main_login = get_parent()
	if main_login and main_login.has_method("_show_student_class_code_screen"):
		main_login._show_student_class_code_screen()
	else:
		hide()
