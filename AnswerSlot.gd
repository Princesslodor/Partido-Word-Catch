extends Button

# Status kung naka-lock na (gaya ng pre-filled letters)
var is_locked: bool = false

func _can_drop_data(_at_position, data):
	# Kung locked na ang slot, bawal nang lagyan ng panibagong letter
	if is_locked:
		return false
	return data is Dictionary and data.has("letter")

func _drop_data(_at_position, data):
	var origin_button = data["origin_button"]
	
	# 1. Kunin ang letter at ilagay sa slot na ito
	text = data["letter"]
	
	# 2. CLEAR THE ORIGIN: Burahin ang letra sa pinanggalingang tile sa baba!
	if origin_button and origin_button != self:
		origin_button.text = ""
	
	# 3. Tawagin ang main script para i-check kung buo na ang salita
	var main_node = get_tree().current_scene
	if main_node.has_method("check_answer"):
		main_node.check_answer()
