@tool
extends EditorPlugin

const TYPES = {
	"FormaSegmentedControl": preload("segmented_control/segmented_control.gd"),
	"FormaRangeSlider": preload("range_slider/range_slider.gd"),
	"FormaSearchableDropdown": preload("searchable_dropdown/searchable_dropdown.gd"),
	"FormaTagInput": preload("tag_input/tag_input.gd"),
	"FormaToastStack": preload("toast_stack/toast_stack.gd"),
}
const ICON = preload("icons/widget.svg")

func _enter_tree() -> void:
	for type_name in TYPES:
		add_custom_type(type_name, "Control", TYPES[type_name], ICON)

func _exit_tree() -> void:
	for type_name in TYPES:
		remove_custom_type(type_name)
