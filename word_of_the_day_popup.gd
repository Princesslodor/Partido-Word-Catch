extends Control

@onready var word_label: Label = $WordLabel if has_node("WordLabel") else null
@onready var syllable_label: Label = $SyllableLabel if has_node("SyllableLabel") else null
@onready var meaning_label: Label = $MeaningLabel if has_node("MeaningLabel") else null
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
# Largest and smallest font sizes for the meaning.
const MEANING_FONT_MAX: int = 30
const BODY_FONT_MIN: int = 15

func _ready() -> void:
	hide()
	if close_button and not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.pressed.connect(_on_close_pressed)

func display_word(word_data: Dictionary) -> void:
	if word_data.is_empty():
		return
	if word_label:
		word_label.text = str(word_data.get("word", ""))
	if meaning_label:
		meaning_label.text = str(word_data.get("meaning", ""))
	# Syllables and part of speech as written in the Glosaryo, e.g.
	# "ba-dang (pangngaran)". Hidden when an entry has neither.
	if syllable_label:
		var line: String = str(word_data.get("syllables", "")).strip_edges()
		var pos: String = str(word_data.get("part_of_speech", "")).strip_edges()
		if pos != "":
			line = (line + " (" + pos + ")").strip_edges()
		syllable_label.text = line
		syllable_label.visible = line != ""

	_layout()
	show()
	move_to_front()

## Stacks the sections from the top of the parchment, skipping hidden ones,
## so there are no empty gaps. If a long meaning would run past the bottom,
## it shrinks a step at a time until everything fits inside.
func _layout() -> void:
	var meaning_size := MEANING_FONT_MAX
	while _place_sections(meaning_size) > AREA_BOTTOM and meaning_size > BODY_FONT_MIN:
		meaning_size -= 1

## Positions every section for the given meaning font size and returns the y where
## the last one ends.
func _place_sections(meaning_size: int) -> float:
	var y := AREA_TOP
	if salita_title_label:
		salita_title_label.position = Vector2(AREA_LEFT, y)
		y += 30.0
	if word_label:
		word_label.position.y = y
		y += _text_height(word_label, word_label.get_theme_font_size("font_size")) + 8.0
	if syllable_label and syllable_label.visible:
		syllable_label.position.y = y - 6.0
		y += _text_height(syllable_label, syllable_label.get_theme_font_size("font_size")) + 4.0
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
	return y

## Height of a word-wrapped label's text at the given font size.
func _text_height(label: Label, font_size: int) -> float:
	var font := label.get_theme_font("font")
	var text_size := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, label.size.x, font_size)
	var lines := roundf(text_size.y / font.get_height(font_size))
	return text_size.y + label.get_theme_constant("line_spacing") * maxf(lines - 1.0, 0.0)

func _on_close_pressed() -> void:
	hide()
