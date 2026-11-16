@tool
extends RefCounted
## Shared defaults. Override colors under the "FormaUI" theme type.

const COLORS = {
	"background": Color("0e1015"),
	"surface": Color("191c25"),
	"surface_hover": Color("242836"),
	"border": Color("333847"),
	"text": Color("edf0f7"),
	"muted": Color("979fb3"),
	"accent": Color("b7a1ff"),
	"accent_soft": Color("302944"),
	"success": Color("91d9bc"),
	"danger": Color("f5a2ae"),
}

static func color(control: Control, key: StringName) -> Color:
	if control.has_theme_color(key, &"FormaUI"):
		return control.get_theme_color(key, &"FormaUI")
	return COLORS.get(String(key), Color.WHITE)

static func box(fill: Color, border: Color = Color.TRANSPARENT, radius: int = 10) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.content_margin_left = 12
	result.content_margin_right = 12
	result.content_margin_top = 9
	result.content_margin_bottom = 9
	return result

static func font(control: Control) -> Font:
	return control.get_theme_font(&"font", &"FormaUI")

static func font_size(control: Control) -> int:
	if control.has_theme_font_size(&"font_size", &"FormaUI"):
		return control.get_theme_font_size(&"font_size", &"FormaUI")
	return 14

static func make_theme() -> Theme:
	var result = Theme.new()
	result.default_font_size = 14
	for key in COLORS:
		result.set_color(key, &"FormaUI", COLORS[key])
	result.set_color(&"font_color", &"Label", COLORS.text)
	result.set_color(&"font_color", &"Button", COLORS.text)
	result.set_color(&"font_hover_color", &"Button", COLORS.text)
	result.set_color(&"font_focus_color", &"Button", COLORS.text)
	result.set_stylebox(&"normal", &"Button", box(COLORS.surface, COLORS.border))
	result.set_stylebox(&"hover", &"Button", box(COLORS.surface_hover, COLORS.accent))
	result.set_stylebox(&"pressed", &"Button", box(COLORS.accent_soft, COLORS.accent))
	result.set_stylebox(&"focus", &"Button", box(Color.TRANSPARENT, COLORS.accent))
	result.set_stylebox(&"normal", &"LineEdit", box(COLORS.background, COLORS.border))
	result.set_stylebox(&"focus", &"LineEdit", box(Color.TRANSPARENT, COLORS.accent))
	result.set_color(&"font_color", &"LineEdit", COLORS.text)
	result.set_color(&"font_placeholder_color", &"LineEdit", COLORS.muted)
	result.set_color(&"caret_color", &"LineEdit", COLORS.accent)
	result.set_color(&"selection_color", &"LineEdit", COLORS.accent_soft)
	return result
