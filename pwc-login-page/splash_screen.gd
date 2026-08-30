extends Control

# References sa Splash Screen UI Nodes
@onready var character = $Character
@onready var game_logo = $GameLogo
@onready var loading_bar = $LoadingBar
@onready var loading_label = $LoadingLabel

# References sa About Game UI Nodes
@onready var about_card = $AboutGameContainer
@onready var continue_button = $AboutGameContainer/VBoxContainer/ContinueButton

# File path ng susunod na Scene (I-select sa Inspector o palitan ang path dito)
@export_file("*.tscn") var next_scene: String = ""

func _ready():
	# 1. Siguraduhing hidden muna ang About Card habang naglo-load
	if about_card:
		about_card.hide()
		
	# 2. I-connect ang Continue Button signal
	if continue_button:
		if not continue_button.pressed.is_connected(_on_continue_button_pressed):
			continue_button.pressed.connect(_on_continue_button_pressed)
		
	# 3. I-apply ang mga styles at i-start ang animations
	_apply_loading_label_styles()
	_apply_loading_bar_styles()
	_start_character_animation()
	_start_logo_pulse()
	_start_loading_process()

# Automatic Styling para sa Loading Label (Puti na may Dark Outline)
func _apply_loading_label_styles():
	if loading_label:
		loading_label.add_theme_color_override("font_color", Color("#FFFFFF"))       # Purong Puti
		loading_label.add_theme_color_override("font_outline_color", Color("#1A0C06")) # Dark Brown/Black
		loading_label.add_theme_constant_override("outline_size", 12)                 # Makapal na Outline

# Automatic Styling para sa LoadingBar (StyleBoxFlat)
func _apply_loading_bar_styles():
	if not loading_bar or not (loading_bar is ProgressBar):
		return
		
	# Background Style (Dark Brown + Wood Border)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#311A0E")       # Madilim na brown sa loob
	bg_style.border_color = Color("#9B531C")   # Kulay kahoy na frame
	bg_style.set_border_width_all(4)            
	bg_style.set_corner_radius_all(20)         
	
	# Fill Style (Lime Green)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color("#7CE400")     # Maliwanag na berdeng lime
	fill_style.set_corner_radius_all(15)       
	
	loading_bar.add_theme_stylebox_override("background", bg_style)
	loading_bar.add_theme_stylebox_override("fill", fill_style)

# Animation para sa Character (Idle floating motion)
func _start_character_animation():
	if character:
		var tween = create_tween().set_loops()
		tween.tween_property(character, "position:y", character.position.y - 15, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(character, "position:y", character.position.y + 15, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Animation para sa Game Logo (Pulse motion)
func _start_logo_pulse():
	if game_logo:
		var tween = create_tween().set_loops()
		tween.tween_property(game_logo, "scale", Vector2(1.05, 1.05), 0.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(game_logo, "scale", Vector2(1.0, 1.0), 0.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Loading Process (0% to 100%)
func _start_loading_process():
	if loading_bar:
		loading_bar.value = 0
		var tween = create_tween()
		
		# BINAGALAN: Binago mula 3.0 seconds papuntang 5.0 seconds
		tween.tween_property(loading_bar, "value", 100.0, 5.0)
		
		# Update percentage label frame by frame
		tween.step_finished.connect(func(_idx): _update_loading_text())
		
		await tween.finished
		
		# Pagkatapos mag-load: Itatago ang Loading Bar, Label, AT Game Logo
		if loading_bar: loading_bar.hide()
		if loading_label: loading_label.hide()
		if game_logo: game_logo.hide()
		
		# Ipapakita ang About Game Card
		if about_card:
			about_card.show()

# Continuous update ng Loading Text Percentage
func _update_loading_text():
	if loading_label and loading_bar:
		var current_percent = int(loading_bar.value)
		loading_label.text = "Loading... " + str(current_percent) + "%"

# Kapag pinindot ang CONTINUE Button sa About Card
func _on_continue_button_pressed():
	print("--- NA-CLICK ANG CONTINUE BUTTON ---")
	
	if next_scene != "" and ResourceLoader.exists(next_scene):
		print("PUMUPUNTA NA SA LOGIN SCENE: ", next_scene)
		get_tree().change_scene_to_file(next_scene)
	else:
		print("ERROR: Walang nakalagay na valid na Login Scene path sa 'Next Scene' property!")
