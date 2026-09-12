extends Control

signal confirmed
signal canceled

# Saan lilipat kapag pinindot ang "Oo" (confirm). Ipapalit ito depende sa
# kung saan naka-instance ang popup na ito - e.g. login page kapag mula sa
# campaign map, o campaign map kapag mula sa loob ng isang level.
@export_file("*.tscn") var confirm_target_scene: String = "res://login_page.tscn"

# Node references batay sa button names ("Hindi" at "Oo")
@onready var no_button: Button = $BackgroundOverlay/ExitConfirmationBackground/CancelButton if has_node("BackgroundOverlay/ExitConfirmationBackground/CancelButton") else null
@onready var yes_button: Button = $BackgroundOverlay/ExitConfirmationBackground/OkButton if has_node("BackgroundOverlay/ExitConfirmationBackground/OkButton") else null

func _ready():
	hide()
	mouse_filter = Control.MOUSE_FILTER_PASS
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
	get_tree().change_scene_to_file(confirm_target_scene)
