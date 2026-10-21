extends Control

@onready var character = get_node_or_null("Character")
@onready var loading_bar = $LoadingBar
@onready var loading_label = $LoadingLabel

@onready var about_card = $AboutGameContainer
@onready var continue_button = $AboutGameContainer/VBoxContainer/ContinueButton

@export_file("*.tscn") var next_scene: String = ""

func _ready():
	if about_card:
		about_card.hide()
		
	if continue_button:
		if not continue_button.pressed.is_connected(_on_continue_button_pressed):
			continue_button.pressed.connect(_on_continue_button_pressed)
		
	_apply_loading_label_styles()
	_apply_loading_bar_styles()
	_start_character_animation()
	_start_loading_process()
	_connect_sound_to_all_buttons(self)

func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()

func _apply_loading_label_styles():
	if loading_label:
		loading_label.add_theme_color_override("font_color", Color("#FFFFFF"))
		loading_label.add_theme_color_override("font_outline_color", Color("#1A0C06"))
		loading_label.add_theme_constant_override("outline_size", 12)

func _apply_loading_bar_styles():
	if not loading_bar or not (loading_bar is ProgressBar):
		return
		
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#311A0E")
	bg_style.border_color = Color("#9B531C")
	bg_style.set_border_width_all(6)
	bg_style.set_corner_radius_all(20)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color("#7CE400")
	fill_style.set_corner_radius_all(15)
	
	fill_style.expand_margin_left = -6
	fill_style.expand_margin_top = -6
	fill_style.expand_margin_right = -6
	fill_style.expand_margin_bottom = -6
		
	loading_bar.add_theme_stylebox_override("background", bg_style)
	loading_bar.add_theme_stylebox_override("fill", fill_style)

func _start_character_animation():
	if character:
		var tween = create_tween().set_loops()
		tween.tween_property(character, "position:y", character.position.y - 15, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(character, "position:y", character.position.y + 15, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
func _start_loading_process():
	if loading_bar:
		loading_bar.value = 0
		var tween = create_tween()
		
		tween.tween_property(loading_bar, "value", 100.0, 5.0)
		tween.step_finished.connect(func(_idx): _update_loading_text())
		
		await tween.finished
		
		if loading_bar: loading_bar.hide()
		if loading_label: loading_label.hide()
		if character: character.hide()
		
		if about_card:
			about_card.show()

func _update_loading_text():
	if loading_label and loading_bar:
		var current_percent = int(loading_bar.value)
		loading_label.text = "Loading... " + str(current_percent) + "%"

func _on_continue_button_pressed():
	print("--- NA-CLICK ANG CONTINUE BUTTON ---")
	
	if next_scene != "" and ResourceLoader.exists(next_scene):
		print("PUMUPUNTA NA SA LOGIN SCENE: ", next_scene)
		Global.change_scene(next_scene)
	else:
		print("ERROR: Walang nakalagay na valid na Login Scene path sa 'Next Scene' property!")
