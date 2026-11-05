## UiKit.gd
## Paleta medieval e fábricas de controles compartilhadas por todas as telas.
class_name UiKit
extends RefCounted

const C_BG_DARK       := Color8( 18,  14,  10, 255)
const C_BG_PANEL      := Color8( 28,  22,  14, 245)
const C_BORDER_GOLD   := Color8(148, 112,  38, 255)
const C_BORDER_GOLD2  := Color8(196, 156,  60, 180)
const C_TEXT_GOLD     := Color8(212, 180,  90, 255)
const C_TEXT_GOLD2    := Color8(240, 210, 120, 255)
const C_TEXT_WHITE    := Color8(238, 232, 218, 255)
const C_TEXT_MUTED    := Color8(160, 148, 120, 255)
const C_BLUE_MAIN     := Color8( 60, 110, 190, 255)
const C_BLUE_LIGHT    := Color8(120, 175, 255, 255)
const C_BLUE_DIM      := Color8( 35,  65, 120, 200)
const C_RED_MAIN      := Color8(160,  30,  30, 255)
const C_RED_BORDER    := Color8(200,  60,  60, 255)
const C_RED_DIM       := Color8( 90,  18,  18, 200)
const C_GREEN_MAIN    := Color8( 30, 100,  70, 255)
const C_GREEN_LIGHT   := Color8( 80, 180, 120, 255)
const C_GREEN_DIM     := Color8( 18,  58,  40, 200)
const C_BAR_BG        := Color8( 42,  34,  20, 255)
const C_BAR_GREEN     := Color8( 68, 168,  68, 255)
const C_BAR_ORANGE    := Color8(220, 140,  40, 255)
const C_SEPARATOR     := Color8(100,  80,  30, 140)
const C_PARCHMENT     := Color8(187, 163, 117, 255)

const FONT_PATHS := {
	"Cinzel": "res://assets/fonts/Cinzel.ttf",
	"Libre Baskerville": "res://assets/fonts/Baskerville.ttf",
	"Source Sans 3": "res://assets/fonts/SourceSans.ttf",
}

static var _font_cache : Dictionary = {}

static func get_font(hint: String) -> Font:
	if _font_cache.has(hint):
		return _font_cache[hint]
	var path: String = FONT_PATHS.get(hint, FONT_PATHS["Source Sans 3"])
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path)
	_font_cache[hint] = f
	return f

static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func make_label(txt: String, size: int, color: Color, font_hint: String = "Source Sans 3") -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	var f := get_font(font_hint)
	if f:
		lbl.add_theme_font_override("font", f)
	return lbl

static func box(bg: Color, border: Color, border_w: int = 2, radius: int = 6, padding: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	if padding > 0:
		sb.set_content_margin_all(padding)
	return sb

static func apply_panel_style(p: Control, bg: Color, border: Color, bw_top: float = 1.5, bw_bot: float = 1.5, bw_left: float = 1.5, bw_right: float = 1.5, radius: int = 0, padding: int = 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_top = int(bw_top)
	sb.border_width_bottom = int(bw_bot)
	sb.border_width_left = int(bw_left)
	sb.border_width_right = int(bw_right)
	sb.set_corner_radius_all(radius)
	if padding > 0:
		sb.set_content_margin_all(padding)
	p.add_theme_stylebox_override("panel", sb)

static func make_progress_bar(min_w: int, height: int) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = 0.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(min_w, height)
	pb.add_theme_stylebox_override("background", box(C_BAR_BG, C_BORDER_GOLD, 1, 3))
	pb.add_theme_stylebox_override("fill", box(C_BAR_GREEN, C_BAR_GREEN, 0, 3))
	return pb

static func make_hline() -> ColorRect:
	var c := ColorRect.new()
	c.custom_minimum_size = Vector2(0, 1)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.color = C_SEPARATOR
	return c

static func add_vseparator(parent: Container) -> void:
	var sep := VSeparator.new()
	var linha := StyleBoxLine.new()
	linha.color = C_SEPARATOR
	linha.vertical = true
	linha.thickness = 3
	linha.grow_end = -10.0
	linha.grow_begin = -10.0
	sep.add_theme_stylebox_override("separator", linha)
	parent.add_child(sep)

static func make_section(min_width: int, expand: bool, margins: Vector4i) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   margins.x)
	mc.add_theme_constant_override("margin_right",  margins.y)
	mc.add_theme_constant_override("margin_top",    margins.z)
	mc.add_theme_constant_override("margin_bottom", margins.w)
	if min_width > 0:
		mc.custom_minimum_size = Vector2(min_width, 0)
	if expand:
		mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return mc

static func _wire_button_sounds(btn: Button) -> void:
	btn.mouse_entered.connect(func(): if not btn.disabled: AudioManager.play_sfx("ui_hover", 0.05))
	btn.pressed.connect(func(): AudioManager.play_sfx("ui_click"))

## Botão de ação com ícone, título (LblTitle) e subtítulo (LblSub).
static func make_action_button(titulo: String, subtitulo: String, bg_dark: Color, icon_path: String = "", size: Vector2 = Vector2(210, 100)) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	var tex := load_texture(icon_path) if icon_path != "" else null
	if tex:
		var icon_box := CenterContainer.new()
		icon_box.custom_minimum_size = Vector2(50, 50)
		icon_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_box)
		var icon_rect := TextureRect.new()
		icon_rect.texture = tex
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(50, 50)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(icon_rect)

	var text_vbox := VBoxContainer.new()
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 0)
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)

	var lbl_title := make_label(titulo, 18, C_TEXT_GOLD, "Cinzel")
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_title.custom_minimum_size = Vector2(0, 30)
	lbl_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_title.name = "LblTitle"
	text_vbox.add_child(lbl_title)

	if subtitulo != "":
		var lbl_sub := make_label(subtitulo, 16, C_TEXT_WHITE, "Source Sans 3")
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_sub.custom_minimum_size = Vector2(0, 22)
		lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_sub.name = "LblSub"
		text_vbox.add_child(lbl_sub)

	var sb_normal := box(bg_dark, C_BORDER_GOLD, 2, 6)
	var sb_hover := box(bg_dark.lightened(0.14), C_TEXT_GOLD2, 2, 6)
	var sb_pressed := box(bg_dark.darkened(0.12), C_BORDER_GOLD, 2, 6)
	var sb_disabled := box(bg_dark.darkened(0.30), C_SEPARATOR, 2, 6)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	_wire_button_sounds(btn)
	return btn

## Botão simples de texto (menus).
static func make_menu_button(text: String, size: Vector2 = Vector2(360, 64), bg: Color = C_BG_PANEL, font_size: int = 22) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", C_TEXT_GOLD)
	btn.add_theme_color_override("font_hover_color", C_TEXT_GOLD2)
	btn.add_theme_color_override("font_disabled_color", C_TEXT_MUTED)
	var f := get_font("Cinzel")
	if f:
		btn.add_theme_font_override("font", f)
	btn.add_theme_stylebox_override("normal", box(bg, C_BORDER_GOLD, 2, 6))
	btn.add_theme_stylebox_override("hover", box(bg.lightened(0.14), C_TEXT_GOLD2, 2, 6))
	btn.add_theme_stylebox_override("pressed", box(bg.darkened(0.12), C_BORDER_GOLD, 2, 6))
	btn.add_theme_stylebox_override("disabled", box(bg.darkened(0.3), C_SEPARATOR, 2, 6))
	_wire_button_sounds(btn)
	return btn

## Célula "TÍTULO / valor" para grades de estatísticas. Retorna o Label do valor.
static func add_stat_cell(grid: GridContainer, label: String, value: String, color: Color, icon_path: String = "") -> Label:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	grid.add_child(vb)
	vb.add_child(make_label(label, 14, C_TEXT_MUTED, "Source Sans 3"))
	var lbl_val := make_label(value, 20, color, "Source Sans 3")
	var tex := load_texture(icon_path) if icon_path != "" else null
	if tex:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var icon_rect := TextureRect.new()
		icon_rect.texture = tex
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(24, 24)
		hb.add_child(icon_rect)
		hb.add_child(lbl_val)
		vb.add_child(hb)
	else:
		vb.add_child(lbl_val)
	return lbl_val

static func star_text(count: int, total: int = 3) -> String:
	return "★".repeat(count) + "☆".repeat(total - count)
