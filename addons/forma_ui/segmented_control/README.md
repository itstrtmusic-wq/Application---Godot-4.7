# Segmented control

Use `segmented_control.tscn`, or enable Forma UI and add a `FormaSegmentedControl` node.

- `options: PackedStringArray`: segment captions. Each segment gets equal width.
- `selected: int`: selected index, clamped to the available options; `-1` for an empty control.
- `disabled: bool`: disables pointer and keyboard interaction.
- `select(index, emit_signal = true)`: select an item programmatically.
- `selection_changed(index)`: emitted when `select()` or user interaction changes the selection. Inspector/property assignments are silent.

Click a segment, or focus the control with Tab and use arrow keys, Home, or End. Theme colors come from the shared `FormaUI` theme type. The node expands horizontally and reports a minimum width based on its labels.
