@tool
extends Control
## Instance-local notification stack. Oldest notifications are dismissed at capacity.
## A duration of 0 keeps a toast until dismissed; -1 uses default_duration.

signal toast_dismissed(id: int)
signal action_pressed(id: int)

const Style = preload("res://addons/forma_ui/shared/style.gd")

@export_range(1, 20, 1) var max_visible: int = 3:
	set(value):
		max_visible = maxi(1, value)
		while _entries.size() > max_visible:
			dismiss(int(_entries[0].id))
@export_range(0.0, 60.0, 0.1) var default_duration: float = 4.0

var _stack: VBoxContainer
var _entries: Array[Dictionary] = []
var _next_id := 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = VBoxContainer.new()
	_stack.alignment = BoxContainer.ALIGNMENT_END
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stack.add_theme_constant_override("separation", 10)
	add_child(_stack)
	_stack.minimum_size_changed.connect(update_minimum_size)
	theme_changed.connect(_refresh_theme)
	for entry in _entries:
		_build_toast(entry)
	set_process(not Engine.is_editor_hint())


func _get_minimum_size() -> Vector2:
	var height := 0.0
	if is_instance_valid(_stack):
		height = _stack.get_combined_minimum_size().y
	return Vector2(300, height)


func _draw() -> void:
	if Engine.is_editor_hint() and _entries.is_empty():
		draw_style_box(Style.box(Style.color(self, "surface"), Style.color(self, "border")), Rect2(Vector2.ZERO, Vector2(size.x, 54)))
		draw_string(Style.font(self), Vector2(16, 32), "ToastStack · notifications appear here", HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, Style.font_size(self) - 1, Style.color(self, "muted"))


## kind accepts "info", "success", "warning", or "error". Unknown kinds use info.
## Hover or keyboard focus within a toast pauses its countdown. Actions emit, then dismiss.
func push_toast(message: String, kind: String = "info", duration: float = -1.0, action_text: String = "") -> int:
	while _entries.size() >= max_visible:
		dismiss(int(_entries[0].id))
	var lifetime := default_duration if duration < 0 else duration
	var entry: Dictionary = {
		"id": _next_id,
		"message": message,
		"kind": kind if kind in ["info", "success", "warning", "error"] else "info",
		"duration": maxf(0, lifetime),
		"remaining": maxf(0, lifetime),
		"action": action_text,
		"panel": null,
		"progress": null,
	}
	_next_id += 1
	_entries.append(entry)
	if is_instance_valid(_stack):
		_build_toast(entry)
	queue_redraw()
	return int(entry.id)


func dismiss(id: int) -> void:
	for index in _entries.size():
		var entry := _entries[index]
		if int(entry.id) != id:
			continue
		_entries.remove_at(index)
		var panel: PanelContainer = entry.panel
		if is_instance_valid(panel):
			_stack.remove_child(panel)
			panel.queue_free()
		update_minimum_size()
		queue_redraw()
		toast_dismissed.emit(id)
		return


func clear() -> void:
	var ids: Array[int] = []
	for entry in _entries:
		ids.append(int(entry.id))
	for id in ids:
		dismiss(id)


func get_toast_count() -> int:
	return _entries.size()


func _process(delta: float) -> void:
	var expired: Array[int] = []
	var focus_owner := get_viewport().gui_get_focus_owner()
	for entry in _entries:
		if float(entry.duration) <= 0:
			continue
		var panel: PanelContainer = entry.panel
		if not is_instance_valid(panel):
			continue
		if panel.get_global_rect().has_point(get_global_mouse_position()):
			continue
		if focus_owner != null and (focus_owner == panel or panel.is_ancestor_of(focus_owner)):
			continue
		entry.remaining = maxf(0, float(entry.remaining) - delta)
		var progress: ProgressBar = entry.progress
		if is_instance_valid(progress):
			progress.value = float(entry.remaining) / float(entry.duration)
		if float(entry.remaining) <= 0:
			expired.append(int(entry.id))
	for id in expired:
		dismiss(id)


func _build_toast(entry: Dictionary) -> void:
	var tone := Style.color(self, "accent")
	var mark := "•"
	match String(entry.kind):
		"success":
			tone = Style.color(self, "success")
			mark = "✓"
		"warning":
			tone = Color("e5b96f")
			mark = "!"
		"error":
			tone = Style.color(self, "danger")
			mark = "!"
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := Style.box(Style.color(self, "surface"), Style.color(self, "border"), 12)
	box.content_margin_left = 16
	box.content_margin_right = 12
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box)
	_stack.add_child(panel)
	entry.panel = panel
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var icon := _label(mark, 17, tone)
	icon.custom_minimum_size.x = 16
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 3)
	row.add_child(text_column)
	text_column.add_child(_label(String(entry.kind).to_upper(), 10, tone))
	var message := _label(String(entry.message), Style.font_size(self) - 1, Style.color(self, "text"))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 160
	text_column.add_child(message)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Dismiss notification"
	close.flat = true
	close.custom_minimum_size = Vector2(24, 24)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.add_theme_font_size_override("font_size", 20)
	close.add_theme_color_override("font_color", Style.color(self, "muted"))
	close.add_theme_color_override("font_hover_color", Style.color(self, "text"))
	close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close.pressed.connect(dismiss.bind(int(entry.id)))
	row.add_child(close)
	if not String(entry.action).is_empty():
		var action := Button.new()
		action.text = String(entry.action)
		action.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		action.add_theme_font_size_override("font_size", 12)
		action.add_theme_color_override("font_color", tone)
		var action_box := Style.box(tone.darkened(0.75), Color.TRANSPARENT, 6)
		action_box.content_margin_left = 10
		action_box.content_margin_right = 10
		action_box.content_margin_top = 5
		action_box.content_margin_bottom = 5
		action.add_theme_stylebox_override("normal", action_box)
		action.pressed.connect(_activate_action.bind(int(entry.id)))
		text_column.add_child(action)
	if float(entry.duration) > 0:
		var progress := ProgressBar.new()
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.custom_minimum_size.y = 2
		progress.show_percentage = false
		progress.max_value = 1.0
		progress.value = float(entry.remaining) / float(entry.duration)
		progress.add_theme_stylebox_override("background", _progress_box(Style.color(self, "border")))
		progress.add_theme_stylebox_override("fill", _progress_box(tone))
		column.add_child(progress)
		entry.progress = progress
	if not Engine.is_editor_hint():
		panel.modulate.a = 0.0
		panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.18)
	update_minimum_size()


func _progress_box(color: Color) -> StyleBoxFlat:
	var box := Style.box(color, Color.TRANSPARENT, 1)
	box.content_margin_left = 0
	box.content_margin_right = 0
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	box.set_border_width_all(0)
	return box


func _refresh_theme() -> void:
	if not is_instance_valid(_stack):
		return
	for entry in _entries:
		var panel: PanelContainer = entry.panel
		if is_instance_valid(panel):
			_stack.remove_child(panel)
			panel.queue_free()
		entry.panel = null
		entry.progress = null
		_build_toast(entry)
	queue_redraw()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", Style.font(self))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _activate_action(id: int) -> void:
	action_pressed.emit(id)
	dismiss(id)
