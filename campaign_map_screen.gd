extends Control

# Coastal Shore's 10 buttons are shared between Yunit 1 (first 5) and
# Yunit 2 (last 5) - it's the same background/container for both, just
# showing a different half. Lagonoy Valley now holds only Yunit 3's 5
# levels, and Isarog Foothills holds all 15 of Yunit 4's (its 10 original
# levels plus the 5 that used to be Lagonoy's second half), so every unit
# after the first two has its own single backdrop.
const COASTAL_TOTAL_LEVELS: int = 10
const LAGONOY_TOTAL_LEVELS: int = 5
const ISAROG_TOTAL_LEVELS: int = 15
const UNIT_LEVEL_COUNTS: Array = [5, 5, 5, 15]

# Inayos ang paths batay sa iyong Scene Tree
@onready var region_option: OptionButton = $RegionOptionButton
@onready var settings_button: TextureButton = $SettingsButton 
@onready var settings_menu: Control = $SettingsMenu
@onready var level_info_popup: Control = $LevelInfoPopup

@onready var coastal_levels: Control = $"Level Container/CoastalShoreLevels"
@onready var lagonoy_levels: Control = $"Level Container/LagonoyValleyLevels"
@onready var isarog_levels: Control = $"Level Container/IsarogFoothillsLevels"

@onready var coin_labels: Array = [
	$"Level Container/CoastalShoreLevels/Header/CoinDisplay/CoinLabel",
	$"Level Container/LagonoyValleyLevels/Header/CoinDisplay/CoinLabel",
	$"Level Container/IsarogFoothillsLevels/Header/CoinDisplay/CoinLabel",
]

var coastal_bg: Texture2D = preload("res://Coastal Shore.png")
var lagonoy_bg: Texture2D = preload("res://Lagonoy Valley.png")
var isarog_bg: Texture2D = preload("res://Isarog Foothills.png")

func _ready() -> void:
	# Give each Student their own per-account shuffled word/level order
	# (see LevelData.apply_student_shuffle for why) before any level content
	# is shown. Seeded by class code + name + PIN, not device_id, so it
	# stays the same for this student even if they log in on another device.
	if GameManager.role == "STUDENT" and GameManager.class_code != "" and GameManager.player_name != "" and GameManager.student_pin != "":
		var seed_key := GameManager.class_code + "|" + GameManager.player_name + "|" + GameManager.student_pin
		LevelData.apply_student_shuffle(seed_key)

	if settings_menu:
		settings_menu.hide()

	if settings_button:
		if not settings_button.pressed.is_connected(_on_settings_button_pressed):
			settings_button.pressed.connect(_on_settings_button_pressed)

	_setup_option_button()
	_load_region(0)
	_update_coin_display()
	_connect_sound_to_all_buttons(self)

# --- AUDIO CLICK SYSTEM ---
func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()

func _update_coin_display() -> void:
	for label in coin_labels:
		if label:
			label.text = str(GameManager.player_coins)

func _setup_option_button() -> void:
	if not region_option:
		return

	region_option.clear()

	region_option.add_item("YUNIT 1", 0)
	region_option.add_item("YUNIT 2", 1)
	region_option.add_item("YUNIT 3", 2)
	region_option.add_item("YUNIT 4", 3)

	var current_unlocked_level: int = GameManager.unlocked_level

	# Each unit unlocks once the player has cleared every level before it -
	# i.e. their unlocked_level has moved past that unit's last level.
	var levels_before_unit: int = 0
	for i in range(UNIT_LEVEL_COUNTS.size()):
		region_option.set_item_disabled(i, i > 0 and current_unlocked_level <= levels_before_unit)
		levels_before_unit += UNIT_LEVEL_COUNTS[i]

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

func _load_region(unit_index: int) -> void:
	if coastal_levels: coastal_levels.hide()
	if lagonoy_levels: lagonoy_levels.hide()
	if isarog_levels: isarog_levels.hide()

	var active_container: Control
	var current_bg_texture: Texture2D
	var level_offset: int = 0
	# Which of the active container's buttons (1-based, by child order)
	# belong to this unit - everything outside this range gets hidden
	# entirely rather than just locked. Only Coastal Shore needs this,
	# since it's the one container shared by two units.
	var visible_range: Vector2i = Vector2i(1, 999)

	match unit_index:
		0: # Yunit 1 - Coastal Shore, first 5 buttons
			active_container = coastal_levels
			current_bg_texture = coastal_bg
			level_offset = 0
			visible_range = Vector2i(1, 5)
		1: # Yunit 2 - Coastal Shore, last 5 buttons
			active_container = coastal_levels
			current_bg_texture = coastal_bg
			level_offset = 0
			visible_range = Vector2i(6, 10)
		2: # Yunit 3 - Lagonoy Valley (now just 5 levels)
			active_container = lagonoy_levels
			current_bg_texture = lagonoy_bg
			level_offset = COASTAL_TOTAL_LEVELS
		3: # Yunit 4 - Isarog Foothills (now 15 levels)
			active_container = isarog_levels
			current_bg_texture = isarog_bg
			level_offset = COASTAL_TOTAL_LEVELS + LAGONOY_TOTAL_LEVELS

	if active_container:
		active_container.show()

		if active_container.has_node("Background"):
			var bg_node = active_container.get_node("Background") as TextureRect
			if bg_node:
				bg_node.texture = current_bg_texture

		_update_level_locks(active_container, level_offset, visible_range)

func _update_level_locks(container: Control, offset: int, visible_range: Vector2i = Vector2i(1, 999)) -> void:
	var unlocked_limit: int = GameManager.unlocked_level

	var button_counter: int = 1

	for child in container.get_children():
		if not (child is Button):
			continue

		var btn = child as Button

		if button_counter < visible_range.x or button_counter > visible_range.y:
			# Belongs to the OTHER unit sharing this container (e.g. Yunit
			# 1's buttons while Yunit 2 is selected) - hide entirely rather
			# than lock, so it doesn't show up as a locked level that isn't
			# actually part of the unit currently being viewed.
			btn.hide()
			button_counter += 1
			continue

		btn.show()
		var global_level_num: int = offset + button_counter
		var lock_icon_name := "LockIcon" + str(global_level_num)

		# theme_override_styles/normal in the .tscn lives in the same override
		# slot that add/remove_theme_stylebox_override() manipulate, so the
		# button's original circle style has to be cached once and restored
		# explicitly - removing the override entirely falls back to Godot's
		# plain default Button look, not the original style.
		if not btn.has_meta("original_normal_style"):
			btn.set_meta("original_normal_style", btn.get_theme_stylebox("normal"))
		var original_style: StyleBox = btn.get_meta("original_normal_style")

		if global_level_num < unlocked_limit:
			# Already completed - unlocked, but no special highlight needed.
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			if original_style:
				btn.add_theme_stylebox_override("normal", original_style)
			if btn.has_node(lock_icon_name):
				btn.get_node(lock_icon_name).hide()

			if not btn.pressed.is_connected(_on_level_button_pressed):
				btn.pressed.connect(_on_level_button_pressed.bind(global_level_num))
		elif global_level_num == unlocked_limit:
			# The one level the student should play next - make it stand out.
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			btn.add_theme_stylebox_override("normal", _get_next_level_highlight_style())
			if btn.has_node(lock_icon_name):
				btn.get_node(lock_icon_name).hide()

			if not btn.pressed.is_connected(_on_level_button_pressed):
				btn.pressed.connect(_on_level_button_pressed.bind(global_level_num))
		else:
			# Still locked.
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.8)
			if original_style:
				btn.add_theme_stylebox_override("normal", original_style)
			if btn.has_node(lock_icon_name):
				btn.get_node(lock_icon_name).show()

		button_counter += 1

## Bright gold/orange highlight so the next level to play stands out from
## both already-completed levels and still-locked ones.
func _get_next_level_highlight_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.83, 0.2, 1)
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.9, 0.35, 0.05, 1)
	style.corner_radius_top_left = 50
	style.corner_radius_top_right = 50
	style.corner_radius_bottom_right = 50
	style.corner_radius_bottom_left = 50
	style.shadow_color = Color(1.0, 0.7, 0.0, 0.6)
	style.shadow_size = 10
	return style

func _on_level_button_pressed(level_num: int) -> void:
	if not level_info_popup:
		return
	var lesson_title := _unit_label_for_level(level_num)
	if level_info_popup.has_method("display_level_info"):
		level_info_popup.display_level_info(level_num, lesson_title)

func _on_settings_button_pressed() -> void:
	if settings_menu:
		settings_menu.show()
		settings_menu.move_to_front()

func _unit_label_for_level(level_num: int) -> String:
	if level_num <= 5:
		return "Yunit 1: Pagbisto kan Sakuyang Sadiri saka Pamilya"
	elif level_num <= 10:
		return "Yunit 2: Pag-aram kan Sakuyang Komunidad"
	elif level_num <= COASTAL_TOTAL_LEVELS + LAGONOY_TOTAL_LEVELS:
		return "Yunit 3: Sa Luwas kan Sakuyang Komunidad"
	else:
		return "Yunit 4: Pangangataman kan Satuyang Kapalibotan"
