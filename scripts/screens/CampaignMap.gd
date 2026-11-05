## CampaignMap.gd
## Mapa de campanha: 5 cenários x 4 fases, estrelas, cadeados e briefing da fase.
extends Control
class_name CampaignMap

signal phase_chosen(phase: int)
signal archetype_requested
signal back

const SHAPE_TEXT := {
	"RECT": "Retângulos simples",
	"HALF_DIAGONAL": "Meios-blocos e arestas diagonais",
	"TRAPEZOID": "Trapézios e formas compostas",
	"COMPLEX": "Figuras complexas e preenchidas",
	"HOLLOW": "Malhas vazadas (áreas com buracos)",
}
const UNIT_TEXT := {
	"m2": "m² (1 bloco = 1 m²)",
	"m2_km2": "m², virando km² acima de 10.000 m² (1 bloco = 400 m²)",
	"km2": "km² (1 bloco = 50.000 m²)",
	"ha": "hectares (1 bloco = 1 ha)",
}
const CARTO_TEXT := {
	"ACTIVE": "Presente e ativa",
	"SILENT": "Presente, comenta só nas derrotas",
	"ABSENT": "Ausente",
}

var _brief : Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.C_BG_DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var tex := UiKit.load_texture("res://assets/ui/mapa.png")
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(t)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.02, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_right = -40
	root.offset_top = 24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	root.add_child(_build_header())

	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	for si in CampaignData.SCENARIOS.size():
		cols.add_child(_build_scenario(si))

func _build_header() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)

	var b_back := UiKit.make_menu_button("◄ MENU", Vector2(180, 52), UiKit.C_BG_PANEL, 18)
	b_back.pressed.connect(func(): back.emit())
	hb.add_child(b_back)

	var title := UiKit.make_label("MAPA DE CAMPANHA", 44, UiKit.C_TEXT_GOLD2, "Cinzel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 6)
	hb.add_child(title)

	var info := VBoxContainer.new()
	var arch_txt := "Sem arquétipo" if GameState.archetype == "" else ArchetypeData.display_name(GameState.archetype)
	var l1 := UiKit.make_label("Conselheiro: %s" % arch_txt, 20, UiKit.C_TEXT_WHITE, "Source Sans 3")
	var l2 := UiKit.make_label("Recursos Estratégicos: %s" % _pips(GameState.resources), 20, UiKit.C_TEXT_GOLD, "Source Sans 3")
	info.add_child(l1)
	info.add_child(l2)
	hb.add_child(info)

	var b_arch := UiKit.make_menu_button("TROCAR", Vector2(140, 52), UiKit.C_BG_PANEL, 18)
	b_arch.pressed.connect(func(): archetype_requested.emit())
	hb.add_child(b_arch)
	return hb

func _pips(n: int) -> String:
	return "●".repeat(maxi(n, 0)) + " (%d)" % n

func _build_scenario(si: int) -> Control:
	var sc: Dictionary = CampaignData.SCENARIOS[si]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiKit.apply_panel_style(panel, Color(0.07, 0.055, 0.035, 0.88), UiKit.C_BORDER_GOLD, 2, 2, 2, 2, 8, 16)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var roman := UiKit.make_label("CENÁRIO %s" % sc["roman"], 16, UiKit.C_TEXT_MUTED, "Source Sans 3")
	roman.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(roman)
	var name_l := UiKit.make_label(str(sc["name"]).to_upper(), 24, UiKit.C_TEXT_GOLD, "Cinzel")
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(300, 64)
	vb.add_child(name_l)
	var first_cfg := CampaignData.get_phase(int(sc["first"]))
	var blurb := UiKit.make_label(str(sc["blurb"]), 15, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(300, 90)
	vb.add_child(blurb)
	var facts := UiKit.make_label("Terreno: %s\nTempo: %ds por rodada" % [CampaignData.terrain_text(first_cfg), int(sc["time"])], 15, UiKit.C_TEXT_MUTED, "Source Sans 3")
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.custom_minimum_size = Vector2(300, 60)
	vb.add_child(facts)
	vb.add_child(UiKit.make_hline())

	for p in range(int(sc["first"]), int(sc["last"]) + 1):
		vb.add_child(_build_phase_button(p))
	return panel

func _build_phase_button(p: int) -> Button:
	var unlocked := GameState.is_unlocked(p)
	var stars := GameState.get_stars(p)
	var b := UiKit.make_menu_button("", Vector2(0, 64), UiKit.C_BG_PANEL if unlocked else Color(0.1, 0.1, 0.1, 0.8), 20)
	var suffix := UiKit.star_text(stars) if unlocked else "🔒"
	if not unlocked:
		suffix = "BLOQUEADA"
	b.text = "FASE %d   %s" % [p, suffix]
	b.disabled = not unlocked
	b.pressed.connect(func(): _open_briefing(p))
	return b

# ─────────────────────────────────────────────
#  BRIEFING
# ─────────────────────────────────────────────
func _open_briefing(p: int) -> void:
	if _brief and is_instance_valid(_brief):
		_brief.queue_free()
	var cfg := CampaignData.get_phase(p)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_brief = overlay

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -400
	panel.offset_right = 400
	panel.offset_top = -330
	panel.offset_bottom = 330
	UiKit.apply_panel_style(panel, UiKit.C_BG_DARK, UiKit.C_BORDER_GOLD, 3, 3, 3, 3, 8, 28)
	overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var t := UiKit.make_label("FASE %d — %s" % [p, str(cfg["scenario_name"]).to_upper()], 30, UiKit.C_TEXT_GOLD, "Cinzel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UiKit.make_hline())

	var rows := [
		["Terreno", CampaignData.terrain_text(cfg)],
		["Tempo por rodada", "%d segundos" % int(cfg["time"])],
		["Formas inimigas", SHAPE_TEXT[cfg["shape"]]],
		["Grade de referência", _ring_text(int(cfg["ref_ring"]))],
		["Unidade de medida", UNIT_TEXT[cfg["unit_mode"]]],
		["Cartógrafa", CARTO_TEXT[cfg["cartographer"]]],
		["Objetivo", "Dominar 70% do mapa em 10 rodadas" + (" — MORTE SÚBITA: um erro encerra a fase" if cfg["sudden_death"] else "")],
	]
	for r in rows:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var k := UiKit.make_label(str(r[0]) + ":", 18, UiKit.C_TEXT_MUTED, "Source Sans 3")
		k.custom_minimum_size = Vector2(190, 0)
		hb.add_child(k)
		var v := UiKit.make_label(str(r[1]), 18, UiKit.C_TEXT_WHITE, "Libre Baskerville")
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.custom_minimum_size = Vector2(500, 0)
		hb.add_child(v)
		vb.add_child(hb)

	vb.add_child(UiKit.make_hline())
	var best := "Melhor: %s   Precisão: %d%%" % [UiKit.star_text(GameState.get_stars(p)), int(GameState.get_best_ip(p))]
	var bl := UiKit.make_label(best, 18, UiKit.C_TEXT_GOLD2, "Source Sans 3")
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(bl)

	var arch := GameState.archetype
	var al: Label
	if arch == "":
		al = UiKit.make_label("Escolha um conselheiro antes de partir.", 18, UiKit.C_BAR_ORANGE, "Source Sans 3")
	else:
		var d := ArchetypeData.get_data(arch)
		al = UiKit.make_label("Conselheiro: %s — %s / %s (RE: %d)" % [d["name"], d["passive_name"], d["active_name"], GameState.resources], 17, UiKit.C_TEXT_WHITE, "Source Sans 3")
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(al)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var hb2 := HBoxContainer.new()
	hb2.alignment = BoxContainer.ALIGNMENT_CENTER
	hb2.add_theme_constant_override("separation", 20)
	vb.add_child(hb2)
	var b_cancel := UiKit.make_menu_button("VOLTAR", Vector2(180, 56), UiKit.C_BG_PANEL, 18)
	b_cancel.pressed.connect(func(): overlay.queue_free())
	hb2.add_child(b_cancel)
	var b_arch := UiKit.make_menu_button("TROCAR CONSELHEIRO", Vector2(300, 56), UiKit.C_BG_PANEL, 18)
	b_arch.pressed.connect(func(): archetype_requested.emit())
	hb2.add_child(b_arch)
	var b_go := UiKit.make_menu_button("INICIAR FASE", Vector2(260, 56), UiKit.C_GREEN_DIM, 20)
	b_go.disabled = arch == ""
	b_go.pressed.connect(func(): phase_chosen.emit(p))
	hb2.add_child(b_go)

func _ring_text(ring: int) -> String:
	if ring >= 99:
		return "Total: o quadriculado cobre todo o mapa"
	if ring <= 0:
		return "Nenhuma: o inimigo não tem malha de apoio"
	return "%d célula ao redor do inimigo" % ring
