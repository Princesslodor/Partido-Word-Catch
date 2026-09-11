extends Node

var player_coins: int = 0
var player_hearts: int = 4

var audio_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

var horray_audio = preload("res://audio/horray.mp3")

func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	play_background_music()

func play_click_sound():
	var sound_path = "res://audio/click.mp3"
	if ResourceLoader.exists(sound_path):
		audio_player.stream = load(sound_path)
		audio_player.play()

func play_horray():
	if horray_audio:
		sfx_player.stream = horray_audio
		sfx_player.play()

func play_word_audio(audio_filename: String):
	var sound_path = "res://audio/" + audio_filename
	if ResourceLoader.exists(sound_path):
		audio_player.stream = load(sound_path)
		audio_player.play()

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
