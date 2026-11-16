# Searchable dropdown

Use `searchable_dropdown.tscn`, or enable Forma UI and add a `FormaSearchableDropdown` node.

- `options: PackedStringArray`: option captions, preserving their original indices.
- `selected: int`: selected index; `-1` clears the selection.
- `placeholder: String`: shown when no option is selected.
- `disabled: bool`: disables interaction and closes an open popup.
- `select(index, emit_signal = true)`: change the selection programmatically.
- `get_filtered_indices(query) -> PackedInt32Array`: case-insensitive substring matches, with surrounding query whitespace ignored.
- `open_popup()` / `close_popup()`: control the search popup at runtime.
- `selection_changed(index, value)`: emitted when `select()` or user interaction changes the selection. Property assignments are silent.

Click the field or focus it and press Enter, Space, or Down. Type a search, use Up/Down or Home/End to choose a result, and press Enter to confirm. Escape or clicking outside dismisses the popup. The original options are never modified by filtering. Empty results cannot be selected. Popup interaction is disabled in the editor, while the field remains visible for layout work.
