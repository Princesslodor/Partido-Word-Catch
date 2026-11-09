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
	_start_logo_animation()
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

# --- MOVING LOGO ---
# The logo is split into pictures in images/logo_parts/, all the same size as
# the logo, stacked on the Character box. Points below are logo pixels (500 wide).
const LOGO_PARTS := "res://images/logo_parts/"
const LOGO_WIDTH := 500.0
const GIRL_FEET := Vector2(170, 200)
const GIRL_HAND := Vector2(222, 62)
const CAP_BOY_FEET := Vector2(375, 292)
const NET_BOY_FEET := Vector2(265, 300)
const NET_GRIP := Vector2(294, 212)
const BLOCK_CENTRES := {"block_p": Vector2(250, 53), "block_w": Vector2(252, 110), "block_c": Vector2(254, 164)}

func _start_logo_animation():
	if not character or not ResourceLoader.exists(LOGO_PARTS + "base.png"):
		return
	character.texture = load(LOGO_PARTS + "base.png")
	var cap_boy = _add_logo_part("cap_boy", CAP_BOY_FEET, character)
	var blocks := []
	for block_name in ["block_p", "block_w", "block_c"]:
		blocks.append(_add_logo_part(block_name, BLOCK_CENTRES[block_name], character))
	var net_boy = _add_logo_part("net_boy", NET_BOY_FEET, character)
	var net = _add_logo_part("net", NET_GRIP, net_boy)
	net.show_behind_parent = true
	var girl = _add_logo_part("girl", GIRL_FEET, character)

	# The girl puts the blocks up one by one: P, then W, then C.
	for i in blocks.size():
		_place_logo_block(blocks[i], BLOCK_CENTRES.values()[i], girl, 0.3 + i * 1.0)

	# The boy in the red cap looks around with his telescope.
	var look := cap_boy.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	look.tween_property(cap_boy, "rotation", deg_to_rad(-2.5), 1.6)
	look.tween_property(cap_boy, "rotation", deg_to_rad(2.5), 1.6)

	# The small boy scoops with his net to catch the letters.
	var scoop := net.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scoop.tween_property(net, "rotation", deg_to_rad(-7.0), 1.2)
	scoop.tween_property(net, "rotation", deg_to_rad(3.0), 1.2)
	var lean := net_boy.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	lean.tween_property(net_boy, "rotation", deg_to_rad(-1.2), 1.2)
	lean.tween_property(net_boy, "rotation", deg_to_rad(1.2), 1.2)

func _add_logo_part(part_name: String, pivot: Vector2, parent: Control) -> TextureRect:
	var part := TextureRect.new()
	part.texture = load(LOGO_PARTS + part_name + ".png")
	part.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	part.stretch_mode = TextureRect.STRETCH_SCALE
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	part.size = character.size
	part.pivot_offset = pivot * (character.size.x / LOGO_WIDTH)
	parent.add_child(part)
	return part

# A block starts small at the girl's hand and lands in its place while she reaches.
func _place_logo_block(block: TextureRect, centre: Vector2, girl: TextureRect, delay: float):
	var logo_scale: float = character.size.x / LOGO_WIDTH
	block.modulate.a = 0.0
	block.position = (GIRL_HAND - centre) * logo_scale
	block.scale = Vector2.ONE * 0.6
	var tween := block.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(block, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(block, "position", Vector2.ZERO, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(block, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var reach := girl.create_tween()
	reach.tween_interval(delay)
	reach.tween_property(girl, "rotation", deg_to_rad(3.5), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reach.tween_property(girl, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
