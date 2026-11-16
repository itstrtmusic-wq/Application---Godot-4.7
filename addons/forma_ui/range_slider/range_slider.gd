@tool
extends Control
## A two-handle numeric range. Arrows move the active handle; Tab switches handles.

signal values_changed(lower: float, upper: float)
signal drag_started()
signal drag_ended()

const Style = preload("../shared/style.gd")
const HANDLE_RADIUS = 8.0
const INSET = 12.0

@export var min_value: float = 0.0:
	set(value):
		min_value = value
		_normalize()
@export var max_value: float = 100.0:
	set(value):
		max_value = value
		_normalize()
@export_range(0.0, 1000.0, 0.01, "or_greater") var step: float = 1.0:
	set(value):
		step = maxf(value, 0.0)
		_normalize()
@export var lower_value: float = 20.0:
	set(value):
		lower_value = _snap(value)
		lower_value = minf(lower_value, upper_value)
		queue_redraw()
@export var upper_value: float = 80.0:
	set(value):
		upper_value = maxf(_snap(value), lower_value)
		queue_redraw()
@export var disabled: bool = false:
	set(value):
		disabled = value
		if disabled and _dragging:
			_dragging = false
			drag_ended.emit()
		queue_redraw()

var active_handle: int = 0
var _dragging = false
var _hovered = false

func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _ready() -> void:
	_normalize()
	mouse_entered.connect(func(): _hovered = true; queue_redraw())
	mouse_exited.connect(func(): _hovered = false; queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	theme_changed.connect(queue_redraw)
	resized.connect(queue_redraw)

func _get_minimum_size() -> Vector2:
	return Vector2(140, 44)

func _snap(value: float) -> float:
	var high = maxf(min_value, max_value)
	var result = value
	if step > 0:
		result = min_value + snappedf(value - min_value, step)
	return clampf(result, min_value, high)

func _normalize() -> void:
	# Treat inverted bounds as a zero-length interval until they are corrected.
	var low = _snap(lower_value)
	var high = _snap(upper_value)
	# Set upper first so its setter cannot retain a stale, out-of-bounds lower.
	lower_value = minf(low, high)
	upper_value = maxf(low, high)
	lower_value = minf(low, high)
	queue_redraw()

func set_values(lower: float, upper: float, emit_signal: bool = true) -> void:
	var low = _snap(minf(lower, upper))
	var high = _snap(maxf(lower, upper))
	var changed = not is_equal_approx(low, lower_value) or not is_equal_approx(high, upper_value)
	# Widen first to allow assigning a new interval entirely above the old one.
	upper_value = high
	lower_value = low
	upper_value = high
	if changed and emit_signal:
		values_changed.emit(lower_value, upper_value)

func _x(value: float) -> float:
	var span = max_value - min_value
	if span <= 0:
		return INSET
	return INSET + (size.x - INSET * 2) * (value - min_value) / span

func _value_at(x: float) -> float:
	var ratio = clampf((x - INSET) / maxf(size.x - INSET * 2, 1), 0, 1)
	return _snap(lerpf(min_value, maxf(min_value, max_value), ratio))

func _move_handle(value: float) -> void:
	if active_handle == 0:
		set_values(minf(value, upper_value), upper_value)
	else:
		set_values(lower_value, maxf(value, lower_value))

func _gui_input(event: InputEvent) -> void:
	if disabled or Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus()
			var lower_distance = absf(event.position.x - _x(lower_value))
			var upper_distance = absf(event.position.x - _x(upper_value))
			if not is_equal_approx(lower_distance, upper_distance):
				active_handle = 0 if lower_distance < upper_distance else 1
			_dragging = true
			drag_started.emit()
			_move_handle(_value_at(event.position.x))
		elif _dragging:
			_dragging = false
			drag_ended.emit()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_move_handle(_value_at(event.position.x))
		accept_event()
	elif event is InputEventKey and event.pressed:
		var increment = step if step > 0 else maxf((max_value - min_value) / 100.0, 0.01)
		var current = lower_value if active_handle == 0 else upper_value
		match event.keycode:
			KEY_TAB:
				if (not event.shift_pressed and active_handle == 0) or (event.shift_pressed and active_handle == 1):
					active_handle = 1 - active_handle
				else:
					return
			KEY_LEFT, KEY_DOWN:
				_move_handle(current - increment)
			KEY_RIGHT, KEY_UP:
				_move_handle(current + increment)
			KEY_HOME:
				_move_handle(min_value)
			KEY_END:
				_move_handle(max_value)
			_:
				return
		queue_redraw()
		accept_event()

func _draw() -> void:
	var alpha = 0.4 if disabled else 1.0
	var center = size.y / 2.0
	var track_color = Style.color(self, &"border")
	track_color.a *= alpha
	var accent = Style.color(self, &"accent")
	accent.a *= alpha
	draw_style_box(Style.box(track_color, Color.TRANSPARENT, 2), Rect2(INSET, center - 2, maxf(size.x - INSET * 2, 0), 4))
	draw_style_box(Style.box(accent, Color.TRANSPARENT, 2), Rect2(_x(lower_value), center - 2, maxf(_x(upper_value) - _x(lower_value), 0), 4))
	for index in 2:
		var point = Vector2(_x(lower_value if index == 0 else upper_value), center)
		if has_focus() and active_handle == index and not disabled:
			draw_arc(point, HANDLE_RADIUS + 4, 0, TAU, 40, accent, 1.5, true)
		draw_circle(point, HANDLE_RADIUS, accent, true, -1, true)
		var dot = Style.color(self, &"background")
		dot.a *= alpha
		draw_circle(point, 2.5, dot, true, -1, true)
