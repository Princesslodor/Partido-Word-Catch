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
		
	var lvl_key = int(current_level)
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
		
	if has_node("%LevelLabel"):
		%LevelLabel.text = "LEVEL " + str(current_level)
		
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	
	update_level_image(current_level)
	setup_answer_slots(current_word)
	setup_scrambled_letters(current_word)

func update_level_image(lvl: int):
	var folder_path = "res://Picture_HintLevel/"
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var found_file = ""
		
		while file_name != "":
			if not dir.current_is_dir():
				var target_str = "level_" + str(lvl)
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
					print("DIREKTANG NAKUHA SA FOLDER: ", full_path)
				elif has_node("HintPicture"):
					$HintPicture.texture = tex
					$HintPicture.visible = true
					$HintPicture.show()
					print("DIREKTANG NAKUHA SA FOLDER: ", full_path)
		else:
			print("BABALA: Walang nakitang larawan sa loob ng folder para sa level: ", lvl)
	else:
		print("ERROR: Hindi mabuksan ang folder na: ", folder_path)

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
		else:
			if slot.has_method("set_as_space"):
				slot.set_as_space(false)
				
			if char_idx in hint_indices:
				current_placed_letters[char_idx] = char
				_set_tile_text(slot, char)
				if "is_locked" in slot:
					slot.is_locked = true

func setup_scrambled_letters(word: String):
	var grid = _get_scrambled_grid()
	if grid == null:
		return
		
	var tiles = grid.get_children()
	
	for tile in tiles:
		tile.visible = false
		_clear_tile_text(tile)

	var letters: Array = []
	for c in word:
		if c != " ":
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
			
			if tile.has_method("setup_tile"):
				tile.setup_tile(letter_val)

func check_answer():
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
			print("TAMA ANG SAGOT!")
			show_victory_popup()
		else:
			print("MALING SAGOT! Subukan ulit.")

func show_victory_popup():
	var lvl_key = int(current_level)
	var level_info = LevelData.levels[lvl_key]
	
	player_coins += 10
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
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
	if ResourceLoader.exists(audio_path):
		var player = null
		if has_node("%AudioPlayer"):
			player = %AudioPlayer
		elif has_node("%AudioStreamPlay"):
			player = %AudioStreamPlay
		elif has_node("SpeakerButton/AudioStreamPlay"):
			player = $SpeakerButton/AudioStreamPlay
		elif has_node("SpeakerButton/AudioStreamPlayer2D"):
			player = $SpeakerButton/AudioStreamPlayer2D
			
		if player:
			player.stream = load(audio_path)
			player.play()

func _on_speaker_button_pressed():
	var lvl_key = int(current_level)
	var level_info = LevelData.levels[lvl_key]
	if level_info.has("audio"):
		play_audio(level_info["audio"])

func _on_next_level_button_pressed():
	current_level += 1
	if current_level <= LevelData.levels.size():
		load_current_level()
		if has_node("%CoinsLabel"):
			%CoinsLabel.text = "🪙 " + str(player_coins)
	else:
		print("Natapos na ang lahat ng levels!")

# --- HELPER FUNCTIONS ---
func _get_answer_slot_container() -> Node:
	if has_node("%AnswerSlotsContainer"):
		return %AnswerSlotsContainer
	elif has_node("VBoxContainer/AnswerSlotsContainer"):
		return $VBoxContainer/AnswerSlotsContainer
	elif has_node("VBoxContainer/AnswerSlot"):
		return $VBoxContainer/AnswerSlot
	elif has_node("AnswerSlotsContainer"):
		return $AnswerSlotsContainer
	return null

func _get_scrambled_grid() -> Node:
	if has_node("%ScrambledLettersGrid"):
		return %ScrambledLettersGrid
	elif has_node("VBoxContainer/ScrambledLettersGrid"):
		return $VBoxContainer/ScrambledLettersGrid
	elif has_node("ScrambledLettersGrid"):
		return $ScrambledLettersGrid
	return null

func get_hint_count_for_level(lvl: int) -> int:
	if lvl >= 1 and lvl <= 2:
		return 1
	elif lvl >= 3 and lvl <= 5:
		return 1
	elif lvl >= 6 and lvl <= 9:
		return 2
	elif lvl == 10:
		return 2
	elif lvl >= 11 and lvl <= 15:
		return 2
	elif lvl == 16:
		return 3
	elif lvl == 17:
		return 3
	elif lvl >= 18 and lvl <= 19:
		return 4
	elif lvl >= 20:
		return 5
	return 1

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

func _on_next_level_pressed() -> void:
	_on_next_level_button_pressed()
