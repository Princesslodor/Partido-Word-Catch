extends Button

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	if not is_connected("pressed", Callable(self, "_on_pressed")):
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if audio_stream_player_2d:
		# Hanapin ang Main Scene (Node2D) para makuha ang current_level
		var main_node = get_tree().current_scene
		if main_node and "current_level" in main_node:
			var lvl_key = int(main_node.current_level)
			if LevelData.levels.has(lvl_key):
				var level_info = LevelData.levels[lvl_key]
				if level_info.has("audio"):
					var audio_filename = level_info["audio"]
					var audio_path = "res://audio/" + audio_filename
					
					if ResourceLoader.exists(audio_path):
						audio_stream_player_2d.stream = load(audio_path)
						audio_stream_player_2d.play()
						print("Tumutugtog ang audio para sa level: ", audio_filename)
						return
					else:
						print("ERROR: Hindi makita ang audio file sa path: ", audio_path)
		
		# Fallback kung sakaling walang mahanap na level data pero may stream na nakalagay sa Inspector
		if audio_stream_player_2d.stream:
			audio_stream_player_2d.play()
			print("Audio is playing from inspector stream!")
		else:
			print("ERROR: Walang audio stream na nakalagay o hindi mahanap ang level.")
	else:
		print("ERROR: Hindi makita ang AudioStreamPlayer2D.")
