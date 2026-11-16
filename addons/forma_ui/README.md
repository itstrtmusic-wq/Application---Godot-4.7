# Forma UI · 0.1.0

Five independent `Control` nodes for Godot 4. Tested on Godot 4.6.3 Standard.

Copy this entire folder to `res://addons/forma_ui`, then enable **Forma UI** under **Project → Project Settings → Plugins**. Search `Forma` in the Create Node dialog. Each widget can also be instantiated directly from its `.tscn` without enabling the plugin.

- [SegmentedControl](segmented_control/README.md)
- [RangeSlider](range_slider/README.md)
- [SearchableDropdown](searchable_dropdown/README.md)
- [TagInput](tag_input/README.md)
- [ToastStack](toast_stack/README.md)

Each widget works independently; keep `shared` and the widget's own directory when instancing scenes. The editor plugin registers all five types, so keep the entire addon when using the plugin. There are no global services or demo dependencies.

For theming, duplicate `shared/default_theme.tres` into your project and assign it to a parent Control. Custom colors live under the `FormaUI` theme type: `background`, `surface`, `surface_hover`, `border`, `text`, `muted`, `accent`, `accent_soft`, `success`, `danger`. Optional `font` and `font_size` are supported under the same type.

Licensed under Apache 2.0; see [LICENSE](LICENSE).
