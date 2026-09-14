extends Node2D

var current_level: int = 16

var player_coins: int:
	get: return GameManager.player_coins
	set(val): GameManager.player_coins = val

var player_stars: int = 3
var player_hearts: int:
	get: return GameManager.player_hearts
	set(val): GameManager.player_hearts = val

var heart_regen_timer: Timer
const REGEN_TIME: float = 600.0
const RESTORE_HEART_COST: int = 20

var out_of_hearts_modal: Control = null
var out_of_hearts_countdown_label: Label = null
var out_of_hearts_restore_button: Button = null

var current_word: String = ""
var current_placed_letters: Array = []

var extra_alphabet: Array = ["A", "B", "K", "D", "E", "G", "H", "I", "L", "M", "N", "O", "P", "R", "S", "T", "U", "W", "Y"]

func _ready():
	if Global.requested_level >= 16 and Global.requested_level <= 20:
		current_level = Global.requested_level
		Global.requested_level = 0

	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = false
	elif has_node("VictoryPopup"):
		$VictoryPopup.visible = false
		
	_connect_button("%SpeakerButton", "SpeakerButton", "_on_speaker_button_pressed")
	_connect_button("%NextLevel", "NextLevel", "_on_next_level_button_pressed")
	_connect_button("%RevealHintButton", "RevealHintB", "_on_reveal_hint_pressed")
	_connect_button("%RemoveLetterButton", "RemoveLette", "_on_remove_letter_pressed")
	_connect_button("%ShuffleButton", "ShuffleButto", "_on_shuffle_pressed")
	_connect_button("%SettingsButton2", "SettingsButton2", "_on_settings_button_pressed")
	_connect_button("%BackButton", "BackButton", "_on_back_button_pressed")

	setup_heart_timer()
	load_current_level()
	_connect_sound_to_all_buttons(self)

func _process(_delta):
	update_timer_display()

func setup_heart_timer():
	heart_regen_timer = Timer.new()
	heart_regen_timer.wait_time = REGEN_TIME
	heart_regen_timer.one_shot = false
	heart_regen_timer.timeout.connect(_on_heart_regen_timeout)
	add_child(heart_regen_timer)

	if player_hearts < 4:
		heart_regen_timer.start()

func _connect_button(unique_path: String, node_name: String, method_name: String):
	var btn = null
	if has_node(unique_path):
		btn = get_node(unique_path)
	elif has_node("%" + node_name):
		btn = get_node("%" + node_name)
	elif has_node(node_name):
		btn = get_node(node_name)
		
	if btn and btn is BaseButton:
		if not btn.is_connected("pressed", Callable(self, method_name)):
			btn.pressed.connect(Callable(self, method_name))

func load_current_level():
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = false
		
	var lvl_key = int(current_level)

	# Resume with whatever stars were left the last time this level was
	# left mid-attempt, matching node_2d.gd's behavior for levels 1-15.
	player_stars = GameManager.in_progress_stars.get(str(lvl_key), 3)
	update_stars_display()
	update_hearts_display()
	_check_out_of_hearts()

	if not LevelData.levels.has(lvl_key):
		print("Tapos na ang lahat ng levels!")
		return

	var level_info = LevelData.levels[lvl_key]
	current_word = level_info["word"].to_upper()
	
	current_placed_letters.clear()
	for i in range(current_word.length()):
		current_placed_letters.append("")
	
	if has_node("%TagalogHintText"):
		%TagalogHintText.text = '"' + level_info["clue"] + '"'
	elif has_node("Tagalog"):
		$Tagalog.text = '"' + level_info["clue"] + '"'
		
	if has_node("%LevelLabel"):
		%LevelLabel.text = "LEVEL " + str(current_level)
		
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	
	var slot_container = _get_answer_slot_container()
	if slot_container and slot_container is GridContainer: slot_container.columns = 7
	var grid = _get_scrambled_grid()
	if grid and grid is GridContainer: grid.columns = 7

	# The hint image files are named after whichever level number a word was
	# ORIGINALLY authored under, not its current (possibly shuffled) level
	# number - image_level tracks that so the right picture keeps showing.
	update_level_image(level_info.get("image_level", current_level))
	update_background(current_level)
	setup_answer_slots(current_word)
	setup_scrambled_letters(current_word)

func update_background(lvl: int):
	if has_node("CanvasLayer/LagonoyValleyBg"): $CanvasLayer/LagonoyValleyBg.visible = false
	if has_node("CanvasLayer/CoastalShore"): $CanvasLayer/CoastalShore.visible = false
	if has_node("CanvasLayer/GreenWood"): $CanvasLayer/GreenWood.visible = false
	if has_node("CanvasLayer/BlueWood"): $CanvasLayer/BlueWood.visible = false
	if has_node("CanvasLayer/VioletWood"): $CanvasLayer/VioletWood.visible = false
		
	if lvl >= 16 and lvl <= 20:
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
			if not dir.current_is_dir():
				var target_str = "level_" + str(lvl) + "."
				if target_str in file_name.to_lower():
					found_file = file_name
					break
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		if found_file != "":
			var full_path = folder_path + found_file
			var tex = load(full_path)
			if tex:
				if has_node("%HintPicture"):
					%HintPicture.texture = tex
					%HintPicture.visible = true
					%HintPicture.show()
				elif has_node("HintPicture"):
					$HintPicture.texture = tex
					$HintPicture.visible = true
					$HintPicture.show()

func setup_answer_slots(word: String):
	var slot_container = _get_answer_slot_container()
	if not slot_container:
		return
		
	var slots = slot_container.get_children()
	
	for slot in slots:
		slot.visible = false
		_clear_tile_text(slot)
		if "is_locked" in slot:
			slot.is_locked = false
		if slot.has_method("set_as_space"):
			slot.set_as_space(false)

	var hint_count = get_hint_count_for_level(current_level)
	
	var valid_indices = []
	for i in range(word.length()):
		if word[i] != " ":
			valid_indices.append(i)
	
	valid_indices.shuffle()
	
	var hint_indices = []
	for i in range(min(hint_count, valid_indices.size())):
		hint_indices.append(valid_indices[i])

	for char_idx in range(word.length()):
		if char_idx >= slots.size():
			break
			
		var slot = slots[char_idx]
		var char = word[char_idx]
		
		slot.visible = true
		_clear_tile_text(slot)
		if "is_locked" in slot:
			slot.is_locked = false
			
		if char == " ":
			if slot.has_method("set_as_space"):
				slot.set_as_space(true)
			slot.visible = false
			current_placed_letters[char_idx] = " "
		else:
			if slot.has_method("set_as_space"):
				slot.set_as_space(false)
				
			if char_idx in hint_indices:
				current_placed_letters[char_idx] = char
				_set_tile_text(slot, char)
				if "is_locked" in slot:
					slot.is_locked = true

	for i in range(word.length(), slots.size()):
		slots[i].visible = false

func setup_scrambled_letters(word: String):
	var grid = _get_scrambled_grid()
	if grid == null:
		return
		
	var tiles = grid.get_children()
	
	for tile in tiles:
		tile.visible = false
		_clear_tile_text(tile)
		if tile.has_method("reset_tile"):
			tile.reset_tile()

	var letters: Array = []
	for c in word:
		if c != " ":
			letters.append(c)
		
	var total_tiles = tiles.size()
	var needed_extras = total_tiles - letters.size()
	for i in range(needed_extras):
		var random_letter = extra_alphabet[randi() % extra_alphabet.size()]
		letters.append(random_letter)
		
	letters.shuffle()
	
	for i in range(total_tiles):
		var tile = tiles[i]
		if i < letters.size():
			tile.visible = true
			var letter_val = letters[i]
			_set_tile_text(tile, letter_val)
			
			if tile.has_method("setup_tile"):
				tile.setup_tile(letter_val)
		else:
			tile.visible = false

func check_answer(from_hint: bool = false):
	var slot_container = _get_answer_slot_container()
	if slot_container == null:
		return

	var slots = slot_container.get_children()
	var constructed_word = ""
	var is_full = true

	for char_idx in range(current_word.length()):
		if char_idx >= slots.size():
			is_full = false
			break
			
		var slot = slots[char_idx]
		var target_char = current_word[char_idx]
		
		if target_char == " ":
			constructed_word += " "
		else:
			var slot_text = ""
			if "text" in slot:
				slot_text = slot.text.strip_edges().to_upper()
			elif slot.has_node("Label"):
				slot_text = slot.get_node("Label").text.strip_edges().to_upper()

			if slot_text == "":
				is_full = false
				break
			constructed_word += slot_text

	if is_full and constructed_word.length() == current_word.length():
		if constructed_word == current_word:
			show_victory_popup()
		elif not from_hint:
			# Skip the penalty when this check was triggered by Reveal Hint
			# fixing one wrong letter - other still-wrong slots would
			# otherwise make an already-paid-for hint also cost a star.
			handle_wrong_answer()

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
	if has_node("CanvasLayer/TopBar/LiveLabel"):
		$CanvasLayer/TopBar/LiveLabel.text = "❤️ " + str(player_hearts)

func update_timer_display():
	if heart_regen_timer and not heart_regen_timer.is_stopped():
		var time_left = int(heart_regen_timer.time_left)
		var minutes = time_left / 60
		var seconds = time_left % 60
		var time_string = "%02d:%02d" % [minutes, seconds]
		if out_of_hearts_countdown_label and is_instance_valid(out_of_hearts_countdown_label):
			out_of_hearts_countdown_label.text = time_string

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
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	GameManager.save_game()
	_check_out_of_hearts()

func _ensure_out_of_hearts_modal() -> Control:
	if out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		return out_of_hearts_modal

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
	GameManager.in_progress_stars.erase(str(lvl_key))
	GameManager.complete_level(lvl_key, player_stars)
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	if has_node("%+coin"):
		get_node("%+coin").text = "+10 COINS"
	
	if has_node("%WordLabel"):
		%WordLabel.text = level_info.get("word", "")
		
	if has_node("%MeaningLabel"):
		%MeaningLabel.text = level_info.get("meaning", "")
		
	if has_node("%CulturalNoteLabel"):
		%CulturalNoteLabel.text = level_info.get("cultural_note", "")
		
	var particles = get_node_or_null("%CPUParticles2D")
	if particles and particles is CPUParticles2D:
		particles.emitting = false
		particles.restart()
		particles.emitting = true
	
	Global.play_horray()
		
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = true
		
	if level_info.has("audio"):
		play_audio(level_info["audio"])

func _on_reveal_hint_pressed():
	if player_coins < 10:
		return
	var slot_container = _get_answer_slot_container()
	if not slot_container:
		return
	var slots = slot_container.get_children()
	for i in range(current_word.length()):
		if i >= slots.size():
			break
		var slot = slots[i]
		var target_char = current_word[i]
		if target_char == " ":
			continue
		var slot_text = ""
		if "text" in slot:
			slot_text = slot.text.strip_edges().to_upper()
		elif slot.has_node("Label"):
			slot_text = slot.get_node("Label").text.strip_edges().to_upper()
		if slot_text != target_char:
			player_coins -= 10
			if has_node("%CoinsLabel"):
				%CoinsLabel.text = "🪙 " + str(player_coins)
			GameManager.save_game()
			_set_tile_text(slot, target_char)
			current_placed_letters[i] = target_char
			if "is_locked" in slot:
				slot.is_locked = true
			check_answer(true)
			break

func _on_remove_letter_pressed():
	if player_coins < 5:
		return
		
	var grid = _get_scrambled_grid()
	if not grid:
		return
		
	var tiles = grid.get_children()
	var wrong_indices = []
	
	for i in range(tiles.size()):
		var tile = tiles[i]
		if tile.visible:
			var tile_text = ""
			if "text" in tile:
				tile_text = tile.text.strip_edges().to_upper()
			elif tile.has_node("Label"):
				tile_text = tile.get_node("Label").text.strip_edges().to_upper()
			
			if tile_text != "" and not (tile_text in current_word):
				wrong_indices.append(i)
				
	if wrong_indices.size() == 0:
		return

	wrong_indices.shuffle()
	var selected_index = wrong_indices[0]
	var selected_tile = tiles[selected_index]
	
	_clear_tile_text(selected_tile)
	
	player_coins -= 5
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	GameManager.save_game()

func _on_shuffle_pressed():
	setup_scrambled_letters(current_word)

func play_audio(audio_filename: String):
	var audio_path = "res://audio/" + audio_filename
	if ResourceLoader.exists(audio_path):
		var player = null
		if has_node("%AudioPlayer"):
			player = %AudioPlayer
		elif has_node("%AudioStreamPlay"):
			player = %AudioStreamPlay
		if player:
			player.stream = load(audio_path)
			player.play()

func _on_speaker_button_pressed():
	var lvl_key = int(current_level)
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

	if current_level == 21:
		# Without this, level_21_30.gd falls back to its own hardcoded
		# default starting level instead of actually starting at 21 - it
		# only happens to match today because that default is coincidentally
		# also 21, so this is here to not silently break if that ever changes.
		Global.requested_level = current_level
		get_tree().change_scene_to_file("res://level_21_30.tscn")
		return

	if current_level <= LevelData.levels.size():
		load_current_level()
		if has_node("%CoinsLabel"):
			%CoinsLabel.text = "🪙 " + str(player_coins)
	else:
		print("Natapos na ang lahat ng levels!")

func _get_answer_slot_container() -> Node:
	if has_node("%AnswerSlotsContainer"):
		return %AnswerSlotsContainer
	return null

func _get_scrambled_grid() -> Node:
	if has_node("%ScrambledLettersGrid"):
		return %ScrambledLettersGrid
	return null

func get_hint_count_for_level(lvl: int) -> int:
	return 3

func _clear_tile_text(tile_node: Node):
	_set_tile_text(tile_node, "")

func _set_tile_text(tile_node: Node, val: String):
	if tile_node.has_method("set_letter"):
		tile_node.set_letter(val)
	elif "text" in tile_node:
		tile_node.text = val
	elif tile_node.has_node("Label"):
		tile_node.get_node("Label").text = val

func _on_next_level_pressed() -> void:
	_on_next_level_button_pressed()

func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()
