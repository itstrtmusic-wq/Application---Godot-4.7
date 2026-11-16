# FormaRangeSlider

Instance `range_slider.tscn`, or create **FormaRangeSlider** with the addon enabled.

- Inspector: `min_value`, `max_value`, `step`, `lower_value`, `upper_value`, `disabled`.
- Method: `set_values(lower, upper, emit_signal=true)` sorts, snaps, and clamps a pair of values. Emits once only if the interval changed.
- Signals: `values_changed(lower, upper)`, `drag_started()`, `drag_ended()`.
- `active_handle`: 0 selects the lower handle, 1 selects the upper handle.

Drag a handle or click the track to move the nearest handle. Arrow keys move the active handle by `step`. Tab moves from the lower to the upper handle and then out of the widget; Shift+Tab reverses this. Home/End move the active handle to its allowed endpoint without crossing the other handle.

Steps are relative to `min_value`; `step=0` allows continuous values. Inverted bounds behave as a zero-length interval at `min_value` until corrected. Assigning Inspector properties is silent; use `set_values` for change notifications. Disabled blocks user input but permits programmatic updates.
