extends Control

# --- UI NODES ---
@onready var title_label: Label = $FrameBoard/TitleLabel
@onready var close_button: TextureButton = $FrameBoard/TitleLabel/TextureButton
@onready var lesson_label: Label = $FrameBoard/Panel/LessonLabel
@onready var play_button: Button = $FrameBoard/Panel2

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
	print("Simula ng laro para sa Level ", current_level)
	# Dito lilipat sa Gameplay Scene kapag nakagawa ka na ng Gameplay Screen:
	# get_tree().change_scene_to_file("res://gameplay_level_1.tscn")
