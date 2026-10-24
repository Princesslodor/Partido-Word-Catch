extends Node2D

var current_level: int = 1
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
	if has_node("CanvasLayer/VictoryPopup/ColorRect/CloseVictoryButton"):
		var close_btn = $CanvasLayer/VictoryPopup/ColorRect/CloseVictoryButton
		if not close_btn.is_connected("pressed", Callable(self, "_on_close_victory_pressed")):
			close_btn.pressed.connect(_on_close_victory_pressed)

	load_current_level()
	_connect_sound_to_all_buttons(self)

func _process(_delta):
	check_slots_automatically()
	update_timer_display()

func load_current_level():
	if has_node("%VictoryPopup"): %VictoryPopup.visible = false

	var lvl_key = int(current_level)

	# Resume with whatever stars were left the last time this level was
	# left mid-attempt (leaving for the campaign map and coming back
	# shouldn't hand a fresh 3 stars for free) - defaults to 3 if this
	# level has no in-progress attempt saved.
	player_stars = GameManager.in_progress_stars.get(str(lvl_key), 3)
	# 0 stars means a failed try (older saves kept it); start fresh.
	if player_stars <= 0:
		player_stars = 3
	level_failed = false
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
	if has_node("%CoinsLabel"): %CoinsLabel.text = str(player_coins)
	
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
		if has_node("CanvasLayer/CoastalShore"):
			$CanvasLayer/CoastalShore.visible = true
	elif lvl >= 11:
		if has_node("CanvasLayer/LagonoyValleyBg"):
			$CanvasLayer/LagonoyValleyBg.visible = true

func update_level_image(lvl: int):
	# lvl here must be the ORIGINAL (pre-shuffle) level number - see
	# get_hint_image_path()'s comment for why this can't scan the folder.
	var image_path: String = LevelData.get_hint_image_path(lvl)
	if image_path == "":
		return
	var tex = load(image_path)
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
	Global.pop_in_sequence(tiles)

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
			Global.play_correct_sound()
			show_victory_popup()
		else:
			Global.play_wrong_sound()
			handle_wrong_answer()
	elif not is_full:
		last_slots_full_state = false

func check_answer():
	check_slots_automatically()

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
	if has_node("%LiveLabel"):
		get_node("%LiveLabel").text = str(player_hearts)

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

## Shows a blocking modal explaining why play is locked once hearts hit 0,
## with a live countdown to the next heart - and hides it again the moment
## a heart regenerates. Hearts are the only thing gating this: player_stars
## resets to 3 on every level load, so it's never independently "empty"
## outside of this same out-of-hearts state.
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
	if has_node("%CoinsLabel"): %CoinsLabel.text = str(player_coins)
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
	if has_node("%LiveLabel"):
		var live: Control = get_node("%LiveLabel")
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
	# Level's finished, so there's no "in-progress attempt" to resume
	# anymore - replaying it later should start fresh with 3 stars again.
	# Erased before complete_level() so its own save_game() call picks up
	# this change too, instead of needing a separate save here.
	GameManager.in_progress_stars.erase(str(lvl_key))
	GameManager.complete_level(lvl_key, player_stars)
	if has_node("%CoinsLabel"): %CoinsLabel.text = str(player_coins)
	if has_node("%+coin"): get_node("%+coin").text = "+10 COINS"
	Global.set_result_texts(self, false)
	if has_node("%WordLabel"): %WordLabel.text = level_info.get("word", "")
	if has_node("%MeaningLabel"): %MeaningLabel.text = level_info.get("meaning", "")
	if has_node("%CulturalNoteLabel"): %CulturalNoteLabel.text = level_info.get("cultural_note", "")
	if has_node("%VictoryPopup"):
		%VictoryPopup.visible = true
		Global.victory_stars_for_level(self, player_stars)
	
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
			Global.play_coin_spend_sound()
			if has_node("%CoinsLabel"): %CoinsLabel.text = str(player_coins)
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
	Global.play_coin_spend_sound()
	if has_node("%CoinsLabel"): %CoinsLabel.text = str(player_coins)
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
	if level_failed:
		level_failed = false
		load_current_level()
		return
	current_level += 1
	if current_level == 17:
		# level_16_20.gd only adopts this as its starting level if it's set
		# here first - without it, that scene's own hardcoded default
		# (current_level = 16) wins instead, silently replaying Level 16
		# rather than advancing to 17.
		Global.requested_level = current_level
		Global.change_scene("res://level_16_20.tscn")
		return

	if current_level <= LevelData.levels.size():
		load_current_level()
		if has_node("%CoinsLabel"): %CoinsLabel.text = str(player_coins)

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
