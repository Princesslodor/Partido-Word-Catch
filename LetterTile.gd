extends Button

func _get_drag_data(_at_position):
	if text == "":
		return null
		
	var drag_data = {
		"origin_button": self,
		"letter": text
	}
	
	# 1. Kopyahin ang MISMONG Button (duplicate) para eksaktong puting tile at font styling ang lumabas!
	var preview_button = self.duplicate()
	
	# Siguraduhing maayos ang laki at hindi nakaharang sa click
	preview_button.custom_minimum_size = size
	preview_button.size = size
	
	var control = Control.new()
	control.add_child(preview_button)
	
	# I-center sa ilalim ng cursor/daliri habang dino-drag
	preview_button.position = -size / 2.0
	
	set_drag_preview(control)
	
	# 2. Instant Hide: Mawawala agad ang text sa lumang pwesto habang dino-drag
	text = ""
	
	return drag_data
