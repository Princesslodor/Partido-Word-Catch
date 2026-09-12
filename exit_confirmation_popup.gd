extends Control

signal confirmed
signal canceled

# If true, confirming actually closes the whole app (get_tree().quit()).
# If false (default), confirming just navigates to confirm_target_scene -
# e.g. returning to the campaign map from inside a level is "back to menu",
# not "quit the game".
@export var quit_app: bool = false

# Saan lilipat kapag pinindot ang "Oo" (confirm), kapag quit_app == false.
# Ipapalit ito depende sa kung saan naka-instance ang popup na ito - e.g.
# login page kapag mula sa campaign map, o campaign map kapag mula sa loob
# ng isang level.
@export_file("*.tscn") var confirm_target_scene: String = "res://login_page.tscn"

# Optional override for the popup's message, so it can say something more
# specific than the default "leave the game?" wording (e.g. "return to the
# map?" when this instance isn't actually quitting the app).
@export var confirm_message: String = ""

# Node references batay sa button names ("Hindi" at "Oo")
@onready var no_button: Button = $BackgroundOverlay/ExitConfirmationBackground/CancelButton if has_node("BackgroundOverlay/ExitConfirmationBackground/CancelButton") else null
@onready var yes_button: Button = $BackgroundOverlay/ExitConfirmationBackground/OkButton if has_node("BackgroundOverlay/ExitConfirmationBackground/OkButton") else null
@onready var message_label: Label = $BackgroundOverlay/ExitConfirmationBackground/Label if has_node("BackgroundOverlay/ExitConfirmationBackground/Label") else null

func _ready():
	hide()
	mouse_filter = Control.MOUSE_FILTER_PASS
	if message_label and confirm_message != "":
		message_label.text = confirm_message
	_connect_signals()

func _connect_signals():
	if no_button and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)
		
	if yes_button and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)

func open_popup():
	show()
	move_to_front()

func _on_no_pressed():
	emit_signal("canceled")
	hide()

func _on_yes_pressed():
	emit_signal("confirmed")
	hide()
	if quit_app:
		get_tree().quit()
	else:
		get_tree().change_scene_to_file(confirm_target_scene)
