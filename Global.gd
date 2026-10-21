extends Node

var player_coins: int = 0
var player_hearts: int = 4

# Level requested from the campaign map (0 = start each gameplay scene at its default level)
var requested_level: int = 0

var audio_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
# Separate players for coin/correct/wrong so they can't cut each other off -
# level completion fires play_correct_sound(), play_coin_sound(), and
# play_horray() all in the same instant (see show_victory_popup()), and
# they'd otherwise all fight over one shared player, leaving only the last
# one triggered audible.
var coin_player: AudioStreamPlayer
var answer_player: AudioStreamPlayer
# Word pronunciation used to share audio_player with the generic button
# click sound - pressing a speaker button also counts as a button press,
# so the click (connected after the pronunciation on most screens) would
# immediately overwrite the pronunciation audio before it was audible.
# Dedicated player, same fix as coin/answer/game-complete above.
var word_audio_player: AudioStreamPlayer

var horray_audio = preload("res://audio/horray.mp3")

func _ready():
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "SFX"
	add_child(audio_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	coin_player = AudioStreamPlayer.new()
	coin_player.bus = "SFX"
	add_child(coin_player)

	answer_player = AudioStreamPlayer.new()
	answer_player.bus = "SFX"
	add_child(answer_player)

	word_audio_player = AudioStreamPlayer.new()
	word_audio_player.bus = "SFX"
	add_child(word_audio_player)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)
	play_background_music()

	_apply_saved_audio_settings()

	get_tree().node_added.connect(_on_node_added)
	_setup_screen_fade()

## --- SCREEN TRANSITIONS ---
## Use Global.change_scene(path) instead of get_tree().change_scene_to_file():
## the screen fades to dark, switches, then fades back in. Taps are blocked
## while it fades so a double tap can't switch twice.
const FADE_OUT_TIME := 0.2
const FADE_IN_TIME := 0.3
var _fade: ColorRect
var _changing_scene: bool = false

func _setup_screen_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.08, 0.06, 0.04, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	get_tree().scene_changed.connect(_fade_in)

func change_scene(path: String) -> void:
	if _changing_scene:
		return
	_changing_scene = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := _fade_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_OUT_TIME)
	await tween.finished
	if get_tree().change_scene_to_file(path) != OK:
		push_error("Global.change_scene: couldn't open " + path)
		_fade_in()

func _fade_in() -> void:
	_changing_scene = false
	var tween := _fade_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_IN_TIME)
	tween.tween_callback(func(): _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE)

## Keeps running while a level has paused the game.
func _fade_tween() -> Tween:
	return create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

## --- BUTTON SQUISH ---
## Every button shrinks a little while held and springs back on release.
func _on_button_down(button: BaseButton) -> void:
	if button.disabled or button.has_meta("_pulse_tween"):
		return
	if not button.has_meta("_base_scale"):
		button.set_meta("_base_scale", button.scale)
		_center_pivot(button)
	var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", button.get_meta("_base_scale") * 0.93, 0.07)

func _on_button_up(button: BaseButton) -> void:
	if not button.has_meta("_base_scale") or button.has_meta("_pulse_tween"):
		return
	# Tiles that grow on hover spring back to their hover size if still hovered.
	var target: Vector2 = button.get_meta("_base_scale")
	if button.has_meta("_hover_grow") and button.is_hovered():
		target *= HOVER_GROW
	var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", target, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Moves the scaling centre to the middle without moving what's on screen.
## Many buttons are drawn scaled (e.g. the map's Settings and Word of the
## Day icons at 0.2x), and for those changing pivot_offset alone shifts
## the drawn button, so the position is shifted back by the same amount.
## Buttons inside a Container are left alone - the container owns their
## position.
func _center_pivot(control: Control) -> void:
	var new_pivot := control.size / 2.0
	var delta := new_pivot - control.pivot_offset
	if delta == Vector2.ZERO:
		return
	if control.scale != Vector2.ONE:
		if control.get_parent() is Container:
			return
		control.position -= delta * (Vector2.ONE - control.scale)
	control.pivot_offset = new_pivot

## --- IN-LEVEL ANIMATIONS ---
## Small effects the level scripts call at the right moments.

## The scale a control was designed at (kept the first time we animate it,
## so every effect returns it to exactly that size).
func _base_scale(control: Control) -> Vector2:
	if not control.has_meta("_base_scale"):
		control.set_meta("_base_scale", control.scale)
	return control.get_meta("_base_scale")

## Visible tiles grow in one after another (a level starting, or a shuffle).
func pop_in_sequence(nodes: Array, step: float = 0.05) -> void:
	var delay := 0.0
	for node in nodes:
		if node is Control and node.visible:
			_base_scale(node)
			# Hidden until its turn. (Not shrunk yet: a container resets its
			# children's scale when it lays them out, so the size is only
			# set once the tween starts.)
			node.modulate.a = 0.0
			# Deferred: tiles inside a container only get their size next frame.
			_pop_in_node.call_deferred(node, delay)
			delay += step

func _pop_in_node(control: Control, delay: float) -> void:
	if not is_instance_valid(control):
		return
	var base := _base_scale(control)
	var tween := control.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func():
		control.scale = base
		_center_pivot(control)
		control.modulate.a = 1.0
	)
	tween.tween_property(control, "scale", base, 0.28).from(base * 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## A quick springy bounce (a letter landing in a slot).
func bounce(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var base := _base_scale(control)
	control.scale = base
	_center_pivot(control)
	var tween := control.create_tween()
	tween.tween_property(control, "scale", base * 1.18, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", base, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Side-to-side shake (the answer row on a wrong answer). Always ends back
## at the exact starting position, even if shaken again mid-shake.
func shake(control: Control) -> void:
	if not is_instance_valid(control):
		return
	if not control.has_meta("_shake_x"):
		control.set_meta("_shake_x", control.position.x)
	var x0: float = control.get_meta("_shake_x")
	if control.has_meta("_shake_tween"):
		var old: Tween = control.get_meta("_shake_tween")
		if old and old.is_valid():
			old.kill()
	var tween := control.create_tween()
	control.set_meta("_shake_tween", tween)
	for dx in [14.0, -12.0, 9.0, -6.0, 3.0, 0.0]:
		tween.tween_property(control, "position:x", x0 + dx, 0.045)
	tween.tween_callback(func():
		control.position.x = x0
		control.remove_meta("_shake_x")
		control.remove_meta("_shake_tween")
	)

## A star (or any sprite/control) that's about to disappear grows and fades
## away instead of just vanishing. Works on a copy, so the real node can be
## hidden right away as before.
func pop_away(item: CanvasItem) -> void:
	if not is_instance_valid(item) or not item.is_visible_in_tree():
		return
	var ghost := item.duplicate(0) as CanvasItem
	ghost.set_script(null)
	item.get_parent().add_child(ghost)
	ghost.visible = true
	if ghost is Control:
		_center_pivot(ghost)
	var tween := ghost.create_tween().set_parallel()
	tween.tween_property(ghost, "scale", ghost.scale * 1.8, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(ghost.queue_free)

## Wrong answer in a level: shake the answer row and pop away the star
## that's being lost. Call before player_stars is reduced.
func wrong_answer_effects(level: Node, answer_row: Node, stars_before: int) -> void:
	if answer_row is Control:
		shake(answer_row)
	if stars_before >= 1 and stars_before <= 3:
		var star_name: String = ["StarWithFill", "StarWithFill2", "StarWithFill3"][stars_before - 1]
		var star := level.get_node_or_null("CanvasLayer/LevelDesign/" + star_name) as CanvasItem
		if star:
			pop_away(star)

## Victory in a level: hang the earned stars under the "MAHUSAY!" sign.
func victory_stars_for_level(level: Node, earned: int) -> void:
	var popup := level.get_node_or_null("%VictoryPopup") as Control
	var star := level.get_node_or_null("CanvasLayer/LevelDesign/StarWithFill")
	if popup == null or star == null:
		return
	var sign := popup.get_node_or_null("MAHUSAY!") as Control
	# In the popup's own coordinates, so the popup's pop-in scale doesn't
	# throw the stars off.
	var center := Vector2(360, 215)
	if sign:
		center = sign.position + Vector2(sign.size.x * sign.scale.x / 2.0, sign.size.y * sign.scale.y + 48.0)
	show_victory_stars(popup, earned, star.texture, center)

## Results card heading and button text. A failed level turns the card
## into the fail screen (see _set_fail_card); level_num picks the unit
## shown on its sign.
func set_result_texts(level: Node, failed: bool, last_level: bool = false, level_num: int = 0) -> void:
	var popup := level.get_node_or_null("CanvasLayer/VictoryPopup") as Control
	if popup:
		_set_fail_card(popup, failed)
	var title := level.get_node_or_null("CanvasLayer/VictoryPopup/MAHUSAY!") as Label
	var next_label := level.get_node_or_null("CanvasLayer/VictoryPopup/NextLevel/Label") as Label
	var title_text := "MAHUSAY!"
	var next_text := "Sunod na Level  >>"
	if failed:
		title_text = "YUNIT %d" % unit_for_level(level_num)
		next_text = "Subukan Ulit"
	elif last_level:
		title_text = "TAPOS MO NA!"
		next_text = "Bumalik sa Mapa"
	if title: title.text = title_text
	if next_label: next_label.text = next_text

## Levels per unit, in order: Yunit 1-3 have 5 levels, Yunit 4 has 15.
const UNIT_LEVEL_COUNTS: Array = [5, 5, 5, 15]

func unit_for_level(level_num: int) -> int:
	var last := 0
	for i in UNIT_LEVEL_COUNTS.size():
		last += UNIT_LEVEL_COUNTS[i]
		if level_num <= last:
			return i + 1
	return UNIT_LEVEL_COUNTS.size()

## Word card nodes hidden while the results card shows the fail screen.
const _WORD_CARD_NODES: Array = ["salita_title", "kahulugan_title", "culturalnote _title",
	"pakinggan_ang_pagbigkas", "MeaningLabel", "CulturalNoteLabel", "WordLabel",
	"SpeakerButton", "+coin", "ColorRect/Book", "ColorRect/Woods"]

## Switches the results card between the word card (a win) and the fail
## screen: "HINDI NAKAPASA!", three empty stars, a broken heart and a
## centred "Subukan Ulit" button. Positions are on the 720x1280 canvas.
func _set_fail_card(popup: Control, failed: bool) -> void:
	for path in _WORD_CARD_NODES:
		var node := popup.get_node_or_null(path) as CanvasItem
		if node:
			node.visible = not failed
	var card := popup.get_node_or_null("FailCard") as Control
	if failed and card == null:
		card = _build_fail_card(popup)
	if card:
		card.visible = failed
	if failed:
		var old_stars := popup.get_node_or_null("VictoryStars")
		if old_stars:
			old_stars.free()
		var particles := popup.get_node_or_null("CPUParticles2D") as CPUParticles2D
		if particles:
			particles.emitting = false

	var title := popup.get_node_or_null("MAHUSAY!") as Label
	if title:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if failed else HORIZONTAL_ALIGNMENT_LEFT

	# The button moves to the middle (no coins sign beside it) and its text
	# is centred; the original layout is kept to put back after a win.
	var button := popup.get_node_or_null("NextLevel") as Control
	var label := popup.get_node_or_null("NextLevel/Label") as Label
	if button == null or label == null:
		return
	if not button.has_meta("win_position"):
		button.set_meta("win_position", button.position)
		label.set_meta("win_rect", Rect2(label.position, label.size))
		label.set_meta("win_font_size", label.get_theme_font_size("font_size"))
	if failed:
		button.position = Vector2(360 - button.size.x / 2.0, button.get_meta("win_position").y)
		label.position = Vector2(0, 21)
		label.size = Vector2(button.size.x, 55)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 40)
	else:
		var rect: Rect2 = label.get_meta("win_rect")
		button.position = button.get_meta("win_position")
		label.position = rect.position
		label.size = rect.size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", label.get_meta("win_font_size"))

func _build_fail_card(popup: Control) -> Control:
	var card := Control.new()
	card.name = "FailCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_child(card)
	# Keep the close button and the "Subukan Ulit" button on top.
	popup.move_child(card, popup.get_node("ColorRect").get_index() + 1)

	var sign := popup.get_node_or_null("MAHUSAY!") as Label
	if sign:
		var title := sign.duplicate() as Label
		card.add_child(title)
		title.visible = true
		title.text = "HINDI NAKAPASA!"
		title.add_theme_font_size_override("font_size", 56)
		title.add_theme_color_override("font_color", Color(0.78, 0.16, 0.10))
		title.add_theme_color_override("font_outline_color", Color(1, 1, 1))
		title.add_theme_constant_override("outline_size", 10)
		title.add_theme_color_override("font_shadow_color", Color(0.35, 0.2, 0.1, 0.5))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = Vector2(80, 335)
		title.size = Vector2(560, 80)

	var body := popup.get_node_or_null("pakinggan_ang_pagbigkas") as Label
	if body:
		# body is already hidden with the word card, so show the copies.
		var line := body.duplicate() as Label
		card.add_child(line)
		line.visible = true
		line.text = "Sayang! Kaya mo 'yan, subukan ulit."
		line.add_theme_font_size_override("font_size", 26)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.position = Vector2(80, 420)
		line.size = Vector2(560, 40)

		var lost := body.duplicate() as Label
		card.add_child(lost)
		lost.visible = true
		lost.text = "-1 buhay"
		lost.add_theme_font_size_override("font_size", 34)
		lost.add_theme_color_override("font_color", Color(0.78, 0.16, 0.10))
		lost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lost.position = Vector2(80, 840)
		lost.size = Vector2(560, 50)

	# Empty stars: a faded filled star under the outline-only one.
	var full_tex := load("res://Partido Word Catch Game Pic/Star with fill.png") as Texture2D
	var empty_tex := load("res://Partido Word Catch Game Pic/Star without fill.png") as Texture2D
	var sizes := [120.0, 150.0, 120.0]
	var centers := [Vector2(220, 560), Vector2(360, 530), Vector2(500, 560)]
	for i in 3:
		for tex in [full_tex, empty_tex]:
			var star := TextureRect.new()
			star.texture = tex
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star.mouse_filter = Control.MOUSE_FILTER_IGNORE
			star.size = Vector2(sizes[i], sizes[i])
			star.position = centers[i] - star.size / 2.0
			if tex == full_tex:
				star.modulate = Color(0.55, 0.5, 0.45, 0.45)
			card.add_child(star)

	# Broken heart: the heart picture split down the middle, halves tipped
	# apart, with a parchment-coloured crack between them.
	var heart := load("res://images/heart.png") as Texture2D
	if heart:
		var half_size := Vector2(heart.get_width() / 2.0, heart.get_height()) * 0.62
		var center := Vector2(360, 745)
		for side in 2:
			var piece := AtlasTexture.new()
			piece.atlas = heart
			piece.region = Rect2(side * heart.get_width() / 2.0, 0, heart.get_width() / 2.0, heart.get_height())
			var half := TextureRect.new()
			half.texture = piece
			half.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			half.mouse_filter = Control.MOUSE_FILTER_IGNORE
			half.size = half_size
			half.pivot_offset = Vector2(half_size.x if side == 0 else 0.0, half_size.y)
			half.position = center + Vector2(-half_size.x - 6 if side == 0 else 6, -half_size.y / 2.0)
			half.rotation_degrees = -14 if side == 0 else 14
			card.add_child(half)
		var crack := Line2D.new()
		crack.width = 7
		crack.default_color = Color(1.0, 0.925, 0.785)
		crack.points = PackedVector2Array([Vector2(360, 680), Vector2(348, 705), Vector2(372, 730),
			Vector2(350, 758), Vector2(366, 790), Vector2(360, 820)])
		card.add_child(crack)
	return card

## Three stars hanging under the victory sign, popping in one after another.
## Earned stars are full colour, missed ones are dimmed. center is in the
## popup's local coordinates.
func show_victory_stars(popup: Control, earned: int, texture: Texture2D, center: Vector2) -> void:
	if not is_instance_valid(popup) or texture == null:
		return
	var old := popup.get_node_or_null("VictoryStars")
	if old:
		old.free()
	var row := Control.new()
	row.name = "VictoryStars"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_child(row)
	var sizes := [64.0, 80.0, 64.0]
	var offsets := [Vector2(-78, 6), Vector2(0, -6), Vector2(78, 6)]
	for i in 3:
		var star := TextureRect.new()
		star.texture = texture
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.size = Vector2(sizes[i], sizes[i])
		row.add_child(star)
		star.position = center + offsets[i] - star.size / 2.0
		star.pivot_offset = star.size / 2.0
		if i >= earned:
			star.modulate = Color(0.35, 0.33, 0.3, 0.85)
		star.scale = Vector2.ZERO
		var tween := star.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(0.35 + i * 0.22)
		tween.tween_property(star, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Letter tiles and answer slots: their .tscn hover style is a plain flat
## box. Replace it with a slightly brighter copy of the tile's own texture,
## and grow the tile a little while the mouse is over it.
const HOVER_GROW := 1.07

func setup_tile_hover(button: Button) -> void:
	var normal := button.get_theme_stylebox("normal")
	button.add_theme_stylebox_override("hover", _shaded_style(normal, 0.12))
	button.add_theme_stylebox_override("hover_pressed", _shaded_style(normal, -0.06))
	button.add_theme_stylebox_override("pressed", _shaded_style(normal, -0.06))
	button.set_meta("_hover_grow", true)
	button.mouse_entered.connect(func(): hover_grow(button, true))
	button.mouse_exited.connect(func(): hover_grow(button, false))

# Tile pictures have a rim (and see-through edges), so keep the word inside
# the flat middle: a share of the width (meta "_fit_padding_share") plus a bit.
const FIT_TEXT_PADDING_SHARE := 0.10
const FIT_TEXT_PADDING := 4.0
## Shrinks a tile's font just enough for its word to fit inside the box
## (long words like NAGBIBISITA), and goes back to the scene's own size for
## short ones. Never goes below min_size so the word stays readable.
func fit_text_to_box(button: Button, min_size: int = 11) -> void:
	if not button.has_meta("_fit_base_font_size"):
		button.set_meta("_fit_base_font_size", button.get_theme_font_size("font_size"))
	var base: int = button.get_meta("_fit_base_font_size")
	button.add_theme_font_size_override("font_size", fitting_font_size(button, button.text, base, min_size))
	# The box keeps its size instead of stretching around the word.
	button.clip_text = true

## Largest font size (from base down to min_size) at which text fits the box.
func fitting_font_size(button: Button, text: String, base: int, min_size: int = 11) -> int:
	var box_w: float = button.custom_minimum_size.x
	if box_w <= 0.0:
		box_w = button.size.x
	var share: float = button.get_meta("_fit_padding_share", FIT_TEXT_PADDING_SHARE)
	var room := box_w - (box_w * share + FIT_TEXT_PADDING) * 2.0
	var font := button.get_theme_font("font")
	var fs := base
	if text != "" and font and room > 0.0:
		while fs > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
			fs -= 1
	return fs

func hover_grow(control: Control, on: bool) -> void:
	if not is_instance_valid(control) or control.has_meta("_pulse_tween"):
		return
	if on and control is BaseButton and control.disabled:
		return
	var base := _base_scale(control)
	if control.scale.is_equal_approx(base):
		_center_pivot(control)
	if control.has_meta("_hover_tween"):
		var old: Tween = control.get_meta("_hover_tween")
		if old and old.is_valid():
			old.kill()
	var tween := control.create_tween()
	tween.tween_property(control, "scale", base * (HOVER_GROW if on else 1.0), 0.12).set_ease(Tween.EASE_OUT)
	control.set_meta("_hover_tween", tween)

## Gentle "tap me" pulse (the next level on the campaign map). Pass
## on = false to stop it and put the node back at its normal size.
func pulse(control: Control, on: bool = true) -> void:
	if not is_instance_valid(control):
		return
	if control.has_meta("_pulse_tween"):
		var old: Tween = control.get_meta("_pulse_tween")
		if old and old.is_valid():
			old.kill()
		control.remove_meta("_pulse_tween")
		control.scale = _base_scale(control)
	if not on:
		return
	var base := _base_scale(control)
	control.scale = base
	_center_pivot(control)
	var tween := control.create_tween().set_loops()
	tween.tween_property(control, "scale", base * 1.08, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "scale", base, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	control.set_meta("_pulse_tween", tween)

## --- POPUP POP-IN ---
## Any Control whose name ends in "Popup" (VictoryPopup, ClassJoinedPopup,
## ExitConfirmationPopup, ...) fades in and grows slightly with a small
## bounce each time it's shown.
func _watch_popup(popup: Control) -> void:
	popup.visibility_changed.connect(func():
		if is_instance_valid(popup) and popup.is_visible_in_tree():
			_pop_in(popup)
	)
	if popup.is_visible_in_tree():
		_pop_in.call_deferred(popup)

func _pop_in(popup: Control) -> void:
	if not is_instance_valid(popup) or not popup.is_inside_tree():
		return
	if not popup.has_meta("_base_scale"):
		popup.set_meta("_base_scale", popup.scale)
		_center_pivot(popup)
	var base: Vector2 = popup.get_meta("_base_scale")
	popup.scale = base * 0.92
	popup.modulate.a = 0.0
	var tween := popup.create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(popup, "modulate:a", 1.0, 0.18)
	tween.tween_property(popup, "scale", base, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## --- BUTTON HOVER/PRESS LOOK ---
## Most buttons only set a "normal" style in their .tscn, so on hover,
## press, focus or disabled Godot fell back to its plain grey rectangle.
## Every Button that appears gets those states made from its own normal
## style instead: a lighter copy on hover, a darker one when pressed, a
## faded one when disabled, and no focus box. Styles a scene or script
## already set on purpose (e.g. the sound/music toggles) are left alone,
## and the copies are remade whenever a script swaps the normal style
## (e.g. the campaign map's "next level" highlight).
const _AUTO_STATES_META := "_auto_button_states"

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.button_down.connect(_on_button_down.bind(node))
		node.button_up.connect(_on_button_up.bind(node))
	elif node is Control and node.name.ends_with("Popup") and node.get_class() == "Control":
		_watch_popup(node)
	if node is Button and not node.has_meta(_AUTO_STATES_META):
		node.set_meta(_AUTO_STATES_META, {})
		node.theme_changed.connect(_refresh_button_states.bind(node))
		_refresh_button_states.call_deferred(node)

func _refresh_button_states(button: Button) -> void:
	if not is_instance_valid(button) or not button.has_theme_stylebox_override("normal"):
		return
	var normal := button.get_theme_stylebox("normal")
	var auto: Dictionary = button.get_meta(_AUTO_STATES_META)
	if auto.get("_source") == normal:
		return
	auto["_source"] = normal

	var states := {
		"hover": _shaded_style(normal, 0.15),
		"pressed": _shaded_style(normal, -0.12),
		"hover_pressed": _shaded_style(normal, -0.12),
		"disabled": _shaded_style(normal, 0.0, 0.6),
		"focus": StyleBoxEmpty.new(),
	}
	for state in states:
		if button.has_theme_stylebox_override(state) and not auto.has(state):
			continue
		auto[state] = true
		button.add_theme_stylebox_override(state, states[state])

	# Keep the text colour too - otherwise it turns Godot's default white on hover/press.
	if button.has_theme_color_override("font_color"):
		var color := button.get_theme_color("font_color")
		for key in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			if not button.has_theme_color_override(key) or auto.has(key):
				auto[key] = true
				button.add_theme_color_override(key, color)

## amount > 0 lightens, < 0 darkens; alpha scales the opacity.
func _shaded_style(style: StyleBox, amount: float, alpha: float = 1.0) -> StyleBox:
	if style is StyleBoxFlat:
		var flat := style.duplicate() as StyleBoxFlat
		flat.bg_color = flat.bg_color.lightened(amount) if amount >= 0.0 else flat.bg_color.darkened(-amount)
		flat.border_color = flat.border_color.lightened(amount) if amount >= 0.0 else flat.border_color.darkened(-amount)
		flat.bg_color.a *= alpha
		flat.border_color.a *= alpha
		return flat
	if style is StyleBoxTexture:
		var textured := style.duplicate() as StyleBoxTexture
		var v := 1.0 + amount
		textured.modulate_color = Color(v, v, v, alpha)
		return textured
	return style

## Applies the sound/music on-off state saved in GameManager, so a mute
## chosen in Settings is still in effect after the app is closed and
## reopened (not just for the rest of this session).
func _apply_saved_audio_settings():
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1 and "is_sound_enabled" in gm:
		AudioServer.set_bus_mute(sfx_bus, not gm.is_sound_enabled)

	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1 and "is_music_enabled" in gm:
		AudioServer.set_bus_mute(music_bus, not gm.is_music_enabled)

func play_click_sound():
	var sound_path = "res://audio/click.mp3"
	if ResourceLoader.exists(sound_path):
		audio_player.volume_db = 0.0
		audio_player.stream = load(sound_path)
		audio_player.play()

func play_horray():
	if horray_audio:
		sfx_player.stream = horray_audio
		sfx_player.play()

## Bigger celebration sound for finishing the whole game (level 30), used
## in place of the regular per-level horray.
func play_game_complete_sound():
	var sound_path = "res://audio/game_complete.mp3"
	if ResourceLoader.exists(sound_path):
		sfx_player.stream = load(sound_path)
		sfx_player.play()

## Per-instance sound feedback (coins earned, correct/wrong answer) - each
## uses its own dedicated player (see the vars above) so triggering more
## than one of these at once, like on level completion, doesn't silently
## cut any of them off.
func play_coin_sound():
	var sound_path = "res://audio/coin_award.mp3"
	if ResourceLoader.exists(sound_path):
		coin_player.stream = load(sound_path)
		coin_player.play()

func play_correct_sound():
	var sound_path = "res://audio/correct_answer.mp3"
	if ResourceLoader.exists(sound_path):
		answer_player.stream = load(sound_path)
		answer_player.play()

func play_wrong_sound():
	var sound_path = "res://audio/wrong_answer.mp3"
	if ResourceLoader.exists(sound_path):
		answer_player.stream = load(sound_path)
		answer_player.play()

## Coins being spent (Restore Heart, Hint, Alisin) - the reverse of
## play_coin_sound(), uses the same dedicated coin_player.
func play_coin_spend_sound():
	var sound_path = "res://audio/coin_spend.mp3"
	if ResourceLoader.exists(sound_path):
		coin_player.stream = load(sound_path)
		coin_player.play()

func play_word_audio(audio_filename: String):
	play_word_audio_with_volume(audio_filename, 0.0)

const BGM_DUCKED_VOLUME_DB: float = -18.0
var _bgm_normal_volume_db: float = 0.0

## Plays a word's pronunciation audio, ducking the background music while it
## plays so it's actually audible, then restoring it once the word finishes.
func play_word_audio_with_volume(audio_filename: String, boost_db: float = 0.0):
	var sound_path = "res://audio/" + audio_filename
	if not ResourceLoader.exists(sound_path):
		return

	_duck_background_music()

	word_audio_player.volume_db = clamp(boost_db, 0.0, 12.0)
	word_audio_player.stream = load(sound_path)
	word_audio_player.play()

	if word_audio_player.finished.is_connected(_on_word_audio_finished):
		word_audio_player.finished.disconnect(_on_word_audio_finished)
	word_audio_player.finished.connect(_on_word_audio_finished, CONNECT_ONE_SHOT)

func _duck_background_music():
	if not bgm_player:
		return
	_bgm_normal_volume_db = bgm_player.volume_db
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", BGM_DUCKED_VOLUME_DB, 0.2)

func _on_word_audio_finished():
	if not bgm_player:
		return
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", _bgm_normal_volume_db, 0.4)

func play_background_music():
	var bgm_path = "res://audio/Partido_Word_Catch_30min_enhanced.mp3"
	if ResourceLoader.exists(bgm_path):
		var stream = load(bgm_path)
		if stream is AudioStreamMP3 or stream is AudioStreamWAV:
			stream.loop = true
		bgm_player.stream = stream
		bgm_player.play()
		if not bgm_player.finished.is_connected(_on_bgm_finished):
			bgm_player.finished.connect(_on_bgm_finished)

func _on_bgm_finished():
	bgm_player.play()
