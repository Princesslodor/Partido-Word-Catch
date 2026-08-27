extends Node2D

var current_level: int = 17


var player_coins: int:
	get: return Global.player_coins
	set(val): Global.player_coins = val

var current_word: String = ""
var current_placed_letters: Array = []

var extra_alphabet: Array = ["A", "B", "K", "D", "E", "G", "H", "I", "L", "M", "N", "O", "P", "R", "S", "T", "U", "W", "Y"]

func _ready():
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = false
	elif has_node("VictoryPopup"):
		$VictoryPopup.visible = false
		
	_connect_button("%SpeakerButton", "SpeakerButton", "_on_speaker_button_pressed")
	_connect_button("%NextLevelButton", "NextLevelButton", "_on_next_level_button_pressed")
	_connect_button("%RevealHintButton", "RevealHintB", "_on_reveal_hint_pressed")
	_connect_button("%RemoveLetterButton", "RemoveLette", "_on_remove_letter_pressed")
	_connect_button("%ShuffleButton", "ShuffleButto", "_on_shuffle_pressed")
			
	load_current_level()
	
	
	_connect_sound_to_all_buttons(self)

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
			show_victory_popup()

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
			_set_tile_text(slot, target_char)
			current_placed_letters[i] = target_char
			if "is_locked" in slot:
				slot.is_locked = true
			check_answer()
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

func _on_next_level_button_pressed():
	current_level += 1
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
