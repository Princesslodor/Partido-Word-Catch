extends Button

var cached_letter: String = ""
# True only on the tile a drag started from. Every Control gets the
# drag-end notification, so without this a missed drop would refill all
# the emptied tiles, including ones whose word is already in an answer box.
var _is_drag_source: bool = false

func _ready():
	# Grow a little with a highlight on hover, instead of the flat box.
	Global.setup_tile_hover(self)

# Text gets swapped from many places (drag, drop, hints, shuffle), so check
# each frame and resize the font whenever the word changes.
var _fitted_text: String = "<not fitted yet>"
func _process(_delta):
	if text != _fitted_text:
		_fitted_text = text
		Global.fit_text_to_box(self)

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
	_is_drag_source = true
	return drag_data

func _notification(what):
	if what == NOTIFICATION_DRAG_END and _is_drag_source:
		_is_drag_source = false
		# Kung binitawan sa labas (hindi tinanggap ng AnswerSlot), ibalik ang letrang hinawakan
		if not is_drag_successful():
			if text == "":
				text = cached_letter
