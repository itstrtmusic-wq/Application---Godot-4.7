# FormaToastStack

Instance `toast_stack.tscn`, or create **FormaToastStack** with the addon enabled. Position it in any UI container or screen corner; it does not require an autoload. Notifications align to the bottom of its allocated area, and empty space passes mouse input through.

```gdscript
var id = $ToastStack.push_toast("Settings saved", "success")
$ToastStack.push_toast("Item removed", "info", 6.0, "Undo")
$ToastStack.push_toast("Connection lost", "error", 0.0) # Persistent
$ToastStack.dismiss(id)
```

- Inspector: `max_visible` (minimum 1), `default_duration` (seconds).
- Methods: `push_toast(message, kind="info", duration=-1.0, action_text="") -> int`, `dismiss(id)`, `clear()`, `get_toast_count() -> int`.
- Kinds: `info`, `success`, `warning`, `error`; other values become `info`.
- Duration: negative uses `default_duration`; 0 persists. Hover or keyboard focus within a toast pauses expiry so its action and dismiss controls remain reachable.
- At capacity, the oldest toast is dismissed before the new one appears.
- Signals: `toast_dismissed(id)`, `action_pressed(id)`. An action emits its signal then dismisses that toast. IDs increase per instance.
