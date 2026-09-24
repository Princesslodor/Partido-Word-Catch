extends Control

@onready var word_label: Label = $WordLabel if has_node("WordLabel") else null
@onready var meaning_label: Label = $MeaningLabel if has_node("MeaningLabel") else null
@onready var cultural_note_label: Label = $CulturalNoteLabel if has_node("CulturalNoteLabel") else null
@onready var speaker_button: Button = $SpeakerButton if has_node("SpeakerButton") else null
@onready var close_button: TextureButton = $FrameBoard/CloseButton if has_node("FrameBoard/CloseButton") else null

var _current_audio_filename: String = ""

func _ready() -> void:
	hide()
	if close_button and not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.pressed.connect(_on_close_pressed)
	if speaker_button and not speaker_button.is_connected("pressed", Callable(self, "_on_speaker_pressed")):
		speaker_button.pressed.connect(_on_speaker_pressed)

func display_word(word_data: Dictionary) -> void:
	if word_data.is_empty():
		return
	if word_label:
		word_label.text = str(word_data.get("word", ""))
	if meaning_label:
		meaning_label.text = str(word_data.get("meaning", ""))
	if cultural_note_label:
		cultural_note_label.text = str(word_data.get("cultural_note", ""))
	_current_audio_filename = str(word_data.get("audio", ""))
	show()
	move_to_front()

func _on_speaker_pressed() -> void:
	if _current_audio_filename != "":
		Global.play_word_audio(_current_audio_filename)

func _on_close_pressed() -> void:
	hide()
