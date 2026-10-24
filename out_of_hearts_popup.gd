class_name OutOfHeartsPopup
extends Control
## The "Ubos na ang Buhay!" window shown on the level screens when hearts
## run out: a countdown until all hearts come back, a button to buy one
## heart with coins, and a button back to the map. Also holds the heart
## pop-out animation played when hearts come back.
##
## Built in code on the project's 720x1280 design canvas (fixed pixel
## positions, like the rest of the UI) so all three level scenes share it.

signal restore_pressed
signal back_pressed

const HEART_TEXTURE := preload("res://images/heart.png")
const TITLE_FONT := preload("res://Fredoka-Bold.ttf")
const TIMER_FONT := preload("res://LuckiestGuy-Regular.ttf")
const BODY_FONT := preload("res://Nunito-Bold.ttf")

const RED := Color(0.86, 0.2, 0.32)
const PINK := Color(1.0, 0.88, 0.91)
const CREAM := Color(1.0, 0.97, 0.92)

var _panel: Panel
var _timer_label: Label
var _timer_heart: TextureRect
var _restore_button: Button
var _empty_hearts: Array[TextureRect] = []

static func create(cost: int, max_hearts: int) -> OutOfHeartsPopup:
	var popup := OutOfHeartsPopup.new()
	popup._build(cost, max_hearts)
	return popup

func _build(cost: int, max_hearts: int) -> void:
	name = "OutOfHeartsModal"
	position = Vector2.ZERO
	size = Vector2(720, 1280)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = Vector2(720, 1280)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", _box(CREAM, RED, 6, 36, true))
	_panel.position = Vector2(110, 395)
	_panel.size = Vector2(500, 490)
	_panel.pivot_offset = _panel.size / 2
	add_child(_panel)

	# Four grey hearts: the ones that will all come back together.
	var row_width := max_hearts * 70 - 10
	for i in max_hearts:
		var heart := _heart_icon(60)
		heart.position = Vector2((500 - row_width) / 2.0 + i * 70, 28)
		heart.modulate = Color(0.55, 0.55, 0.55, 0.55)
		_panel.add_child(heart)
		_empty_hearts.append(heart)

	var title := _label("Ubos na ang Buhay!", TITLE_FONT, 40, RED)
	title.position = Vector2(20, 98)
	title.size = Vector2(460, 50)
	_panel.add_child(title)

	var message := _label("Hintayin ang orasan para bumalik ang lahat ng %d buhay mo." % max_hearts, BODY_FONT, 20, Color(0.3, 0.25, 0.22))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	message.position = Vector2(40, 152)
	message.size = Vector2(420, 60)
	_panel.add_child(message)

	# The countdown, in a pink pill with a beating heart.
	var pill := Panel.new()
	pill.add_theme_stylebox_override("panel", _box(PINK, Color(0.95, 0.55, 0.65), 4, 40, false))
	pill.position = Vector2(95, 222)
	pill.size = Vector2(310, 84)
	_panel.add_child(pill)

	_timer_heart = _heart_icon(56)
	_timer_heart.position = Vector2(24, 14)
	_timer_heart.pivot_offset = Vector2(28, 28)
	pill.add_child(_timer_heart)

	_timer_label = _label("--:--", TIMER_FONT, 52, RED)
	_timer_label.position = Vector2(90, 8)
	_timer_label.size = Vector2(200, 70)
	pill.add_child(_timer_label)

	_restore_button = Button.new()
	_restore_button.text = "Ibalik ang 1 Buhay (%d Barya)" % cost
	_restore_button.add_theme_font_override("font", BODY_FONT)
	_restore_button.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var bg := Color(0.96, 0.6, 0.16) if state != "pressed" else Color(0.88, 0.5, 0.1)
		_restore_button.add_theme_stylebox_override(state, _box(bg, Color(0.8, 0.42, 0.05), 3, 30, false))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		_restore_button.add_theme_color_override(c, Color.WHITE)
	_restore_button.position = Vector2(50, 330)
	_restore_button.size = Vector2(400, 62)
	_restore_button.pressed.connect(func(): restore_pressed.emit())
	_panel.add_child(_restore_button)

	var back := Button.new()
	back.text = "Bumalik sa Mapa"
	back.add_theme_font_override("font", BODY_FONT)
	back.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus"]:
		back.add_theme_stylebox_override(state, _box(Color(0.42, 0.62, 0.32), Color(0.3, 0.48, 0.22), 3, 26, false))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(c, Color.WHITE)
	back.position = Vector2(140, 410)
	back.size = Vector2(220, 52)
	back.pressed.connect(func(): back_pressed.emit())
	_panel.add_child(back)

	# The heart in the timer gently beats.
	var beat := create_tween().set_loops()
	beat.tween_property(_timer_heart, "scale", Vector2(1.15, 1.15), 0.45).set_trans(Tween.TRANS_SINE)
	beat.tween_property(_timer_heart, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)

## Shows the window with a little pop.
func open() -> void:
	if visible and _panel.scale == Vector2.ONE:
		return
	show()
	_panel.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_time_text(text: String) -> void:
	_timer_label.text = text if text != "" else "--:--"

func set_can_buy(can_buy: bool) -> void:
	_restore_button.disabled = not can_buy
	_restore_button.modulate = Color(1, 1, 1, 1) if can_buy else Color(1, 1, 1, 0.5)

## Plays the "hearts are back" animation over `parent`: `count` hearts pop
## out one after another in the middle of the screen with a "+N Buhay!"
## label, then fly to `target` (the hearts counter's global position)
## and fade. Safe to call with nothing else on screen.
static func play_heart_pop(parent: Node, count: int, target: Vector2) -> void:
	if parent == null or count <= 0:
		return
	var layer := Control.new()
	layer.name = "HeartPop"
	layer.size = Vector2(720, 1280)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(layer)
	target = layer.get_global_transform().affine_inverse() * target

	var size := 110.0
	var gap := 22.0
	var row := count * size + (count - 1) * gap
	var start_x := (720.0 - row) / 2.0
	var y := 560.0
	var last_delay := 0.0
	for i in count:
		var heart := TextureRect.new()
		heart.texture = HEART_TEXTURE
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size = Vector2(size, size)
		heart.pivot_offset = heart.size / 2
		heart.position = Vector2(start_x + i * (size + gap), y)
		heart.scale = Vector2.ZERO
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(heart)
		var delay := 0.15 * i
		last_delay = delay
		var t := heart.create_tween()
		t.tween_interval(delay)
		t.tween_property(heart, "scale", Vector2(1.35, 1.35), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(heart, "scale", Vector2.ONE, 0.15)
		t.tween_interval(0.7 + 0.15 * (count - 1 - i))
		t.set_parallel(true)
		t.tween_property(heart, "position", target - heart.size / 2, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(heart, "scale", Vector2(0.35, 0.35), 0.5)
		t.tween_property(heart, "modulate:a", 0.0, 0.5).set_delay(0.3)

	var text := Label.new()
	text.text = "+%d Buhay!" % count
	text.add_theme_font_override("font", TIMER_FONT)
	text.add_theme_font_size_override("font_size", 56)
	text.add_theme_color_override("font_color", Color(1, 0.95, 0.95))
	text.add_theme_color_override("font_outline_color", RED)
	text.add_theme_constant_override("outline_size", 14)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.size = Vector2(720, 80)
	text.position = Vector2(0, y + size + 30)
	text.pivot_offset = text.size / 2
	text.scale = Vector2.ZERO
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(text)
	var tt := text.create_tween()
	tt.tween_interval(last_delay + 0.1)
	tt.tween_property(text, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tt.tween_interval(0.9)
	tt.tween_property(text, "modulate:a", 0.0, 0.4)

	var cleanup := layer.create_tween()
	cleanup.tween_interval(last_delay + 2.2)
	cleanup.tween_callback(layer.queue_free)

func _heart_icon(px: float) -> TextureRect:
	var heart := TextureRect.new()
	heart.texture = HEART_TEXTURE
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.size = Vector2(px, px)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return heart

func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _box(bg: Color, border: Color, border_width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	if shadow:
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = 12
		box.shadow_offset = Vector2(0, 6)
	return box
