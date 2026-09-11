extends Node2D

var current_level: int = 1
var player_coins: int:
	get: 
		if Global.player_coins <= 0 and not Global.has_meta("coins_initialized"):
			Global.player_coins = 20
			Global.set_meta("coins_initialized", true)
		return Global.player_coins
	set(val): Global.player_coins = val

var player_stars: int = 3
var player_hearts: int:
	get:
		if not Global.has_meta("hearts_initialized"):
			Global.player_hearts = 4
			Global.set_meta("hearts_initialized", true)
		return Global.player_hearts
	set(val): Global.player_hearts = val

# Timer para sa 15 minuto (15 * 60 = 900 seconds)
var heart_regen_timer: Timer
const REGEN_TIME: float = 900.0 

var current_word: String = ""
var current_placed_letters: Array = []
var last_slots_full_state: bool = false

var extra_alphabet: Array = ["A", "B", "K", "D", "E", "G", "H", "I", "L", "M", "N", "O", "P", "R", "S", "T", "U", "W", "Y"]

func _ready():
	if has_node("%VictoryPopup"): %VictoryPopup.visible = false
	if has_node("%SpeakerButton") and not %SpeakerButton.is_connected("pressed", Callable(self, "_on_speaker_button_pressed")):
		%SpeakerButton.pressed.connect(_on_speaker_button_pressed)
	if has_node("%NextLevelButton") and not %NextLevelButton.is_connected("pressed", Callable(self, "_on_next_level_button_pressed")):
		%NextLevelButton.pressed.connect(_on_next_level_button_pressed)
	if has_node("%RevealHintButton") and not %RevealHintButton.is_connected("pressed", Callable(self, "_on_reveal_hint_pressed")):
		%RevealHintButton.pressed.connect(_on_reveal_hint_pressed)
	if has_node("%RemoveLetterButton") and not %RemoveLetterButton.is_connected("pressed", Callable(self, "_on_remove_letter_pressed")):
		%RemoveLetterButton.pressed.connect(_on_remove_letter_pressed)
	if has_node("%ShuffleButton") and not %ShuffleButton.is_connected("pressed", Callable(self, "_on_shuffle_pressed")):
		%ShuffleButton.pressed.connect(_on_shuffle_pressed)
		
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
		
	player_stars = 3
	update_stars_display()
	update_hearts_display()
	last_slots_full_state = false

	var lvl_key = int(current_level)
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
	
	if player_stars <= 0:
		player_hearts -= 1
		if player_hearts < 0:
			player_hearts = 0
		update_hearts_display()
		
		if heart_regen_timer.is_stopped():
			heart_regen_timer.start()
			
		if player_hearts <= 0:
			print("Naubos na ang lahat ng puso!")

func update_stars_display():
	if has_node("CanvasLayer/LevelDesign/StarWithFill"):
		$CanvasLayer/LevelDesign/StarWithFill.visible = (player_stars >= 1)
	if has_node("CanvasLayer/LevelDesign/StarWithFill2"):
		$CanvasLayer/LevelDesign/StarWithFill2.visible = (player_stars >= 2)
	if has_node("CanvasLayer/LevelDesign/StarWithFill3"):
		$CanvasLayer/LevelDesign/StarWithFill3.visible = (player_stars >= 3)

func update_hearts_display():
	if has_node("TopBar/HeartLabel"):
		$TopBar/HeartLabel.text = str(player_hearts)

func update_timer_display():
	if heart_regen_timer and not heart_regen_timer.is_stopped():
		var time_left = int(heart_regen_timer.time_left)
		var minutes = time_left / 60
		var seconds = time_left % 60
		var time_string = "%02d:%02d" % [minutes, seconds]
		if has_node("%HeartTimerLabel"):
			%HeartTimerLabel.text = time_string
	else:
		if has_node("%HeartTimerLabel"):
			%HeartTimerLabel.text = ""

func _on_heart_regen_timeout():
	if player_hearts < 4:
		player_hearts += 1
		update_hearts_display()
		
	if player_hearts < 4:
		heart_regen_timer.start()
	else:
		heart_regen_timer.stop()

func show_victory_popup():
	var lvl_key = int(current_level)
	var level_info = LevelData.levels[lvl_key]
	player_coins += 10
	if has_node("%CoinsLabel"): %CoinsLabel.text = "🪙 " + str(player_coins)
	if has_node("%RewardCoinsLabel"): %RewardCoinsLabel.text = "+10 COINS"
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

func _on_next_level_button_pressed():
	current_level += 1
	if current_level == 17:
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
