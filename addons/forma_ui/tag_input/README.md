# FormaTagInput

Instance `tag_input.tscn`, or create **FormaTagInput** with the addon enabled.

- Inspector: `tags`, `placeholder`, `max_tags` (0 = unlimited), `disabled`.
- Methods: `add_tag(text) -> bool`, `remove_tag(text) -> bool`, `clear_tags()`.
- Signals: `tag_added(tag)`, `tag_removed(tag)`, `tags_changed(tags)`, `tag_rejected(tag, reason)`.
- Rejection reasons: `empty`, `duplicate`, `limit`, `disabled`.

Enter or comma commits text. Empty-field Backspace removes the last tag. Chips wrap and can be removed by click or keyboard. Long tags ellipsize to the available width while retaining their full value in the tooltip; resizing preserves draft text and focus. Tags are trimmed and duplicates are compared without case. Assign a new PackedStringArray to `tags` to update programmatically; direct assignment is normalized without emitting user-change signals. `max_tags` limits additions without deleting existing tags. Disabled blocks all mutation methods and user edits.
