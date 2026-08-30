extends Control

# --- UI NODES ---
@onready var close_button: TextureButton = $BackgroundOverlay/PopupBoard/CloseButton

# Palitan ang type ng sound_toggle mula CheckButton -> Button / TextureButton
@onready var sound_toggle: Button = $BackgroundOverlay/PopupBoard/VBoxContainer/SoundCard/HBoxContainer/SoundToggle

@onready var name_label: Label = $BackgroundOverlay/PopupBoard/VBoxContainer/AccountCard/VBoxContainer/NameLabel
@onready var grade_label: Label = $BackgroundOverlay/PopupBoard/VBoxContainer/AccountCard/VBoxContainer/SectionLabel
@onready var section_label: Label = $BackgroundOverlay/PopupBoard/VBoxContainer/AccountCard/VBoxContainer/SectionLabel

@onready var help_card: Panel = $BackgroundOverlay/PopupBoard/VBoxContainer/HelpCard
@onready var logout_button: Button = $BackgroundOverlay/PopupBoard/VBoxContainer/LogOutButton

var is_sound_on: bool = true

func _ready() -> void:
	_load_player_info()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		
	if sound_toggle:
		# Gagawing Toggle Mode ang ordinaryong Button
		sound_toggle.toggle_mode = true
		sound_toggle.button_pressed = is_sound_on
		sound_toggle.text = "" # Siguraduhing walang text
		
		# I-connect ang draw event at click handler
		sound_toggle.toggled.connect(_on_sound_toggled)
		sound_toggle.draw.connect(_draw_custom_toggle)
		
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)

func _load_player_info() -> void:
	if Engine.has_singleton("GameManager") or "GameManager" in get_tree().root:
		name_label.text = "Name: " + str(GameManager.player_name)
		grade_label.text = "Grade level: " + str(GameManager.grade_level)
		section_label.text = "Section: " + str(GameManager.section_name)
		is_sound_on = GameManager.is_sound_enabled
		if sound_toggle:
			sound_toggle.button_pressed = is_sound_on

func _draw_custom_toggle() -> void:
	var rect = Rect2(Vector2.ZERO, sound_toggle.size)
	var radius = rect.size.y / 2.0
	var is_on = sound_toggle.button_pressed
	
	# Color: Green kapag ON, Gray kapag OFF
	var bg_color = Color("#4A7C59") if is_on else Color("#888888")
	
	# 1. Background Track
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(int(radius))
	sound_toggle.draw_style_box(style, rect)
	
	# 2. White Circle Knob
	var circle_margin = 3.0
	var circle_radius = radius - circle_margin
	var circle_x = rect.size.x - radius if is_on else radius
	var circle_center = Vector2(circle_x, radius)
	
	sound_toggle.draw_circle(circle_center, circle_radius, Color.WHITE)

func _on_close_pressed() -> void:
	hide()

func _on_sound_toggled(toggled_on: bool) -> void:
	is_sound_on = toggled_on
	sound_toggle.queue_redraw()
	if Engine.has_singleton("GameManager") or "GameManager" in get_tree().root:
		GameManager.set_sound_enabled(toggled_on)

func _on_logout_pressed() -> void:
	print("Logging out...")
