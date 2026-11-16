extends SceneTree
## Run: godot --headless --path . --script tests/test_widgets.gd
## Exercises the public API and real node lifecycles without a test framework.

const Segmented = preload("res://addons/forma_ui/segmented_control/segmented_control.gd")
const Dropdown = preload("res://addons/forma_ui/searchable_dropdown/searchable_dropdown.gd")
const Tags = preload("res://addons/forma_ui/tag_input/tag_input.gd")
const Toasts = preload("res://addons/forma_ui/toast_stack/toast_stack.gd")
const RangeWidget = preload("res://addons/forma_ui/range_slider/range_slider.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)


func _mount(node: Control) -> void:
	node.size = Vector2(480, 160)
	root.add_child(node)


func _press_key(viewport: Viewport, keycode: Key, unicode: int = 0) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.unicode = unicode
	event.pressed = true
	viewport.push_input(event, true)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	viewport.push_input(release, true)


func _run() -> void:
	root.gui_embed_subwindows = true
	await _test_segmented()
	await _test_dropdown()
	await _test_tags()
	await _test_tag_layout()
	await _test_range()
	await _test_toasts()
	await process_frame
	if _failures == 0:
		print("FORMA_UI_TESTS: %d checks passed" % _checks)
	else:
		printerr("FORMA_UI_TESTS: %d of %d checks failed" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _test_segmented() -> void:
	var control = Segmented.new()
	control.options = PackedStringArray(["Overview", "Details", "Activity"])
	_mount(control)
	await process_frame
	var selections: Array = []
	control.selection_changed.connect(func(index: int): selections.append(index))
	control.select(1)
	_check(control.selected == 1, "Segmented selects an option")
	_check(selections == [1], "Segmented emits the selected index once")
	control.select(1)
	_check(selections.size() == 1, "Segmented does not re-emit an unchanged selection")
	control.select(2, false)
	_check(control.selected == 2 and selections.size() == 1, "Segmented supports silent changes")
	var key := InputEventKey.new()
	key.keycode = KEY_HOME
	key.pressed = true
	control._gui_input(key)
	_check(control.selected == 0, "Segmented Home key selects the first option")
	key.keycode = KEY_RIGHT
	control._gui_input(key)
	_check(control.selected == 1, "Segmented arrow key changes the selected option")
	control.disabled = true
	control._gui_input(key)
	_check(control.selected == 1, "Disabled Segmented ignores keyboard input")
	control.options = PackedStringArray()
	_check(control.selected == -1, "Segmented supports an empty option set")
	control._gui_input(key)
	var independent = Segmented.new()
	_mount(independent)
	await process_frame
	_check(independent.selected != 2, "Segmented instances have independent selection state")
	control.queue_free()
	independent.queue_free()
	await process_frame


func _test_dropdown() -> void:
	var control = Dropdown.new()
	control.options = PackedStringArray(["Animation", "Audio", "Camera", "Canvas"])
	_mount(control)
	await process_frame
	_check(control.get_filtered_indices("ca") == PackedInt32Array([2, 3]), "Dropdown filters substrings and preserves source indices")
	_check(control.get_filtered_indices("AUDIO") == PackedInt32Array([1]), "Dropdown matching ignores case")
	_check(control.get_filtered_indices("").size() == 4, "Dropdown empty search returns every option")
	_check(control.get_filtered_indices("missing").is_empty(), "Dropdown has an empty result state")
	var selections: Array = []
	control.selection_changed.connect(func(index: int, value: String): selections.append([index, value]))
	control.select(3)
	_check(control.selected == 3, "Dropdown stores the source index")
	_check(selections == [[3, "Canvas"]], "Dropdown emits the source index and text")
	control.select(1, false)
	_check(control.selected == 1 and selections.size() == 1, "Dropdown supports silent changes")
	control.grab_focus()
	_press_key(root, KEY_SPACE)
	await process_frame
	var popup := control.find_child("SearchPopup", true, false) as PopupPanel
	_check(is_instance_valid(popup) and popup.visible, "Dropdown Space key opens its popup")
	if is_instance_valid(popup):
		var search_nodes := popup.find_children("*", "LineEdit", true, false)
		var result_nodes := popup.find_children("*", "ItemList", true, false)
		_check(search_nodes.size() == 1 and result_nodes.size() == 1, "Dropdown popup contains search and result controls")
		if search_nodes.size() == 1 and result_nodes.size() == 1:
			var search := search_nodes[0] as LineEdit
			var results := result_nodes[0] as ItemList
			_check(search.has_focus(), "Dropdown focuses its search field on open")
			_press_key(popup, KEY_C, 99)
			_press_key(popup, KEY_A, 97)
			await process_frame
			_check(search.text == "ca" and results.item_count == 2, "Dropdown typed search filters the visible result list")
			_press_key(popup, KEY_DOWN)
			_press_key(popup, KEY_ENTER)
			await process_frame
			_check(control.selected == 3 and not popup.visible, "Dropdown Down and Enter select the filtered source item and close")
			control.grab_focus()
			_press_key(root, KEY_SPACE)
			await process_frame
			_press_key(popup, KEY_ESCAPE)
			await process_frame
			_check(not popup.visible and control.selected == 3, "Dropdown Escape closes without changing selection")
	control.queue_free()
	await process_frame


func _test_tags() -> void:
	var control = Tags.new()
	_mount(control)
	await process_frame
	var added: Array = []
	var removed: Array = []
	var changed: Array = []
	var rejected: Array = []
	control.tag_added.connect(func(value: String): added.append(value))
	control.tag_removed.connect(func(value: String): removed.append(value))
	control.tags_changed.connect(func(values: PackedStringArray): changed.append(values.duplicate()))
	control.tag_rejected.connect(func(value: String, reason: String): rejected.append([value, reason]))
	_check(control.add_tag("  Design  "), "TagInput accepts a nonempty tag")
	_check(control.tags == PackedStringArray(["Design"]), "TagInput trims surrounding whitespace")
	_check(added == ["Design"] and changed.size() == 1, "TagInput emits addition and new state once")
	_check(not control.add_tag("design"), "TagInput rejects case-insensitive duplicates")
	_check(not control.add_tag("   "), "TagInput rejects empty tags")
	_check(control.tags.size() == 1 and added.size() == 1, "Rejected tags leave the selection unchanged")
	control.max_tags = 2
	_check(control.add_tag("Audio"), "TagInput accepts tags below its limit")
	_check(not control.add_tag("Motion"), "TagInput enforces its configured limit")
	_check(not rejected.is_empty(), "TagInput reports rejected input")
	_check(control.remove_tag("Design"), "TagInput removes an existing tag")
	_check(removed == ["Design"] and control.tags == PackedStringArray(["Audio"]), "TagInput emits removal and preserves other tags")
	_check(not control.remove_tag("Missing"), "TagInput reports a missing removal without mutation")
	control.clear_tags()
	_check(control.tags.is_empty(), "TagInput clears its tags")
	control.disabled = true
	_check(not control.add_tag("Blocked") and control.tags.is_empty(), "Disabled TagInput rejects mutations")
	control.disabled = false
	control.max_tags = 0
	await process_frame
	var entry := control.find_child("TagEntry", true, false) as LineEdit
	_check(is_instance_valid(entry), "TagInput exposes an editable tag entry")
	if is_instance_valid(entry):
		entry.grab_focus()
		_press_key(root, KEY_U, 117)
		_press_key(root, KEY_I, 105)
		_press_key(root, KEY_ENTER)
		await process_frame
		_check(control.tags == PackedStringArray(["ui"]), "TagInput typed Enter submits a tag")
		entry = control.find_child("TagEntry", true, false) as LineEdit
		_check(entry.text.is_empty() and entry.has_focus(), "TagInput clears input and preserves focus after submission")
		_press_key(root, KEY_BACKSPACE)
		await process_frame
		_check(control.tags.is_empty(), "TagInput Backspace removes the last tag when input is empty")
	var independent = Tags.new()
	_mount(independent)
	await process_frame
	control.add_tag("Local")
	_check(independent.tags.is_empty(), "TagInput instances do not share their tag arrays")
	control.queue_free()
	independent.queue_free()
	await process_frame


func _test_range() -> void:
	var control = RangeWidget.new()
	control.min_value = 0.0
	control.max_value = 100.0
	control.step = 5.0
	_mount(control)
	await process_frame
	var changes: Array = []
	control.values_changed.connect(func(lower: float, upper: float): changes.append(Vector2(lower, upper)))
	control.set_values(13.0, 87.0)
	_check(is_equal_approx(control.lower_value, 15.0) and is_equal_approx(control.upper_value, 85.0), "RangeSlider snaps both handles to the nearest step")
	_check(changes.size() == 1, "RangeSlider emits one change for a pair of values")
	control.set_values(15.0, 85.0)
	_check(changes.size() == 1, "RangeSlider does not re-emit unchanged values")
	control.set_values(-50.0, 150.0)
	_check(is_equal_approx(control.lower_value, 0.0) and is_equal_approx(control.upper_value, 100.0), "RangeSlider clamps both values to its bounds")
	control.set_values(90.0, 10.0)
	_check(control.lower_value <= control.upper_value, "RangeSlider prevents crossed handles")
	_check(control.lower_value >= control.min_value and control.upper_value <= control.max_value, "RangeSlider crossed input remains within its bounds")
	var count_before := changes.size()
	control.set_values(25.0, 75.0, false)
	_check(is_equal_approx(control.lower_value, 25.0) and is_equal_approx(control.upper_value, 75.0) and changes.size() == count_before, "RangeSlider supports silent changes")
	control.disabled = true
	var before := Vector2(control.lower_value, control.upper_value)
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	control._gui_input(key)
	_check(Vector2(control.lower_value, control.upper_value) == before, "Disabled RangeSlider ignores keyboard input")
	control.disabled = false
	control.set_values(20.0, 80.0, false)
	control.active_handle = 1
	key.keycode = KEY_LEFT
	control._gui_input(key)
	_check(is_equal_approx(control.lower_value, 20.0) and is_equal_approx(control.upper_value, 75.0), "RangeSlider keyboard moves only the active handle")
	var dragging: Array = []
	control.drag_started.connect(func(): dragging.append("start"))
	control.drag_ended.connect(func(): dragging.append("end"))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(103.2, 80.0)
	control._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(480.0, 80.0)
	control._gui_input(motion)
	press.pressed = false
	control._gui_input(press)
	_check(is_equal_approx(control.lower_value, 75.0) and is_equal_approx(control.upper_value, 75.0), "RangeSlider pointer drag stops at the other handle")
	_check(dragging == ["start", "end"], "RangeSlider brackets a pointer drag with lifecycle signals")
	control.min_value = 3.0
	control.max_value = 43.0
	control.set_values(4.0, 42.0)
	_check(is_equal_approx(control.lower_value, 3.0) and is_equal_approx(control.upper_value, 43.0), "RangeSlider snaps relative to a nonzero minimum")
	control.max_value = control.min_value
	control.set_values(-100.0, 100.0)
	_check(is_equal_approx(control.lower_value, 3.0) and is_equal_approx(control.upper_value, 3.0), "RangeSlider handles a zero-length range")
	control.queue_free()
	await process_frame


func _test_tag_layout() -> void:
	var control = Tags.new()
	_mount(control)
	control.size = Vector2(300, 160)
	for frame in 3:
		await process_frame
	var entry := control.find_child("TagEntry", true, false) as LineEdit
	entry.text = "unfinished input"
	entry.grab_focus()
	var long_tag := "W".repeat(500)
	control.add_tag(long_tag)
	for frame in 3:
		await process_frame
	_check(control.tags == PackedStringArray([long_tag]), "TagInput preserves the full value of a long tag")
	var flows := control.find_children("*", "HFlowContainer", true, false)
	_check(flows.size() == 1, "TagInput has a wrapping layout for long tags")
	if flows.size() == 1:
		var flow := flows[0] as HFlowContainer
		for width in [300.0, 220.0, 640.0]:
			control.size.x = width
			for frame in 3:
				await process_frame
			var outer := control.get_global_rect()
			var fits := flow.get_global_rect().position.x >= outer.position.x - 0.5 and flow.get_global_rect().end.x <= outer.end.x + 0.5
			for child in flow.get_children():
				if child is Control and child.visible:
					var bounds: Rect2 = child.get_global_rect()
					fits = fits and bounds.position.x >= outer.position.x - 0.5 and bounds.end.x <= outer.end.x + 0.5
			_check(fits and is_equal_approx(control.size.x, width), "TagInput long tag stays inside a %dpx control" % int(width))
			entry = control.find_child("TagEntry", true, false) as LineEdit
			_check(entry.text == "unfinished input" and entry.has_focus(), "TagInput resize to %dpx retains unfinished text and focus" % int(width))
	control.queue_free()
	await process_frame


func _test_toasts() -> void:
	var control = Toasts.new()
	control.max_visible = 2
	_mount(control)
	await process_frame
	var dismissed: Array = []
	var actions: Array = []
	control.toast_dismissed.connect(func(id: int): dismissed.append(id))
	control.action_pressed.connect(func(id: int): actions.append(id))
	var first: int = control.push_toast("Saved", "success", 0.0)
	var second: int = control.push_toast("Connection lost", "error", 0.0, "Retry")
	control.size.y = 420.0
	for frame in 3:
		await process_frame
	var stacks := control.find_children("*", "VBoxContainer", false, false)
	_check(stacks.size() == 1, "ToastStack has one notification layout")
	if stacks.size() == 1:
		var stack := stacks[0] as VBoxContainer
		var last_panel := stack.get_child(stack.get_child_count() - 1) as PanelContainer
		_check(absf(last_panel.get_global_rect().end.y - stack.get_global_rect().end.y) <= 0.5, "ToastStack notifications align to the bottom of the stack")
	_check(first != second, "ToastStack assigns distinct toast IDs")
	_check(control.get_toast_count() == 2, "ToastStack retains simultaneous notifications")
	control.dismiss(first)
	_check(control.get_toast_count() == 1, "ToastStack dismisses a toast by ID")
	_check(dismissed.has(first), "ToastStack emits the dismissed ID")
	control.dismiss(first)
	_check(dismissed.count(first) == 1, "ToastStack does not dismiss the same ID twice")
	await process_frame
	var action_button: Button
	for button in control.find_children("*", "Button", true, false):
		if button.text == "Retry":
			action_button = button
	_check(is_instance_valid(action_button), "ToastStack exposes the optional action button")
	if is_instance_valid(action_button):
		action_button.grab_focus()
		_press_key(root, KEY_SPACE)
		await process_frame
		_check(actions == [second] and dismissed.has(second) and control.get_toast_count() == 0, "ToastStack keyboard action emits its ID and dismisses the toast")
	control.clear()
	_check(control.get_toast_count() == 0, "ToastStack clears its notifications")
	var oldest: int = control.push_toast("One", "info", 0.0)
	control.push_toast("Two", "info", 0.0)
	control.push_toast("Three", "info", 0.0)
	_check(control.get_toast_count() <= control.max_visible, "ToastStack respects its visible limit")
	_check(dismissed.has(oldest), "ToastStack evicts its oldest toast at capacity")
	control.clear()
	var expiring: int = control.push_toast("Temporary", "info", 0.05)
	await create_timer(0.2).timeout
	_check(control.get_toast_count() == 0 and dismissed.has(expiring), "ToastStack expires timed notifications")
	var persistent: int = control.push_toast("Persistent", "info", 0.0)
	await create_timer(0.12).timeout
	_check(control.get_toast_count() == 1 and not dismissed.has(persistent), "ToastStack duration zero remains until dismissal")
	control.clear()
	var focused: int = control.push_toast("Focusable", "info", 0.05, "Inspect")
	await process_frame
	var focused_button: Button
	for button in control.find_children("*", "Button", true, false):
		if button.text == "Inspect":
			focused_button = button
	if is_instance_valid(focused_button):
		focused_button.grab_focus()
		await create_timer(0.12).timeout
		_check(control.get_toast_count() == 1 and not dismissed.has(focused), "ToastStack pauses expiry while an action has keyboard focus")
		focused_button.release_focus()
		await create_timer(0.12).timeout
		_check(control.get_toast_count() == 0 and dismissed.has(focused), "ToastStack resumes expiry after keyboard focus leaves")
	else:
		_check(false, "ToastStack builds its focused expiry test action")
	control.queue_free()
	await process_frame
