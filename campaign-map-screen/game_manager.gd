extends Control

# --- UI NODES ---
# Tip: Sa Scene Dock, i-right click ang OptionButton -> Access as Unique Name (%)
@onready var background: TextureRect = $Background
@onready var region_option: OptionButton = %OptionButton if has_node("%OptionButton") else $WoodenBanner/OptionButton

# --- LEVEL CONTAINERS ---
@onready var coastal_levels: Control = $LevelContainer/CoastalShoreLevels
@onready var lagonoy_levels: Control = $LevelContainer/LagonoyLevels
@onready var isarog_levels: Control = $LevelContainer/IsarogLevels

# --- BACKGROUND TEXTURES ---
var coastal_bg: Texture2D = preload("res://Coastal Shore.png")
var lagonoy_bg: Texture2D = preload("res://Lagonoy Valley.png")
var isarog_bg: Texture2D = preload("res://Isarog Foothills.png")

func _ready() -> void:
	_setup_option_button()
	_load_region(0) # Default: Coastal Shore (Index 0)

# ---------------------------------------------------------
# 1. SETUP AT DROPDOWN MENU LOGIC
# ---------------------------------------------------------
func _setup_option_button() -> void:
	# Null Check para maiwasan ang "Cannot call clear on null value"
	if not region_option:
		print("WARNING: Hindi mahanap ang OptionButton node. Siguraduhing tama ang node path.")
		return

	region_option.clear()
	
	region_option.add_item("COASTAL SHORE", 0)
	region_option.add_item("LAGONOY VALLEY", 1)
	region_option.add_item("ISAROG FOOTHILLS", 2)
	
	# --- MAIN BUTTON FONT STYLE ---
	region_option.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	region_option.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	region_option.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.9, 1))
	region_option.add_theme_font_size_override("font_size", 20) # Laki ng font sa wooden button
	
	# --- DROPDOWN POPUP LIST FONT STYLE ---
	var popup = region_option.get_popup()
	if popup:
		popup.add_theme_font_size_override("font_size", 22) # Laki ng font sa dropdown list
		popup.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	region_option.select(0)
	
	if not region_option.item_selected.is_connected(_on_region_selected):
		region_option.item_selected.connect(_on_region_selected)

func _on_region_selected(index: int) -> void:
	_load_region(index)

# ---------------------------------------------------------
# 2. PAGPAPALIT NG MGA MAPA AT LEVELS
# ---------------------------------------------------------
func _load_region(region_index: int) -> void:
	# Itago muna ang lahat ng level containers
	if coastal_levels: coastal_levels.hide()
	if lagonoy_levels: lagonoy_levels.hide()
	if isarog_levels: isarog_levels.hide()
	
	var active_container: Control
	
	match region_index:
		0:
			if background: background.texture = coastal_bg
			active_container = coastal_levels
		1:
			if background: background.texture = lagonoy_bg
			active_container = lagonoy_levels
		2:
			if background: background.texture = isarog_bg
			active_container = isarog_levels

	if active_container:
		active_container.show()
		_update_level_locks(active_container)

# ---------------------------------------------------------
# 3. LOCK AT UNLOCK SYSTEM
# ---------------------------------------------------------
func _update_level_locks(container: Control) -> void:
	# Safety check para sa GameManager singleton
	var unlocked_limit: int = 1
	if Engine.has_singleton("GameManager") or "GameManager" in get_tree().root:
		unlocked_limit = GameManager.unlocked_level
		
	var children = container.get_children()
	
	for index in range(children.size()):
		var btn = children[index] as Button
		if not btn:
			continue
			
		var level_num: int = index + 1
		
		if level_num <= unlocked_limit:
			# UNLOCKED STATE
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1) # Full brightness
			
			if btn.has_node("LockIcon"):
				btn.get_node("LockIcon").hide()
				
			if not btn.pressed.is_connected(_on_level_button_pressed):
				btn.pressed.connect(_on_level_button_pressed.bind(level_num))
		else:
			# LOCKED STATE
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.8) # Grayed out
			
			if btn.has_node("LockIcon"):
				btn.get_node("LockIcon").show()

# ---------------------------------------------------------
# 4. LEVEL CLICK HANDLER
# ---------------------------------------------------------
func _on_level_button_pressed(level_num: int) -> void:
	print("Lalabas ang gameplay para sa Level: ", level_num)
