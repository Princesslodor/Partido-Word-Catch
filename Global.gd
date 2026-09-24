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
