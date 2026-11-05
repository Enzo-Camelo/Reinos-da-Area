## MainMenu.gd
## Menu principal: estandarte com os botões à esquerda e a capa emoldurada à direita.
extends Control
class_name MainMenu

signal play_pressed
signal continue_pressed
signal archetype_pressed
signal map_pressed
signal quit_pressed

var _archetype_lbl : Label
var _continue_btn : Button
var _first : Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/parchment.gdshader")
	mat.set_shader_parameter("base_color", Color(0.30, 0.22, 0.13))
	mat.set_shader_parameter("stain_color", Color(0.12, 0.08, 0.04))
	mat.set_shader_parameter("ink_color", Color(0.75, 0.6, 0.3))
	mat.set_shader_parameter("motif", 1)
	mat.set_shader_parameter("motif_strength", 0.08)
	mat.set_shader_parameter("rect_size", Vector2(1920, 1080))
	mat.set_shader_parameter("vignette", 0.7)
	bg.material = mat
	add_child(bg)

	_build_cover()
	_build_banner()

	var footer := UiKit.make_label("Reinos da Área - feito por: Enzo Camelo Vieira", 14, UiKit.C_TEXT_MUTED, "Source Sans 3")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -34
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)

	if _first:
		_first.grab_focus.call_deferred()

## Capa emoldurada, levemente inclinada, como uma carta sobre a mesa.
func _build_cover() -> void:
	var holder := Control.new()
	holder.size = Vector2(800, 900)
	holder.position = Vector2(1000, 90)
	holder.pivot_offset = holder.size / 2.0
	holder.rotation_degrees = 1.6
	add_child(holder)
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.45)
	shadow.position = Vector2(14, 16)
	shadow.size = holder.size
	holder.add_child(shadow)
	var frame := PanelContainer.new()
	frame.size = holder.size
	frame.add_theme_stylebox_override("panel", OrnateStyleBox.new(Color(0.2, 0.15, 0.09), Color(0.1, 0.07, 0.04)))
	holder.add_child(frame)
	var tex := UiKit.load_texture("res://assets/ui/capa.png")
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(tr)

func _build_banner() -> void:
	var panel := UiKit.ornate_panel()
	panel.position = Vector2(110, 70)
	panel.custom_minimum_size = Vector2(700, 940)
	panel.size = Vector2(700, 940)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	var crest := TextureRect.new()
	crest.texture = UiKit.load_texture("res://assets/icons/brasao.png")
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.custom_minimum_size = Vector2(130, 130)
	vb.add_child(crest)

	var title := UiKit.make_label("REINOS DA ÁREA", 58, UiKit.C_TEXT_GOLD2, "Cinzel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)
	var motto := UiKit.make_label("Conquiste territórios. Calcule para vencer.", 20, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(motto)
	vb.add_child(UiKit.make_hline())

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	vb.add_child(gap)

	var has_progress := GameState.archetype != "" and GameState.unlocked_phase > 1
	_continue_btn = UiKit.make_menu_button("CONTINUAR — FASE %d" % GameState.unlocked_phase, Vector2(440, 64), UiKit.C_GREEN_DIM)
	_continue_btn.visible = has_progress
	var b_play := UiKit.make_menu_button("JOGAR CAMPANHA", Vector2(440, 64))
	var b_arch := UiKit.make_menu_button("CONSELHEIRO", Vector2(440, 64))
	var b_map := UiKit.make_menu_button("MAPA DE CENÁRIOS", Vector2(440, 64))
	var b_opt := UiKit.make_menu_button("OPÇÕES", Vector2(440, 64))
	var b_quit := UiKit.make_menu_button("SAIR", Vector2(440, 64), UiKit.C_RED_DIM)
	for b in [_continue_btn, b_play, b_arch, b_map, b_opt, b_quit]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(b)
	_first = _continue_btn if has_progress else b_play
	_continue_btn.pressed.connect(func(): continue_pressed.emit())
	b_play.pressed.connect(func(): play_pressed.emit())
	b_arch.pressed.connect(func(): archetype_pressed.emit())
	b_map.pressed.connect(func(): map_pressed.emit())
	b_opt.pressed.connect(_open_options)
	b_quit.pressed.connect(func(): quit_pressed.emit())

	_archetype_lbl = UiKit.make_label(_archetype_text(), 18, UiKit.C_TEXT_MUTED, "Source Sans 3")
	_archetype_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_archetype_lbl)

func _archetype_text() -> String:
	if GameState.archetype == "":
		return "Nenhum conselheiro escolhido ainda"
	return "Conselheiro atual: %s" % ArchetypeData.display_name(GameState.archetype)

func _open_options() -> void:
	var o := OptionsPanel.new()
	o.progress_reset.connect(func():
		_archetype_lbl.text = _archetype_text()
		_continue_btn.visible = false)
	add_child(o)
