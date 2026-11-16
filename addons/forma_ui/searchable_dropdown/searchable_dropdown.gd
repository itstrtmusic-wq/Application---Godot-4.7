@tool
extends Control
## Single-select dropdown with case-insensitive search and keyboard navigation.

signal selection_changed(index: int, value: String)

const Style = preload("res://addons/forma_ui/shared/style.gd")

@export var options: PackedStringArray = []:
	set(value):
		options = value
		selected = selected
		if is_instance_valid(_results):
			_filter(_search.text)
		queue_redraw()
@export var selected: int = -1:
	set(value):
		selected = clampi(value, -1, options.size() - 1)
		queue_redraw()
@export var placeholder: String = "Select an option…":
	set(value):
		placeholder = value
		queue_redraw()
@export var disabled: bool = false:
	set(value):
		disabled = value
		focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL
		if value:
			close_popup()
		queue_redraw()

var _popup: PopupPanel
var _search: LineEdit
var _results: ItemList
var _filtered := PackedInt32Array()
var _hovered: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	theme_changed.connect(_on_theme_changed)
	resized.connect(queue_redraw)
	mouse_entered.connect(func() -> void:
		_hovered = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hovered = false
		queue_redraw())

func _get_minimum_size() -> Vector2:
	return Vector2(180.0, 44.0)

func select(index: int, emit_signal: bool = true) -> void:
	var previous: int = selected
	selected = index
	if emit_signal and previous != selected:
		selection_changed.emit(selected, options[selected] if selected >= 0 else "")

func get_filtered_indices(query: String) -> PackedInt32Array:
	var matches := PackedInt32Array()
	var needle: String = query.strip_edges().to_lower()
	for index in options.size():
		if needle.is_empty() or options[index].to_lower().contains(needle):
			matches.append(index)
	return matches

func open_popup() -> void:
	if disabled or Engine.is_editor_hint() or not is_inside_tree():
		return
	_ensure_popup()
	_search.clear()
	_filter("")
	_popup.popup(_get_popup_rect())
	_search.call_deferred("grab_focus")
	queue_redraw()

func close_popup() -> void:
	if is_instance_valid(_popup):
		_popup.hide()
	queue_redraw()

func _ensure_popup() -> void:
	if is_instance_valid(_popup):
		return
	_popup = PopupPanel.new()
	_popup.name = "SearchPopup"
	add_child(_popup)
	_popup.popup_hide.connect(func() -> void:
		queue_redraw()
		if not disabled:
			grab_focus())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 10)
	_popup.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	_search = LineEdit.new()
	_search.placeholder_text = "Search options…"
	_search.custom_minimum_size.y = 38.0
	column.add_child(_search)
	_search.text_changed.connect(_filter)
	_search.text_submitted.connect(func(_text: String) -> void: _activate_highlighted())
	_search.gui_input.connect(_search_input)
	_results = ItemList.new()
	_results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results.focus_mode = Control.FOCUS_NONE
	_results.add_theme_constant_override("v_separation", 10)
	column.add_child(_results)
	_results.item_clicked.connect(func(index: int, _position: Vector2, button: int) -> void:
		if button == MOUSE_BUTTON_LEFT:
			_choose(index))
	_results.item_activated.connect(_choose)
	_refresh_popup_theme()

func _on_theme_changed() -> void:
	queue_redraw()
	_refresh_popup_theme()

func _refresh_popup_theme() -> void:
	if not is_instance_valid(_popup) or not is_instance_valid(_results):
		return
	_popup.add_theme_stylebox_override("panel", Style.box(Style.color(self, &"surface"), Style.color(self, &"border")))
	var font: Font = Style.font(self)
	var font_size: int = Style.font_size(self)
	_search.add_theme_font_override("font", font)
	_search.add_theme_font_size_override("font_size", font_size)
	_search.add_theme_color_override("font_color", Style.color(self, &"text"))
	_search.add_theme_color_override("font_placeholder_color", Style.color(self, &"muted"))
	_search.add_theme_color_override("caret_color", Style.color(self, &"accent"))
	_search.add_theme_color_override("selection_color", Style.color(self, &"accent_soft"))
	_search.add_theme_stylebox_override("normal", Style.box(Style.color(self, &"background"), Style.color(self, &"border"), 7))
	_search.add_theme_stylebox_override("focus", Style.box(Color.TRANSPARENT, Style.color(self, &"accent"), 7))
	_results.add_theme_font_override("font", font)
	_results.add_theme_font_size_override("font_size", font_size)
	_results.add_theme_color_override("font_color", Style.color(self, &"text"))
	_results.add_theme_color_override("font_selected_color", Style.color(self, &"text"))
	_results.add_theme_stylebox_override("panel", Style.box(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	_results.add_theme_stylebox_override("selected", Style.box(Style.color(self, &"accent_soft"), Color.TRANSPARENT, 6))
	_results.add_theme_stylebox_override("selected_focus", Style.box(Style.color(self, &"accent_soft"), Color.TRANSPARENT, 6))

func _get_popup_rect() -> Rect2i:
	# get_screen_transform() is Godot's popup-space transform: logical viewport
	# coordinates for embedded windows and desktop coordinates for native windows.
	var transform: Transform2D = get_screen_transform()
	var anchor: Rect2 = transform * Rect2(Vector2.ZERO, size)
	var popup_scale: float = maxf(0.01, minf(absf(transform.get_scale().x), absf(transform.get_scale().y)))
	_popup.content_scale_factor = popup_scale
	var dimensions := Vector2(maxf(240.0 * popup_scale, anchor.size.x), 286.0 * popup_scale)
	var bounds: Rect2 = _get_popup_bounds()
	if bounds.has_area():
		dimensions = dimensions.min(bounds.size)
	var point := Vector2(anchor.position.x, anchor.end.y + 6.0 * popup_scale)
	if bounds.has_area():
		if point.y + dimensions.y > bounds.end.y:
			point.y = anchor.position.y - dimensions.y - 6.0 * popup_scale
		point.x = clampf(point.x, bounds.position.x, bounds.end.x - dimensions.x)
		point.y = clampf(point.y, bounds.position.y, bounds.end.y - dimensions.y)
	return Rect2i(Vector2i(point.round()), Vector2i(dimensions.ceil()))

func _get_popup_bounds() -> Rect2:
	if _popup.is_embedded():
		var viewport: Viewport = get_viewport()
		while viewport != null:
			if viewport.gui_embed_subwindows:
				return viewport.get_visible_rect()
			var parent: Node = viewport.get_parent()
			viewport = parent.get_viewport() if parent != null else null
	return Rect2(DisplayServer.screen_get_usable_rect(get_window().current_screen))

func _filter(query: String) -> void:
	_filtered = get_filtered_indices(query)
	_results.clear()
	for index in _filtered:
		_results.add_item(options[index])
	if _filtered.is_empty():
		_results.add_item("No matching options")
		_results.set_item_disabled(0, true)
	else:
		var highlight: int = _filtered.find(selected)
		_results.select(maxi(0, highlight))
		_results.ensure_current_is_visible()

func _activate_highlighted() -> void:
	var indices: PackedInt32Array = _results.get_selected_items()
	if not indices.is_empty():
		_choose(indices[0])

func _choose(index: int) -> void:
	if index < 0 or index >= _filtered.size():
		return
	select(_filtered[index])
	close_popup()

func _search_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.keycode == KEY_ESCAPE:
		close_popup()
		_search.accept_event()
		return
	if _filtered.is_empty():
		return
	var indices: PackedInt32Array = _results.get_selected_items()
	var current: int = indices[0] if not indices.is_empty() else 0
	match event.keycode:
		KEY_DOWN:
			current = mini(_filtered.size() - 1, current + 1)
		KEY_UP:
			current = maxi(0, current - 1)
		KEY_HOME:
			current = 0
		KEY_END:
			current = _filtered.size() - 1
		_:
			return
	_results.select(current)
	_results.ensure_current_is_visible()
	_search.accept_event()

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		open_popup()
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_DOWN]:
		open_popup()
		accept_event()

func _draw() -> void:
	var fill: Color = Style.color(self, &"surface_hover") if _hovered and not disabled else Style.color(self, &"background")
	var border: Color = Style.color(self, &"accent") if has_focus() else Style.color(self, &"border")
	draw_style_box(Style.box(fill, border), Rect2(Vector2.ZERO, size))
	var font: Font = Style.font(self)
	var font_size: int = Style.font_size(self)
	var value: String = options[selected] if selected >= 0 and selected < options.size() else placeholder
	var text_color: Color = Style.color(self, &"text") if selected >= 0 else Style.color(self, &"muted")
	if disabled:
		text_color.a *= 0.45
	var baseline: float = (size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	var available: float = maxf(0.0, size.x - 54.0)
	while value.length() > 1 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
		value = value.left(value.length() - 2) + "…"
	draw_string(font, Vector2(14.0, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, available, font_size, text_color)
	var center := Vector2(size.x - 21.0, size.y * 0.5)
	draw_polyline(PackedVector2Array([center + Vector2(-4.0, -2.0), center + Vector2(0.0, 2.0), center + Vector2(4.0, -2.0)]), text_color, 1.5, true)
