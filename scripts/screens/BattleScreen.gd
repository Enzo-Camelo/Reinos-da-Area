## BattleScreen.gd
## Tela de uma fase: HUD medieval, território, rodadas, habilidades de arquétipo, Cartógrafa,
## tutorial, pausa e painel de fim de fase. A lógica de regras fica em GameManager/CombatResolver.

extends Node2D
class_name BattleScreen

signal exit_to_map
signal go_to_phase(phase: int)

# ─────────────────────────────────────────────
#  CONFIGURAÇÕES
# ─────────────────────────────────────────────
const CELL_SIZE         : int = 60
const GRID_COLS         : int = 32
const GRID_ROWS         : int = 13
const HALF_COLS         : int = GRID_COLS / 2
const REGION_WIDTH      : int = 16
const HUD_TOP_HEIGHT    : int = 80
const HUD_BOTTOM_HEIGHT : int = 220
const FIELD_W           : int = CELL_SIZE * GRID_COLS
const FIELD_H           : int = CELL_SIZE * GRID_ROWS

const C_BG_DARK     := UiKit.C_BG_DARK
const C_BORDER_GOLD := UiKit.C_BORDER_GOLD
const C_TEXT_GOLD   := UiKit.C_TEXT_GOLD
const C_TEXT_GOLD2  := UiKit.C_TEXT_GOLD2
const C_TEXT_WHITE  := UiKit.C_TEXT_WHITE
const C_TEXT_MUTED  := UiKit.C_TEXT_MUTED
const C_BLUE_LIGHT  := UiKit.C_BLUE_LIGHT
const C_RED_DIM     := UiKit.C_RED_DIM
const C_RED_MAIN    := UiKit.C_RED_MAIN
const C_RED_BORDER  := UiKit.C_RED_BORDER
const C_GREEN_DIM   := UiKit.C_GREEN_DIM
const C_BLUE_DIM    := UiKit.C_BLUE_DIM
const C_BAR_ORANGE  := UiKit.C_BAR_ORANGE

const ARCH_ICONS := {
	"ESTRATEGISTA": "res://assets/ui/rosa-dos-ventos.png",
	"ENGENHEIRO": "res://assets/icons/shield.png",
	"GUERREIRO": "res://assets/icons/swords.png",
}

var phase_n : int = 1
var cfg : Dictionary = {}

var game_manager  : GameManager
var territory_gen : TerritoryGenerator
var renderer      : TerritoryRenderer
var cartographer  : CartographerPanel
var end_panel     : PhaseEndPanel
var _ui           : CanvasLayer

# HUD superior
var lbl_area_value    : Label
var lbl_area_unit     : Label
var bar_dominance     : DominanceBar
var lbl_dominance_pct : Label
var tracker           : RoundTracker
var lbl_world_phase   : Label
var lbl_scenario      : Label
var lbl_terrain       : Label
# sobre o campo
var timer_medallion   : TimerMedallion
var lbl_ribbon_player : Label
var lbl_ribbon_enemy  : Label
# painel inferior
var lbl_multiplier    : Label
var lbl_streak        : Label
var lbl_score         : Label
var lbl_atk           : Label
var lbl_def           : Label
var lbl_ip            : Label
var btn_row           : HBoxContainer
var result_vbox       : VBoxContainer
var btn_attack        : Button
var btn_defend        : Button
var btn_retreat       : Button
var lbl_result_title  : Label
var lbl_result_detail : Label
var lbl_result_areas  : Label
var lbl_chip_dom      : Label
var lbl_chip_area     : Label
var lbl_chip_ip       : Label
var btn_continue      : Button
var btn_skill         : Button
var pips              : ResourcePips
var toast_panel       : PanelContainer
var lbl_toast         : Label

var _buttons_enabled := false
var _tutorial_open   := false
var _pause_open      := false
var _closed          := false
var _last_timer_sec  := -1
var _toast_token     := 0

func setup(n: int) -> void:
	phase_n = n

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	cfg = CampaignData.get_phase(phase_n)
	if GameState.archetype == "":
		GameState.archetype = "GUERREIRO"
	_build_game_manager()
	_build_territory_system()
	_build_ui()
	_connect_signals()
	AudioManager.play_music("bg_music")
	_begin_phase()

func _build_game_manager() -> void:
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)

func _build_territory_system() -> void:
	territory_gen = TerritoryGenerator.new()
	territory_gen.grid_cols = GRID_COLS
	territory_gen.grid_rows = GRID_ROWS
	territory_gen.min_cells = 4
	territory_gen.max_cells = 130

	renderer = TerritoryRenderer.new()
	renderer.name = "Renderer"
	renderer.cell_size = CELL_SIZE
	renderer.grid_cols = GRID_COLS
	renderer.grid_rows = GRID_ROWS
	renderer.position = Vector2(0, HUD_TOP_HEIGHT)
	add_child(renderer)

func _connect_signals() -> void:
	game_manager.phase_changed.connect(_on_phase_changed)
	game_manager.round_started.connect(_on_round_started)
	game_manager.round_resolved.connect(_on_round_resolved)
	game_manager.phase_ended.connect(_on_phase_ended)
	game_manager.score_updated.connect(_on_score_updated)
	game_manager.timer_tick.connect(_on_timer_tick)
	game_manager.skill_activated.connect(_on_skill_activated)
	game_manager.skill_denied.connect(_on_skill_denied)
	game_manager.resources_changed.connect(_on_resources_changed)

func _exit_tree() -> void:
	_closed = true

# ─────────────────────────────────────────────
#  INÍCIO DA FASE
# ─────────────────────────────────────────────
func _begin_phase() -> void:
	game_manager.start_phase(cfg, GameState.archetype, GameState.resources)
	renderer.set_scenario(int(cfg["scenario_idx"]))
	renderer.set_reference_ring(_effective_ring())
	lbl_world_phase.text = "CENÁRIO %s · FASE %d" % [cfg["roman"], phase_n]
	lbl_scenario.text = str(cfg["scenario_name"]).to_upper()
	lbl_terrain.text = "TERRENO: %s" % str(cfg["terrain_name"]).to_upper()
	tracker.reset()
	timer_medallion.setup(float(cfg["time"]))
	_update_dominance(0.0, true)
	_update_area_display(game_manager.carry_area)
	cartographer.configure(cfg["cartographer"])
	_refresh_skill_ui()

	await get_tree().create_timer(0.4).timeout
	if _closed:
		return
	_start_round()
	if phase_n == 1 and not GameState.tutorial_done:
		_show_tutorial()

func _effective_ring() -> int:
	var r: int = cfg["ref_ring"]
	if r < 99:
		r += game_manager.extra_reference_ring()   # Olho de Águia: +2 células
	return r

func _show_tutorial() -> void:
	_tutorial_open = true
	game_manager.set_timer_paused(true)
	var t := TutorialOverlay.new()
	t.targets = get_tutorial_targets()
	_ui.add_child(t)
	t.finished.connect(func():
		_tutorial_open = false
		game_manager.set_timer_paused(false)
		GameState.tutorial_done = true
		GameState.save_game())

## Retângulos (em tela) destacados em cada passo do tutorial.
func get_tutorial_targets() -> Array:
	return [
		Rect2(0, HUD_TOP_HEIGHT, FIELD_W / 2.0, FIELD_H),
		Rect2(FIELD_W / 2.0, HUD_TOP_HEIGHT, FIELD_W / 2.0, FIELD_H),
		btn_row.get_global_rect().grow(10),
		timer_medallion.get_global_rect().grow(8),
		bar_dominance.get_global_rect().grow(10),
	]

# ─────────────────────────────────────────────
#  UI
# ─────────────────────────────────────────────
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)

	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(screen)

	_build_field_overlay(screen)
	_build_top_bar(screen)
	_build_bottom_hud(screen)

	cartographer = CartographerPanel.new()
	cartographer.position = Vector2(960 - 380, HUD_TOP_HEIGHT + 104)
	_ui.add_child(cartographer)

	_build_toast()

	end_panel = PhaseEndPanel.new()
	end_panel.repeat_pressed.connect(func(): go_to_phase.emit(phase_n))
	end_panel.next_pressed.connect(func(): go_to_phase.emit(phase_n + 1))
	end_panel.map_pressed.connect(func(): exit_to_map.emit())
	_ui.add_child(end_panel)

func _panel_with(style: StyleBox) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	return p

## Faixas "SEU REINO"/"REINO INIMIGO" e o relógio sobre o campo.
func _build_field_overlay(parent: Control) -> void:
	for side in 2:
		var is_player := side == 0
		var rib := _panel_with(OrnateStyleBox.new(Color(0.16, 0.12, 0.08, 0.9), Color(0.08, 0.06, 0.04, 0.9),
				UiKit.C_BLUE_LIGHT.darkened(0.2) if is_player else UiKit.C_RED_BORDER))
		(rib.get_theme_stylebox("panel") as OrnateStyleBox).set_content_margin_all(5.0)
		(rib.get_theme_stylebox("panel") as OrnateStyleBox).studs = false
		rib.position = Vector2(480 - 210 if is_player else 1440 - 210, HUD_TOP_HEIGHT + 12)
		rib.custom_minimum_size = Vector2(420, 0)
		rib.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(rib)
		var l := UiKit.make_label("", 18, C_BLUE_LIGHT if is_player else Color8(235, 130, 120), "Cinzel")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rib.add_child(l)
		if is_player:
			lbl_ribbon_player = l
		else:
			lbl_ribbon_enemy = l
	timer_medallion = TimerMedallion.new()
	timer_medallion.position = Vector2(960 - 42, HUD_TOP_HEIGHT + 6)
	parent.add_child(timer_medallion)

func _build_toast() -> void:
	toast_panel = _panel_with(OrnateStyleBox.new(Color(0.15, 0.11, 0.07, 0.96), Color(0.07, 0.05, 0.03, 0.96), C_TEXT_GOLD2))
	toast_panel.position = Vector2(960 - 400, HUD_TOP_HEIGHT + 200)
	toast_panel.custom_minimum_size = Vector2(800, 0)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.visible = false
	_ui.add_child(toast_panel)
	lbl_toast = UiKit.make_label("", 20, C_TEXT_GOLD2, "Cinzel")
	lbl_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(lbl_toast)

func _toast(text: String, seconds: float = 3.0) -> void:
	_toast_token += 1
	var my := _toast_token
	lbl_toast.text = text
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(seconds).timeout
	if _closed or my != _toast_token:
		return
	toast_panel.visible = false

func _build_top_bar(parent: Control) -> void:
	var top_bg := PanelContainer.new()
	top_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size = Vector2(0, HUD_TOP_HEIGHT)
	top_bg.offset_bottom = HUD_TOP_HEIGHT
	var sb := OrnateStyleBox.new(Color(0.16, 0.12, 0.08), Color(0.07, 0.05, 0.03))
	sb.studs = false
	sb.cut = 0.0
	sb.set_content_margin_all(6.0)
	top_bg.add_theme_stylebox_override("panel", sb)
	parent.add_child(top_bg)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	top_bg.add_child(hbox)

	# --- esquerda: brasão + área ---
	var left := HBoxContainer.new()
	left.custom_minimum_size = Vector2(440, 0)
	left.add_theme_constant_override("separation", 14)
	hbox.add_child(left)
	var crest := TextureRect.new()
	crest.texture = UiKit.load_texture("res://assets/icons/brasao.png")
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.custom_minimum_size = Vector2(62, 66)
	left.add_child(crest)
	var area_vb := VBoxContainer.new()
	area_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	area_vb.add_theme_constant_override("separation", -2)
	left.add_child(area_vb)
	area_vb.add_child(UiKit.make_label("SEU REINO", 13, C_TEXT_MUTED, "Source Sans 3"))
	lbl_area_value = UiKit.make_label("0", 32, C_BLUE_LIGHT, "Cinzel")
	area_vb.add_child(lbl_area_value)
	lbl_area_unit = UiKit.make_label("ÁREA TOTAL", 13, C_TEXT_MUTED, "Source Sans 3")
	area_vb.add_child(lbl_area_unit)

	UiKit.add_vseparator(hbox)

	# --- centro: domínio + rodadas ---
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 0)
	hbox.add_child(center)
	var dom_row := HBoxContainer.new()
	dom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dom_row.add_theme_constant_override("separation", 10)
	center.add_child(dom_row)
	dom_row.add_child(UiKit.make_label("DOMÍNIO", 15, C_TEXT_GOLD, "Cinzel"))
	bar_dominance = DominanceBar.new()
	bar_dominance.custom_minimum_size = Vector2(440, 28)
	bar_dominance.tooltip_text = "Domine 70% do mapa até a rodada 10 para vencer a fase."
	dom_row.add_child(bar_dominance)
	lbl_dominance_pct = UiKit.make_label("0%", 20, C_TEXT_GOLD2, "Cinzel")
	lbl_dominance_pct.custom_minimum_size = Vector2(54, 0)
	dom_row.add_child(lbl_dominance_pct)
	var tr_row := HBoxContainer.new()
	tr_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(tr_row)
	tracker = RoundTracker.new()
	tracker.custom_minimum_size = Vector2(330, 32)
	tracker.tooltip_text = "Rodadas da fase (10). Azul: vitória · Vermelho: derrota · Cinza: recuo."
	tr_row.add_child(tracker)

	UiKit.add_vseparator(hbox)

	# --- direita: cenário e terreno ---
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(440, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 0)
	hbox.add_child(right)
	lbl_world_phase = UiKit.make_label("", 24, C_TEXT_GOLD, "Cinzel")
	lbl_world_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(lbl_world_phase)
	lbl_scenario = UiKit.make_label("", 15, C_TEXT_WHITE, "Libre Baskerville")
	lbl_scenario.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(lbl_scenario)
	lbl_terrain = UiKit.make_label("", 14, C_TEXT_MUTED, "Source Sans 3")
	lbl_terrain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(lbl_terrain)

func _hud_section(min_w: int, expand: bool) -> MarginContainer:
	var m := UiKit.make_section(min_w, expand, Vector4i(20, 20, 10, 10))
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return m

func _build_bottom_hud(parent: Control) -> void:
	var bottom_bg := PanelContainer.new()
	bottom_bg.anchor_top = 1.0
	bottom_bg.anchor_bottom = 1.0
	bottom_bg.anchor_left = 0.0
	bottom_bg.anchor_right = 1.0
	bottom_bg.offset_top = -HUD_BOTTOM_HEIGHT
	bottom_bg.offset_bottom = 0
	var sb := OrnateStyleBox.new(Color(0.16, 0.12, 0.08), Color(0.07, 0.05, 0.03))
	sb.studs = false
	sb.cut = 0.0
	sb.set_content_margin_all(4.0)
	bottom_bg.add_theme_stylebox_override("panel", sb)
	parent.add_child(bottom_bg)

	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 0)
	bottom_bg.add_child(main_hbox)

	# --- ESQUERDA: conselho de guerra ---
	var left_panel := _hud_section(430, false)
	main_hbox.add_child(left_panel)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	left_panel.add_child(lv)
	var title_lbl := UiKit.make_label("CONSELHO DE GUERRA", 15, C_TEXT_GOLD2, "Cinzel")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(title_lbl)
	lv.add_child(UiKit.make_hline())
	var grid_center := CenterContainer.new()
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(grid_center)
	var data_grid := GridContainer.new()
	data_grid.columns = 3
	data_grid.add_theme_constant_override("h_separation", 28)
	data_grid.add_theme_constant_override("v_separation", 12)
	grid_center.add_child(data_grid)
	lbl_multiplier = UiKit.add_stat_cell(data_grid, "TERRENO", "Plano", C_TEXT_WHITE)
	lbl_streak = UiKit.add_stat_cell(data_grid, "SEQUÊNCIA", "0 vitórias", C_BAR_ORANGE)
	lbl_score = UiKit.add_stat_cell(data_grid, "PONTOS", "0", C_TEXT_GOLD)
	lbl_atk = UiKit.add_stat_cell(data_grid, "SEU ATAQUE", "×1", C_RED_BORDER, "res://assets/icons/swords.png")
	lbl_def = UiKit.add_stat_cell(data_grid, "DEFESA INIMIGA", "×1", C_BLUE_LIGHT, "res://assets/icons/shield.png")
	lbl_ip = UiKit.add_stat_cell(data_grid, "PRECISÃO", "—", C_TEXT_WHITE)
	_tip(lbl_multiplier, "Terreno da rodada: altera o peso do ataque e da defesa.")
	_tip(lbl_streak, "Vitórias seguidas. O Guerreiro ganha Embalo de Combate.")
	_tip(lbl_score, "Pontos da fase: 100 por vitória, mais sequência e velocidade.")
	_tip(lbl_atk, "Multiplicador do seu território ao atacar (terreno, Embalo, Muralha).")
	_tip(lbl_def, "Multiplicador do território inimigo ao defender (terreno).")
	_tip(lbl_ip, "Índice de Precisão: o quanto suas decisões foram certas.")

	UiKit.add_vseparator(main_hbox)

	# --- CENTRO: ações / resultado ---
	var center_panel := _hud_section(0, true)
	main_hbox.add_child(center_panel)
	var center_vbox := VBoxContainer.new()
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 8)
	center_panel.add_child(center_vbox)

	btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 22)
	center_vbox.add_child(btn_row)
	btn_attack  = UiKit.make_action_button("ATACAR", "Seu reino é maior", C_RED_DIM, "res://assets/icons/swords.png", Vector2(250, 128))
	btn_defend  = UiKit.make_action_button("DEFENDER", "O inimigo é maior", C_BLUE_DIM, "res://assets/icons/shield.png", Vector2(250, 128))
	btn_retreat = UiKit.make_action_button("RECUAR", "−3% de Domínio", C_GREEN_DIM, "res://assets/icons/boot.png", Vector2(250, 128))
	for pair in [[btn_attack, "A"], [btn_defend, "D"], [btn_retreat, "R"]]:
		btn_row.add_child(pair[0])
		_add_key_badge(pair[0], pair[1])
	btn_attack.pressed.connect(func(): _on_action(GameManager.Action.ATTACK))
	btn_defend.pressed.connect(func(): _on_action(GameManager.Action.DEFEND))
	btn_retreat.pressed.connect(func(): _on_action(GameManager.Action.RETREAT))

	_build_result_panel(center_vbox)

	UiKit.add_vseparator(main_hbox)

	# --- DIREITA: conselheiro ---
	var right_panel := _hud_section(520, false)
	main_hbox.add_child(right_panel)
	_build_archetype_panel(right_panel)

func _tip(l: Control, text: String) -> void:
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.tooltip_text = text

func _add_key_badge(btn: Control, key: String) -> void:
	var k := KeyBadge.make(key, 28.0)
	k.position = Vector2(btn.custom_minimum_size.x - k.custom_minimum_size.x - 10.0, 10.0)
	btn.add_child(k)

func _build_result_panel(center_vbox: VBoxContainer) -> void:
	result_vbox = VBoxContainer.new()
	result_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_vbox.add_theme_constant_override("separation", 6)
	result_vbox.visible = false
	center_vbox.add_child(result_vbox)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	result_vbox.add_child(head)
	lbl_result_title = UiKit.make_label("", 34, Color.WHITE, "Cinzel")
	lbl_result_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(lbl_result_title)
	btn_continue = UiKit.make_action_button("PRÓXIMA RODADA", "", C_GREEN_DIM, "", Vector2(370, 48))
	btn_continue.pressed.connect(_on_continue_pressed)
	head.add_child(btn_continue)
	_add_key_badge(btn_continue, "Enter")
	(btn_continue.find_child("LblTitle", true, false) as Label).add_theme_font_size_override("font_size", 17)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 12)
	result_vbox.add_child(chips)
	lbl_chip_dom = _chip(chips)
	lbl_chip_area = _chip(chips)
	lbl_chip_ip = _chip(chips)

	lbl_result_detail = UiKit.make_label("", 15, C_TEXT_WHITE, "Libre Baskerville")
	lbl_result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_result_detail.custom_minimum_size = Vector2(700, 0)
	result_vbox.add_child(lbl_result_detail)
	lbl_result_areas = UiKit.make_label("", 14, C_TEXT_MUTED, "Source Sans 3")
	lbl_result_areas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_result_areas.custom_minimum_size = Vector2(700, 0)
	result_vbox.add_child(lbl_result_areas)

func _chip(parent: Control) -> Label:
	var p := _panel_with(UiKit.box(Color(0.1, 0.075, 0.045, 0.95), C_BORDER_GOLD, 1, 4, 5))
	parent.add_child(p)
	var l := UiKit.make_label("", 16, C_TEXT_WHITE, "Source Sans 3")
	p.add_child(l)
	return l

func _build_archetype_panel(right_panel: Control) -> void:
	var d := ArchetypeData.get_data(GameState.archetype)
	var accent: Color = d.get("color", C_RED_MAIN)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 5)
	right_panel.add_child(rv)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	rv.add_child(head)
	var emblem := _panel_with(OrnateStyleBox.new(accent.darkened(0.3), accent.darkened(0.6), accent.lightened(0.3)))
	(emblem.get_theme_stylebox("panel") as OrnateStyleBox).set_content_margin_all(5.0)
	(emblem.get_theme_stylebox("panel") as OrnateStyleBox).studs = false
	head.add_child(emblem)
	var icon := TextureRect.new()
	icon.texture = UiKit.load_texture(ARCH_ICONS.get(GameState.archetype, ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 40)
	emblem.add_child(icon)
	var nv := VBoxContainer.new()
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", -2)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nv)
	nv.add_child(UiKit.make_label(str(d.get("name", "—")).to_upper(), 20, C_TEXT_GOLD2, "Cinzel"))
	nv.add_child(UiKit.make_label(str(d.get("tagline", "")), 14, C_TEXT_MUTED, "Libre Baskerville"))
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 0)
	head.add_child(rbox)
	var rl := UiKit.make_label("RECURSOS", 12, C_TEXT_MUTED, "Source Sans 3")
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rbox.add_child(rl)
	pips = ResourcePips.new()
	pips.custom_minimum_size = Vector2(160, 24)
	pips.tooltip_text = "Recursos Estratégicos (RE): gaste para usar a habilidade ativa. +1 a cada fase nova concluída."
	pips.mouse_filter = Control.MOUSE_FILTER_STOP
	rbox.add_child(pips)

	rv.add_child(UiKit.make_hline())
	var pl := UiKit.make_label("PASSIVA — %s" % d.get("passive_name", ""), 14, C_TEXT_GOLD, "Source Sans 3")
	rv.add_child(pl)
	var pd := UiKit.make_label(str(d.get("passive_desc", "")), 13, C_TEXT_WHITE, "Libre Baskerville")
	pd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pd.custom_minimum_size = Vector2(470, 0)
	rv.add_child(pd)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(spacer)

	btn_skill = UiKit.make_action_button(str(d.get("active_name", "")), "Custo: %d RE" % int(d.get("cost", 1)), accent.darkened(0.45), "", Vector2(0, 62))
	btn_skill.tooltip_text = str(d.get("active_desc", "")) + "\n1× por fase."
	btn_skill.pressed.connect(_on_skill_pressed)
	(btn_skill.find_child("LblTitle", true, false) as Label).custom_minimum_size = Vector2(0, 22)
	(btn_skill.find_child("LblSub", true, false) as Label).custom_minimum_size = Vector2(0, 18)
	rv.add_child(btn_skill)
	_add_key_badge_right(btn_skill, "E")

func _add_key_badge_right(btn: Control, key: String) -> void:
	var k := KeyBadge.make(key, 26.0)
	k.anchor_left = 1.0
	k.anchor_right = 1.0
	k.offset_left = -k.custom_minimum_size.x - 10.0
	k.offset_right = -10.0
	k.offset_top = 8.0
	k.offset_bottom = 34.0
	btn.add_child(k)

# ─────────────────────────────────────────────
#  RODADA
# ─────────────────────────────────────────────
func _start_round() -> void:
	if _closed:
		return
	var rt := game_manager.pick_terrain()
	var atk: float = rt["atk"]
	var def: float = rt["def"]
	var shape: String = cfg["shape"]

	var p_cells := territory_gen.generate(game_manager.carry_area, 0, REGION_WIDTH, 1, shape)
	var p_area := TerritoryGenerator.area_of(p_cells)
	var e_cells : Dictionary = {}
	var e_area := 0.0
	for attempt in 30:
		# A diferença é medida na razão EFETIVA (depois do terreno): força_J / força_I = 1 +- diff.
		var diff := randf_range(cfg["diff_min"], cfg["diff_max"])
		var dir := 1.0 if randi() % 2 == 0 else -1.0
		var e_target := p_area * atk / (def * (1.0 + dir * diff))
		e_cells = territory_gen.generate(e_target, HALF_COLS, REGION_WIDTH, 1, shape)
		e_area = TerritoryGenerator.area_of(e_cells)
		if CombatResolver.is_unambiguous(p_area, e_area, atk, def):
			break

	renderer.set_reference_ring(_effective_ring())
	renderer.set_territories(p_cells, e_cells)
	AudioManager.play_sfx("map_unroll")
	renderer.play_vs_animation()
	_update_area_display(p_area)

	game_manager.start_new_round(p_area, e_area, rt)
	_update_force_labels()
	cartographer.on_round_start(_aspect_of(e_cells))

func _aspect_of(cells: Dictionary) -> float:
	var mn := Vector2i(1000, 1000)
	var mx := Vector2i(-1, -1)
	for k in cells.keys():
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
		mx = Vector2i(maxi(mx.x, k.x), maxi(mx.y, k.y))
	var w := float(mx.x - mn.x + 1)
	var h := float(mx.y - mn.y + 1)
	return w / maxf(h, 1.0)

func _on_phase_changed(phase: String) -> void:
	if _closed:
		return
	if phase == "ANALYSIS":
		_set_buttons_enabled(false)
		btn_row.visible = true
		result_vbox.visible = false
		_last_timer_sec = -1
		_refresh_skill_ui()
		await get_tree().create_timer(1.5).timeout
		if _closed or game_manager.current_phase != GameManager.Phase.ANALYSIS:
			return
		game_manager.enter_decision_phase()
	elif phase == "DECISION":
		_set_buttons_enabled(true)
		renderer.set_enemy_pulse(true)
		_refresh_skill_ui()
	elif phase == "RESULT":
		_set_buttons_enabled(false)
		_refresh_skill_ui()
	elif phase == "RESTART":
		btn_row.visible = true
		result_vbox.visible = false
		await get_tree().create_timer(0.4).timeout
		if _closed:
			return
		_start_round()

func _on_round_started(round_num: int) -> void:
	tracker.set_current(round_num)
	timer_medallion.setup(float(cfg["time"]))

func _on_action(action: GameManager.Action) -> void:
	if not _buttons_enabled or _tutorial_open or _pause_open:
		return
	_set_buttons_enabled(false)
	renderer.set_enemy_pulse(false)
	game_manager.resolve_action(action)

func _on_round_resolved(info: Dictionary) -> void:
	renderer.set_enemy_pulse(false)
	_play_result_sequence(info)

func _play_result_sequence(info: Dictionary) -> void:
	await get_tree().create_timer(1.0).timeout
	if _closed:
		return
	var action: int = info["action"]
	var delay_acao := 2.0
	if action == CombatResolver.ACTION_ATTACK:
		AudioManager.play_sfx("action_attack")
		delay_acao = 3.0
	elif action == CombatResolver.ACTION_DEFEND:
		AudioManager.play_sfx("action_defend")
		delay_acao = 3.0
	else:
		AudioManager.play_sfx("action_retreat")
	await get_tree().create_timer(delay_acao).timeout
	if _closed:
		return

	var result: String = info["result"]
	renderer.reveal_enemy_grid()
	renderer.play_result_flash(result)
	AudioManager.play_sfx("result_" + result.to_lower())
	if result == "WIN":
		renderer.play_ink_spread()
	elif result == "LOSE":
		renderer.play_defeat_pulse()
		_shake_field()
	var bell := AccuracyTracker.sound_for(float(info["ip"]))
	if bell != "":
		get_tree().create_timer(0.9).timeout.connect(func(): AudioManager.play_sfx("bell_" + bell))

	tracker.add_result(result)
	_fill_result_text(info)
	_update_dominance(game_manager.dominance)
	_update_area_display(float(info["new_area"]))
	_spawn_result_effects(info)
	lbl_ip.text = "%d%%" % int(round(AccuracyTracker.phase_ip(game_manager.ip_values)))
	cartographer.on_result(result, action)

	var will_end: bool = float(info["new_area"]) < GameManager.MIN_AREA \
		or (cfg["sudden_death"] and result == "LOSE") \
		or game_manager.current_round >= GameManager.TOTAL_ROUNDS
	var custom_lbl = btn_continue.find_child("LblTitle", true, false)
	if custom_lbl:
		custom_lbl.text = "VER RESUMO" if will_end else "PRÓXIMA RODADA"
	btn_row.visible = false
	result_vbox.visible = true

## Selo grande sobre o campo e números flutuantes no HUD.
func _spawn_result_effects(info: Dictionary) -> void:
	var result: String = info["result"]
	var stamp := "VITÓRIA"
	var col := Color(1.0, 0.86, 0.4)
	if result == "LOSE":
		stamp = "DERROTA"
		col = Color(0.95, 0.3, 0.28)
	elif result == "DRAW":
		stamp = "RECUO"
		col = Color(0.8, 0.78, 0.7)
	FloatingText.spawn(_ui, Vector2(960 - 190, HUD_TOP_HEIGHT + 300), stamp, col, 78)
	var dom := int(round(float(info["dom_delta"])))
	if dom != 0:
		FloatingText.spawn(_ui, bar_dominance.global_position + Vector2(bar_dominance.size.x * 0.5, 22), "%+d%%" % dom,
				UiKit.C_BAR_GREEN if dom > 0 else C_RED_BORDER, 26)
	var ap := int(round(float(info["area_pct"]) * 100.0))
	if ap != 0:
		FloatingText.spawn(_ui, lbl_area_value.global_position + Vector2(40, 30), "%+d%% área" % ap,
				C_BLUE_LIGHT if ap > 0 else C_RED_BORDER, 22)

func _shake_field() -> void:
	if GameState.reduce_motion:
		return
	var base := renderer.position
	var tw := create_tween()
	for i in 6:
		var amp := 10.0 * (1.0 - i / 6.0)
		tw.tween_property(renderer, "position", base + Vector2(randf_range(-amp, amp), randf_range(-amp, amp)), 0.05)
	tw.tween_property(renderer, "position", base, 0.05)

func _fill_result_text(info: Dictionary) -> void:
	var result: String = info["result"]
	var action: int = info["action"]
	var dom: int = int(round(float(info["dom_delta"])))
	var pct: int = int(round(absf(float(info["area_pct"])) * 100.0))
	var detail := ""
	var ap := int(round(float(info["area_pct"]) * 100.0))
	if result == "WIN":
		lbl_result_title.text = "VITÓRIA"
		lbl_result_title.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
		if action == CombatResolver.ACTION_ATTACK:
			detail = "ATACAR: seu território era MAIOR."
		else:
			detail = "DEFENDER: o inimigo era maior e você resistiu!"
	elif result == "LOSE":
		lbl_result_title.text = "DERROTA"
		lbl_result_title.add_theme_color_override("font_color", Color(0.95, 0.35, 0.32))
		if action == CombatResolver.ACTION_ATTACK:
			detail = "ATACAR FALHOU: o inimigo era maior. Você perdeu %d%% da sua área." % pct
		else:
			detail = "DEFENDER FALHOU: você era o maior, deveria ter atacado! O erro custou %d%% da área." % pct
	else:
		lbl_result_title.text = "RECUO"
		lbl_result_title.add_theme_color_override("font_color", Color(0.90, 0.80, 0.30))
		if info["timeout"]:
			detail = "TEMPO ESGOTADO: o relógio acabou e você recuou. A área fica intacta."
		else:
			detail = "RECUAR: ação segura. Sua área se mantém intacta."
	if info["golpe"]:
		detail += " (Golpe Decisivo dobrou o resultado.)"
	lbl_result_detail.text = detail

	lbl_chip_dom.text = "Domínio %+d%%" % dom
	lbl_chip_dom.add_theme_color_override("font_color", UiKit.C_BAR_GREEN if dom > 0 else (C_RED_BORDER if dom < 0 else C_TEXT_WHITE))
	lbl_chip_area.text = "Área %+d%%" % ap
	lbl_chip_area.add_theme_color_override("font_color", C_BLUE_LIGHT if ap > 0 else (C_RED_BORDER if ap < 0 else C_TEXT_WHITE))
	lbl_chip_ip.text = "Precisão da rodada: %d" % int(round(float(info["ip"])))

	var pa := UnitFormatter.short(float(info["area_j"]), cfg)
	var ea := UnitFormatter.short(float(info["area_i"]), cfg)
	var diff_pct := absf(float(info["area_j"]) - float(info["area_i"])) / maxf(float(info["area_j"]), float(info["area_i"])) * 100.0
	lbl_result_areas.text = "Seu território: %s   Inimigo: %s   Diferença: %s%%\n%s" % [pa, ea, UnitFormatter.fmt_number(diff_pct, 1), _calc_text(info)]

## Cálculo com modificadores de terreno e habilidades (mensagem de revelação do GDD 6.1).
func _calc_text(info: Dictionary) -> String:
	var boost := (1.0 + float(info["embalo"])) * (CombatResolver.WALL_MULT if info["muralha"] else 1.0)
	var pm: float = float(info["atk"]) * boost
	var em: float = float(info["def"])
	var tags_p : Array[String] = []
	if not is_equal_approx(float(info["atk"]), 1.0):
		tags_p.append("atacante, %s" % game_manager.terrain["name"])
	if float(info["embalo"]) > 0.0:
		tags_p.append("Embalo")
	if info["muralha"]:
		tags_p.append("Muralha")
	var tp := "" if tags_p.is_empty() else " (%s)" % ", ".join(tags_p)
	var te := ""
	if not is_equal_approx(em, 1.0):
		te = " (defensor, %s)" % game_manager.terrain["name"]
	return "Você: %s ×%s%s = %s   |   Inimigo: %s ×%s%s = %s" % [
		UnitFormatter.short(float(info["area_j"]), cfg), UnitFormatter.fmt_number(pm, 2), tp,
		UnitFormatter.short(float(info["force_player"]), cfg),
		UnitFormatter.short(float(info["area_i"]), cfg), UnitFormatter.fmt_number(em, 2), te,
		UnitFormatter.short(float(info["force_enemy"]), cfg)]

func _on_continue_pressed() -> void:
	if not result_vbox.visible:
		return
	result_vbox.visible = false
	game_manager.finish_round()

func _on_phase_ended(summary: Dictionary) -> void:
	btn_row.visible = true
	_set_buttons_enabled(false)
	var won: bool = summary["won"]
	var gained: bool = won and phase_n >= GameState.unlocked_phase
	GameState.record_phase(phase_n, won, int(summary["stars"]), float(summary["ip"]), int(summary["xp"]))
	AudioManager.stop_music()
	AudioManager.play_music("phase_win" if won else "phase_lose")
	end_panel.show_summary(summary, phase_n < CampaignData.TOTAL_PHASES, gained)

# ─────────────────────────────────────────────
#  HABILIDADES
# ─────────────────────────────────────────────
func _on_skill_pressed() -> void:
	if _tutorial_open or _pause_open:
		return
	game_manager.try_activate_skill()

func _on_skill_activated(id: String) -> void:
	AudioManager.play_sfx("ui_click")
	_refresh_skill_ui()
	_update_force_labels()
	if id == "ANALISE_CAMPO":
		renderer.reveal_enemy_temporarily(GameManager.ANALYSIS_SECONDS)
		var f := UnitFormatter.format_area(game_manager.enemy_area, cfg)
		var extra: String = "  " + str(f["sub"]) if f["sub"] != "" else ""
		_toast("Análise de Campo — área real do inimigo: %s%s" % [f["main"], extra], GameManager.ANALYSIS_SECONDS)
	elif id == "MURALHA":
		_toast("Muralha de Emergência — seu território ×1,25 nesta rodada", 3.5)
	else:
		_toast("Golpe Decisivo — ganho e perda dobrados nesta rodada", 3.5)
	_pulse_skill_button(Color(1.0, 0.9, 0.5))

func _on_skill_denied() -> void:
	AudioManager.play_sfx("ui_click")
	_pulse_skill_button(Color(1.0, 0.25, 0.25))
	_toast("Recursos Estratégicos insuficientes", 1.5)

## Vibra e fica vermelho por 0,5s quando não há recursos (GDD §5, mecânica 2).
func _pulse_skill_button(col: Color) -> void:
	btn_skill.pivot_offset = btn_skill.size / 2.0
	btn_skill.modulate = col
	var tw := create_tween()
	if not GameState.reduce_motion:
		tw.tween_property(btn_skill, "rotation_degrees", 3.0, 0.07)
		tw.tween_property(btn_skill, "rotation_degrees", -3.0, 0.14)
		tw.tween_property(btn_skill, "rotation_degrees", 0.0, 0.07)
	tw.parallel().tween_property(btn_skill, "modulate", Color.WHITE, 0.5)

func _on_resources_changed(value: int) -> void:
	GameState.resources = value
	_refresh_skill_ui()

func _refresh_skill_ui() -> void:
	if btn_skill == null or pips == null:
		return
	var cost := game_manager.skill_cost()
	pips.set_count(game_manager.resources)
	var sub := btn_skill.find_child("LblSub", true, false) as Label
	if game_manager.skill_used_phase:
		if sub:
			sub.text = "USADA NESTA FASE"
		btn_skill.disabled = true
	else:
		if sub:
			sub.text = "Custo: %d RE" % cost
		btn_skill.disabled = not game_manager.can_use_skill()

# ─────────────────────────────────────────────
#  PAUSA E ENTRADA
# ─────────────────────────────────────────────
func _open_pause() -> void:
	if _pause_open or _closed:
		return
	_pause_open = true
	game_manager.set_timer_paused(true)
	var p := PauseMenu.new()
	_ui.add_child(p)
	p.resumed.connect(func():
		_pause_open = false
		if not _tutorial_open:
			game_manager.set_timer_paused(false))
	p.quit_to_map.connect(func():
		_closed = true
		exit_to_map.emit())

func _unhandled_input(event: InputEvent) -> void:
	if _closed or _tutorial_open or _pause_open:
		return
	if event.is_action_pressed("ui_cancel"):
		if end_panel.visible:
			_closed = true
			exit_to_map.emit()
		else:
			_open_pause()
		return
	if event.is_action_pressed("ui_skill"):
		_on_skill_pressed()
	elif event.is_action_pressed("ui_accept") and result_vbox.visible:
		_on_continue_pressed()
	elif event.is_action_pressed("ui_attack"):
		_on_action(GameManager.Action.ATTACK)
	elif event.is_action_pressed("ui_defend"):
		_on_action(GameManager.Action.DEFEND)
	elif event.is_action_pressed("ui_retreat"):
		_on_action(GameManager.Action.RETREAT)

# ─────────────────────────────────────────────
#  ATUALIZAÇÃO DO HUD
# ─────────────────────────────────────────────
func _set_buttons_enabled(enabled: bool) -> void:
	_buttons_enabled = enabled
	btn_attack.disabled = not enabled
	btn_defend.disabled = not enabled
	btn_retreat.disabled = not enabled
	var alpha := 1.0 if enabled else 0.45
	btn_attack.modulate.a = alpha
	btn_defend.modulate.a = alpha
	btn_retreat.modulate.a = alpha

func _on_score_updated(score: int, streak: int) -> void:
	var txt := "%d vitórias" % streak
	var bonus := game_manager.embalo_bonus()
	if bonus > 0.0:
		txt += " (+%d%%)" % int(round(bonus * 100.0))
	lbl_streak.text = txt
	lbl_score.text = UnitFormatter.fmt_number(float(score), 0)
	_update_force_labels()

func _on_timer_tick(secs_left: float) -> void:
	var sec_int := ceili(secs_left)
	timer_medallion.set_left(secs_left)
	if secs_left <= 10.0:
		if _last_timer_sec == -1 and sec_int > 0:
			_last_timer_sec = 10
			AudioManager.play_sfx("timer_tick")   # batidas de guerra nos últimos 10s
	else:
		_last_timer_sec = -1

func _update_force_labels() -> void:
	var gm := game_manager
	var boost := (1.0 + gm.embalo_bonus()) * (CombatResolver.WALL_MULT if gm.wall_active else 1.0)
	var atk := float(gm.terrain["atk"]) * boost
	var def := float(gm.terrain["def"])
	lbl_atk.text = "×%s" % UnitFormatter.fmt_number(atk, 2)
	lbl_def.text = "×%s" % UnitFormatter.fmt_number(def, 2)
	lbl_multiplier.text = str(gm.terrain["name"])
	lbl_terrain.text = "TERRENO: %s" % str(gm.terrain["name"]).to_upper()
	lbl_ribbon_player.text = "SEU REINO · ATAQUE ×%s" % UnitFormatter.fmt_number(atk, 2)
	lbl_ribbon_enemy.text = "REINO INIMIGO · DEFESA ×%s" % UnitFormatter.fmt_number(def, 2)

func _update_area_display(area: float) -> void:
	var f := UnitFormatter.format_area(area, cfg)
	lbl_area_value.text = str(f["main"])
	lbl_area_unit.text = str(f["sub"]) if f["sub"] != "" else "ÁREA TOTAL"

func _update_dominance(pct: float, instant: bool = false) -> void:
	if instant:
		bar_dominance.set_value_now(pct)
	else:
		bar_dominance.set_value_animated(pct)
	lbl_dominance_pct.text = "%.0f%%" % pct
