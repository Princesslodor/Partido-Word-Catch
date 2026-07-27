extends Node2D

var current_level: int = 1
var player_coins: int = 20

var current_word: String = ""
var current_placed_letters: Array = []

var extra_alphabet: Array = ["A", "B", "K", "D", "E", "G", "H", "I", "L", "M", "N", "O", "P", "R", "S", "T", "U", "W", "Y"]

func _ready():
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = false
		
	if has_node("%SpeakerButton"):
		if not %SpeakerButton.is_connected("pressed", Callable(self, "_on_speaker_button_pressed")):
			%SpeakerButton.pressed.connect(_on_speaker_button_pressed)
			
	if has_node("%NextLevelButton"):
		if not %NextLevelButton.is_connected("pressed", Callable(self, "_on_next_level_button_pressed")):
			%NextLevelButton.pressed.connect(_on_next_level_button_pressed)
			
	load_current_level()

func load_current_level():
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = false
		
	var level_info = LevelData.levels[current_level]
	current_word = level_info["word"].to_upper() # e.g., "IDO"
	
	current_placed_letters.clear()
	for i in range(current_word.length()):
		current_placed_letters.append("")
	
	if has_node("%TagalogHintText"):
		%TagalogHintText.text = '"' + level_info["clue"] + '"'
		
	if has_node("%LevelLabel"):
		%LevelLabel.text = "LEVEL " + str(current_level)
		
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
	
	update_level_image(current_word.to_lower())
	setup_answer_slots(current_word)
	setup_scrambled_letters(current_word)

func update_level_image(word_lower: String):
	var image_path = "res://images/" + word_lower + ".png"
	if ResourceLoader.exists(image_path) and has_node("%BackgroundPic"):
		%BackgroundPic.texture = load(image_path)

func setup_answer_slots(word: String):
	var word_length = word.length()
	var slot_container = _get_answer_slot_container()
		
	if slot_container:
		var slots = slot_container.get_children()
		var hint_index = word_length - 1  # Pre-filled hint (e.g. 'O')
		
		for i in range(slots.size()):
			if i < word_length:
				slots[i].visible = true
				slots[i].stored_origin_button = null
				
				if i == hint_index:
					var hint_char = String(word[i])
					current_placed_letters[i] = hint_char
					_set_tile_text(slots[i], hint_char)
					if "is_locked" in slots[i]:
						slots[i].is_locked = true
				else:
					_clear_tile_text(slots[i])
					if "is_locked" in slots[i]:
						slots[i].is_locked = false
			else:
				slots[i].visible = false

func setup_scrambled_letters(word: String):
	var grid = _get_scrambled_grid()
	if grid == null:
		return
		
	var tiles = grid.get_children()
	var letters: Array = []
	
	for c in word:
		letters.append(c)
		
	var needed_extras = tiles.size() - letters.size()
	for i in range(needed_extras):
		var random_letter = extra_alphabet[randi() % extra_alphabet.size()]
		letters.append(random_letter)
		
	letters.shuffle()
	
	for i in range(tiles.size()):
		if i < letters.size():
			tiles[i].visible = true
			_set_tile_text(tiles[i], letters[i])
			
			var tile = tiles[i]
			var letter_val = letters[i]
			
			if tile is Button or tile is TextureButton:
				if tile.is_connected("pressed", Callable(self, "_on_letter_tile_pressed")):
					tile.disconnect("pressed", Callable(self, "_on_letter_tile_pressed"))
				
				tile.pressed.connect(func(): _on_letter_tile_pressed(tile, letter_val))

# --- 🎯 CLICKING & DRAGGING CHECKING LOGIC ---

func _on_letter_tile_pressed(tile_button: Node, letter: String):
	var empty_index = -1
	for i in range(current_word.length()):
		if current_placed_letters[i] == "":
			empty_index = i
			break
			
	if empty_index != -1:
		current_placed_letters[empty_index] = letter
		
		var slot_container = _get_answer_slot_container()
		if slot_container:
			var slots = slot_container.get_children()
			_set_tile_text(slots[empty_index], letter)
			if "stored_origin_button" in slots[empty_index]:
				slots[empty_index].stored_origin_button = tile_button
			
		tile_button.visible = false
		
		check_answer()

# TINAWAG NITO AT NG ANSWERSLOT.GD (Pang-Drag & Drop at Click)
func check_answer():
	var slot_container = _get_answer_slot_container()
	if slot_container == null:
		return

	var slots = slot_container.get_children()
	var constructed_word = ""
	var is_full = true

	# Basahin ang aktwal na nakasulat sa Answer Slots
	for i in range(current_word.length()):
		var slot_text = ""
		if "text" in slots[i]:
			slot_text = slots[i].text.strip_edges().to_upper()
		elif slots[i].has_node("Label"):
			slot_text = slots[i].get_node("Label").text.strip_edges().to_upper()

		if slot_text == "":
			is_full = false
			break
		constructed_word += slot_text

	# I-update din ang tracking array
	for i in range(current_word.length()):
		if i < constructed_word.length():
			current_placed_letters[i] = constructed_word[i]

	if is_full:
		if constructed_word == current_word:
			print("TAMA ANG SAGOT!")
			show_victory_popup()
		else:
			print("MALING SAGOT! Subukan ulit.")

# --- 🏆 VICTORY POPUP LOGIC ---
func show_victory_popup():
	var level_info = LevelData.levels[current_level]
	
	player_coins += 10
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
	if has_node("%RewardCoinsLabel"):
		%RewardCoinsLabel.text = "+10 COINS"
	
	if has_node("%WordLabel"):
		%WordLabel.text = level_info.get("word", "")
		
	if has_node("%MeaningLabel"):
		%MeaningLabel.text = level_info.get("meaning", "")
		
	if has_node("%CulturalNoteLabel"):
		%CulturalNoteLabel.text = level_info.get("cultural_note", "")
		
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = true
		
	if level_info.has("audio"):
		play_audio(level_info["audio"])

func play_audio(audio_filename: String):
	var audio_path = "res://audio/" + audio_filename
	if ResourceLoader.exists(audio_path) and has_node("%AudioPlayer"):
		%AudioPlayer.stream = load(audio_path)
		%AudioPlayer.play()

func _on_speaker_button_pressed():
	var level_info = LevelData.levels[current_level]
	if level_info.has("audio"):
		play_audio(level_info["audio"])

func _on_next_level_button_pressed():
	current_level += 1
	if current_level <= LevelData.levels.size():
		load_current_level()

# --- HELPER FUNCTIONS ---
func _get_answer_slot_container() -> Node:
	if has_node("%AnswerSlotsContainer"):
		return %AnswerSlotsContainer
	elif has_node("VBoxContainer/AnswerSlotsContainer"):
		return $VBoxContainer/AnswerSlotsContainer
	elif has_node("VBoxContainer/AnswerSlot"):
		return $VBoxContainer/AnswerSlot
	return null

func _get_scrambled_grid() -> Node:
	if has_node("%ScrambledLettersGrid"):
		return %ScrambledLettersGrid
	elif has_node("VBoxContainer/ScrambledLettersGrid"):
		return $VBoxContainer/ScrambledLettersGrid
	return null

func _clear_tile_text(tile_node: Node):
	_set_tile_text(tile_node, "")

func _set_tile_text(tile_node: Node, val: String):
	if tile_node.has_method("set_letter"):
		tile_node.set_letter(val)
	elif "text" in tile_node:
		tile_node.text = val
	elif tile_node.has_node("Label"):
		tile_node.get_node("Label").text = val
	
	for child in tile_node.get_children():
		if child is Label:
			child.text = val
