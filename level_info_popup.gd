extends Control

# --- UI NODES ---
@onready var title_label: Label = $FrameBoard/TitleLabel
@onready var close_button: TextureButton = $FrameBoard/TitleLabel/TextureButton
@onready var lesson_label: Label = $Panel/LessonLabel
@onready var play_button: Button = $Panel2

var current_level: int = 1

func _ready() -> void:
	hide() # Naka-hide muna sa simula
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

func display_level_info(level_num: int, lesson_title: String) -> void:
	current_level = level_num
	
	if title_label:
		title_label.text = "Level " + str(level_num)
		
	if lesson_label:
		lesson_label.text = lesson_title
		
	show()
	move_to_front()

func _on_close_pressed() -> void:
	hide()

func _on_play_pressed() -> void:
	Global.requested_level = current_level
	if current_level >= 1 and current_level <= 16:
		get_tree().change_scene_to_file("res://node_2d.tscn")
	elif current_level >= 17 and current_level <= 20:
		get_tree().change_scene_to_file("res://level_16_20.tscn")
	elif current_level >= 21 and current_level <= 30:
		get_tree().change_scene_to_file("res://level_21_30.tscn")
