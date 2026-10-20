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
	if has_node("CanvasLayer/VictoryPopup/ColorRect/CloseVictoryButton"):
		var close_btn = $CanvasLayer/VictoryPopup/ColorRect/CloseVictoryButton
		if not close_btn.is_connected("pressed", Callable(self, "_on_close_victory_pressed")):
			close_btn.pressed.connect(_on_close_victory_pressed)

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

	if not LevelData.sentence_pools.has(lvl_key):
		return

	current_sentence_words = LevelData.sentence_pools[lvl_key]["words"]
		
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
		%CoinsLabel.text = str(player_coins)
	
	# The hint image files are named after whichever level number a word was
	# ORIGINALLY authored under, not its current (possibly shuffled) level
	# number - image_level tracks that so the right picture keeps showing.
	var image_lvl: int = lvl_key
	if LevelData.levels.has(lvl_key):
		image_lvl = LevelData.levels[lvl_key].get("image_level", lvl_key)
	update_level_image(image_lvl)
	setup_answer_slots()
	setup_scrambled_word_blocks()

func update_level_image(lvl: int):
	# lvl here must be the ORIGINAL (pre-shuffle) level number - see
	# LevelData.get_hint_image_path()'s comment for why this can't scan the folder.
	var image_path: String = LevelData.get_hint_image_path(lvl)
	if image_path == "":
		return
	var tex = load(image_path)
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
					if "is_locked" in subchild: subchild.is_locked = false
			else:
				child.visible = false
				_set_block_text(child, "")
				if "is_locked" in child: child.is_locked = false

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
	if LevelData.sentence_pools.has(current_level):
		level_distractors = LevelData.sentence_pools[current_level]["distractors"].duplicate()
		
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
		var slots = _get_all_answer_slots()
		if slot_index < slots.size() and "is_locked" in slots[slot_index] and slots[slot_index].is_locked:
			return
		var word_in_slot = selected_word_blocks[slot_index]
		if word_in_slot != "":
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
			Global.play_correct_sound()
			show_victory_popup()
		elif not from_hint:
			# Skip the penalty when this check was triggered by Reveal Hint
			# fixing one wrong word - other still-wrong slots would
			# otherwise make an already-paid-for hint also cost a star.
			Global.play_wrong_sound()
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
	out_of_hearts_restore_button.text = "Restore 1 Heart (%d Coins)" % RESTORE_HEART_COST
	out_of_hearts_restore_button.disabled = player_coins < RESTORE_HEART_COST
	out_of_hearts_restore_button.modulate = Color(1, 1, 1, 1) if player_coins >= RESTORE_HEART_COST else Color(1, 1, 1, 0.5)

func _on_restore_heart_pressed() -> void:
	if player_coins < RESTORE_HEART_COST or player_hearts > 0:
		return
	player_coins -= RESTORE_HEART_COST
	Global.play_coin_spend_sound()
	player_hearts = min(player_hearts + 1, 4)
	update_hearts_display()
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
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

func _on_close_victory_pressed() -> void:
	get_tree().change_scene_to_file("res://campaign_map_screen.tscn")

func show_victory_popup():
	var lvl_key = int(current_level)
	GameManager.add_coins(10)
	GameManager.in_progress_stars.erase(str(lvl_key))
	GameManager.complete_level(lvl_key, player_stars)
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
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

	# Level 30 is the last level in the whole game - the regular "next
	# level" flow has nowhere to go from here, so show a distinct
	# completion message/sound and send the player back to the map instead.
	var title_label = get_node_or_null("CanvasLayer/VictoryPopup/MAHUSAY!")
	var next_level_label = get_node_or_null("CanvasLayer/VictoryPopup/NextLevel/Label")
	if lvl_key >= 30:
		if title_label: title_label.text = "TAPOS MO NA!"
		if next_level_label: next_level_label.text = "Bumalik sa Mapa"
		Global.play_game_complete_sound()
	else:
		if title_label: title_label.text = "MAHUSAY!"
		if next_level_label: next_level_label.text = "Sunod na Level  >>"
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
				var target_word = current_sentence_words[i].to_upper()
				player_coins -= 10
				Global.play_coin_spend_sound()
				if has_node("%CoinsLabel"):
					%CoinsLabel.text = str(player_coins)
				GameManager.save_game()
				_set_block_text(slot, target_word)
				selected_word_blocks[i] = target_word
				if "is_locked" in slot: slot.is_locked = true
				_disable_tray_tile_for_word(target_word)
				check_answer(true)
				break

func _disable_tray_tile_for_word(word: String):
	var grid = _get_scrambled_grid()
	if not grid: return
	for tile in grid.get_children():
		if tile.visible and _get_block_text(tile) == word:
			tile.visible = false
			if tile is BaseButton: tile.disabled = true
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
	if current_level >= 30:
		# No level 31 to load - the button reads "Bumalik sa Mapa" at this
		# point (see show_victory_popup()), so send the player back to the
		# Campaign Map instead of silently doing nothing.
		get_tree().change_scene_to_file("res://campaign_map_screen.tscn")
		return
	current_level += 1
	if current_level <= 30:
		load_current_level()
		if has_node("%CoinsLabel"):
			%CoinsLabel.text = str(player_coins)

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

func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()
