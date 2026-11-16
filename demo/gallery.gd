extends Control
## Demonstration only. No addon code depends on this scene.

const Style = preload("res://addons/forma_ui/shared/style.gd")
const Segmented = preload("res://addons/forma_ui/segmented_control/segmented_control.gd")
const RangeWidget = preload("res://addons/forma_ui/range_slider/range_slider.gd")
const Dropdown = preload("res://addons/forma_ui/searchable_dropdown/searchable_dropdown.gd")
const Tags = preload("res://addons/forma_ui/tag_input/tag_input.gd")
const Toasts = preload("res://addons/forma_ui/toast_stack/toast_stack.gd")

var _grid: GridContainer
var _sidebar: PanelContainer
var _scroll: ScrollContainer
var _cards: Array[Control] = []
var _toasts: Control

func _ready() -> void:
	theme = Style.make_theme()
	DisplayServer.window_set_min_size(Vector2i(720, 600))
	var background = ColorRect.new()
	background.color = Style.color(self, &"background")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shell = HBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)
	_build_sidebar(shell)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shell.add_child(_scroll)
	var margin = _margin(36)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(margin)
	var page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 26)
	margin.add_child(page)
	_build_header(page)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	page.add_child(_grid)
	_build_segmented()
	_build_range()
	_build_dropdown()
	_build_tags()
	_build_toasts(page)
	var footer = _label("MADE FOR GODOT 4     /     Tab to focus · Arrow keys to adjust · Esc to close", 12, "muted")
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(footer)
	_toasts = Toasts.new()
	_toasts.name = "LiveNotifications"
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_toasts.offset_left = -380
	_toasts.offset_right = -24
	_toasts.offset_top = -360
	_toasts.offset_bottom = -24
	add_child(_toasts)
	resized.connect(_responsive)
	_responsive()
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()

func _build_sidebar(shell: HBoxContainer) -> void:
	_sidebar = PanelContainer.new()
	_sidebar.custom_minimum_size.x = 224
	_sidebar.add_theme_stylebox_override("panel", Style.box(Color("12151c"), Color("252a36"), 0))
	shell.add_child(_sidebar)
	var margin = _margin(18)
	_sidebar.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	margin.add_child(column)
	var brand = HBoxContainer.new()
	brand.add_theme_constant_override("separation", 10)
	column.add_child(brand)
	var logo = TextureRect.new()
	logo.texture = preload("res://addons/forma_ui/icons/widget.svg")
	logo.custom_minimum_size = Vector2(29, 29)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.add_child(logo)
	brand.add_child(_label("forma", 29, "text"))
	column.add_child(_label("A little more considered.", 12, "muted"))
	_spacer(column, 42)
	column.add_child(_label("COMPONENTS", 10, "muted"))
	var names = ["Segmented control", "Range slider", "Searchable dropdown", "Tag input", "Toast stack"]
	for i in names.size():
		var button = Button.new()
		button.text = "%02d   %s" % [i + 1, names[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", Style.box(Color.TRANSPARENT, Color.TRANSPARENT, 6))
		button.add_theme_stylebox_override("hover", Style.box(Color("242331"), Color.TRANSPARENT, 6))
		button.pressed.connect(func(): _scroll.ensure_control_visible(_cards[i]))
		column.add_child(button)
	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(fill)
	column.add_child(_label("ONE ADDON. FIVE BUILDING BLOCKS.", 10, "muted"))
	column.add_child(_label("v0.1.0  /  Godot 4", 12, "text"))

func _build_header(page: VBoxContainer) -> void:
	var top = HBoxContainer.new()
	page.add_child(top)
	var caption = _label("FORMA UI   /   COMPONENT LIBRARY", 11, "muted")
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(caption)
	top.add_child(_label("●  Interactive gallery", 12, "success"))
	var title = _label("Small controls. Thoughtful details.", 31, "text")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(title)
	var subtitle = _label("Five independent widgets for your next Godot project. Explore their behavior below.", 14, "muted")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subtitle)

func _card(parent: Node, index: int, title: String, description: String, api: String) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", Style.box(Color("14171f"), Color("2a2f3c"), 14))
	parent.add_child(panel)
	_cards.append(panel)
	var margin = _margin(22)
	panel.add_child(margin)
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var heading = HBoxContainer.new()
	column.add_child(heading)
	var name_label = _label(title, 18, "text")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(name_label)
	heading.add_child(_label("%02d" % index, 12, "accent"))
	var detail = _label(description, 13, "muted")
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	var stage = VBoxContainer.new()
	stage.name = "Stage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation", 10)
	column.add_child(stage)
	var code = _label(api, 11, "muted")
	code.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(code)
	return stage

func _build_segmented() -> void:
	var stage = _card(_grid, 1, "Segmented control", "One choice. A clear sense of place.", "SIGNAL   selection_changed(index)")
	var control = Segmented.new()
	control.options = PackedStringArray(["Overview", "Details", "Activity"])
	stage.add_child(control)
	var state = _label("Selected: Overview", 12, "accent")
	stage.add_child(state)
	control.selection_changed.connect(func(index: int): state.text = "Selected: " + control.options[index])

func _build_range() -> void:
	var stage = _card(_grid, 2, "Range slider", "Define both ends of the spectrum.", "SIGNAL   values_changed(lower, upper)")
	var control = RangeWidget.new()
	control.tooltip_text = "Drag either handle. Tab switches handles; arrows adjust values."
	stage.add_child(control)
	var row = HBoxContainer.new()
	stage.add_child(row)
	var bounds = _label("20 — 80", 12, "accent")
	bounds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bounds)
	row.add_child(_label("0 – 100", 12, "muted"))
	control.values_changed.connect(func(lower: float, upper: float): bounds.text = "%d — %d" % [lower, upper])

func _build_dropdown() -> void:
	var stage = _card(_grid, 3, "Searchable dropdown", "Find the right option without the scrolling.", "SIGNAL   selection_changed(index, value)")
	var control = Dropdown.new()
	control.options = PackedStringArray(["Animation", "Audio", "Camera", "Canvas", "Input", "Materials", "Navigation", "Particles", "Physics", "Rendering", "Shaders", "UI & Layout"])
	control.placeholder = "Choose a workspace…"
	stage.add_child(control)
	var state = _label("12 options · Type to filter", 12, "muted")
	stage.add_child(state)
	control.selection_changed.connect(func(_index: int, value: String): state.text = "Workspace: " + value)

func _build_tags() -> void:
	var stage = _card(_grid, 4, "Tag input", "A home for ideas, one little chip at a time.", "SIGNAL   tags_changed(tags)")
	var control = Tags.new()
	control.tags = PackedStringArray(["Design", "Godot"])
	control.max_tags = 6
	control.placeholder = "Add a tag…"
	stage.add_child(control)
	var state = _label("Enter or comma to add · 2 / 6 tags", 12, "muted")
	state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage.add_child(state)
	control.tags_changed.connect(func(tags: PackedStringArray): state.text = "Enter or comma to add · %d / 6 tags" % tags.size())
	control.tag_rejected.connect(func(_tag: String, reason: String): state.text = reason)

func _build_toasts(page: VBoxContainer) -> void:
	var stage = _card(page, 5, "Toast stack", "A small update that stays out of the way. Dismiss it, act on it, or let it fade.", "METHOD   push_toast(message, kind, duration, action_text)")
	var actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	stage.add_child(actions)
	var examples = [
		["Send a notification", "Your workspace has been updated.", "info", ""],
		["Success", "All changes saved. Nicely done.", "success", ""],
		["Error", "Could not connect. Please try again.", "error", "Retry"],
		["With an action", "Item moved to the archive.", "info", "Undo"],
	]
	for example in examples:
		var button = Button.new()
		button.text = example[0]
		button.pressed.connect(func(): _toasts.push_toast(example[1], example[2], 5.0, example[3]))
		actions.add_child(button)
	stage.add_child(_label("Up to 3 at a time · Pause on hover or focus · No global singleton", 12, "muted"))

func _responsive() -> void:
	if not is_instance_valid(_grid):
		return
	_sidebar.visible = size.x >= 960
	_grid.columns = 2 if size.x >= 1120 else 1

func _label(text: String, font_size: int, color_key: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Style.color(self, color_key))
	return label

func _margin(amount: int) -> MarginContainer:
	var margin = MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, amount)
	return margin

func _spacer(parent: Node, height: float) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)

func _capture() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var destination = OS.get_environment("FORMA_CAPTURE_PATH")
	if destination.is_empty():
		destination = "/tmp/forma-ui-gallery.png"
	image.save_png(destination)
	get_tree().quit()
