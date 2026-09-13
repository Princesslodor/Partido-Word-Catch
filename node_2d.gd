extends Node2D

var current_level: int = 1
var player_coins: int:
	get: return GameManager.player_coins
	set(val): GameManager.player_coins = val

var player_stars: int = 3
var player_hearts: int:
	get: return GameManager.player_hearts
	set(val): GameManager.player_hearts = val

# Timer para sa 10 minuto (10 * 60 = 600 seconds)
var heart_regen_timer: Timer
const REGEN_TIME: float = 600.0
const RESTORE_HEART_COST: int = 20

var out_of_hearts_modal: Control = null
var out_of_hearts_countdown_label: Label = null
var out_of_hearts_restore_button: Button = null

var current_word: String = ""
var current_placed_letters: Array = []
var last_slots_full_state: bool = false

var extra_alphabet: Array = ["A", "B", "K", "D", "E", "G", "H", "I", "L", "M", "N", "O", "P", "R", "S", "T", "U", "W", "Y"]

func _ready():
	if Global.requested_level >= 1 and Global.requested_level <= 16:
		current_level = Global.requested_level
		Global.requested_level = 0

	if has_node("%VictoryPopup"): %VictoryPopup.visible = false
	if has_node("%SpeakerButton") and not %SpeakerButton.is_connected("pressed", Callable(self, "_on_speaker_button_pressed")):
		%SpeakerButton.pressed.connect(_on_speaker_button_pressed)
	if has_node("%NextLevel") and not %NextLevel.is_connected("pressed", Callable(self, "_on_next_level_button_pressed")):
		%NextLevel.pressed.connect(_on_next_level_button_pressed)
	if has_node("%RevealHintButton") and not %RevealHintButton.is_connected("pressed", Callable(self, "_on_reveal_hint_pressed")):
		%RevealHintButton.pressed.connect(_on_reveal_hint_pressed)
	if has_node("%RemoveLetterButton") and not %RemoveLetterButton.is_connected("pressed", Callable(self, "_on_remove_letter_pressed")):
		%RemoveLetterButton.pressed.connect(_on_remove_letter_pressed)
	if has_node("%ShuffleButton") and not %ShuffleButton.is_connected("pressed", Callable(self, "_on_shuffle_pressed")):
		%ShuffleButton.pressed.connect(_on_shuffle_pressed)
	if has_node("%SettingsButton") and not %SettingsButton.is_connected("pressed", Callable(self, "_on_settings_button_pressed")):
		%SettingsButton.pressed.connect(_on_settings_button_pressed)
	if has_node("%BackButton") and not %BackButton.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
		%BackButton.pressed.connect(_on_back_button_pressed)

	setup_heart_timer()
	load_current_level()
	_connect_sound_to_all_buttons(self)

func _process(_delta):
	check_slots_automatically()
	update_timer_display()

func setup_heart_timer():
	heart_regen_timer = Timer.new()
	heart_regen_timer.wait_time = REGEN_TIME
	heart_regen_timer.one_shot = false
	heart_regen_timer.timeout.connect(_on_heart_regen_timeout)
	add_child(heart_regen_timer)
	
	if player_hearts < 4:
		heart_regen_timer.start()

func load_current_level():
	if has_node("%VictoryPopup"): %VictoryPopup.visible = false

	var lvl_key = int(current_level)

	# Resume with whatever stars were left the last time this level was
	# left mid-attempt (leaving for the campaign map and coming back
	# shouldn't hand a fresh 3 stars for free) - defaults to 3 if this
	# level has no in-progress attempt saved.
	player_stars = GameManager.in_progress_stars.get(str(lvl_key), 3)
	update_stars_display()
	update_hearts_display()
	last_slots_full_state = false
	_check_out_of_hearts()

	if not LevelData.levels.has(lvl_key): return
		
	var level_info = LevelData.levels[lvl_key]
	current_word = level_info["word"].to_upper()
	
	current_placed_letters.clear()
	for i in range(current_word.length()):
		current_placed_letters.append("")
	
	if has_node("%TagalogHintText"): %TagalogHintText.text = '"' + level_info["clue"] + '"'
	if has_node("%LevelLabel"): %LevelLabel.text = "LEVEL " + str(current_level)
	if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)
	
	var slot_container = _get_answer_slot_container()
	if slot_container and slot_container is GridContainer: slot_container.columns = 7
	var grid = _get_scrambled_grid()
	if grid and grid is GridContainer: grid.columns = 7

	update_level_image(current_level)
	update_background(current_level)
	setup_answer_slots(current_word)
	setup_scrambled_letters(current_word)

func update_background(lvl: int):
	if has_node("CanvasLayer/LagonoyValleyBg"):
		$CanvasLayer/LagonoyValleyBg.visible = false
	if has_node("CanvasLayer/CoastalShore"):
		$CanvasLayer/CoastalShore.visible = false
	if has_node("CanvasLayer/GreenWood"):
		$CanvasLayer/GreenWood.visible = false
	if has_node("CanvasLayer/BlueWood"):
		$CanvasLayer/BlueWood.visible = false
	if has_node("CanvasLayer/VioletWood"):
		$CanvasLayer/VioletWood.visible = false
		
	if lvl >= 1 and lvl <= 10:
		if has_node("CanvasLayer/LagonoyValleyBg"):
			$CanvasLayer/LagonoyValleyBg.visible = true
	elif lvl >= 11:
		if has_node("CanvasLayer/CoastalShore"):
			$CanvasLayer/CoastalShore.visible = true

func update_level_image(lvl: int):
	var folder_path = "res://Picture_HintLevel/"
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var found_file = ""
		while file_name != "":
			if not dir.current_is_dir() and ("level_" + str(lvl) in file_name.to_lower()):
				found_file = file_name
				break
			file_name = dir.get_next()
		dir.list_dir_end()
		if found_file != "":
			var full_path = folder_path + found_file
			var tex = load(full_path)
			if tex and has_node("%HintPicture"):
				%HintPicture.texture = tex
				%HintPicture.visible = true
				%HintPicture.show()

func setup_answer_slots(word: String):
	var slot_container = _get_answer_slot_container()
	if not slot_container: return
	var slots = slot_container.get_children()
	
	for slot in slots:
		slot.visible = false
		_clear_tile_text(slot)
		if "is_locked" in slot: slot.is_locked = false
		if slot.has_method("set_as_space"): slot.set_as_space(false)

	var hint_count = get_hint_count_for_level(current_level)
	var valid_indices = []
	for i in range(word.length()):
		if word[i] != " ": valid_indices.append(i)
	valid_indices.shuffle()
	
	var hint_indices = []
	for i in range(min(hint_count, valid_indices.size())):
		hint_indices.append(valid_indices[i])

	for char_idx in range(word.length()):
		if char_idx >= slots.size(): break
		var slot = slots[char_idx]
		var char = word[char_idx]
		
		slot.visible = true
		_clear_tile_text(slot)
		if "is_locked" in slot: slot.is_locked = false
			
		if char == " ":
			if slot.has_method("set_as_space"): slot.set_as_space(true)
			slot.visible = false
			current_placed_letters[char_idx] = " "
		else:
			if slot.has_method("set_as_space"): slot.set_as_space(false)
			if char_idx in hint_indices:
				current_placed_letters[char_idx] = char
				_set_tile_text(slot, char)
				if "is_locked" in slot: slot.is_locked = true

func setup_scrambled_letters(word: String):
	var grid = _get_scrambled_grid()
	if grid == null: return
	var tiles = grid.get_children()
	
	for tile in tiles:
		tile.visible = false
		_clear_tile_text(tile)
		if tile.has_method("reset_tile"):
			tile.reset_tile()

	var letters: Array = []
	for c in word:
		if c != " ": letters.append(c)
		
	var needed_extras = tiles.size() - letters.size()
	for i in range(needed_extras):
		letters.append(extra_alphabet[randi() % extra_alphabet.size()])
	letters.shuffle()
	
	for i in range(tiles.size()):
		if i < letters.size():
			tiles[i].visible = true
			_set_tile_text(tiles[i], letters[i])
			if tiles[i].has_method("setup_tile"): tiles[i].setup_tile(letters[i])
		else:
			tiles[i].visible = false

func check_slots_automatically():
	var slot_container = _get_answer_slot_container()
	if slot_container == null: return
	var slots = slot_container.get_children()
	var constructed_word = ""
	var is_full = true

	for char_idx in range(current_word.length()):
		if char_idx >= slots.size():
			is_full = false
			break
		var slot = slots[char_idx]
		if current_word[char_idx] == " ":
			constructed_word += " "
		else:
			var slot_text = ""
			if slot.has_method("get_letter"):
				slot_text = slot.get_letter().strip_edges().to_upper()
			elif "text" in slot and slot.text != "": 
				slot_text = slot.text.strip_edges().to_upper()
			elif slot.has_node("Label"): 
				slot_text = slot.get_node("Label").text.strip_edges().to_upper()

			if slot_text == "":
				is_full = false
				break
			constructed_word += slot_text

	if is_full and not last_slots_full_state:
		last_slots_full_state = true
		if constructed_word == current_word:
			show_victory_popup()
		else:
			handle_wrong_answer()
	elif not is_full:
		last_slots_full_state = false

func check_answer():
	check_slots_automatically()

func handle_wrong_answer():
	player_stars -= 1
	if player_stars < 0:
		player_stars = 0
	update_stars_display()

	# Persist immediately so leaving for the campaign map right after a
	# mistake (without triggering the hearts-lost save below) doesn't
	# lose the reduced star count.
	GameManager.in_progress_stars[str(int(current_level))] = player_stars
	GameManager.save_game()

	if player_stars <= 0:
		player_hearts -= 1
		if player_hearts < 0:
			player_hearts = 0
		update_hearts_display()
		GameManager.save_game()  # heart loss on top of the star save above

		if heart_regen_timer.is_stopped():
			heart_regen_timer.start()

		_check_out_of_hearts()

func update_stars_display():
	if has_node("CanvasLayer/LevelDesign/StarWithFill"):
		$CanvasLayer/LevelDesign/StarWithFill.visible = (player_stars >= 1)
	if has_node("CanvasLayer/LevelDesign/StarWithFill2"):
		$CanvasLayer/LevelDesign/StarWithFill2.visible = (player_stars >= 2)
	if has_node("CanvasLayer/LevelDesign/StarWithFill3"):
		$CanvasLayer/LevelDesign/StarWithFill3.visible = (player_stars >= 3)

func update_hearts_display():
	if has_node("%LiveLabel"):
		get_node("%LiveLabel").text = str(player_hearts)

func update_timer_display():
	if heart_regen_timer and not heart_regen_timer.is_stopped():
		var time_left = int(heart_regen_timer.time_left)
		var minutes = time_left / 60
		var seconds = time_left % 60
		var time_string = "%02d:%02d" % [minutes, seconds]
		if has_node("%HeartTimerLabel"):
			%HeartTimerLabel.text = time_string
		if out_of_hearts_countdown_label and is_instance_valid(out_of_hearts_countdown_label):
			out_of_hearts_countdown_label.text = time_string
	else:
		if has_node("%HeartTimerLabel"):
			%HeartTimerLabel.text = ""

func _on_heart_regen_timeout():
	if player_hearts < 4:
		player_hearts += 1
		update_hearts_display()
		GameManager.save_game()

	if player_hearts < 4:
		heart_regen_timer.start()
	else:
		heart_regen_timer.stop()

	_check_out_of_hearts()

## Shows a blocking modal explaining why play is locked once hearts hit 0,
## with a live countdown to the next heart - and hides it again the moment
## a heart regenerates. Hearts are the only thing gating this: player_stars
## resets to 3 on every level load, so it's never independently "empty"
## outside of this same out-of-hearts state.
func _check_out_of_hearts() -> void:
	if player_hearts <= 0:
		var modal := _ensure_out_of_hearts_modal()
		modal.show()
		modal.move_to_front()
		update_timer_display()
		_update_restore_heart_button()
	elif out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		out_of_hearts_modal.hide()

func _update_restore_heart_button() -> void:
	if not out_of_hearts_restore_button:
		return
	out_of_hearts_restore_button.text = "Restore 1 Heart (🪙 %d)" % RESTORE_HEART_COST
	out_of_hearts_restore_button.disabled = player_coins < RESTORE_HEART_COST
	out_of_hearts_restore_button.modulate = Color(1, 1, 1, 1) if player_coins >= RESTORE_HEART_COST else Color(1, 1, 1, 0.5)

func _on_restore_heart_pressed() -> void:
	if player_coins < RESTORE_HEART_COST or player_hearts > 0:
		return
	player_coins -= RESTORE_HEART_COST
	player_hearts = min(player_hearts + 1, 4)
	update_hearts_display()
	if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)
	GameManager.save_game()
	_check_out_of_hearts()

func _ensure_out_of_hearts_modal() -> Control:
	if out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		return out_of_hearts_modal

	# Fixed pixel positions against the project's 720x1280 design canvas -
	# matching how every other UI element here is placed (layout_mode=0,
	# explicit offsets) - NOT percentage anchors. Anchors resolve against
	# the actual viewport rect, which "expand" stretch mode can make wider
	# than 720 on a desktop/debug window, throwing off any 0.5-anchored
	# centering relative to the design canvas.
	var overlay := Control.new()
	overlay.name = "OutOfHeartsModal"
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(720, 1280)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.position = Vector2.ZERO
	dim.size = Vector2(720, 1280)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.91, 1)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.65, 0.27, 0.0, 1)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(150, 490)
	panel.size = Vector2(420, 300)
	overlay.add_child(panel)

	var title := Label.new()
	title.text = "Out of Hearts!"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.65, 0.1, 0.1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20, 20)
	title.size = Vector2(380, 40)
	panel.add_child(title)

	var message := Label.new()
	message.text = "You've run out of hearts. Wait for them to refill before you can play again."
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	message.position = Vector2(20, 65)
	message.size = Vector2(380, 65)
	panel.add_child(message)

	out_of_hearts_countdown_label = Label.new()
	out_of_hearts_countdown_label.add_theme_font_size_override("font_size", 34)
	out_of_hearts_countdown_label.add_theme_color_override("font_color", Color(0.1, 0.3, 0.6, 1))
	out_of_hearts_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	out_of_hearts_countdown_label.position = Vector2(20, 135)
	out_of_hearts_countdown_label.size = Vector2(380, 40)
	panel.add_child(out_of_hearts_countdown_label)

	out_of_hearts_restore_button = Button.new()
	out_of_hearts_restore_button.position = Vector2(20, 185)
	out_of_hearts_restore_button.size = Vector2(380, 45)
	var restore_style := StyleBoxFlat.new()
	restore_style.bg_color = Color(0.91, 0.6, 0.15, 1)
	restore_style.corner_radius_top_left = 22
	restore_style.corner_radius_top_right = 22
	restore_style.corner_radius_bottom_left = 22
	restore_style.corner_radius_bottom_right = 22
	out_of_hearts_restore_button.add_theme_stylebox_override("normal", restore_style)
	out_of_hearts_restore_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	out_of_hearts_restore_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	out_of_hearts_restore_button.pressed.connect(_on_restore_heart_pressed)
	panel.add_child(out_of_hearts_restore_button)

	var back_btn := Button.new()
	back_btn.text = "Back to Map"
	back_btn.position = Vector2(110, 240)
	back_btn.size = Vector2(200, 45)
	back_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	back_btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1, 1))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://campaign_map_screen.tscn"))
	panel.add_child(back_btn)

	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(overlay)
	else:
		add_child(overlay)
	out_of_hearts_modal = overlay
	return overlay

func show_victory_popup():
	var lvl_key = int(current_level)
	var level_info = LevelData.levels[lvl_key]
	GameManager.add_coins(10)
	# Level's finished, so there's no "in-progress attempt" to resume
	# anymore - replaying it later should start fresh with 3 stars again.
	# Erased before complete_level() so its own save_game() call picks up
	# this change too, instead of needing a separate save here.
	GameManager.in_progress_stars.erase(str(lvl_key))
	GameManager.complete_level(lvl_key, player_stars)
	if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)
	if has_node("%+coin"): get_node("%+coin").text = "+10 COINS"
	if has_node("%WordLabel"): %WordLabel.text = level_info.get("word", "")
	if has_node("%MeaningLabel"): %MeaningLabel.text = level_info.get("meaning", "")
	if has_node("%CulturalNoteLabel"): %CulturalNoteLabel.text = level_info.get("cultural_note", "")
	if has_node("%VictoryPopup"): %VictoryPopup.visible = true
	
	var particles = get_node_or_null("%CPUParticles2D")
	if particles and particles is CPUParticles2D:
		particles.emitting = false
		particles.restart()
		particles.emitting = true
	
	Global.play_horray()

# --- HINT BUTTONS ---
func _on_reveal_hint_pressed():
	if player_coins < 10: return
		
	var slot_container = _get_answer_slot_container()
	if not slot_container: return
	var slots = slot_container.get_children()
	
	for i in range(current_word.length()):
		if i >= slots.size(): break
		var slot = slots[i]
		var target_char = current_word[i]
		if target_char == " ": continue
		
		var slot_text = ""
		if "text" in slot: slot_text = slot.text.strip_edges().to_upper()
		elif slot.has_node("Label"): slot_text = slot.get_node("Label").text.strip_edges().to_upper()
		
		if slot_text != target_char:
			player_coins -= 10
			if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)
			GameManager.save_game()
			_set_tile_text(slot, target_char)
			current_placed_letters[i] = target_char
			if "is_locked" in slot: slot.is_locked = true
			break

func _on_remove_letter_pressed():
	if player_coins < 5: return
		
	var grid = _get_scrambled_grid()
	if not grid: return
	var tiles = grid.get_children()
	
	var wrong_indices = []
	for i in range(tiles.size()):
		var tile = tiles[i]
		if tile.visible:
			var tile_text = ""
			if "text" in tile: tile_text = tile.text.strip_edges().to_upper()
			elif tile.has_node("Label"): tile_text = tile.get_node("Label").text.strip_edges().to_upper()
			
			if tile_text != "" and not (tile_text in current_word):
				wrong_indices.append(i)
				
	if wrong_indices.size() == 0: return

	wrong_indices.shuffle()
	var selected_index = wrong_indices[0]
	var selected_tile = tiles[selected_index]
	
	_clear_tile_text(selected_tile)
	player_coins -= 5
	if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)
	GameManager.save_game()

func _on_shuffle_pressed():
	setup_scrambled_letters(current_word)
# --------------------

func play_audio(audio_filename: String):
	if Global.has_method("play_word_audio_with_volume"):
		Global.play_word_audio_with_volume(audio_filename, 1000.0)
	else:
		Global.play_word_audio(audio_filename)

func _on_speaker_button_pressed():
	var lvl_key = int(current_level)
	if LevelData.levels.has(lvl_key):
		var level_info = LevelData.levels[lvl_key]
		if level_info.has("audio"):
			play_audio(level_info["audio"])

func _on_settings_button_pressed():
	if has_node("%SettingsMenu"):
		%SettingsMenu.show()
		%SettingsMenu.move_to_front()

func _on_back_button_pressed():
	if has_node("%ExitConfirmationPopup") and %ExitConfirmationPopup.has_method("open_popup"):
		%ExitConfirmationPopup.open_popup()

func _on_next_level_button_pressed():
	current_level += 1
	if current_level == 17:
		# level_16_20.gd only adopts this as its starting level if it's set
		# here first - without it, that scene's own hardcoded default
		# (current_level = 16) wins instead, silently replaying Level 16
		# rather than advancing to 17.
		Global.requested_level = current_level
		get_tree().change_scene_to_file("res://level_16_20.tscn")
		return

	if current_level <= LevelData.levels.size():
		load_current_level()
		if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)

func _get_answer_slot_container() -> Node:
	if has_node("%AnswerSlotsContainer"): return %AnswerSlotsContainer
	return null

func _get_scrambled_grid() -> Node:
	if has_node("%ScrambledLettersGrid"): return %ScrambledLettersGrid
	return null

func get_hint_count_for_level(lvl: int) -> int:
	if lvl >= 1 and lvl <= 2: return 1
	elif lvl >= 3 and lvl <= 5: return 1
	elif lvl >= 6 and lvl <= 9: return 2
	elif lvl == 10: return 2
	elif lvl >= 11 and lvl <= 15: return 2
	elif lvl == 16: return 3
	elif lvl == 17: return 3
	elif lvl >= 18 and lvl <= 19: return 4
	elif lvl >= 20: return 5
	return 1

func _clear_tile_text(tile_node: Node): _set_tile_text(tile_node, "")

func _set_tile_text(tile_node: Node, val: String):
	if tile_node.has_method("set_letter"):
		tile_node.set_letter(val)
	elif "text" in tile_node: 
		tile_node.text = val
	elif tile_node.has_node("Label"): 
		tile_node.get_node("Label").text = val

func _on_next_level_pressed() -> void: 
	_on_next_level_button_pressed()

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
