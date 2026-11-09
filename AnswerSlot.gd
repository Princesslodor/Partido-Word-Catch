extends Button

var is_locked: bool = false
var current_origin_button: Button = null

func _ready():
	# Grow a little with a highlight on hover, instead of the flat box.
	Global.setup_tile_hover(self)

# Text gets swapped from many places (drop, tap to clear, hints), so check
# each frame and resize the font whenever the word changes.
var _fitted_text: String = "<not fitted yet>"
func _process(_delta):
	if text != _fitted_text:
		_fitted_text = text
		Global.fit_text_to_box(self)
	_update_answer_light()

# The box lights up yellow when its letter (or word) is right, red when wrong.
const LIGHT_CORRECT := Color(1.0, 0.86, 0.15)
const LIGHT_WRONG := Color(1.0, 0.36, 0.32)
var _lit_for: String = ""

func _update_answer_light():
	var scene = get_tree().current_scene
	if scene == null:
		return
	# A new level can leave the same letter in a box, so the level counts too.
	var key := text + "|" + str(scene.get("current_level"))
	if key == _lit_for:
		return
	_lit_for = key
	var shown := text.strip_edges().to_upper()
	if shown == "":
		self_modulate = Color.WHITE
	elif shown == _expected_answer(scene):
		self_modulate = LIGHT_CORRECT
	else:
		self_modulate = LIGHT_WRONG

func _expected_answer(scene) -> String:
	if "current_sentence_words" in scene:
		var words: Array = scene.current_sentence_words
		var index: int = scene._get_all_answer_slots().find(self)
		if index >= 0 and index < words.size():
			return str(words[index]).strip_edges().to_upper()
	elif "current_word" in scene:
		var word: String = scene.current_word
		if get_index() < word.length():
			return word[get_index()]
	return ""

func _can_drop_data(_at_position, data):
	if is_locked:
		return false
	return data is Dictionary and data.has("letter")

func _drop_data(_at_position, data):
	var dropped_letter = data["letter"]
	var origin_btn = data["origin_button"]
	
	# Kung may laman na ang slot na ito dati, ibalik muna ang lumang letter sa pinanggalingan nito
	if text != "" and current_origin_button != null:
		current_origin_button.text = current_origin_button.cached_letter
	
	# Ilagay ang bagong letter sa slot
	text = dropped_letter
	Global.bounce(self)
	current_origin_button = origin_btn
	
	# Siguraduhing blangko ang pinanggalingang tile sa baba (may maiwang space)
	if origin_btn:
		origin_btn.text = ""
	
	# I-check ang sagot sa main scene
	var main_node = get_tree().current_scene
	if main_node.has_method("check_answer"):
		main_node.check_answer()

func _pressed():
	if is_locked or text == "":
		return
		
	# Kapag pinindot ang AnswerSlot para tanggalin ang letter, ibalik ito sa pinanggalingang tile
	if current_origin_button != null:
		current_origin_button.text = current_origin_button.cached_letter
		
	text = ""
	current_origin_button = null
	
	var main_node = get_tree().current_scene
	if main_node.has_method("check_answer"):
		main_node.check_answer()
