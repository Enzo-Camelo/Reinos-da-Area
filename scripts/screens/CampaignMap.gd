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
const CARTO_TEXT := {
	"ACTIVE": "Presente e ativa",
	"SILENT": "Presente, comenta só nas derrotas",
	"ABSENT": "Ausente",
}

## Traçado da estrada desenhada em mapa.png (coordenadas numa imagem de 2576×1405).
const ROAD := [
	# Planícies
	Vector2(185, 995), Vector2(245, 952), Vector2(315, 922), Vector2(380, 892), Vector2(445, 852),
	Vector2(469, 822), Vector2(445, 795), Vector2(380, 760), Vector2(320, 725), Vector2(302, 697),
	Vector2(325, 670), Vector2(390, 632), Vector2(445, 587), Vector2(495, 566), Vector2(550, 566),
	Vector2(605, 582), Vector2(650, 575), Vector2(690, 567),
	# passagem atrás das montanhas e Vales
	Vector2(735, 508), Vector2(790, 477), Vector2(860, 486), Vector2(897, 522), Vector2(892, 565),
	Vector2(875, 600), Vector2(900, 630), Vector2(935, 670), Vector2(932, 710), Vector2(895, 765),
	Vector2(845, 825), Vector2(830, 860), Vector2(860, 895), Vector2(925, 915),
	# Serra
	Vector2(1000, 900), Vector2(1050, 872), Vector2(1085, 830), Vector2(1105, 770), Vector2(1140, 710),
	Vector2(1195, 665), Vector2(1250, 630), Vector2(1300, 602), Vector2(1350, 592), Vector2(1400, 591),
	Vector2(1475, 600), Vector2(1540, 627), Vector2(1595, 668),
	# pedras do Arquipélago
	Vector2(1651, 700), Vector2(1706, 725), Vector2(1749, 758), Vector2(1816, 788), Vector2(1856, 781),
	Vector2(1906, 795), Vector2(1956, 785), Vector2(1996, 770), Vector2(2040, 759),
]
## Trecho da estrada de cada cenário: as 4 fases ficam igualmente espaçadas entre os dois pontos.
const REGION_SPANS := [
	[Vector2(315, 922), Vector2(640, 576)],
	[Vector2(778, 480), Vector2(905, 910)],
	[Vector2(1085, 830), Vector2(1460, 598)],
	[Vector2(1630, 690), Vector2(1996, 770)],
]
## Abismo (fases 17–20): um selo logo abaixo de cada pedra voadora, sem tampá-la.
const ROCK_NODES := [
	Vector2(2120, 740),   # pedra da esquerda
	Vector2(2260, 720),  # pedra abismo
	Vector2(2430, 635),   # cristal da direita
	Vector2(2334, 420),   # ilha do topo: o Império das Formas
]
## Ponto de curvatura de cada salto (fases 16→17, 17→18, 18→19 e 19→20).
## A linha é puxada na direção do ponto, sem chegar a tocá-lo. null = linha reta.
## Para a linha chegar por baixo de uma fase, o ponto precisa ter o mesmo x dela.
const JUMP_CONTROLS := [
	null,                 # 16→17: reta
	Vector2(2190, 645),   # 17→18: arco suave por cima
	Vector2(2400, 962),   # 18→19: curva por baixo
	Vector2(2334, 545),   # 19→20: curva leve, entrando por baixo da 20
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
var _node_pos : Array[Vector2] = []
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

	_node_pos = node_positions()
	_trail = Control.new()
	_trail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trail.draw.connect(_draw_trail)
	add_child(_trail)

	_build_nodes()
	add_child(_build_header())

	var focus_phase := GameState.latest_playable_phase()
	if GameState.star_gate_text() != "":
		add_child(_build_gate_notice(GameState.star_gate_text()))
	# "Continuar" não abre uma fase travada por falta de estrelas
	if auto_brief > 0 and not GameState.is_unlocked(auto_brief):
		auto_brief = 0
	_nodes[focus_phase - 1].grab_focus.call_deferred()
	if not GameState.has_seen("prologue"):
		_tell_story("prologue", StoryData.prologue(), func():
			if auto_brief > 0:
				_open_briefing(auto_brief))
	elif auto_brief > 0:
		_open_briefing.call_deferred(auto_brief)

## Faixa no rodapé avisando por que o próximo terreno está fechado.
func _build_gate_notice(text: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.box(Color(0.12, 0.08, 0.04, 0.96), UiKit.C_BORDER_GOLD, 2, 6, 10))
	p.position = Vector2(960 - 600, 1080 - 70)
	p.custom_minimum_size = Vector2(1200, 0)
	var l := UiKit.make_label("★ " + text, 20, UiKit.C_TEXT_GOLD2, "Libre Baskerville")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## Mostra uma cena da história, marca como vista e segue em frente.
func _tell_story(key: String, pages: Array, then: Callable) -> void:
	var s := StoryOverlay.new()
	s.pages = pages
	s.finished.connect(func():
		GameState.mark_seen(key)
		then.call_deferred())
	add_child(s)

## Distância percorrida na estrada até o ponto dela mais próximo de p.
static func road_distance(p: Vector2) -> float:
	var walked := 0.0
	var best := 0.0
	var best_gap := INF
	for i in range(ROAD.size() - 1):
		var a: Vector2 = ROAD[i]
		var b: Vector2 = ROAD[i + 1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var gap := p.distance_to(q)
		if gap < best_gap:
			best_gap = gap
			best = walked + a.distance_to(q)
		walked += a.distance_to(b)
	return best

static func road_point(distance: float) -> Vector2:
	var left := maxf(distance, 0.0)
	for i in range(ROAD.size() - 1):
		var a: Vector2 = ROAD[i]
		var b: Vector2 = ROAD[i + 1]
		var length := a.distance_to(b)
		if left <= length:
			return a.lerp(b, left / length)
		left -= length
	return ROAD[ROAD.size() - 1]

## Posição de cada fase na imagem (fase 1 primeiro): estrada até a 16, pedras voadoras depois.
static func node_positions() -> Array[Vector2]:
	var out : Array[Vector2] = []
	for span in REGION_SPANS:
		var from := road_distance(span[0])
		var to := road_distance(span[1])
		for k in 4:
			out.append(road_point(lerpf(from, to, k / 3.0)))
	for p in ROCK_NODES:
		out.append(p)
	return out

## Pontos do caminho entre a fase de índice i e a seguinte: pela estrada ou num salto em arco.
static func path_between(i: int) -> PackedVector2Array:
	var nodes := node_positions()
	var a := nodes[i]
	var b := nodes[i + 1]
	var points := PackedVector2Array()
	var first_jump := REGION_SPANS.size() * 4 - 1
	if i < first_jump:
		var from := road_distance(a)
		var to := road_distance(b)
		var steps := maxi(2, int((to - from) / 4.0))
		for s in steps + 1:
			points.append(road_point(lerpf(from, to, s / float(steps))))
	else:
		var control: Variant = JUMP_CONTROLS[i - first_jump]
		var bend: Vector2 = (a + b) / 2.0 if control == null else control
		for s in 49:
			var t := s / 48.0
			points.append(a.lerp(bend, t).lerp(bend.lerp(b, t), t))
	return points

func _to_screen(p: Vector2) -> Vector2:
	return _map_rect.position + p * (_map_rect.size.x / MAP_SRC.x)

func _screen_pos(i: int) -> Vector2:
	return _to_screen(_node_pos[i])

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
		elif GameState.missing_stars(p) > 0:
			n.tooltip_text = "Fase %d — bloqueada.\nEste terreno exige %d estrelas (você tem %d)." % [
				p, CampaignData.stars_required(p), GameState.total_stars()]
		else:
			n.tooltip_text = "Fase %d — bloqueada.\nConclua a fase anterior." % p
		n.pressed.connect(func(): _open_briefing(p))
		add_child(n)
		_nodes.append(n)

## Trilha tracejada (estrada e saltos); trechos já percorridos em dourado.
func _draw_trail() -> void:
	const DASH := 12.0
	const SPACE := 10.0
	for i in range(CampaignData.TOTAL_PHASES - 1):
		var done := GameState.is_unlocked(i + 2)
		var col := Color(1.0, 0.82, 0.28) if done else Color(0.93, 0.88, 0.74, 0.85)
		var path := path_between(i)
		var dash := PackedVector2Array([_to_screen(path[0])])
		var drawing := true
		var walked := 0.0
		for j in range(1, path.size()):
			var from := _to_screen(path[j - 1])
			var to := _to_screen(path[j])
			walked += from.distance_to(to)
			if drawing:
				dash.append(to)
			if walked >= (DASH if drawing else SPACE):
				if drawing:
					_stroke(dash, col)
				drawing = not drawing
				dash = PackedVector2Array([to])
				walked = 0.0
		if drawing and dash.size() > 1:
			_stroke(dash, col)

func _stroke(points: PackedVector2Array, col: Color) -> void:
	_trail.draw_polyline(points, Color(0.12, 0.07, 0.02, 0.85), 8.0, true)
	_trail.draw_polyline(points, col, 4.0, true)

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
	var total := UiKit.make_label("★ %d" % GameState.total_stars(), 22, UiKit.C_TEXT_GOLD2, "Source Sans 3")
	total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total.tooltip_text = "Estrelas somadas. Cada novo terreno exige mais %d." % CampaignData.STARS_PER_SCENARIO
	total.mouse_filter = Control.MOUSE_FILTER_STOP
	hb.add_child(total)
	var pips := ResourcePips.new()
	pips.custom_minimum_size = Vector2(170, 30)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.tooltip_text = "Recursos Estratégicos (RE)"
	pips.mouse_filter = Control.MOUSE_FILTER_STOP
	pips.set_count(GameState.resources)
	hb.add_child(pips)

	var b_guide := UiKit.make_menu_button("COMO JOGAR", Vector2(200, 50), UiKit.C_BG_PANEL, 17)
	b_guide.pressed.connect(func(): add_child(GuidePanel.new()))
	hb.add_child(b_guide)

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
	# primeira visita a um cenário: a história (com a lição da região) vem antes do briefing
	var chapter_idx := int(cfg["scenario_idx"])
	var chapter_key := "chapter_%d" % chapter_idx
	if GameState.is_unlocked(p) and not GameState.has_seen(chapter_key):
		_tell_story(chapter_key, StoryData.chapter(chapter_idx), _open_briefing.bind(p))
		return

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
	panel.custom_minimum_size = Vector2(1240, 0)
	center.add_child(panel)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 26)
	panel.add_child(columns)
	columns.add_child(_build_king_column())

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	columns.add_child(vb)

	var t := UiKit.make_label("FASE %d — %s" % [p, str(cfg["scenario_name"]).to_upper()], 30, Color8(92, 40, 14), "Cinzel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var why_title := UiKit.make_label("POR QUE VOCÊ MARCHA", 17, Color8(92, 40, 14), "Cinzel")
	why_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(why_title)
	var why := UiKit.make_label(StoryData.mission(p), 18, INK, "Libre Baskerville")
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size = Vector2(760, 0)
	vb.add_child(why)
	vb.add_child(_rule())
	var foe := StoryData.rival(p)
	var foe_lbl := UiKit.make_label("Rival: %s\n“%s”" % [foe["name"], foe["quote"]], 19, Color8(130, 40, 20), "Libre Baskerville")
	foe_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foe_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foe_lbl.custom_minimum_size = Vector2(760, 0)
	vb.add_child(foe_lbl)
	vb.add_child(_rule())

	var rows := [
		["Terreno", CampaignData.terrain_text(cfg)],
		["Tempo por rodada", "%d segundos" % int(cfg["time"])],
		["Formas inimigas", SHAPE_TEXT[cfg["shape"]]],
		["Grade de referência", _ring_text(int(cfg["ref_ring"]))],
		["Escala do mapa", UnitFormatter.scale_text(cfg)],
		["Cartógrafa", CARTO_TEXT[cfg["cartographer"]]],
		["Objetivo", "Terminar as 10 rodadas com 60% de Domínio ou mais" + (" — MORTE SÚBITA: um erro encerra a fase" if cfg["sudden_death"] else "")],
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
	var best := "Melhor: %s   Precisão: %d%%\nBronze 60%% (passa)   •   Prata 80%%   •   Ouro 100%% de Domínio" % [
		UiKit.star_text(GameState.get_stars(p)), int(GameState.get_best_ip(p))]
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
	var b_cancel := UiKit.make_menu_button("VOLTAR  [Esc]", Vector2(190, 56), UiKit.C_BG_PANEL, 18)
	b_cancel.pressed.connect(_close_briefing)
	hb2.add_child(b_cancel)
	var b_story := UiKit.make_menu_button("HISTÓRIA", Vector2(170, 56), UiKit.C_BG_PANEL, 18)
	b_story.pressed.connect(func(): _tell_story(chapter_key, StoryData.chapter(chapter_idx), func(): pass))
	hb2.add_child(b_story)
	var b_arch := UiKit.make_menu_button("TROCAR CONSELHEIRO", Vector2(300, 56), UiKit.C_BG_PANEL, 18)
	b_arch.pressed.connect(func(): archetype_requested.emit())
	hb2.add_child(b_arch)
	var b_go := UiKit.make_menu_button("INICIAR FASE", Vector2(230, 56), UiKit.C_RED_DIM, 20)
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

## Retrato do protagonista no briefing: o jogador vê quem ele é nesta guerra.
func _build_king_column() -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	var portrait := TextureRect.new()
	portrait.texture = UiKit.load_texture(StoryData.PORTRAIT_KING)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(290, 515)
	col.add_child(portrait)
	for line in [["ARQUITETO-REI", 24, Color8(92, 40, 14), "Cinzel"], ["Este é você", 16, INK_MUTED, "Source Sans 3"]]:
		var l := UiKit.make_label(line[0], line[1], line[2], line[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	return col

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
