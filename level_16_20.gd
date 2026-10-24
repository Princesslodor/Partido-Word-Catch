extends Node2D

var current_level: int = 16

var player_coins: int:
	get: return GameManager.player_coins
	set(val): GameManager.player_coins = val

var player_stars: int = 3
# Set when the level was failed (all 3 stars lost); the results card then
# shows the fail screen, whose "Subukan Ulit" button replays this level.
var level_failed: bool = false
var player_hearts: int:
	get: return GameManager.player_hearts
	set(val): GameManager.player_hearts = val

const RESTORE_HEART_COST: int = 20

var out_of_hearts_modal: OutOfHeartsPopup = null

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
	if has_node("CanvasLayer/VictoryPopup/ColorRect/CloseVictoryButton"):
		var close_btn = $CanvasLayer/VictoryPopup/ColorRect/CloseVictoryButton
		if not close_btn.is_connected("pressed", Callable(self, "_on_close_victory_pressed")):
			close_btn.pressed.connect(_on_close_victory_pressed)

	load_current_level()
	_connect_sound_to_all_buttons(self)

func _process(_delta):
	update_timer_display()

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
	# 0 stars means a failed try (older saves kept it); start fresh.
	if player_stars <= 0:
		player_stars = 3
	level_failed = false
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
		%CoinsLabel.text = str(player_coins)
	
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
	if has_node("CanvasLayer/IsarogFoothillsBg"): $CanvasLayer/IsarogFoothillsBg.visible = false
	if has_node("CanvasLayer/GreenWood"): $CanvasLayer/GreenWood.visible = false
	if has_node("CanvasLayer/BlueWood"): $CanvasLayer/BlueWood.visible = false
	if has_node("CanvasLayer/VioletWood"): $CanvasLayer/VioletWood.visible = false

	if lvl >= 16 and lvl <= 20:
		if has_node("CanvasLayer/IsarogFoothillsBg"):
			$CanvasLayer/IsarogFoothillsBg.visible = true

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
	Global.pop_in_sequence(tiles)

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
			Global.play_correct_sound()
			show_victory_popup()
		elif not from_hint:
			# Skip the penalty when this check was triggered by Reveal Hint
			# fixing one wrong letter - other still-wrong slots would
			# otherwise make an already-paid-for hint also cost a star.
			Global.play_wrong_sound()
			handle_wrong_answer()

func handle_wrong_answer():
	Global.wrong_answer_effects(self, _get_answer_slot_container(), player_stars)
	player_stars -= 1
	if player_stars < 0:
		player_stars = 0
	update_stars_display()

	if player_stars <= 0:
		fail_level()
		return

	# Persist immediately so leaving for the campaign map right after a
	# mistake doesn't hand back the lost star.
	GameManager.in_progress_stars[str(int(current_level))] = player_stars
	GameManager.save_game()

## Out of stars: the level is failed. It costs one heart, gives 0 stars and
## shows the fail screen, whose "Subukan Ulit" button restarts the level.
func fail_level():
	level_failed = true
	GameManager.in_progress_stars.erase(str(int(current_level)))
	GameManager.lose_heart()
	update_hearts_display()
	# Let the last star finish popping away first.
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree() or not level_failed:
		return
	Global.set_result_texts(self, true, false, int(current_level))
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = true

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

## Gives back hearts that refilled since the last check (they keep
## refilling while the game is closed) and shows the countdown until they do.
func update_timer_display():
	var hearts_before: int = player_hearts
	if GameManager.refresh_hearts():
		update_hearts_display()
		_check_out_of_hearts()
		if player_hearts > hearts_before:
			_play_heart_pop(player_hearts - hearts_before)
	var time_left := GameManager.seconds_to_next_heart()
	var time_string := ""
	if time_left > 0:
		time_string = "%02d:%02d" % [time_left / 60, time_left % 60]
	if has_node("%HeartTimerLabel"):
		%HeartTimerLabel.text = time_string
	if out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		out_of_hearts_modal.set_time_text(time_string)

func _check_out_of_hearts() -> void:
	if player_hearts <= 0:
		var modal := _ensure_out_of_hearts_modal()
		modal.open()
		modal.move_to_front()
		update_timer_display()
		_update_restore_heart_button()
	elif out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		out_of_hearts_modal.hide()

func _update_restore_heart_button() -> void:
	if out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		out_of_hearts_modal.set_can_buy(player_coins >= RESTORE_HEART_COST)

func _on_restore_heart_pressed() -> void:
	if player_coins < RESTORE_HEART_COST or player_hearts > 0:
		return
	player_coins -= RESTORE_HEART_COST
	Global.play_coin_spend_sound()
	GameManager.gain_heart()
	update_hearts_display()
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
	GameManager.save_game()
	_check_out_of_hearts()
	_play_heart_pop(1)

func _ensure_out_of_hearts_modal() -> OutOfHeartsPopup:
	if out_of_hearts_modal and is_instance_valid(out_of_hearts_modal):
		return out_of_hearts_modal
	var popup := OutOfHeartsPopup.create(RESTORE_HEART_COST, GameManager.MAX_HEARTS)
	popup.restore_pressed.connect(_on_restore_heart_pressed)
	popup.back_pressed.connect(func(): Global.change_scene("res://campaign_map_screen.tscn"))
	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(popup)
	else:
		add_child(popup)
	out_of_hearts_modal = popup
	return popup

## Hearts that came back pop out in the middle of the screen and fly to
## the hearts counter at the top.
func _play_heart_pop(count: int) -> void:
	var parent: Node = $CanvasLayer if has_node("CanvasLayer") else self
	var target := Vector2(150, 60)
	if has_node("CanvasLayer/TopBar/LiveLabel"):
		var live: Control = get_node("CanvasLayer/TopBar/LiveLabel")
		target = live.get_global_rect().get_center()
	OutOfHeartsPopup.play_heart_pop(parent, count, target)

func _on_close_victory_pressed() -> void:
	Global.change_scene("res://campaign_map_screen.tscn")

func show_victory_popup():
	var lvl_key = int(current_level)
	var level_info = LevelData.levels[lvl_key]

	if player_stars <= 0:
		fail_level()
		return
	GameManager.add_coins(10)
	GameManager.in_progress_stars.erase(str(lvl_key))
	GameManager.complete_level(lvl_key, player_stars)
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
	if has_node("%+coin"):
		get_node("%+coin").text = "+10 COINS"
	Global.set_result_texts(self, false)
	
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
		Global.victory_stars_for_level(self, player_stars)
		
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
			Global.play_coin_spend_sound()
			if has_node("%CoinsLabel"):
				%CoinsLabel.text = str(player_coins)
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
	Global.play_coin_spend_sound()
	if has_node("%CoinsLabel"):
		%CoinsLabel.text = str(player_coins)
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
	if level_failed:
		level_failed = false
		load_current_level()
		return
	current_level += 1

	if current_level == 21:
		# Without this, level_21_30.gd falls back to its own hardcoded
		# default starting level instead of actually starting at 21 - it
		# only happens to match today because that default is coincidentally
		# also 21, so this is here to not silently break if that ever changes.
		Global.requested_level = current_level
		Global.change_scene("res://level_21_30.tscn")
		return

	if current_level <= LevelData.levels.size():
		load_current_level()
		if has_node("%CoinsLabel"):
			%CoinsLabel.text = str(player_coins)
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

func _connect_sound_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.is_connected("pressed", Callable(self, "_on_global_button_pressed")):
				child.pressed.connect(Callable(self, "_on_global_button_pressed"))
		if child.get_child_count() > 0:
			_connect_sound_to_all_buttons(child)

func _on_global_button_pressed():
	Global.play_click_sound()
