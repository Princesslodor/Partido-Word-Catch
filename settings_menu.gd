extends Control

# --- SCENE NODE REFERENCES ---
@onready var close_button: BaseButton = $BackgroundOverlay/PopupBoard/CloseButton if has_node("BackgroundOverlay/PopupBoard/CloseButton") else null
@onready var quit_game_button: BaseButton = $BackgroundOverlay/PopupBoard/QuitButton if has_node("BackgroundOverlay/PopupBoard/QuitButton") else null

# Custom Toggles
@onready var sound_toggle: Button = $BackgroundOverlay/PopupBoard/CustomToggle/Panel/SoundRow/SoundToggle if has_node("BackgroundOverlay/PopupBoard/CustomToggle/Panel/SoundRow/SoundToggle") else null
@onready var music_toggle: Button = $BackgroundOverlay/PopupBoard/CustomToggle/Panel/MusicRow/MusicToggle if has_node("BackgroundOverlay/PopupBoard/CustomToggle/Panel/MusicRow/MusicToggle") else null

func _ready():
	hide()
	_fix_mouse_filters()
	_connect_signals()
	_load_saved_settings()

func _fix_mouse_filters():
	if has_node("BackgroundOverlay"):
		$BackgroundOverlay.mouse_filter = Control.MOUSE_FILTER_PASS
	if has_node("BackgroundOverlay/PopupBoard"):
		$BackgroundOverlay/PopupBoard.mouse_filter = Control.MOUSE_FILTER_PASS

func _connect_signals():
	# Navigation Signals
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	if quit_game_button and not quit_game_button.pressed.is_connected(_on_quit_pressed):
		quit_game_button.pressed.connect(_on_quit_pressed)

	# Audio Toggle Signals
	if sound_toggle and not sound_toggle.toggle_changed.is_connected(_on_sound_toggled):
		sound_toggle.toggle_changed.connect(_on_sound_toggled)

	if music_toggle and not music_toggle.toggle_changed.is_connected(_on_music_toggled):
		music_toggle.toggle_changed.connect(_on_music_toggled)

# --- NAVIGATION LOGIC ---
func _on_close_pressed():
	hide()

func _on_quit_pressed():
	# Dynamic search para sa ExitConfirmationPopup
	var exit_popup = get_node_or_null("../ExitConfirmationPopup")
	if not exit_popup:
		exit_popup = get_tree().root.find_child("ExitConfirmationPopup", true, false)

	if exit_popup:
		if exit_popup.has_method("open_popup"):
			exit_popup.open_popup()
		else:
			exit_popup.show()
			exit_popup.move_to_front()
	else:
		print("ERROR: Hindi mahanap ang ExitConfirmationPopup node!")

# --- AUDIO LOGIC ---
func _on_sound_toggled(is_on: bool):
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not is_on)

func _on_music_toggled(is_on: bool):
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not is_on)

func _load_saved_settings():
	if sound_toggle and "is_on" in sound_toggle:
		sound_toggle.is_on = true
	if music_toggle and "is_on" in music_toggle:
		music_toggle.is_on = true
