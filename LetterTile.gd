extends Button

# Function para madaling lagyan ng titik ang tile mula sa main script
func set_letter(new_letter: String):
	text = new_letter

func _get_drag_data(_at_position):
	# Huwag payagang i-drag kung walang nakasulat na letra
	if text == "":
		return null
		
	var drag_data = {
		"origin_button": self,
		"letter": text
	}
	
	# 1. Kopyahin ang MISMONG Button (duplicate) para sa drag preview
	var preview_button = self.duplicate()
	
	# Siguraduhing maayos ang laki
	preview_button.custom_minimum_size = size
	preview_button.size = size
	
	var control = Control.new()
	control.add_child(preview_button)
	
	# I-center sa ilalim ng cursor/daliri habang dino-drag
	preview_button.position = -size / 2.0
	
	set_drag_preview(control)
	
	# 2. Instant Hide: Mawawala ang text sa lumang pwesto habang dino-drag
	text = ""
	
	return drag_data
