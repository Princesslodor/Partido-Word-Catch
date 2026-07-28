extends Button

var is_locked: bool = false
var current_origin_button: Button = null

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
