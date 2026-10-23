extends Control

signal continue_pressed
signal back_pressed

@export_file("*.tscn") var next_scene_path: String = "res://avatar_selection.tscn"

@onready var class_name_label: Label = find_child("ClassNameLabel", true, false) as Label
@onready var teacher_label: Label = find_child("TeacherLabel", true, false) as Label
@onready var teacher_avatar: TextureRect = find_child("TeacherAvatar", true, false) as TextureRect
@onready var continue_button: BaseButton = find_child("ContinueButton", true, false) as BaseButton
@onready var back_button: BaseButton = find_child("BackButton", true, false) as BaseButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_unblock_mouse_recursive(self)
	_connect_signals()
	_load_teacher_avatar()

func _connect_signals() -> void:
	if continue_button and not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
		
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

func _unblock_mouse_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control and child != continue_button and child != back_button:
			if child is ColorRect or child is TextureRect or child is Panel:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			
		_unblock_mouse_recursive(child)

func _load_teacher_avatar() -> void:
	if not teacher_avatar:
		return

	var avatar_path: String = ""

	var gm = get_node_or_null("/root/GameManager")
	if gm and "avatar_path" in gm:
		avatar_path = gm.avatar_path

	if avatar_path == "" and "selected_teacher_avatar_path" in Global:
		avatar_path = Global.selected_teacher_avatar_path

	if avatar_path != "" and ResourceLoader.exists(avatar_path):
		teacher_avatar.texture = load(avatar_path)

func setup_and_show(p_class_name: String = "", p_teacher_name: String = "", avatar_texture: Texture2D = null) -> void:
	if class_name_label:
		class_name_label.text = p_class_name
	if teacher_label:
		_fit_teacher_name(p_teacher_name)
		
	if avatar_texture:
		if teacher_avatar:
			teacher_avatar.texture = avatar_texture
	else:
		_load_teacher_avatar()

	show()
	move_to_front()

## "Teacher:" on one line and the name under it. A long name gets a smaller
## font so it stays inside the box (and is cut with "…" if still too long).
func _fit_teacher_name(teacher_name: String) -> void:
	teacher_label.text = "Teacher:\n" + teacher_name
	var font := teacher_label.get_theme_font("font")
	var size := 24
	while size > 16 and font and font.get_string_size(teacher_name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > teacher_label.size.x:
		size -= 1
	teacher_label.add_theme_font_size_override("font_size", size)

func _on_continue_pressed() -> void:
	# The login page listens for this and changes the scene itself - which
	# takes this popup out of the tree, so changing it here too would fail.
	if continue_pressed.get_connections().size() > 0:
		continue_pressed.emit()
		return
	Global.change_scene(next_scene_path)

func _on_back_pressed() -> void:
	back_pressed.emit()
	hide()
