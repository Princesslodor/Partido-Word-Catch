extends Control

const COASTAL_TOTAL_LEVELS: int = 10
const LAGONOY_TOTAL_LEVELS: int = 10

# Inayos ang paths batay sa iyong Scene Tree
@onready var region_option: OptionButton = $RegionOptionButton
@onready var settings_button: TextureButton = $SettingsButton 
@onready var settings_menu: Control = $SettingsMenu

@onready var coastal_levels: Control = $"Level Container/CoastalShoreLevels"
@onready var lagonoy_levels: Control = $"Level Container/LagonoyValleyLevels"
@onready var isarog_levels: Control = $"Level Container/IsarogFoothillsLevels"

var coastal_bg: Texture2D = preload("res://Coastal Shore.png")
var lagonoy_bg: Texture2D = preload("res://Lagonoy Valley.png")
var isarog_bg: Texture2D = preload("res://Isarog Foothills.png")

func _ready() -> void:
	if settings_menu:
		settings_menu.hide()
	
	if settings_button:
		if not settings_button.pressed.is_connected(_on_settings_button_pressed):
			settings_button.pressed.connect(_on_settings_button_pressed)

	_setup_option_button()
	_load_region(0)

func _setup_option_button() -> void:
	if not region_option:
		return

	region_option.clear()
	
	region_option.add_item("COASTAL SHORE", 0)
	region_option.add_item("LAGONOY VALLEY", 1)
	region_option.add_item("ISAROG FOOTHILLS", 2)
	
	var current_unlocked_level: int = 1
	if Engine.has_singleton("GameManager"):
		current_unlocked_level = GameManager.unlocked_level
	elif "GameManager" in get_tree().root:
		current_unlocked_level = get_tree().root.get_node("GameManager").unlocked_level

	region_option.set_item_disabled(0, false)
	
	var is_lagonoy_unlocked: bool = current_unlocked_level > COASTAL_TOTAL_LEVELS
	region_option.set_item_disabled(1, not is_lagonoy_unlocked)
	
	var is_isarog_unlocked: bool = current_unlocked_level > (COASTAL_TOTAL_LEVELS + LAGONOY_TOTAL_LEVELS)
	region_option.set_item_disabled(2, not is_isarog_unlocked)

	region_option.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# PINALAKI ANG FONT SIZE DITO (mula 20 -> 32)
	region_option.add_theme_font_size_override("font_size", 32)
	
	var popup = region_option.get_popup()
	if popup:
		# PINALAKI DIN ANG FONT SIZE SA DROPDOWN MENU (mula 24 -> 32)
		popup.add_theme_font_size_override("font_size", 32)
		popup.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		popup.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 0.6))
	
	region_option.select(0)
	
	if region_option.item_selected.is_connected(_on_region_selected):
		region_option.item_selected.disconnect(_on_region_selected)
		
	region_option.item_selected.connect(_on_region_selected)

func _on_region_selected(index: int) -> void:
	_load_region(index)

func _load_region(region_index: int) -> void:
	if coastal_levels: coastal_levels.hide()
	if lagonoy_levels: lagonoy_levels.hide()
	if isarog_levels: isarog_levels.hide()
	
	var active_container: Control
	var current_bg_texture: Texture2D
	var level_offset: int = 0
	
	match region_index:
		0:
			active_container = coastal_levels
			current_bg_texture = coastal_bg
			level_offset = 0
		1:
			active_container = lagonoy_levels
			current_bg_texture = lagonoy_bg
			level_offset = COASTAL_TOTAL_LEVELS
		2:
			active_container = isarog_levels
			current_bg_texture = isarog_bg
			level_offset = COASTAL_TOTAL_LEVELS + LAGONOY_TOTAL_LEVELS

	if active_container:
		active_container.show()
		
		if active_container.has_node("Background"):
			var bg_node = active_container.get_node("Background") as TextureRect
			if bg_node:
				bg_node.texture = current_bg_texture
				
		_update_level_locks(active_container, level_offset)

func _update_level_locks(container: Control, offset: int) -> void:
	var unlocked_limit: int = 1
	if Engine.has_singleton("GameManager"):
		unlocked_limit = GameManager.unlocked_level
	elif "GameManager" in get_tree().root:
		unlocked_limit = get_tree().root.get_node("GameManager").unlocked_level
		
	var button_counter: int = 1
	
	for child in container.get_children():
		if not (child is Button):
			continue
			
		var btn = child as Button
		var global_level_num: int = offset + button_counter
		
		if global_level_num <= unlocked_limit:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			if btn.has_node("LockIcon"):
				btn.get_node("LockIcon").hide()
				
			if not btn.pressed.is_connected(_on_level_button_pressed):
				btn.pressed.connect(_on_level_button_pressed.bind(global_level_num))
		else:
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.8)
			if btn.has_node("LockIcon"):
				btn.get_node("LockIcon").show()
				
		button_counter += 1

func _on_level_button_pressed(level_num: int) -> void:
	print("Lalabas ang gameplay para sa Level: ", level_num)

func _on_settings_button_pressed() -> void:
	if settings_menu:
		settings_menu.show()
		settings_menu.move_to_front()
