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
	if button.disabled:
		return
	if not button.has_meta("_base_scale"):
		button.set_meta("_base_scale", button.scale)
		_center_pivot(button)
	var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", button.get_meta("_base_scale") * 0.93, 0.07)

func _on_button_up(button: BaseButton) -> void:
	if not button.has_meta("_base_scale"):
		return
	var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", button.get_meta("_base_scale"), 0.18) \
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
