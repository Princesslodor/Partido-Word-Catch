extends Button

var cached_letter: String = ""

func set_letter(new_letter: String):
	text = new_letter
	cached_letter = new_letter

func _get_drag_data(_at_position):
	if text == "":
		return null
		
	# I-save muna natin ang letrang kasalukuyang hawak nito
	cached_letter = text
	
	var drag_data = {
		"origin_button": self,
		"letter": text
	}
	
	# Kunin ang buong itsura ng tile para sa drag preview
	var preview_button = self.duplicate()
	preview_button.custom_minimum_size = size
	preview_button.size = size
	
	var control = Control.new()
	control.add_child(preview_button)
	preview_button.position = -size / 2.0
	set_drag_preview(control)
	
	# Pansamantalang gawing blangko ang pinanggalingan para may maiwang space
	text = ""
	return drag_data

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# Kung binitawan sa labas (hindi tinanggap ng AnswerSlot), ibalik ang letrang hinawakan
		if not is_drag_successful():
			if text == "":
				text = cached_letter
