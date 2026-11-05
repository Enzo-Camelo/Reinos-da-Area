## MainMenu.gd
## Tela inicial: título, lema, Jogar Campanha, Selecionar Arquétipo, Mapa de Cenários, Opções e Sair.
extends Control
class_name MainMenu

signal play_pressed
signal archetype_pressed
signal map_pressed
signal quit_pressed

var _options_panel : PanelContainer
var _reset_btn : Button
var _reset_armed := false
var _archetype_lbl : Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg_tex := UiKit.load_texture("res://assets/ui/capa.png")
	if bg_tex:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	else:
		var flat := ColorRect.new()
		flat.color = UiKit.C_BG_DARK
		flat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(flat)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.02, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)

	var crown := UiKit.load_texture("res://assets/ui/coroa.png")
	if crown:
		var cr := TextureRect.new()
		cr.texture = crown
		cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cr.custom_minimum_size = Vector2(96, 96)
		vb.add_child(cr)

	var title := UiKit.make_label("REINOS DA ÁREA", 96, UiKit.C_TEXT_GOLD2, "Cinzel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 8)
	vb.add_child(title)

	var line := ColorRect.new()
	line.color = UiKit.C_BORDER_GOLD
	line.custom_minimum_size = Vector2(520, 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(line)

	var motto := UiKit.make_label("Conquiste territórios. Calcule para vencer.", 28, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(motto)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 28)
	vb.add_child(gap)

	var b_play := UiKit.make_menu_button("JOGAR CAMPANHA")
	var b_arch := UiKit.make_menu_button("SELECIONAR ARQUÉTIPO")
	var b_map := UiKit.make_menu_button("MAPA DE CENÁRIOS")
	var b_opt := UiKit.make_menu_button("OPÇÕES")
	var b_quit := UiKit.make_menu_button("SAIR", Vector2(360, 64), UiKit.C_RED_DIM)
	for b in [b_play, b_arch, b_map, b_opt, b_quit]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(b)
	b_play.pressed.connect(func(): play_pressed.emit())
	b_arch.pressed.connect(func(): archetype_pressed.emit())
	b_map.pressed.connect(func(): map_pressed.emit())
	b_opt.pressed.connect(_toggle_options)
	b_quit.pressed.connect(func(): quit_pressed.emit())

	_archetype_lbl = UiKit.make_label(_archetype_text(), 18, UiKit.C_TEXT_MUTED, "Source Sans 3")
	_archetype_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_archetype_lbl)

	var footer := UiKit.make_label("Reinos da Área v0.2 — Enzo Camelo Vieira · Gabriel Luis de Santana · Bruno Faria Travessini", 14, UiKit.C_TEXT_MUTED, "Source Sans 3")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -36
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)

	_build_options()

func _archetype_text() -> String:
	if GameState.archetype == "":
		return "Nenhum arquétipo escolhido ainda"
	return "Conselheiro atual: %s" % ArchetypeData.display_name(GameState.archetype)

func _build_options() -> void:
	_options_panel = PanelContainer.new()
	_options_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_options_panel.custom_minimum_size = Vector2(620, 420)
	_options_panel.offset_left = -310
	_options_panel.offset_right = 310
	_options_panel.offset_top = -210
	_options_panel.offset_bottom = 210
	UiKit.apply_panel_style(_options_panel, UiKit.C_BG_DARK, UiKit.C_BORDER_GOLD, 3, 3, 3, 3, 8, 24)
	_options_panel.visible = false
	add_child(_options_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	_options_panel.add_child(vb)

	var t := UiKit.make_label("OPÇÕES", 36, UiKit.C_TEXT_GOLD, "Cinzel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UiKit.make_hline())

	_add_slider(vb, "Música", GameState.music_volume, func(v: float):
		GameState.music_volume = v
		AudioManager.set_music_volume(v))
	_add_slider(vb, "Efeitos sonoros", GameState.sfx_volume, func(v: float):
		GameState.sfx_volume = v
		AudioManager.set_sfx_volume(v)
		AudioManager.play_sfx("ui_click"))

	_reset_btn = UiKit.make_menu_button("REINICIAR PROGRESSO", Vector2(360, 52), UiKit.C_RED_DIM, 18)
	_reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reset_btn.pressed.connect(_on_reset_pressed)
	vb.add_child(_reset_btn)

	var close := UiKit.make_menu_button("FECHAR", Vector2(240, 52), UiKit.C_GREEN_DIM, 18)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_toggle_options)
	vb.add_child(close)

func _add_slider(parent: Control, text: String, value: float, on_change: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	parent.add_child(hb)
	var l := UiKit.make_label(text, 22, UiKit.C_TEXT_WHITE, "Source Sans 3")
	l.custom_minimum_size = Vector2(200, 0)
	hb.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(300, 32)
	s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	s.value_changed.connect(on_change)
	s.drag_ended.connect(func(_changed: bool): GameState.save_game())
	hb.add_child(s)

func _toggle_options() -> void:
	_options_panel.visible = not _options_panel.visible
	_reset_armed = false
	_reset_btn.text = "REINICIAR PROGRESSO"
	GameState.save_game()

func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = "CONFIRMAR? (APAGA TUDO)"
		return
	GameState.reset_progress()
	_reset_armed = false
	_reset_btn.text = "PROGRESSO REINICIADO"
	_archetype_lbl.text = _archetype_text()
