extends Node2D

var current_level: int = 21

var player_coins: int:
	get: return Global.player_coins
	set(val): Global.player_coins = val

var current_sentence_words: Array = [] 
var selected_word_blocks: Array = []  
var active_tile_mapping = {}

var level_custom_pools = {
	21: {
		"words": ["MAGANA", "NGUNYAN", "MAGKAKAN", "SI", "PAULO"],
		"distractors": ["MAY", "SA", "DUMAN", "ANNA", "LANGOY", "ARIN", "HILING", "INI", "RAYO", "BAHAY"]
	},
	22: {
		"words": ["DAKUL", "AN", "DAKOP", "NI", "TIYO", "SAMMY"],
		"distractors": ["NAGDALAN", "URO-UTRO", "MAGANA", "IGWA", "MAHAMIS", "BANWAAN", "KAN", "SIYA", "ARIN"]
	},
	23: {
		"words": ["BUROBANGGI", "SIYANG", "NAGSUSULO", "NIN", "KIRAY"],
		"distractors": ["KADAKUL", "DAKUL", "URO-ATYAN", "IGWA", "KAMI", "KAYA", "TAWO", "NAGDALAN", "MAGANA", "SA", "MAY"]
	},
	24: {
		"words": ["KADAKUL", "AN", "NAGDADALAN", "SA", "PALABAS", "NA", "INI"],
		"distractors": ["MAGANA", "NGUNYAN", "SI", "PAULO", "MAY", "DUMAN", "ASIN", "ARIN"]
	},
	25: {
		"words": ["IGWA", "SA", "LUGAR", "NINDANG", "MAY", "HALABANG", "KAMOT"],
		"distractors": ["DAKOL", "DAKOP", "NI", "TIYO", "IGWA", "MAHAMIS", "LANGOY"]
	},
	26: {
		"words": ["URO-ATYAN", "MADUMAN", "KAMI", "SA", "MUNISIPYO"],
		"distractors": ["NAGBIBISITA", "MARIA", "HARONG", "KADAKUL", "TAWO", "FIESTA", "ASIN", "RAYO", "INI", "ANNA"]
	},
	27: {
		"words": ["NAGDADALAN", "SI", "MARCO", "NIN", "TELENOVELA", "SA", "TELEBISYON"],
		"distractors": ["MAGAYON", "KAPALIGIRAN", "BANWAAN", "TIYO", "IGWA", "KAMI", "HILING"]
	},
	28: {
		"words": ["URO-UTRO", "NIYANG", "TIGSABI", "AN", "SAKUYANG", "PANGARAN"],
		"distractors": ["NAGLALAKAD", "DALAN", "MAHAMIS", "TINAPAY", "ANNA", "ASIN", "ARIN", "INI", "SA"]
	},
	29: {
		"words": ["MAHAMIS", "AN", "DILA", "NI", "LITA", "KAYA", "DAKUL", "AN", "NAIPABAKAL", "NIYA"],
		"distractors": ["PANINDOG", "LOLA", "SILONG", "KADAKUL", "TAWO", "KAMI", "LANGOY", "SA", "MAY"]
	},
	30: {
		"words": ["NAGBIBISITA", "AN", "SAMUYANG", "PAMILYA", "SA", "BANWAAN", "KAN", "PILI", "KADA", "TAON"],
		"distractors": ["MGA", "KABATAAN", "PARK", "MAHAMIS", "TINAPAY", "ASIN", "ARIN", "INI", "SI", "MAY"]
	}
}

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
	if not level_custom_pools.has(lvl_key):
		return
		
	current_sentence_words = level_custom_pools[lvl_key]["words"]
		
	selected_word_blocks.clear()
	active_tile_mapping.clear()
	for i in range(current_sentence_words.size()):
		selected_word_blocks.append("")
	
	if LevelData.levels.has(lvl_key):
		var level_info = LevelData.levels[lvl_key]
		if has_node("%TagalogHintText"):
			%TagalogHintText.text = '"' + level_info.get("clue", "") + '"'
		elif has_node("Tagalog"):
			$Tagalog.text = '"' + level_info.get("clue", "") + '"'
		
	if has_node("%LevelLabel"):
		%LevelLabel.text = "LEVEL " + str(current_level)
		
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	
	update_level_image(current_level)
	setup_answer_slots()
	setup_scrambled_word_blocks()

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

func _get_all_answer_slots() -> Array:
	var container = _get_answer_slot_container()
	if not container:
		return []
	var all_slots = []
	
	for child in container.get_children():
		if child is Container:
			for subchild in child.get_children():
				if subchild is BaseButton or subchild.has_method("set_letter") or "text" in subchild:
					if not subchild in all_slots:
						all_slots.append(subchild)
		elif child is BaseButton or child.has_method("set_letter") or "text" in child:
			if not child in all_slots:
				all_slots.append(child)
				
	var required_count = current_sentence_words.size()
	if all_slots.size() > required_count:
		return all_slots.slice(0, required_count)
		
	return all_slots

func setup_answer_slots():
	var container = _get_answer_slot_container()
	if container:
		for child in container.get_children():
			if child is Container:
				for subchild in child.get_children():
					subchild.visible = false
					_set_block_text(subchild, "")
			else:
				child.visible = false
				_set_block_text(child, "")

	var slots = _get_all_answer_slots()
	var total_words = current_sentence_words.size()
	
	for i in range(slots.size()):
		var slot = slots[i]
		if i < total_words:
			slot.visible = true
			_set_block_text(slot, "")
			if slot is BaseButton:
				if slot.is_connected("pressed", Callable(self, "_on_answer_slot_pressed")):
					slot.pressed.disconnect(Callable(self, "_on_answer_slot_pressed"))
				slot.pressed.connect(Callable(self, "_on_answer_slot_pressed").bind(i))
		else:
			slot.visible = false

func setup_scrambled_word_blocks():
	var grid = _get_scrambled_grid()
	if grid == null:
		return
		
	var tiles = grid.get_children()
	var words_pool: Array = []
	
	for w in current_sentence_words:
		words_pool.append(w.to_upper())
		
	var level_distractors = []
	if level_custom_pools.has(current_level):
		level_distractors = level_custom_pools[current_level]["distractors"].duplicate()
		
	level_distractors.shuffle()
	
	var max_tiles = min(tiles.size(), current_sentence_words.size() + level_distractors.size())
	
	for d in level_distractors:
		if words_pool.size() < max_tiles and not (d.to_upper() in words_pool):
			words_pool.append(d.to_upper())
			
	words_pool.shuffle()
	
	for i in range(tiles.size()):
		var tile = tiles[i]
		if i < words_pool.size():
			tile.visible = true
			if tile is BaseButton:
				tile.disabled = false
			var w_val = words_pool[i]
			_set_block_text(tile, w_val)
			
			# Tanda: Inalis natin dito ang pag-connect ng tile sa _on_word_block_pressed
			# para hindi ito gumalaw o mawala kapag pinindot (dahil drag-and-drop ang laro).
		else:
			tile.visible = false

func _on_answer_slot_pressed(slot_index: int):
	# Dito na lang nakakonekta kapag gusto nilang i-clear o tanggalin ang laman ng slot kung kinakailangan
	if slot_index < selected_word_blocks.size():
		var word_in_slot = selected_word_blocks[slot_index]
		if word_in_slot != "":
			var slots = _get_all_answer_slots()
			if slot_index < slots.size():
				_set_block_text(slots[slot_index], "")
			selected_word_blocks[slot_index] = ""

func check_answer():
	var slots = _get_all_answer_slots()
	var is_full = true
	
	selected_word_blocks.clear()
	for i in range(slots.size()):
		var val = _get_block_text(slots[i])
		selected_word_blocks.append(val)
		if val == "":
			is_full = false
			
	if is_full and slots.size() == current_sentence_words.size():
		var constructed = " ".join(selected_word_blocks).strip_edges().to_upper()
		var target = " ".join(current_sentence_words).strip_edges().to_upper()
		
		if constructed == target:
			show_victory_popup()

func show_victory_popup():
	var lvl_key = int(current_level)
	player_coins += 10
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	if has_node("%RewardCoinsLabel"):
		%RewardCoinsLabel.text = "+10 COINS"
	
	if LevelData.levels.has(lvl_key):
		var level_info = LevelData.levels[lvl_key]
		if has_node("%WordLabel"):
			%WordLabel.text = level_info.get("word", "")
		if has_node("%MeaningLabel"):
			%MeaningLabel.text = level_info.get("meaning", "")
		if has_node("%CulturalNoteLabel"):
			%CulturalNoteLabel.text = level_info.get("cultural_note", "")
		if level_info.has("audio"):
			play_audio(level_info["audio"])
			
	var particles = get_node_or_null("%CPUParticles2D")
	if particles and particles is CPUParticles2D:
		particles.emitting = false
		particles.restart()
		particles.emitting = true
	
	Global.play_horray()
			
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = true

func _on_reveal_hint_pressed():
	if player_coins < 10:
		return
	var slots = _get_all_answer_slots()
	for i in range(current_sentence_words.size()):
		if i < slots.size():
			var slot = slots[i]
			if _get_block_text(slot) != current_sentence_words[i].to_upper():
				player_coins -= 10
				if has_node("%CoinsLabel"):
					%CoinsLabel.text = "🪙 " + str(player_coins)
				_set_block_text(slot, current_sentence_words[i].to_upper())
				selected_word_blocks[i] = current_sentence_words[i].to_upper()
				check_answer()
				break

func _on_remove_letter_pressed():
	pass

func _on_shuffle_pressed():
	load_current_level()

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
	if LevelData.levels.has(lvl_key):
		var level_info = LevelData.levels[lvl_key]
		if level_info.has("audio"):
			play_audio(level_info["audio"])

func _on_next_level_button_pressed():
	current_level += 1
	if current_level <= 30:
		load_current_level()
		if has_node("%CoinsLabel"):
			%CoinsLabel.text = "🪙 " + str(player_coins)
	else:
		print("Natapos na ang lahat ng levels mula 21 hanggang 30!")

func _get_answer_slot_container() -> Node:
	if has_node("%AnswerSlotsContainer"):
		return %AnswerSlotsContainer
	return null

func _get_scrambled_grid() -> Node:
	if has_node("%ScrambledLettersGrid"):
		return %ScrambledLettersGrid
	return null

func _get_block_text(node: Node) -> String:
	if "text" in node:
		return node.text.strip_edges()
	elif node.has_node("Label"):
		return node.get_node("Label").text.strip_edges()
	return ""

func _set_block_text(node: Node, val: String):
	if node.has_method("set_letter"):
		node.set_letter(val)
	elif "text" in node:
		node.text = val
	elif node.has_node("Label"):
		node.get_node("Label").text = val

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
