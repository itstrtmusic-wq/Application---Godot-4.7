@tool
extends Control
## A compact, keyboard-accessible selection between related views.

signal selection_changed(index: int)

const Style = preload("res://addons/forma_ui/shared/style.gd")

@export var options: PackedStringArray = ["Overview", "Details", "Activity"]:
	set(value):
		options = value
		selected = selected
		update_minimum_size()
		queue_redraw()
@export var selected: int = 0:
	set(value):
		selected = clampi(value, 0, options.size() - 1) if not options.is_empty() else -1
		queue_redraw()
@export var disabled: bool = false:
	set(value):
		disabled = value
		focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL
		queue_redraw()

var _hovered: int = -1

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	theme_changed.connect(func() -> void:
		update_minimum_size()
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hovered = -1
		queue_redraw())

func _get_minimum_size() -> Vector2:
	var widest: float = 48.0
	var font: Font = Style.font(self)
	for option in options:
		widest = maxf(widest, font.get_string_size(option, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.font_size(self)).x + 28.0)
	return Vector2(maxf(120.0, widest * options.size() + 8.0), 44.0)

## Select an item. Inspector assignments do not emit signals; this method does.
func select(index: int, emit_signal: bool = true) -> void:
	var previous: int = selected
	selected = index
	if emit_signal and selected != previous:
		selection_changed.emit(selected)

func _gui_input(event: InputEvent) -> void:
	if disabled or options.is_empty():
		return
	if event is InputEventMouseMotion:
		_hovered = _index_at(event.position)
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		select(_index_at(event.position))
		accept_event()
	elif event is InputEventKey and event.pressed:
		var next: int = selected
		match event.keycode:
			KEY_LEFT, KEY_UP:
				next = maxi(0, selected - 1)
			KEY_RIGHT, KEY_DOWN:
				next = mini(options.size() - 1, selected + 1)
			KEY_HOME:
				next = 0
			KEY_END:
				next = options.size() - 1
			_:
				return
		select(next)
		accept_event()

func _index_at(point: Vector2) -> int:
	if options.is_empty():
		return -1
	return clampi(int((point.x - 4.0) / maxf(1.0, (size.x - 8.0) / options.size())), 0, options.size() - 1)

func _draw() -> void:
	var opacity: float = 0.45 if disabled else 1.0
	var border: Color = Style.color(self, &"accent") if has_focus() else Style.color(self, &"border")
	draw_style_box(Style.box(Style.color(self, &"background"), border), Rect2(Vector2.ZERO, size))
	if options.is_empty():
		return
	var width: float = (size.x - 8.0) / options.size()
	var font: Font = Style.font(self)
	var font_size: int = Style.font_size(self)
	for index in options.size():
		var rect := Rect2(4.0 + index * width, 4.0, width, size.y - 8.0)
		if index == selected:
			var fill: Color = Style.color(self, &"accent_soft")
			fill.a *= opacity
			draw_style_box(Style.box(fill, Color.TRANSPARENT, 7), rect)
		elif index == _hovered and not disabled:
			draw_style_box(Style.box(Style.color(self, &"surface_hover"), Color.TRANSPARENT, 7), rect)
		var text_color: Color = Style.color(self, &"text") if index == selected else Style.color(self, &"muted")
		text_color.a *= opacity
		var baseline: float = rect.position.y + (rect.size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
		draw_string(font, Vector2(rect.position.x + 8.0, baseline), options[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, text_color)
