@tool
extends Control
## A wrapping tag editor. Tags are trimmed and unique, ignoring letter case.

signal tag_added(tag: String)
signal tag_removed(tag: String)
signal tags_changed(tags: PackedStringArray)
signal tag_rejected(tag: String, reason: String)

const Style = preload("res://addons/forma_ui/shared/style.gd")

@export var tags: PackedStringArray = PackedStringArray():
	set(value):
		tags = _normalize(value)
		_schedule_rebuild()
@export var placeholder: String = "Add a tag…":
	set(value):
		placeholder = value
		if is_instance_valid(_input):
			_input.placeholder_text = value
@export_range(0, 1000, 1) var max_tags: int = 0
@export var disabled: bool = false:
	set(value):
		disabled = value
		_schedule_rebuild()

var _flow: HFlowContainer
var _input: LineEdit
var _rebuild_pending := false
var _focused := false


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_IBEAM
	mouse_filter = Control.MOUSE_FILTER_STOP
	_flow = HFlowContainer.new()
	_flow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flow.offset_left = 10
	_flow.offset_top = 8
	_flow.offset_right = -10
	_flow.offset_bottom = -8
	_flow.add_theme_constant_override("h_separation", 6)
	_flow.add_theme_constant_override("v_separation", 6)
	add_child(_flow)
	_flow.minimum_size_changed.connect(update_minimum_size)
	resized.connect(_on_resized)
	theme_changed.connect(_schedule_rebuild)
	_rebuild()


func _get_minimum_size() -> Vector2:
	var height := 48.0
	if is_instance_valid(_flow):
		height = maxf(height, _flow.get_combined_minimum_size().y + 16)
	return Vector2(220, height)


func _draw() -> void:
	var edge := Style.color(self, "accent") if _focused else Style.color(self, "border")
	draw_style_box(Style.box(Style.color(self, "surface"), edge), Rect2(Vector2.ZERO, size))


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_instance_valid(_input):
			_input.grab_focus()
		accept_event()


## Add a tag. Returns false for blank, duplicate, disabled, or over-limit input.
func add_tag(value: String) -> bool:
	var tag := value.strip_edges()
	var reason := ""
	if disabled:
		reason = "disabled"
	elif tag.is_empty():
		reason = "empty"
	elif _contains_tag(tag):
		reason = "duplicate"
	elif max_tags > 0 and tags.size() >= max_tags:
		reason = "limit"
	if not reason.is_empty():
		tag_rejected.emit(tag, reason)
		return false
	var next := tags.duplicate()
	next.append(tag)
	tags = next
	tag_added.emit(tag)
	tags_changed.emit(tags.duplicate())
	return true


## Remove a tag by name, ignoring case.
func remove_tag(value: String) -> bool:
	if disabled:
		return false
	for index in tags.size():
		if tags[index].nocasecmp_to(value.strip_edges()) == 0:
			var removed := tags[index]
			var next := tags.duplicate()
			next.remove_at(index)
			tags = next
			tag_removed.emit(removed)
			tags_changed.emit(tags.duplicate())
			return true
	return false


func clear_tags() -> void:
	if disabled or tags.is_empty():
		return
	var previous := tags.duplicate()
	tags = PackedStringArray()
	for tag in previous:
		tag_removed.emit(tag)
	tags_changed.emit(tags.duplicate())


func _normalize(values: PackedStringArray) -> PackedStringArray:
	var clean := PackedStringArray()
	var seen: Dictionary = {}
	for value in values:
		var tag := value.strip_edges()
		if not tag.is_empty() and not seen.has(tag.to_lower()):
			clean.append(tag)
			seen[tag.to_lower()] = true
	return clean


func _contains_tag(tag: String) -> bool:
	for existing in tags:
		if existing.nocasecmp_to(tag) == 0:
			return true
	return false


func _schedule_rebuild() -> void:
	if not is_instance_valid(_flow) or _rebuild_pending:
		return
	_rebuild_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	if not is_instance_valid(_flow):
		return
	var previous_text := ""
	var focus_owner := get_viewport().gui_get_focus_owner()
	var had_focus := focus_owner != null and is_ancestor_of(focus_owner)
	if is_instance_valid(_input):
		previous_text = _input.text
	_focused = false
	for child in _flow.get_children():
		_flow.remove_child(child)
		child.queue_free()
	for tag in tags:
		var chip := Button.new()
		chip.text = tag + "   ×"
		chip.set_meta("tag_value", tag)
		chip.clip_text = true
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chip.tooltip_text = "Remove " + tag
		chip.disabled = disabled
		chip.custom_minimum_size.y = 30
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.add_theme_font_override("font", Style.font(self))
		chip.add_theme_font_size_override("font_size", Style.font_size(self) - 1)
		chip.add_theme_color_override("font_color", Style.color(self, "text"))
		chip.add_theme_stylebox_override("normal", _chip_box("accent_soft"))
		chip.add_theme_stylebox_override("hover", _chip_box("surface_hover"))
		chip.add_theme_stylebox_override("pressed", _chip_box("surface_hover"))
		chip.add_theme_stylebox_override("disabled", _chip_box("surface"))
		chip.add_theme_stylebox_override("focus", Style.box(Color.TRANSPARENT, Style.color(self, "accent"), 7))
		chip.pressed.connect(_remove_from_button.bind(tag))
		chip.focus_entered.connect(_queue_focus_refresh)
		chip.focus_exited.connect(_queue_focus_refresh)
		_flow.add_child(chip)
	_input = LineEdit.new()
	_input.name = "TagEntry"
	_input.placeholder_text = placeholder
	_input.text = previous_text
	_input.editable = not disabled
	_input.focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	_input.custom_minimum_size = Vector2(120, 30)
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.add_theme_font_override("font", Style.font(self))
	_input.add_theme_font_size_override("font_size", Style.font_size(self))
	_input.add_theme_color_override("font_color", Style.color(self, "text"))
	_input.add_theme_color_override("font_placeholder_color", Style.color(self, "muted"))
	_input.add_theme_color_override("caret_color", Style.color(self, "accent"))
	_input.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_input.text_submitted.connect(_submit)
	_input.text_changed.connect(_on_text_changed)
	_input.gui_input.connect(_input_event)
	_input.focus_entered.connect(_queue_focus_refresh)
	_input.focus_exited.connect(_queue_focus_refresh)
	_flow.add_child(_input)
	_update_chip_widths()
	if had_focus and not disabled:
		_input.grab_focus()
		_input.caret_column = _input.text.length()
	_refresh_focus()
	queue_redraw()
	update_minimum_size()


func _on_resized() -> void:
	_update_chip_widths()
	update_minimum_size()


func _update_chip_widths() -> void:
	if not is_instance_valid(_flow):
		return
	var available := maxf(200, size.x - 20)
	for child in _flow.get_children():
		if not child is Button or not child.has_meta("tag_value"):
			continue
		var chip: Button = child
		var value := String(chip.get_meta("tag_value"))
		var font := chip.get_theme_font("font")
		var font_size := chip.get_theme_font_size("font_size")
		var margins := chip.get_theme_stylebox("normal").get_minimum_size().x
		var full_text := value + "   ×"
		var natural_width := font.get_string_size(full_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + margins
		chip.custom_minimum_size.x = minf(natural_width, available)
		chip.text = _fit_chip_text(value, font, font_size, available - margins)


func _fit_chip_text(value: String, font: Font, font_size: int, available: float) -> String:
	var suffix := "   ×"
	if font.get_string_size(value + suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available:
		return value + suffix
	var low := 0
	var high := value.length()
	while low < high:
		var midpoint := (low + high + 1) / 2
		var candidate := value.substr(0, midpoint) + "…" + suffix
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= available:
			low = midpoint
		else:
			high = midpoint - 1
	return value.substr(0, low) + "…" + suffix


func _chip_box(key: String) -> StyleBoxFlat:
	var box := Style.box(Style.color(self, key), Color.TRANSPARENT, 7)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box


func _submit(value: String) -> void:
	if add_tag(value):
		_input.clear()


func _on_text_changed(value: String) -> void:
	if disabled or not value.contains(","):
		return
	var pieces := value.split(",", true)
	for index in pieces.size() - 1:
		add_tag(pieces[index])
	_input.text = pieces[pieces.size() - 1]
	_input.caret_column = _input.text.length()


func _input_event(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE and _input.text.is_empty():
		if not tags.is_empty():
			remove_tag(tags[tags.size() - 1])
		_input.accept_event()


func _remove_from_button(tag: String) -> void:
	remove_tag(tag)
	if is_instance_valid(_input):
		_input.grab_focus()


func _queue_focus_refresh() -> void:
	_refresh_focus.call_deferred()


func _refresh_focus() -> void:
	if not is_inside_tree():
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	_focused = not disabled and focus_owner != null and is_ancestor_of(focus_owner)
	queue_redraw()
