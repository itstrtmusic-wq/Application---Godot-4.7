# Forma UI

A reusable Godot addon with five independent UI nodes. Each widget has its own script, scene, Inspector properties, and signals. No autoloads, external assets, or third-party dependencies.

## Try the gallery

Open `project.godot` in Godot and press **F5**. Every example is interactive; the gallery adapts to narrower windows.

```sh
godot --path .
```

Developed and tested with **Godot 4.6.3 Standard** using the Compatibility renderer. Other versions, C# integration, and touch devices have not been tested. The repository's original name mentions 4.7; this addon does not require or claim a 4.7 installation.

## Add it to another project

1. Copy **only `addons/forma_ui`** into your project's `addons` directory, keeping that path.
2. Enable **Forma UI** in **Project → Project Settings → Plugins**.
3. In **Create New Node**, search for `Forma` and choose a widget.

You can also instantiate any widget's `.tscn` directly without enabling the editor plugin. The demo, tests, and root project settings are not required. Widgets use ordinary `Control` layout, so they work inside containers or with anchors and offsets.

| Node | Purpose | Documentation |
| --- | --- | --- |
| `FormaSegmentedControl` | Single selection with keyboard navigation | [API](addons/forma_ui/segmented_control/README.md) |
| `FormaRangeSlider` | A numeric interval with two handles | [API](addons/forma_ui/range_slider/README.md) |
| `FormaSearchableDropdown` | Filterable selection with a searchable popup | [API](addons/forma_ui/searchable_dropdown/README.md) |
| `FormaTagInput` | Wrapping, removable tags with validation | [API](addons/forma_ui/tag_input/README.md) |
| `FormaToastStack` | Local notifications with expiry and optional actions | [API](addons/forma_ui/toast_stack/README.md) |

Example with nodes added to a scene:

```gdscript
func _ready() -> void:
    $RangeSlider.values_changed.connect(_on_range_changed)
    $TagInput.tags_changed.connect(func(tags): print(tags))
    $ToastStack.action_pressed.connect(func(id): print("Action on toast ", id))
    $ToastStack.push_toast("Settings saved", "success")

func _on_range_changed(lower: float, upper: float) -> void:
    print("Selected interval: ", lower, " to ", upper)
```

Editor node types are registered by the plugin; scripts avoid global `class_name` registrations. To instantiate in code, use `preload("res://addons/forma_ui/range_slider/range_slider.tscn").instantiate()` or preload the corresponding script and call `.new()`.

## Styling

Widgets have built-in defaults and work without a theme. Assign `addons/forma_ui/shared/default_theme.tres` to a common parent to start customizing. Duplicate it in your project before editing.

Colors are exposed under the **FormaUI** theme type: `background`, `surface`, `surface_hover`, `border`, `text`, `muted`, `accent`, `accent_soft`, `success`, and `danger`. The type also accepts `font` and `font_size`. The shared theme additionally styles native Buttons and LineEdits used inside composite widgets.

```gdscript
var custom_theme = preload("res://addons/forma_ui/shared/default_theme.tres").duplicate(true)
custom_theme.set_color("accent", "FormaUI", Color("69d8ba"))
custom_theme.set_color("accent_soft", "FormaUI", Color("193b34"))
$MyUI.theme = custom_theme
```

## Structure

```text
addons/forma_ui/         # Complete portable addon
  plugin.cfg / plugin.gd
  shared/               # Theme resource and styling helper
  icons/
  segmented_control/    # Each widget: script, scene, API notes
  range_slider/
  searchable_dropdown/
  tag_input/
  toast_stack/
demo/                   # Interactive gallery, separate from addon
tests/                  # Dependency-free Godot checks
tools/                  # Optional addon packaging script
```

## Checks and packaging

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/test_widgets.gd
godot --headless --path . --quit-after 120
python3 tools/package_addon.py
```

The test runner exits nonzero on failed checks. Tests cover selection and signals, keyboard/pointer input, numeric constraints, filtering, tag validation, and notification lifecycle. Headless checks do not establish touch or screen-reader support.

Packaging writes `dist/forma_ui-0.1.0.zip` containing the addon directory, without caches or demo files. The addon carries a copy of this repository's Apache 2.0 license.

