extends Button

# Status kung naka-lock na (gaya ng pre-filled letters)
var is_locked: bool = false

# Dito natin itatago kung saang tile sa baba nanggaling 'yung letter
var stored_origin_button: Button = null

func _can_drop_data(_at_position, data):
	# Kung locked na ang slot, bawal nang lagyan ng panibagong letter
	if is_locked:
		return false
	return data is Dictionary and data.has("letter")

func _drop_data(_at_position, data):
	var origin_button = data["origin_button"]
	
	# Kung may nakalagay nang letter sa slot na 'to dati, ibalik muna sa pinanggalingan nito
	if stored_origin_button != null and stored_origin_button != origin_button:
		stored_origin_button.text = text
	
	# 1. Kunin ang letter at ilagay sa slot na ito
	text = data["letter"]
	stored_origin_button = origin_button
	
	# 2. CLEAR THE ORIGIN: Burahin ang letra sa pinanggalingang tile sa baba!
	if origin_button and origin_button != self:
		origin_button.text = ""
	
	# 3. Tawagin ang main script para i-check kung buo na ang salita
	var main_node = get_tree().current_scene
	if main_node.has_method("check_answer"):
		main_node.check_answer()

# 'PAG KINLICK ANG ANSWERSLOT: Ibalik ang letter sa pinanggalingan sa baba!
func _pressed():
	if is_locked:
		return
		
	if text != "" and stored_origin_button != null:
		# Ibabalik ang text sa dating tile sa baba
		stored_origin_button.text = text
		
		# Lilinisin ang Answer Slot na ito
		text = ""
		stored_origin_button = null
		
		# I-check ulit ang answer pagkatapos alisin ang letter
		var main_node = get_tree().current_scene
		if main_node.has_method("check_answer"):
			main_node.check_answer()
