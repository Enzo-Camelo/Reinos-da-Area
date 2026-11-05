## CampaignMap.gd
## Mapa de campanha: a ilustração dos 5 cenários com 20 selos de fase ligados por uma trilha,
## estrelas, cadeados e briefing da fase em pergaminho.
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

## Posição de cada fase na imagem mapa.png (2576×1405, coordenadas da visualização).
const NODE_POS := [
	Vector2(235, 955), Vector2(430, 810), Vector2(330, 650), Vector2(540, 560),
	Vector2(770, 905), Vector2(885, 730), Vector2(955, 560), Vector2(800, 410),
	Vector2(1210, 830), Vector2(1350, 700), Vector2(1450, 540), Vector2(1330, 330),
	Vector2(1760, 520), Vector2(1730, 840), Vector2(1900, 940), Vector2(1960, 640),
	Vector2(2160, 640), Vector2(2200, 900), Vector2(2400, 650), Vector2(2360, 820),
]
const MAP_SRC := Vector2(2576, 1405)
const HEADER_H := 66.0

const INK := Color8(54, 36, 16)
const INK_MUTED := Color8(112, 82, 44)

var _brief : Control
var _brief_phase := 0
var _map_rect : Rect2
var _trail : Control
var _nodes : Array[PhaseNode] = []
## Se > 0, abre o briefing dessa fase ao entrar (botão Continuar do menu).
var auto_brief := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.C_BG_DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var w := 1920.0 - 80.0
	var h := w * MAP_SRC.y / MAP_SRC.x
	_map_rect = Rect2(40, HEADER_H, w, h)
	var tex := UiKit.load_texture("res://assets/ui/mapa.png")
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.position = _map_rect.position
		t.size = _map_rect.size
		add_child(t)

	_trail = Control.new()
	_trail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trail.draw.connect(_draw_trail)
	add_child(_trail)

	_build_nodes()
	add_child(_build_header())

	var focus_phase := clampi(GameState.unlocked_phase, 1, CampaignData.TOTAL_PHASES)
	_nodes[focus_phase - 1].grab_focus.call_deferred()
	if auto_brief > 0:
		_open_briefing.call_deferred(auto_brief)

func _screen_pos(i: int) -> Vector2:
	return _map_rect.position + NODE_POS[i] * (_map_rect.size.x / MAP_SRC.x)

func _build_nodes() -> void:
	_nodes.clear()
	var current := clampi(GameState.unlocked_phase, 1, CampaignData.TOTAL_PHASES)
	for i in CampaignData.TOTAL_PHASES:
		var p := i + 1
		var n := PhaseNode.new()
		n.setup(p, GameState.is_unlocked(p), GameState.get_stars(p), p == current and GameState.get_stars(p) == 0)
		n.position = _screen_pos(i) - Vector2(38, 38)
		var cfg := CampaignData.get_phase(p)
		if n.unlocked:
			n.tooltip_text = "Fase %d — %s\nTerreno: %s\nTempo: %ds por rodada\nMelhor: %s" % [
				p, cfg["scenario_name"], CampaignData.terrain_text(cfg), int(cfg["time"]), UiKit.star_text(GameState.get_stars(p))]
		else:
			n.tooltip_text = "Fase %d — bloqueada.\nConclua a fase anterior." % p
		n.pressed.connect(func(): _open_briefing(p))
		add_child(n)
		_nodes.append(n)

## Trilha tracejada entre os selos; trechos já percorridos em dourado.
func _draw_trail() -> void:
	for i in range(CampaignData.TOTAL_PHASES - 1):
		var a := _screen_pos(i)
		var b := _screen_pos(i + 1)
		var done := GameState.is_unlocked(i + 2)
		var col := Color(0.95, 0.78, 0.30, 0.95) if done else Color(0.18, 0.11, 0.05, 0.6)
		var mid := (a + b) / 2.0 + Vector2(0, -22.0 if (i % 2 == 0) else 22.0)
		var prev := a
		var dash_on := true
		var seg := 0.0
		for s in range(1, 25):
			var tt := s / 24.0
			var q := a.lerp(mid, tt).lerp(mid.lerp(b, tt), tt)
			seg += prev.distance_to(q)
			if dash_on:
				_trail.draw_line(prev, q, col, 4.0, true)
			if seg > (14.0 if dash_on else 9.0):
				dash_on = not dash_on
				seg = 0.0
			prev = q

func _build_header() -> Control:
	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = HEADER_H
	var sb := OrnateStyleBox.new(Color(0.16, 0.12, 0.08), Color(0.07, 0.05, 0.03))
	sb.studs = false
	sb.cut = 0.0
	sb.set_content_margin_all(5.0)
	bar.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	bar.add_child(hb)

	var b_back := UiKit.make_menu_button("◄ MENU", Vector2(170, 50), UiKit.C_BG_PANEL, 18)
	b_back.pressed.connect(func(): back.emit())
	hb.add_child(b_back)

	var title := UiKit.make_label("MAPA DE CAMPANHA", 36, UiKit.C_TEXT_GOLD2, "Cinzel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(title)

	var arch_txt := "Sem conselheiro" if GameState.archetype == "" else ArchetypeData.display_name(GameState.archetype)
	var l1 := UiKit.make_label("Conselheiro: %s" % arch_txt, 18, UiKit.C_TEXT_WHITE, "Source Sans 3")
	l1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l1)
	var pips := ResourcePips.new()
	pips.custom_minimum_size = Vector2(170, 30)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.tooltip_text = "Recursos Estratégicos (RE)"
	pips.mouse_filter = Control.MOUSE_FILTER_STOP
	pips.set_count(GameState.resources)
	hb.add_child(pips)

	var b_arch := UiKit.make_menu_button("TROCAR", Vector2(140, 50), UiKit.C_BG_PANEL, 18)
	b_arch.pressed.connect(func(): archetype_requested.emit())
	hb.add_child(b_arch)
	return bar

# ─────────────────────────────────────────────
#  BRIEFING (pergaminho desenrolado)
# ─────────────────────────────────────────────
func _open_briefing(p: int) -> void:
	if _brief and is_instance_valid(_brief):
		_brief.queue_free()
	_brief_phase = p
	var cfg := CampaignData.get_phase(p)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_brief = overlay

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := UiKit.ornate_panel("scroll")
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var t := UiKit.make_label("FASE %d — %s" % [p, str(cfg["scenario_name"]).to_upper()], 30, Color8(92, 40, 14), "Cinzel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(_rule())

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
		var k := UiKit.make_label(str(r[0]) + ":", 18, INK_MUTED, "Source Sans 3")
		k.custom_minimum_size = Vector2(200, 0)
		hb.add_child(k)
		var v := UiKit.make_label(str(r[1]), 18, INK, "Libre Baskerville")
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.custom_minimum_size = Vector2(540, 0)
		hb.add_child(v)
		vb.add_child(hb)

	vb.add_child(_rule())
	var best := "Melhor: %s   Precisão: %d%%" % [UiKit.star_text(GameState.get_stars(p)), int(GameState.get_best_ip(p))]
	var bl := UiKit.make_label(best, 19, Color8(120, 62, 10), "Source Sans 3")
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(bl)

	var arch := GameState.archetype
	var al: Label
	if arch == "":
		al = UiKit.make_label("Escolha um conselheiro antes de partir.", 18, Color8(150, 60, 20), "Source Sans 3")
	else:
		var d := ArchetypeData.get_data(arch)
		al = UiKit.make_label("Conselheiro: %s — %s / %s (RE: %d)" % [d["name"], d["passive_name"], d["active_name"], GameState.resources], 17, INK, "Source Sans 3")
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(al)

	var hb2 := HBoxContainer.new()
	hb2.alignment = BoxContainer.ALIGNMENT_CENTER
	hb2.add_theme_constant_override("separation", 20)
	vb.add_child(hb2)
	var b_cancel := UiKit.make_menu_button("VOLTAR  [Esc]", Vector2(210, 56), UiKit.C_BG_PANEL, 18)
	b_cancel.pressed.connect(_close_briefing)
	hb2.add_child(b_cancel)
	var b_arch := UiKit.make_menu_button("TROCAR CONSELHEIRO", Vector2(300, 56), UiKit.C_BG_PANEL, 18)
	b_arch.pressed.connect(func(): archetype_requested.emit())
	hb2.add_child(b_arch)
	var b_go := UiKit.make_menu_button("INICIAR FASE", Vector2(260, 56), UiKit.C_RED_DIM, 20)
	b_go.disabled = arch == ""
	b_go.pressed.connect(func(): phase_chosen.emit(p))
	hb2.add_child(b_go)
	if arch == "":
		b_arch.grab_focus.call_deferred()
	else:
		b_go.grab_focus.call_deferred()

	# o pergaminho se desenrola
	panel.resized.connect(func(): panel.pivot_offset = Vector2(panel.size.x / 2.0, 0))
	panel.scale = Vector2(1.0, 0.05)
	overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("map_unroll")

func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.36, 0.24, 0.1, 0.6)
	r.custom_minimum_size = Vector2(0, 2)
	return r

func _close_briefing() -> void:
	if _brief and is_instance_valid(_brief):
		_brief.queue_free()
	_brief = null
	if _brief_phase > 0 and _brief_phase <= _nodes.size():
		_nodes[_brief_phase - 1].grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _brief and is_instance_valid(_brief):
			_close_briefing()
		else:
			back.emit()

func _ring_text(ring: int) -> String:
	if ring >= 99:
		return "Total: o quadriculado cobre todo o mapa"
	if ring <= 0:
		return "Nenhuma: o inimigo não tem malha de apoio"
	return "%d célula ao redor do inimigo" % ring
