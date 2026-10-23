extends Node
## Makes every screen fill the whole phone, with no black bars.
##
## Every screen is laid out on a 720x1280 canvas, but phones come in many
## shapes (tall 20:9 phones, wider tablets). project.godot uses the "expand"
## stretch aspect, so the game gets the phone's real shape instead of black
## bars. This autoload then:
##   - keeps each screen's 720x1280 layout centred, at its normal size;
##   - enlarges that screen's own background picture until it covers the
##     whole phone, edge to edge (a little of its sides is cropped on a tall
##     phone), so there are no bars or visible seams;
##   - moves things drawn on top of the picture (the level stones on the
##     campaign map, in ON_BACKGROUND_GROUP) along with it;
##   - stretches full-screen dimmers (popup overlays) over the whole phone.

const DESIGN := Vector2(720, 1280)
## Controls in this group sit on a spot of the background picture and move
## with it when it is enlarged (they keep their size).
const ON_BACKGROUND_GROUP := "screen_fit_on_background"

var _scene: Node = null
var _offset := Vector2.ZERO
# Full-screen backgrounds in the current scene, in tree order; the first
# visible one is drawn enlarged behind everything.
var _backgrounds: Array = []
var _cover_layer: CanvasLayer
var _cover: TextureRect
# The background currently drawn by _cover (its own drawing is hidden).
var _covered_bg: CanvasItem = null

func _ready() -> void:
	_cover_layer = CanvasLayer.new()
	_cover_layer.layer = -100
	add_child(_cover_layer)
	_cover = TextureRect.new()
	_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cover.stretch_mode = TextureRect.STRETCH_SCALE
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.hide()
	_cover_layer.add_child(_cover)
	get_tree().node_added.connect(_on_node_added)
	get_viewport().size_changed.connect(func(): _scene = null)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_scene = scene
		if scene:
			_fit_scene(scene)
	_update_cover()

func _fit_scene(scene: Node) -> void:
	var visible_size := get_viewport().get_visible_rect().size
	_offset = ((visible_size - DESIGN) / 2.0).floor()
	_offset = _offset.max(Vector2.ZERO)

	# Find the backgrounds before moving anything, while their rects are
	# still on the 720x1280 canvas.
	_backgrounds.clear()
	_collect_backgrounds(scene)

	if scene is Control:
		_pin_to_design(scene, _offset)
	elif scene is Node2D:
		if not scene.has_meta("screen_fit_base"):
			scene.set_meta("screen_fit_base", scene.position)
		scene.position = scene.get_meta("screen_fit_base") + _offset
	scene.set_meta("screen_fit_done", true)
	_shift_layers(scene)
	_extend_dims(scene)
	_extend_scrolls(scene)
	_move_with_backgrounds(scene)

func _shift_layers(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			if not child.has_meta("screen_fit_base"):
				child.set_meta("screen_fit_base", child.offset)
			child.offset = child.get_meta("screen_fit_base") + _offset
			# Controls sitting straight on a layer are anchored to the real
			# screen; pin them to the 720x1280 layout like the root.
			for item in child.get_children():
				if item is Control:
					_pin_to_design(item, Vector2.ZERO)
		_shift_layers(child)

## Gives a control the same rect it would have on a 720x1280 screen (with
## no anchors, so the real screen size can't move it), plus shift.
func _pin_to_design(c: Control, shift: Vector2) -> void:
	if not c.has_meta("screen_fit_base"):
		c.set_meta("screen_fit_base", Rect2(
			Vector2(c.anchor_left * DESIGN.x + c.offset_left, c.anchor_top * DESIGN.y + c.offset_top),
			Vector2((c.anchor_right - c.anchor_left) * DESIGN.x + c.offset_right - c.offset_left,
				(c.anchor_bottom - c.anchor_top) * DESIGN.y + c.offset_bottom - c.offset_top)))
	var base: Rect2 = c.get_meta("screen_fit_base")
	c.anchor_left = 0.0
	c.anchor_top = 0.0
	c.anchor_right = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = base.position.x + shift.x
	c.offset_top = base.position.y + shift.y
	c.offset_right = base.end.x + shift.x
	c.offset_bottom = base.end.y + shift.y

## A background is a picture that covers (almost) the whole 720x1280 canvas.
func _collect_backgrounds(node: Node) -> void:
	for child in node.get_children():
		if child is TextureRect or child is Sprite2D:
			if child.texture and _canvas_rect(child).encloses(Rect2(Vector2(8, 8), DESIGN - Vector2(16, 16))):
				_backgrounds.append(child)
		if not (child is CanvasLayer and child.get_parent() == self):
			_collect_backgrounds(child)

## The item's rect on its own canvas, without the centring offset.
func _canvas_rect(item: CanvasItem) -> Rect2:
	var rect: Rect2
	if item is Control:
		rect = item.get_global_rect()
	else:
		rect = item.global_transform * item.get_rect()
	if not _in_layer(item):
		rect.position -= _current_root_offset(item)
	return rect

func _in_layer(item: Node) -> bool:
	var p := item.get_parent()
	while p:
		if p is CanvasLayer:
			return true
		p = p.get_parent()
	return false

func _current_root_offset(item: Node) -> Vector2:
	var scene := get_tree().current_scene
	if scene and scene.is_ancestor_of(item):
		if scene is Control or scene is Node2D:
			return _offset if scene.has_meta("screen_fit_done") else Vector2.ZERO
	return Vector2.ZERO

## How much a background must grow, around its own centre, to cover the
## whole phone. Works on its rect on the 720x1280 canvas.
func _cover_scale(rect: Rect2) -> float:
	if _offset == Vector2.ZERO or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return 1.0
	var visible_size := get_viewport().get_visible_rect().size
	var c := rect.get_center()
	var half := rect.size / 2.0
	# The phone's edges, in canvas coordinates.
	var top_left := -_offset
	var bottom_right := visible_size - _offset
	return maxf(1.0, maxf(
		maxf((c.x - top_left.x) / half.x, (bottom_right.x - c.x) / half.x),
		maxf((c.y - top_left.y) / half.y, (bottom_right.y - c.y) / half.y)))

func _update_cover() -> void:
	var bg: CanvasItem = null
	for item in _backgrounds:
		if is_instance_valid(item) and item.is_visible_in_tree():
			bg = item
			break
	if bg != _covered_bg:
		_show_own_drawing(_covered_bg)
		_covered_bg = null
	if bg == null or _offset == Vector2.ZERO or bg.get("texture") == null:
		_cover.hide()
		return
	var rect := _canvas_rect(bg)
	var s := _cover_scale(rect)
	_cover.texture = bg.texture
	_cover.size = rect.size * s
	_cover.position = rect.get_center() - _cover.size / 2.0 + _offset
	_cover.modulate = bg.modulate
	_cover.show()
	if _covered_bg == null:
		# Hide only the picture itself; anything inside it still shows.
		_covered_bg = bg
		if not bg.has_meta("screen_fit_self_modulate"):
			bg.set_meta("screen_fit_self_modulate", bg.self_modulate)
		bg.self_modulate.a = 0.0

func _show_own_drawing(bg: CanvasItem) -> void:
	if is_instance_valid(bg) and bg.has_meta("screen_fit_self_modulate"):
		bg.self_modulate = bg.get_meta("screen_fit_self_modulate")

## Keeps the level stones on their spot of the enlarged campaign map: each
## one's centre is moved the way the picture grows around its centre.
func _move_with_backgrounds(scene: Node) -> void:
	for node in get_tree().get_nodes_in_group(ON_BACKGROUND_GROUP):
		if not (node is Control) or not scene.is_ancestor_of(node):
			continue
		var bg: CanvasItem = null
		for item in _backgrounds:
			if is_instance_valid(item) and item.get_parent() == node.get_parent():
				bg = item
				break
		if bg == null:
			continue
		if not node.has_meta("screen_fit_bg_position"):
			node.set_meta("screen_fit_bg_position", node.position)
		var base: Vector2 = node.get_meta("screen_fit_bg_position")
		var rect := _canvas_rect(bg)
		var s := _cover_scale(rect)
		# The control's centre, on the canvas, before moving it.
		var centre: Vector2 = _canvas_rect(node).get_center() - (node.position - base)
		var moved := rect.get_center() + (centre - rect.get_center()) * s
		node.position = base + (moved - centre)

## A scroll area as tall as the whole canvas (the leaderboard) also runs
## down to the bottom of the phone, so it isn't cut off above the edge, and
## what scrolls up past its top keeps showing up to the top of the phone
## instead of being cut off in a straight line.
func _extend_scrolls(node: Node) -> void:
	for child in node.get_children():
		if child is ScrollContainer and child.size.y >= DESIGN.y - 1.0 and not child.has_meta("screen_fit_scroll"):
			child.set_meta("screen_fit_scroll", true)
			child.size.y += _offset.y
			if _offset.y > 0.0:
				child.clip_contents = false
		_extend_scrolls(child)

func _on_node_added(node: Node) -> void:
	if node is ColorRect and _scene and _scene.is_ancestor_of(node):
		_extend_dim.call_deferred(node)

func _extend_dims(node: Node) -> void:
	for child in node.get_children():
		if child is ColorRect:
			_extend_dim(child)
		_extend_dims(child)

## A colour rect as big as the whole canvas is a dimmer behind a popup.
## Its popup box is often its child, so instead of moving it, a copy of its
## colour that covers the whole phone goes underneath its children and the
## original is made see-through (it still blocks taps as before).
func _extend_dim(rect: ColorRect) -> void:
	if not is_instance_valid(rect) or rect.has_meta("screen_fit_dim") or _offset == Vector2.ZERO:
		return
	if rect.size.x < DESIGN.x - 1.0 or rect.size.y < DESIGN.y - 1.0 or rect.get_global_transform().get_scale() != Vector2.ONE:
		return
	rect.set_meta("screen_fit_dim", true)
	var fill := ColorRect.new()
	fill.set_meta("screen_fit_dim", true)
	fill.name = "ScreenFitFill"
	fill.color = rect.color
	fill.mouse_filter = rect.mouse_filter
	var target := -_offset if _in_layer(rect) else Vector2.ZERO
	fill.position = target - rect.global_position
	fill.size = get_viewport().get_visible_rect().size
	rect.add_child(fill)
	rect.move_child(fill, 0)
	rect.self_modulate.a = 0.0
