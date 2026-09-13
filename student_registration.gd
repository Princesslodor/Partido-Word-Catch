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

	var gm = get_node_or_null("/root/GameManager")
	var sync = get_node_or_null("/root/SyncManager")
	var class_code: String = gm.class_code if gm and "class_code" in gm else ""

	# Before treating this as a brand-new student, check whether this exact
	# name+PIN already has an account in THIS class - if so, this is really
	# the same student coming back (e.g. after "Not You" cleared the local
	# device, or a reinstall), and their real progress should be restored
	# instead of starting them over at zero.
	if sync and sync.has_method("find_student_in_class") and class_code != "" and student_pin != "":
		if continue_button: continue_button.disabled = true
		sync.find_student_in_class(class_code, student_name, student_pin, func(existing_row):
			if continue_button: continue_button.disabled = false
			if existing_row is Dictionary:
				_finish_registration(gm, sync, student_name, student_pin, existing_row)
			else:
				_finish_registration(gm, sync, student_name, student_pin, null)
		)
	else:
		_finish_registration(gm, sync, student_name, student_pin, null)

func _finish_registration(gm, sync, student_name: String, student_pin: String, existing_row) -> void:
	if gm:
		if gm.has_method("set_role"):
			gm.set_role("STUDENT")
		gm.set("player_name", student_name)
		gm.set("student_pin", student_pin)

		if existing_row is Dictionary:
			# Same student, returning to a class they'd already joined -
			# restore their real progress instead of resetting it.
			gm.set("avatar_id", str(existing_row.get("avatar_id", "")))
			gm.set("unlocked_level", int(existing_row.get("unlocked_level", 1)))
			gm.set("player_coins", int(existing_row.get("player_coins", 0)))
			var completed = existing_row.get("completed_levels", {})
			gm.set("completed_levels", completed if completed is Dictionary else {})
			gm.set("player_hearts", 4)

			var student_id: String = str(existing_row.get("student_id", ""))
			if student_id != "" and sync and sync.has_method("claim_student_account"):
				sync.claim_student_account(student_id, gm.device_id, func(_ok): pass)
		else:
			# Genuinely new student - a clean slate. Otherwise a new student
			# on a device that previously had another student's progress
			# saved would inherit their unlocked levels/completed levels,
			# showing up as an "already unlocked" account.
			gm.set("avatar_id", "")
			gm.set("unlocked_level", 1)
			gm.set("player_hearts", 4)
			gm.set("completed_levels", {})
			gm.set("player_coins", 20)   # Starting bonus for a newly-registered student

		if gm.has_method("save_game"):
			gm.save_game()

	print(">>> REGISTRATION SUCCESSFUL! LILIPAT SA CLASS JOINED POPUP <<<")
	registration_successful.emit()

	# DERETSO LILIPAT SA CLASS JOINED POPUP VIA PARENT
	var main_login = get_parent()
	if main_login and main_login.has_method("show_class_joined_popup"):
		var joined_class: String = gm.joined_class_name if gm and "joined_class_name" in gm and gm.joined_class_name != "" else (gm.class_code if gm and "class_code" in gm else "")
		var joined_teacher: String = gm.joined_teacher_name if gm and "joined_teacher_name" in gm else ""
		main_login.show_class_joined_popup(joined_class, joined_teacher)
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
