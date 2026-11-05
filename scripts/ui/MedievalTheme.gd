## MedievalTheme.gd
## Theme global do jogo (fontes, botões, painéis, sliders, tooltips), aplicado uma vez na raiz.
## Também define type variations usadas por UiKit: TitleLabel, DataLabel, HudPanel, ScrollPanel.
class_name MedievalTheme
extends RefCounted

static var _theme : Theme = null

static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme

static func _build() -> Theme:
	var t := Theme.new()
	var f_body := UiKit.get_font("Libre Baskerville")
	var f_data := UiKit.get_font("Source Sans 3")
	var f_title := UiKit.get_font("Cinzel")
	if f_data:
		t.default_font = f_data
	t.default_font_size = 18

	# Label
	t.set_color("font_color", "Label", UiKit.C_TEXT_WHITE)
	t.set_font_size("font_size", "Label", 18)
	t.set_type_variation("TitleLabel", "Label")
	if f_title:
		t.set_font("font", "TitleLabel", f_title)
	t.set_color("font_color", "TitleLabel", UiKit.C_TEXT_GOLD)
	t.set_color("font_outline_color", "TitleLabel", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "TitleLabel", 4)
	t.set_font_size("font_size", "TitleLabel", 32)
	t.set_type_variation("BodyLabel", "Label")
	if f_body:
		t.set_font("font", "BodyLabel", f_body)
	t.set_font_size("font_size", "BodyLabel", 17)
	t.set_type_variation("InkLabel", "Label")   # texto escuro sobre pergaminho
	if f_body:
		t.set_font("font", "InkLabel", f_body)
	t.set_color("font_color", "InkLabel", Color8(54, 36, 16))

	# Button
	var base := Color8(36, 28, 18)
	t.set_stylebox("normal", "Button", OrnateStyleBox.button(base, "normal"))
	t.set_stylebox("hover", "Button", OrnateStyleBox.button(base, "hover"))
	t.set_stylebox("pressed", "Button", OrnateStyleBox.button(base, "pressed"))
	t.set_stylebox("disabled", "Button", OrnateStyleBox.button(base, "disabled"))
	t.set_stylebox("focus", "Button", OrnateStyleBox.button(base, "focus"))
	t.set_color("font_color", "Button", UiKit.C_TEXT_GOLD)
	t.set_color("font_hover_color", "Button", UiKit.C_TEXT_GOLD2)
	t.set_color("font_focus_color", "Button", UiKit.C_TEXT_GOLD2)
	t.set_color("font_pressed_color", "Button", UiKit.C_TEXT_GOLD2)
	t.set_color("font_disabled_color", "Button", UiKit.C_TEXT_MUTED)
	if f_title:
		t.set_font("font", "Button", f_title)
	t.set_font_size("font_size", "Button", 20)

	# Panel
	t.set_stylebox("panel", "PanelContainer", OrnateStyleBox.panel())
	t.set_type_variation("HudPanel", "PanelContainer")
	var hud := OrnateStyleBox.new(Color(0.14, 0.105, 0.07), Color(0.06, 0.045, 0.03))
	hud.studs = false
	hud.cut = 0.0
	hud.set_content_margin_all(8.0)
	t.set_stylebox("panel", "HudPanel", hud)
	t.set_type_variation("ScrollPanel", "PanelContainer")
	t.set_stylebox("panel", "ScrollPanel", OrnateStyleBox.scroll())

	# Tooltip
	var tip := OrnateStyleBox.new(Color(0.1, 0.075, 0.045, 0.97), Color(0.06, 0.045, 0.03, 0.97))
	tip.studs = false
	tip.cut = 3.0
	tip.set_content_margin_all(10.0)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", UiKit.C_TEXT_WHITE)
	t.set_font_size("font_size", "TooltipLabel", 16)

	# Slider
	var track := UiKit.box(UiKit.C_BAR_BG, UiKit.C_BORDER_GOLD, 1, 3)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", UiKit.box(UiKit.C_BORDER_GOLD, UiKit.C_BORDER_GOLD, 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", UiKit.box(UiKit.C_TEXT_GOLD, UiKit.C_TEXT_GOLD, 0, 3))
	var knob := _knob()
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", knob)
	t.set_icon("grabber_disabled", "HSlider", knob)

	# CheckButton: texto simples com o mesmo visual de botão
	t.set_color("font_color", "CheckButton", UiKit.C_TEXT_WHITE)
	t.set_color("font_hover_color", "CheckButton", UiKit.C_TEXT_GOLD2)
	t.set_font_size("font_size", "CheckButton", 20)
	return t

static func _knob() -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 24:
		for x in 24:
			var d := Vector2(x - 11.5, y - 11.5).length()
			if d <= 10.5:
				var c := UiKit.C_TEXT_GOLD2 if d > 7.5 else UiKit.C_BORDER_GOLD
				if d <= 3.0:
					c = UiKit.C_BG_DARK
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
