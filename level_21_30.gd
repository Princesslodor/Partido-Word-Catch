extends Node2D

var current_level: int = 21

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
	if Global.requested_level >= 21 and Global.requested_level <= 30:
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

func check_answer(from_hint: bool = false):
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
		elif not from_hint:
			# Skip the penalty when this check was triggered by Reveal Hint
			# fixing one wrong word - other still-wrong slots would
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
	GameManager.add_coins(10)
	GameManager.in_progress_stars.erase(str(lvl_key))
	GameManager.complete_level(lvl_key, player_stars)
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = "🪙 " + str(player_coins)
	if has_node("%+coin"):
		get_node("%+coin").text = "+10 COINS"
	
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
				GameManager.save_game()
				_set_block_text(slot, current_sentence_words[i].to_upper())
				selected_word_blocks[i] = current_sentence_words[i].to_upper()
				check_answer(true)
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

func _on_settings_button_pressed():
	if has_node("%SettingsMenu"):
		%SettingsMenu.show()
		%SettingsMenu.move_to_front()

func _on_back_button_pressed():
	if has_node("%ExitConfirmationPopup") and %ExitConfirmationPopup.has_method("open_popup"):
		%ExitConfirmationPopup.open_popup()

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
