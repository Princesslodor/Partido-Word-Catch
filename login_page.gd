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
@onready var student_login_container = $StudentLoginContainer if has_node("StudentLoginContainer") else null

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
@onready var remember_me_checkbox: CheckBox = $LoginFormContainer/MarginContainer/VBoxContainer/OptionRow/CheckBox if has_node("LoginFormContainer/MarginContainer/VBoxContainer/OptionRow/CheckBox") else null

# Student Class Code Field
@onready var class_code_input: LineEdit = $ClassCodeContainer/EnterCodeContainer/ClassCodeEdit if has_node("ClassCodeContainer/EnterCodeContainer/ClassCodeEdit") else null
@onready var join_class_button: Button = $ClassCodeContainer/EnterCodeContainer/Button if has_node("ClassCodeContainer/EnterCodeContainer/Button") else null
@onready var join_status_label: Label = $ClassCodeContainer/EnterCodeContainer/JoinStatusLabel if has_node("ClassCodeContainer/EnterCodeContainer/JoinStatusLabel") else null
@onready var student_login_link_button: Button = $ClassCodeContainer/EnterCodeContainer/StudentLoginLinkButton if has_node("ClassCodeContainer/EnterCodeContainer/StudentLoginLinkButton") else null

# Student Login Fields (cross-device account retrieval via name + PIN -
# a student only ever has one class, so no class code field is needed)
@onready var student_login_name_input: LineEdit = $StudentLoginContainer/LoginBoard/NameEdit if has_node("StudentLoginContainer/LoginBoard/NameEdit") else null
@onready var student_login_pin_input: LineEdit = $StudentLoginContainer/LoginBoard/PinEdit if has_node("StudentLoginContainer/LoginBoard/PinEdit") else null
@onready var student_login_button: Button = $StudentLoginContainer/LoginBoard/LoginButton if has_node("StudentLoginContainer/LoginBoard/LoginButton") else null
@onready var student_login_status_label: Label = $StudentLoginContainer/LoginBoard/LoginStatusLabel if has_node("StudentLoginContainer/LoginBoard/LoginStatusLabel") else null

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
@onready var teacher_create_status_label: Label = $TeacherCreateAccount/MarginContainer/VBoxContainer/Spacer/StatusLabel if has_node("TeacherCreateAccount/MarginContainer/VBoxContainer/Spacer/StatusLabel") else null

var current_role: String = "STUDENT"

func _ready():
	_show_role_selection_screen()
	_connect_signals()
	_connect_sound_to_all_buttons(self)

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

	if remember_me_checkbox:
		var gm = get_node_or_null("/root/GameManager")
		remember_me_checkbox.button_pressed = gm.remember_teacher_login if gm and "remember_teacher_login" in gm else true
		if not remember_me_checkbox.toggled.is_connected(_on_remember_me_toggled):
			remember_me_checkbox.toggled.connect(_on_remember_me_toggled)

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

	if student_login_link_button and not student_login_link_button.pressed.is_connected(_show_student_login_screen):
		student_login_link_button.pressed.connect(_show_student_login_screen)

	if student_login_button and not student_login_button.pressed.is_connected(_on_student_login_pressed):
		student_login_button.pressed.connect(_on_student_login_pressed)

func _bind_join_class_btn(node: Node):
	# StudentLoginLinkButton lives under this same container but has its
	# own handler (_show_student_login_screen, wired in _connect_signals) -
	# skip it here so it doesn't ALSO fire the join-class flow on top of
	# switching screens.
	if node.name == "StudentLoginLinkButton":
		return
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
	if student_login_container: student_login_container.hide()

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

func _show_student_login_screen():
	_hide_all_screens()
	if game_logo: game_logo.hide()
	if student_login_container: student_login_container.show()
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
			var gm = get_node_or_null("/root/GameManager")
			var sync = get_node_or_null("/root/SyncManager")
			var class_code: String = gm.class_code if gm and "class_code" in gm else ""
			if gm and sync and class_code != "" and sync.has_method("find_class_by_code"):
				sync.find_class_by_code(class_code, func(class_row):
					var avatar_texture: Texture2D = null
					if class_row is Dictionary and gm.has_method("get_avatar_texture_path"):
						var avatar_path: String = gm.get_avatar_texture_path(str(class_row.get("avatar_id", "")))
						if avatar_path != "" and ResourceLoader.exists(avatar_path):
							avatar_texture = load(avatar_path)
					class_joined_popup.setup_and_show(joined_class, teacher, avatar_texture)
				)
			else:
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
	# avatar_id is intentionally NOT required here - it's a cosmetic pick,
	# not identity. Requiring it meant a student who registered but closed
	# the app before reaching the avatar-selection screen (or any other
	# reason avatar_id ended up blank) would be forced through full
	# registration again on every launch, even though their name/class/
	# progress were already saved fine.
	var already_joined: bool = gm != null \
		and gm.role == "STUDENT" \
		and gm.class_code != "" \
		and gm.player_name != ""

	if already_joined:
		_show_student_welcome_back_screen()
		return

	# Same reasoning as _on_teacher_selected(): _save_role_to_gm() saves
	# immediately, and if this device was just a TEACHER, its class_code
	# would otherwise get pushed to the students table as if the teacher
	# were a student of their own class.
	if gm:
		gm.set("class_code", "")
	_save_role_to_gm("STUDENT")
	_show_student_class_code_screen()

func _on_welcome_back_continue_pressed():
	var gm = get_node_or_null("/root/GameManager")
	if gm and "avatar_id" in gm and gm.avatar_id == "":
		# already_joined no longer requires an avatar, so a student who
		# never finished picking one lands here with none set - send them
		# to pick one instead of continuing with a blank avatar.
		_change_to_avatar_selection()
		return
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

	var gm = get_node_or_null("/root/GameManager")
	var already_registered_here: bool = gm != null \
		and gm.role == "TEACHER" \
		and gm.player_name != "" \
		and gm.class_code != "" \
		and ("remember_teacher_login" not in gm or gm.remember_teacher_login)

	if already_registered_here:
		# This device already has a completed teacher account on it - no
		# need to go through Login (which requires an online lookup) just
		# to get back into an account that's already sitting right here.
		if teacher_dashboard_scene != "":
			get_tree().change_scene_to_file(teacher_dashboard_scene)
		return

	# _save_role_to_gm() flips role and immediately calls save_game(), which
	# opportunistically upserts to Supabase's classes table using whatever
	# class_code/player_name are currently sitting in GameManager. If this
	# device was just a STUDENT (class_code = the class they joined,
	# player_name = their own name), that stale data would get upserted as
	# if THIS device's teacher owns that class - overwriting the real
	# teacher's row with the student's name and an empty email. Clear it
	# first so nothing gets pushed until the teacher actually logs in or
	# registers with real data.
	if gm:
		gm.set("class_code", "")
	_save_role_to_gm("TEACHER")
	_show_teacher_login_screen()

func _on_register_here_pressed():
	_show_teacher_register_screen()

func _on_forgot_password_pressed():
	# There's no real password check yet - Login only verifies the email
	# against the teacher's account, so there's nothing to "reset" yet.
	_show_login_status("No password needed - just use your email.")

## Persists immediately (not just on next save_game() elsewhere) so it takes
## effect even if the teacher closes the app right after toggling it.
func _on_remember_me_toggled(toggled_on: bool) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "remember_teacher_login" in gm:
		gm.set("remember_teacher_login", toggled_on)
		if gm.has_method("save_game"):
			gm.save_game()

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
			var reason: String = sync.last_error if "last_error" in sync and sync.last_error != "" else ""
			_show_join_status("No internet connection. Try again." + (" (" + reason + ")" if reason != "" else ""))
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

## Cross-device account retrieval: a student who already has an account
## (registered on some other phone) looks it up here by exact name + PIN,
## instead of being stuck creating a new account every time they play on a
## different device. No class code needed - a student only ever belongs to
## one class, so it's read from whichever account matches instead of asked
## for again.
func _on_student_login_pressed() -> void:
	var typed_name: String = student_login_name_input.text.strip_edges() if student_login_name_input else ""
	var typed_pin: String = student_login_pin_input.text.strip_edges() if student_login_pin_input else ""

	if typed_name == "" or typed_pin == "":
		_show_student_login_status("Enter your name and PIN.")
		return

	var sync = get_node_or_null("/root/SyncManager")
	if not sync or not sync.has_method("find_student_account"):
		_show_student_login_status("Login isn't available right now.")
		return

	_show_student_login_status("Checking...")
	if student_login_button: student_login_button.disabled = true

	sync.find_student_account(typed_name, typed_pin, func(student_row):
		if student_login_button: student_login_button.disabled = false

		if student_row == null:
			var reason: String = sync.last_error if "last_error" in sync and sync.last_error != "" else ""
			_show_student_login_status("No internet connection. Try again." + (" (" + reason + ")" if reason != "" else ""))
			return
		if student_row is String and student_row == "ambiguous":
			_show_student_login_status("More than one account matches that name and PIN. Please use your class code to join instead.")
			return
		if not (student_row is Dictionary):
			_show_student_login_status("No account found with that name and PIN.")
			return

		_show_student_login_status("")
		var gm = get_node_or_null("/root/GameManager")
		if not gm:
			return

		var found_class_code: String = str(student_row.get("class_code", ""))

		_save_role_to_gm("STUDENT")
		gm.set("player_name", str(student_row.get("player_name", typed_name)))
		gm.set("class_code", found_class_code)
		gm.set("student_pin", typed_pin)
		gm.set("avatar_id", str(student_row.get("avatar_id", "")))
		gm.set("unlocked_level", int(student_row.get("unlocked_level", 1)))
		gm.set("player_coins", int(student_row.get("player_coins", 0)))
		var completed = student_row.get("completed_levels", {})
		gm.set("completed_levels", completed if completed is Dictionary else {})
		gm.set("player_hearts", 4)

		# This device may currently hold a DIFFERENT account's device_id
		# (e.g. a different student was just registered/tested here) -
		# re-pointing this row at that id would fail device_id's unique
		# constraint and could later collide with that other account's
		# own saves. Adopting this row's own established device_id
		# instead avoids that entirely; only claim/re-point when the
		# row doesn't have one yet (e.g. an older account from before
		# device_id was required).
		var student_id: String = str(student_row.get("student_id", ""))
		var existing_device_id: String = str(student_row.get("device_id", ""))
		if existing_device_id != "":
			gm.set("device_id", existing_device_id)
		elif student_id != "" and sync.has_method("claim_student_account"):
			sync.claim_student_account(student_id, gm.device_id, func(_ok): pass)

		# Also pull the class's teacher/section info for the "joined class"
		# display fields, same as the normal join-by-code flow does.
		if found_class_code != "" and sync.has_method("find_class_by_code"):
			sync.find_class_by_code(found_class_code, func(class_row):
				if class_row is Dictionary:
					gm.set("joined_teacher_name", str(class_row.get("teacher_name", "")))
					gm.set("joined_class_name", str(class_row.get("teacher_class_name", "")))
					gm.set("joined_grade_subject", str(class_row.get("grade_subject", "")))
				if gm.has_method("save_game"):
					gm.save_game()
				get_tree().change_scene_to_file(campaign_map_scene if campaign_map_scene != "" else "res://campaign_map_screen.tscn")
			)
		else:
			if gm.has_method("save_game"):
				gm.save_game()
			get_tree().change_scene_to_file(campaign_map_scene if campaign_map_scene != "" else "res://campaign_map_screen.tscn")
	)

func _show_student_login_status(message: String) -> void:
	if not student_login_status_label:
		return
	student_login_status_label.text = message
	student_login_status_label.visible = message != ""

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
			var reason: String = sync.last_error if "last_error" in sync and sync.last_error != "" else ""
			_show_login_status("No internet connection. Try again." + (" (" + reason + ")" if reason != "" else ""))
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
	if teacher_create_status_label: teacher_create_status_label.text = ""

	var name_text: String = teacher_name_input.text.strip_edges() if teacher_name_input else ""
	var email_text: String = teacher_email_input.text.strip_edges() if teacher_email_input else ""
	var school_text: String = teacher_school_input.text.strip_edges() if teacher_school_input else ""
	var grade_subject_text: String = teacher_grade_subject_input.text.strip_edges() if teacher_grade_subject_input else ""
	var class_name_text: String = teacher_class_name_input.text.strip_edges() if teacher_class_name_input else ""

	if name_text == "" or email_text == "" or school_text == "" or grade_subject_text == "" or class_name_text == "":
		if teacher_create_status_label: teacher_create_status_label.text = "Please fill in all fields before continuing."
		return

	_save_role_to_gm("TEACHER")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set("player_name", name_text)
		gm.set("teacher_email", email_text)
		gm.set("school_name", school_text)
		gm.set("grade_subject", grade_subject_text)
		gm.set("teacher_class_name", class_name_text)
		# get_or_create_class_code() reuses whatever class_code is already
		# saved locally - which could belong to a totally different account
		# (e.g. a class a STUDENT previously joined on this same device).
		# A brand-new teacher account must always get a genuinely new code.
		gm.set("class_code", "")
		if gm.has_method("get_or_create_class_code"):
			gm.get_or_create_class_code()
		if gm.has_method("save_game"):
			gm.save_game()
	# Same as the student flow: pick an avatar right after the account is
	# created, rather than landing on the dashboard with no avatar chosen.
	_change_to_avatar_selection()

func _on_back_button_pressed():
	if student_registration and student_registration.is_visible_in_tree():
		_show_student_class_code_screen()
		return
	if student_login_container and student_login_container.is_visible_in_tree():
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
