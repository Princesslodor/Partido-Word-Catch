extends Button

# Signal na ipapadala kapag nagbago ang state (ON / OFF)
signal toggle_changed(is_on: bool)

@export var is_on: bool = true:
	set(value):
		is_on = value
		_update_toggle_visuals(true)

# Color Palette
var color_on: Color = Color("4CAF50")    # Berde (ON)
var color_off: Color = Color("D1D5DB")   # Abuhan/Gray (OFF)
var color_knob: Color = Color("FFFFFF")  # Puting bilog

# UI Elements
var track_style: StyleBoxFlat
var knob: Panel

func _ready():
	toggle_mode = true
	button_pressed = is_on
	flat = false # Siguraduhing false para lumabas ang kulay ng background
	text = ""    # Alisin ang default text
	
	# Minimum size para kasya ang 24x24 knob at padding
	custom_minimum_size = Vector2(60, 30)
	
	_setup_visuals()
	toggled.connect(_on_toggled)

func _setup_visuals():
	# 1. Background Oval Track
	track_style = StyleBoxFlat.new()
	track_style.set_corner_radius_all(15)
	
	# I-apply sa lahat ng states para hindi mawala ang kulay
	add_theme_stylebox_override("normal", track_style)
	add_theme_stylebox_override("pressed", track_style)
	add_theme_stylebox_override("hover", track_style)
	add_theme_stylebox_override("hover_pressed", track_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# 2. Sliding White Knob
	knob = Panel.new()
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var knob_style = StyleBoxFlat.new()
	knob_style.bg_color = color_knob
	knob_style.set_corner_radius_all(12)
	knob.add_theme_stylebox_override("panel", knob_style)
	
	knob.size = Vector2(24, 24)
	add_child(knob)
	
	_update_toggle_visuals(false)

func _on_toggled(pressed_state: bool):
	is_on = pressed_state
	emit_signal("toggle_changed", is_on)

func _update_toggle_visuals(animate: bool):
	if not knob or not track_style: 
		return
	
	var target_bg = color_on if is_on else color_off
	var target_x = 32.0 if is_on else 4.0
	var target_y = 3.0
	
	if animate:
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(track_style, "bg_color", target_bg, 0.2)
		tween.tween_property(knob, "position", Vector2(target_x, target_y), 0.2)
	else:
		track_style.bg_color = target_bg
		knob.position = Vector2(target_x, target_y)
