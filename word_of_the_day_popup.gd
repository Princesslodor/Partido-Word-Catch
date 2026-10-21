extends Control

@onready var word_label: Label = $WordLabel if has_node("WordLabel") else null
@onready var meaning_label: Label = $MeaningLabel if has_node("MeaningLabel") else null
@onready var cultural_note_label: Label = $CulturalNoteLabel if has_node("CulturalNoteLabel") else null
@onready var cultural_note_title_label: Control = $CulturalNoteTitleLabel if has_node("CulturalNoteTitleLabel") else null
@onready var speaker_button: Button = $SpeakerButton if has_node("SpeakerButton") else null
@onready var pakinggan_label: Control = $PakingganLabel if has_node("PakingganLabel") else null
@onready var close_button: TextureButton = $FrameBoard/CloseButton if has_node("FrameBoard/CloseButton") else null
@onready var salita_title_label: Control = $SalitaTitleLabel if has_node("SalitaTitleLabel") else null
@onready var kahulugan_title_label: Control = $KahuluganTitleLabel if has_node("KahuluganTitleLabel") else null
@onready var book_icon: Control = $BookIcon if has_node("BookIcon") else null

# Writing area on the parchment, on the 720x1280 canvas: below the title
# ribbon and above the patterned strip and leaves at the bottom.
const AREA_TOP: float = 458.0
const AREA_BOTTOM: float = 830.0
const AREA_LEFT: float = 123.0
const AREA_RIGHT: float = 612.0
# Largest and smallest font sizes for the meaning and the cultural note.
const MEANING_FONT_MAX: int = 30
const NOTE_FONT_MAX: int = 22
const BODY_FONT_MIN: int = 15

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

	# Glossary words don't always have a cultural note or a recording - hide
	# those parts instead of leaving an empty box / a speaker that does nothing.
	var note: String = str(word_data.get("cultural_note", "")).strip_edges()
	if cultural_note_label:
		cultural_note_label.text = note
		cultural_note_label.visible = note != ""
	if cultural_note_title_label:
		cultural_note_title_label.visible = note != ""

	_current_audio_filename = str(word_data.get("audio", "")).strip_edges()
	var has_audio: bool = _current_audio_filename != ""
	if speaker_button:
		speaker_button.visible = has_audio
	if pakinggan_label:
		pakinggan_label.visible = has_audio

	_layout()
	show()
	move_to_front()

## Stacks the sections from the top of the parchment, skipping hidden ones,
## so there are no empty gaps. If a long meaning or note would run past the
## bottom, both shrink a step at a time until everything fits inside.
func _layout() -> void:
	var meaning_size := MEANING_FONT_MAX
	var note_size := NOTE_FONT_MAX
	while true:
		var bottom := _place_sections(meaning_size, note_size)
		if bottom <= AREA_BOTTOM or (meaning_size <= BODY_FONT_MIN and note_size <= BODY_FONT_MIN):
			break
		meaning_size = maxi(meaning_size - 1, BODY_FONT_MIN)
		note_size = maxi(note_size - 1, BODY_FONT_MIN)

## Positions every section for the given font sizes and returns the y where
## the last one ends.
func _place_sections(meaning_size: int, note_size: int) -> float:
	var y := AREA_TOP
	if salita_title_label:
		salita_title_label.position = Vector2(AREA_LEFT, y)
		y += 30.0
	if word_label:
		word_label.position.y = y
		y += _text_height(word_label, word_label.get_theme_font_size("font_size")) + 8.0
	if speaker_button and speaker_button.visible:
		speaker_button.position.y = y - 4.0
		if pakinggan_label:
			pakinggan_label.position.y = y + 4.0
		y += 46.0
	y += 4.0
	if kahulugan_title_label:
		kahulugan_title_label.position = Vector2(AREA_LEFT, y)
		y += 32.0
	if meaning_label:
		meaning_label.add_theme_font_size_override("font_size", meaning_size)
		meaning_label.position = Vector2(175.0, y)
		meaning_label.size = Vector2(AREA_RIGHT - 175.0, 0)
		var h := _text_height(meaning_label, meaning_size)
		if book_icon:
			# Level with the first line of the meaning.
			var first_line := meaning_label.get_theme_font("font").get_height(meaning_size)
			book_icon.position.y = y + first_line / 2.0 - book_icon.size.y / 2.0
			h = maxf(h, book_icon.position.y + book_icon.size.y - y)
		y += h + 10.0
	if cultural_note_label and cultural_note_label.visible:
		if cultural_note_title_label:
			cultural_note_title_label.position = Vector2(AREA_LEFT, y)
			y += 32.0
		cultural_note_label.add_theme_font_size_override("font_size", note_size)
		cultural_note_label.position = Vector2(AREA_LEFT, y)
		cultural_note_label.size = Vector2(AREA_RIGHT - AREA_LEFT, 0)
		y += _text_height(cultural_note_label, note_size)
	return y

## Height of a word-wrapped label's text at the given font size.
func _text_height(label: Label, font_size: int) -> float:
	var font := label.get_theme_font("font")
	var text_size := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, label.size.x, font_size)
	var lines := roundf(text_size.y / font.get_height(font_size))
	return text_size.y + label.get_theme_constant("line_spacing") * maxf(lines - 1.0, 0.0)

func _on_speaker_pressed() -> void:
	if _current_audio_filename != "":
		Global.play_word_audio(_current_audio_filename)

func _on_close_pressed() -> void:
	hide()
