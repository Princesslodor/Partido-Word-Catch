extends Control

@onready var dashboard: Control = $Dashboard
@onready var create_classcode: Control = $CreateClasscode
@onready var students: Control = $Students
@onready var leaderboard: Control = $Leaderboard
@onready var back_button: TextureButton = $BackButton
@onready var settings_button: TextureButton = $SettingsButton
@onready var settings_menu: Control = $SettingsMenu
@onready var logout_confirmation_popup: Control = $ExitConfirmationPopup

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
@onready var total_students_label: Label = $Dashboard/Control2/TotalStudentsPanel/TotalNumberLabel

# --- Students page (populated live from Supabase) ---
@onready var students_panel: Panel = $Students/Panel
var _dynamic_student_nodes: Array = []

# --- Leaderboard (populated live from Supabase) ---
@onready var leaderboard_content: Control = $Leaderboard/LeaderboardScroll/LeaderboardContent
@onready var podium_slots := [
	$Leaderboard/LeaderboardScroll/LeaderboardContent/First,
	$Leaderboard/LeaderboardScroll/LeaderboardContent/Second,
	$Leaderboard/LeaderboardScroll/LeaderboardContent/Third,
]
@onready var empty_roster_message: Label = $Leaderboard/LeaderboardScroll/LeaderboardContent/EmptyRosterMessage
@onready var levels_graph_panel: Panel = $Leaderboard/LeaderboardScroll/LeaderboardContent/LevelsGraphPanel
@onready var empty_graph_message: Label = $Leaderboard/LeaderboardScroll/LeaderboardContent/LevelsGraphPanel/EmptyGraphMessage

const MAX_EXTRA_ROWS := 5
const MAX_GRAPH_BARS := 6
var _dynamic_leaderboard_nodes: Array = []
var _bold_font: FontFile = load("res://Nunito-Bold.ttf")
var _star_icon: Texture2D = load("res://Partido Word Catch Game Pic/Star with fill.png")

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

	# Re-push this teacher's full info whenever the dashboard opens, so any
	# fields that changed locally (or were missing from an earlier sync,
	# like the account's email) stay up to date online.
	if gm.has_method("save_game"):
		gm.save_game()

	_refresh_total_students_count()

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
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
	if logout_confirmation_popup and logout_confirmation_popup.has_signal("confirmed"):
		if not logout_confirmation_popup.confirmed.is_connected(_on_logout_confirmed):
			logout_confirmation_popup.confirmed.connect(_on_logout_confirmed)

func _on_settings_button_pressed() -> void:
	if settings_menu:
		settings_menu.show()
		settings_menu.move_to_front()

## The teacher account (name/email/school/class code) is cleared so this
## device stops auto-recognizing it as "already registered" - going back
## to the Teacher role screen after this will show the login/register
## flow again instead of skipping straight back into the dashboard.
func _on_logout_confirmed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	gm.set("player_name", "")
	gm.set("teacher_email", "")
	gm.set("school_name", "")
	gm.set("grade_subject", "")
	gm.set("teacher_class_name", "")
	gm.set("class_code", "")
	if gm.has_method("save_game"):
		gm.save_game()

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
	_refresh_students_list()

func _on_leaderboard_button_pressed() -> void:
	_hide_all_pages()
	if leaderboard: leaderboard.show()
	if back_button: back_button.show()
	_refresh_leaderboard()

func _on_back_pressed() -> void:
	_show_dashboard()

func _on_copy_code_pressed() -> void:
	if class_code_edit:
		DisplayServer.clipboard_set(class_code_edit.text)

# --- STUDENTS PAGE (live data from Supabase, offline-safe) ---

func _refresh_total_students_count() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sync = get_node_or_null("/root/SyncManager")
	if not gm or not sync or gm.class_code == "":
		if total_students_label: total_students_label.text = "0"
		return
	sync.fetch_leaderboard(gm.class_code, func(students_data: Array):
		if total_students_label:
			total_students_label.text = str(students_data.size())
	)

func _refresh_students_list() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sync = get_node_or_null("/root/SyncManager")
	if not gm or not sync or gm.class_code == "":
		_render_students_list([])
		return
	sync.fetch_leaderboard(gm.class_code, _render_students_list)

func _render_students_list(students_data: Array) -> void:
	for node in _dynamic_student_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_dynamic_student_nodes.clear()

	if not students_panel:
		return

	if total_students_label:
		total_students_label.text = str(students_data.size())

	if students_data.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No students yet — share your class code so they can join."
		empty_label.add_theme_font_override("font", _bold_font)
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.position = Vector2(30, 110)
		empty_label.size = Vector2(students_panel.size.x - 60, 150)
		students_panel.add_child(empty_label)
		_dynamic_student_nodes.append(empty_label)
		return

	# Header row ("Students" / "View All") is drawn on top of this same
	# panel, occupying its top ~85px - rows must start below that to avoid
	# overlapping it.
	var row_top := 100.0
	var row_height := 64.0
	var max_visible_rows: int = max(1, int((students_panel.size.y - row_top) / row_height))
	for i in range(min(students_data.size(), max_visible_rows)):
		var row: Dictionary = students_data[i]
		var name_label := Label.new()
		name_label.text = str(row.get("player_name", "Student"))
		name_label.add_theme_font_override("font", _bold_font)
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", Color(0.16, 0.38, 0.56, 1))
		name_label.position = Vector2(20, row_top + i * row_height)
		name_label.size = Vector2(330, 40)
		students_panel.add_child(name_label)
		_dynamic_student_nodes.append(name_label)

		var level_label := Label.new()
		level_label.text = "Level " + str(row.get("unlocked_level", 1))
		level_label.add_theme_font_override("font", _bold_font)
		level_label.add_theme_font_size_override("font_size", 22)
		level_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		level_label.position = Vector2(360, row_top + i * row_height)
		level_label.size = Vector2(140, 40)
		students_panel.add_child(level_label)
		_dynamic_student_nodes.append(level_label)

# --- LEADERBOARD (live data from Supabase, offline-safe) ---

func _refresh_leaderboard() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sync = get_node_or_null("/root/SyncManager")
	if not gm or not sync or gm.class_code == "":
		_render_leaderboard([])
		return
	sync.fetch_leaderboard(gm.class_code, _render_leaderboard)

func _render_leaderboard(students_data: Array) -> void:
	# Clear anything generated by a previous refresh before rebuilding.
	for node in _dynamic_leaderboard_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_dynamic_leaderboard_nodes.clear()

	_render_podium(students_data)
	_render_extra_rows(students_data)
	_render_graph(students_data)

## Sums the 0-3 star rating earned on every level a student has completed
## (best_score in GameManager.completed_levels is really a star count, set
## by the gameplay scenes' player_stars when they call complete_level()).
func _total_stars(row: Dictionary) -> int:
	var completed = row.get("completed_levels", {})
	if not (completed is Dictionary):
		return 0
	var total := 0
	for key in completed.keys():
		var entry = completed[key]
		if entry is Dictionary:
			total += int(entry.get("best_score", 0))
	return total

## Relative-to-slot placement for the star + points row under each podium
## card - First (center/tallest stand) has more room below its card than
## the shorter Second/Third stands, hence the different sizing.
const _PODIUM_POINTS_LAYOUT := [
	{"x": 54.0, "y": 192.0, "icon_size": 20.0, "font_size": 18},
	{"x": 37.0, "y": 156.0, "icon_size": 16.0, "font_size": 15},
	{"x": 37.0, "y": 156.0, "icon_size": 16.0, "font_size": 15},
]

func _render_podium(students_data: Array) -> void:
	for i in range(podium_slots.size()):
		var slot: Panel = podium_slots[i]
		var name_label: Label = slot.get_node_or_null("Panel/Label")
		var score_label: Label = slot.get_node_or_null("Panel/Label2")
		if i < students_data.size():
			var row: Dictionary = students_data[i]
			if name_label: name_label.text = str(row.get("player_name", "Student"))
			if score_label: score_label.text = "Lvl " + str(int(row.get("unlocked_level", 1)))

			var cfg: Dictionary = _PODIUM_POINTS_LAYOUT[i]
			var icon := TextureRect.new()
			icon.texture = _star_icon
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position = Vector2(cfg.x, cfg.y)
			icon.size = Vector2(cfg.icon_size, cfg.icon_size)
			slot.add_child(icon)
			_dynamic_leaderboard_nodes.append(icon)

			var points_label := Label.new()
			points_label.text = str(_total_stars(row))
			points_label.add_theme_font_override("font", _bold_font)
			points_label.add_theme_font_size_override("font_size", cfg.font_size)
			points_label.add_theme_color_override("font_color", Color(0.16, 0.16, 0.16, 1))
			points_label.position = Vector2(cfg.x + cfg.icon_size + 4, cfg.y - 3)
			points_label.size = Vector2(50, cfg.icon_size + 8)
			slot.add_child(points_label)
			_dynamic_leaderboard_nodes.append(points_label)
		else:
			if name_label: name_label.text = "—"
			if score_label: score_label.text = "—"

func _render_extra_rows(students_data: Array) -> void:
	if not empty_roster_message:
		return

	if students_data.size() <= 3:
		empty_roster_message.visible = students_data.is_empty()
		return

	empty_roster_message.hide()
	var extra: Array = students_data.slice(3, 3 + MAX_EXTRA_ROWS)
	var row_top := 774.0
	var row_height := 44.0
	for i in range(extra.size()):
		var row: Dictionary = extra[i]
		var y := row_top + i * row_height

		var label := Label.new()
		label.text = "     %d           %s          Lvl %s" % [i + 4, str(row.get("player_name", "Student")), str(int(row.get("unlocked_level", 1)))]
		label.add_theme_font_override("font", _bold_font)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.096, 0.096, 0.096, 1))
		label.position = Vector2(90, y)
		label.size = Vector2(430, row_height)
		leaderboard_content.add_child(label)
		_dynamic_leaderboard_nodes.append(label)

		var icon := TextureRect.new()
		icon.texture = _star_icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(500, y + 10)
		icon.size = Vector2(22, 22)
		leaderboard_content.add_child(icon)
		_dynamic_leaderboard_nodes.append(icon)

		var points_label := Label.new()
		points_label.text = str(_total_stars(row))
		points_label.add_theme_font_override("font", _bold_font)
		points_label.add_theme_font_size_override("font_size", 24)
		points_label.add_theme_color_override("font_color", Color(0.096, 0.096, 0.096, 1))
		points_label.position = Vector2(528, y)
		points_label.size = Vector2(50, row_height)
		leaderboard_content.add_child(points_label)
		_dynamic_leaderboard_nodes.append(points_label)

func _render_graph(students_data: Array) -> void:
	if not levels_graph_panel:
		return

	if students_data.is_empty():
		if empty_graph_message: empty_graph_message.show()
		return
	if empty_graph_message: empty_graph_message.hide()

	var bar_students: Array = students_data.slice(0, min(MAX_GRAPH_BARS, students_data.size()))
	var max_level := 1
	for row in bar_students:
		max_level = max(max_level, int(row.get("unlocked_level", 1)))

	var top := 90.0
	var row_height := 55.0
	var bar_max_width := 360.0
	for i in range(bar_students.size()):
		var row: Dictionary = bar_students[i]
		var level_value: int = int(row.get("unlocked_level", 1))
		var y := top + i * row_height
		var bar_width: float = max(6.0, (float(level_value) / float(max_level)) * bar_max_width)

		var name_label := Label.new()
		name_label.text = str(row.get("player_name", "Student"))
		name_label.add_theme_font_override("font", _bold_font)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color(0.16, 0.16, 0.16, 1))
		name_label.position = Vector2(30, y)
		name_label.size = Vector2(110, 28)
		levels_graph_panel.add_child(name_label)
		_dynamic_leaderboard_nodes.append(name_label)

		var fill := ColorRect.new()
		fill.color = Color(0.9137255, 0.6, 0.15, 1)
		fill.position = Vector2(150, y + 2)
		fill.size = Vector2(bar_width, 24)
		levels_graph_panel.add_child(fill)
		_dynamic_leaderboard_nodes.append(fill)

		var value_label := Label.new()
		value_label.text = str(level_value)
		value_label.add_theme_font_override("font", _bold_font)
		value_label.add_theme_font_size_override("font_size", 20)
		value_label.add_theme_color_override("font_color", Color(0.16, 0.16, 0.16, 1))
		value_label.position = Vector2(150 + bar_width + 8, y)
		value_label.size = Vector2(52, 28)
		levels_graph_panel.add_child(value_label)
		_dynamic_leaderboard_nodes.append(value_label)
