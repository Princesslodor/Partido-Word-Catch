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

func setup_and_show(p_class_name: String = "GRADE 3", p_teacher_name: String = "Ms. Santos", avatar_texture: Texture2D = null) -> void:
	if class_name_label:
		class_name_label.text = p_class_name
	if teacher_label:
		teacher_label.text = "Teacher: " + p_teacher_name
	if teacher_avatar and avatar_texture:
		teacher_avatar.texture = avatar_texture

	show()
	move_to_front()

func _on_continue_pressed() -> void:
	print(">>> CONTINUE CLICKED: LILIPAT SA AVATAR SELECTION <<<")
	continue_pressed.emit()
	
	# Kuhanin ang reference ng Tree bago tuluyang baguhin ang scene
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(next_scene_path)
	else:
		push_error("Error: Cannot change scene, SceneTree is null!")

func _on_back_pressed() -> void:
	print(">>> BACK CLICKED <<<")
	back_pressed.emit()
	hide()
