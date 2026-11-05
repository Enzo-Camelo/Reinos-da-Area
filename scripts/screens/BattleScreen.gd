## BattleScreen.gd
## Tela de uma fase: HUD medieval, território, rodadas, habilidades de arquétipo, Cartógrafa,
## tutorial e painel de fim de fase. A lógica de regras fica em GameManager/CombatResolver.

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
const C_BAR_GREEN   := UiKit.C_BAR_GREEN
const C_BAR_ORANGE  := UiKit.C_BAR_ORANGE
const C_SEPARATOR   := UiKit.C_SEPARATOR

var phase_n : int = 1
var cfg : Dictionary = {}

var game_manager  : GameManager
var territory_gen : TerritoryGenerator
var renderer      : TerritoryRenderer
var cartographer  : CartographerPanel
var end_panel     : PhaseEndPanel
var _ui           : CanvasLayer

var lbl_area_value    : Label
var lbl_area_unit     : Label
var bar_dominance     : ProgressBar
var lbl_dominance_pct : Label
var hud_round_dots    : Array[ColorRect] = []
var lbl_world_phase   : Label
var lbl_terrain       : Label
var lbl_multiplier    : Label
var lbl_streak        : Label
var lbl_atk           : Label
var lbl_def           : Label
var lbl_timer         : Label
var lbl_ip            : Label
var btn_row           : HBoxContainer
var result_vbox       : VBoxContainer
var btn_attack        : Button
var btn_defend        : Button
var btn_retreat       : Button
var lbl_result_title  : Label
var lbl_result_detail : Label
var lbl_result_areas  : Label
var btn_continue      : Button
var btn_skill         : Button
var lbl_resources     : Label
var toast_panel       : PanelContainer
var lbl_toast         : Label

var _buttons_enabled := false
var _tutorial_open   := false
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
	renderer.textura_fundo = load("res://assets/icons/fundo.jpg")
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
	renderer.set_reference_ring(_effective_ring())
	lbl_world_phase.text = "MUNDO %s . FASE %d" % [cfg["roman"], phase_n]
	lbl_terrain.text = "TERRENO:  %s" % str(cfg["terrain_name"]).to_upper()
	_update_dominance(0.0)
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
	_ui.add_child(t)
	t.finished.connect(func():
		_tutorial_open = false
		game_manager.set_timer_paused(false)
		GameState.tutorial_done = true
		GameState.save_game())

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

	_build_top_bar(screen)
	_build_bottom_hud(screen)

	cartographer = CartographerPanel.new()
	cartographer.position = Vector2(510, HUD_TOP_HEIGHT + 6)
	_ui.add_child(cartographer)

	_build_toast()

	end_panel = PhaseEndPanel.new()
	end_panel.repeat_pressed.connect(func(): go_to_phase.emit(phase_n))
	end_panel.next_pressed.connect(func(): go_to_phase.emit(phase_n + 1))
	end_panel.map_pressed.connect(func(): exit_to_map.emit())
	_ui.add_child(end_panel)

func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.position = Vector2(560, HUD_TOP_HEIGHT + 78)
	toast_panel.custom_minimum_size = Vector2(800, 0)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_panel_style(toast_panel, Color(0.12, 0.09, 0.04, 0.94), C_TEXT_GOLD2, 2, 2, 2, 2, 8, 10)
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
	UiKit.apply_panel_style(top_bg, C_BG_DARK, C_BORDER_GOLD, 0, 2, 0, 0)
	parent.add_child(top_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	top_bg.add_child(hbox)

	var m := Vector4i(20, 20, 12, 12)
	var sec_area := UiKit.make_section(0, true, m)
	hbox.add_child(sec_area)
	var area_inner := HBoxContainer.new()
	area_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	area_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec_area.add_child(area_inner)
	var area_vbox := VBoxContainer.new()
	area_vbox.add_theme_constant_override("separation", 0)
	area_inner.add_child(area_vbox)
	lbl_area_value = UiKit.make_label("0", 30, C_BLUE_LIGHT, "Cinzel")
	lbl_area_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_area_unit = UiKit.make_label("ÁREA TOTAL", 15, C_TEXT_MUTED, "Source Sans 3")
	lbl_area_unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_vbox.add_child(lbl_area_value)
	area_vbox.add_child(lbl_area_unit)

	UiKit.add_vseparator(hbox)

	var sec_dom := UiKit.make_section(0, true, m)
	hbox.add_child(sec_dom)
	var dom_vbox := VBoxContainer.new()
	dom_vbox.add_theme_constant_override("separation", 6)
	dom_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dom_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dom_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sec_dom.add_child(dom_vbox)
	var dom_title := UiKit.make_label("OBJETIVO: DOMINAR 70% DO MAPA", 16, C_TEXT_MUTED, "Source Sans 3")
	dom_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dom_vbox.add_child(dom_title)
	var dom_bar_row := HBoxContainer.new()
	dom_bar_row.add_theme_constant_override("separation", 10)
	dom_bar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dom_vbox.add_child(dom_bar_row)
	bar_dominance = UiKit.make_progress_bar(260, 18)
	bar_dominance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dom_bar_row.add_child(bar_dominance)
	lbl_dominance_pct = UiKit.make_label("0%", 16, C_TEXT_GOLD, "Source Sans 3")
	lbl_dominance_pct.custom_minimum_size = Vector2(45, 0)
	dom_bar_row.add_child(lbl_dominance_pct)

	UiKit.add_vseparator(hbox)

	var sec_rounds := UiKit.make_section(0, true, m)
	hbox.add_child(sec_rounds)
	var rounds_vbox := VBoxContainer.new()
	rounds_vbox.add_theme_constant_override("separation", 6)
	rounds_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rounds_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rounds_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sec_rounds.add_child(rounds_vbox)
	var rounds_title := UiKit.make_label("RODADAS", 16, C_TEXT_MUTED, "Source Sans 3")
	rounds_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rounds_vbox.add_child(rounds_title)
	var dots_row := HBoxContainer.new()
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 10)
	rounds_vbox.add_child(dots_row)
	hud_round_dots.clear()
	for i in GameManager.TOTAL_ROUNDS:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(20, 20)
		dot.color = C_SEPARATOR
		dots_row.add_child(dot)
		hud_round_dots.append(dot)

	UiKit.add_vseparator(hbox)

	var sec_phase := UiKit.make_section(0, true, m)
	hbox.add_child(sec_phase)
	var phase_vbox := VBoxContainer.new()
	phase_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	phase_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phase_vbox.add_theme_constant_override("separation", 2)
	sec_phase.add_child(phase_vbox)
	lbl_world_phase = UiKit.make_label("MUNDO I . FASE 1", 18, C_TEXT_GOLD, "Cinzel")
	lbl_world_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_vbox.add_child(lbl_world_phase)
	lbl_terrain = UiKit.make_label("TERRENO:  PLANO", 16, C_TEXT_WHITE, "Source Sans 3")
	lbl_terrain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_vbox.add_child(lbl_terrain)

	var tex := UiKit.load_texture("res://assets/icons/brasao.png")
	if tex:
		var shield_icon := TextureRect.new()
		shield_icon.texture = tex
		shield_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shield_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shield_icon.custom_minimum_size = Vector2(200, 200)
		shield_icon.size = Vector2(140, 140)
		shield_icon.position = Vector2(0, 5)
		shield_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(shield_icon)

func _build_bottom_hud(parent: Control) -> void:
	var bottom_bg := PanelContainer.new()
	bottom_bg.anchor_top = 1.0
	bottom_bg.anchor_bottom = 1.0
	bottom_bg.anchor_left = 0.0
	bottom_bg.anchor_right = 1.0
	bottom_bg.offset_top = -HUD_BOTTOM_HEIGHT
	bottom_bg.offset_bottom = -20
	UiKit.apply_panel_style(bottom_bg, C_BG_DARK, C_BORDER_GOLD, 0, 2, 0, 0)
	parent.add_child(bottom_bg)

	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 0)
	bottom_bg.add_child(main_hbox)

	var bm := Vector4i(24, 24, 14, 14)

	# --- ESQUERDA: informações de batalha ---
	var left_panel := UiKit.make_section(450, false, bm)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(left_panel)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	lv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_child(lv)
	var title_lbl := UiKit.make_label("INFORMAÇÕES DE BATALHA", 14, C_TEXT_GOLD2, "Cinzel")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(title_lbl)
	lv.add_child(UiKit.make_hline())
	var grid_center := CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(grid_center)
	var data_grid := GridContainer.new()
	data_grid.columns = 3
	data_grid.add_theme_constant_override("h_separation", 26)
	data_grid.add_theme_constant_override("v_separation", 10)
	grid_center.add_child(data_grid)
	lbl_multiplier = UiKit.add_stat_cell(data_grid, "TERRENO", "Plano", C_TEXT_WHITE)
	lbl_streak = UiKit.add_stat_cell(data_grid, "SEQUÊNCIA", "0 vitórias", C_BAR_ORANGE)
	lbl_timer = UiKit.add_stat_cell(data_grid, "TEMPO", "%ds" % int(cfg["time"]), C_TEXT_GOLD)
	lbl_atk = UiKit.add_stat_cell(data_grid, "SEU ATAQUE", "×1,0", C_RED_BORDER, "res://assets/icons/swords.png")
	lbl_def = UiKit.add_stat_cell(data_grid, "DEFESA INIMIGA", "×1,0", C_BLUE_LIGHT, "res://assets/icons/shield.png")
	lbl_ip = UiKit.add_stat_cell(data_grid, "PRECISÃO", "—", C_TEXT_WHITE)

	UiKit.add_vseparator(main_hbox)

	# --- CENTRO: botões / resultado ---
	var center_panel := UiKit.make_section(0, true, bm)
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(center_panel)
	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 8)
	center_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_panel.add_child(center_vbox)

	btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 25)
	center_vbox.add_child(btn_row)
	btn_attack  = UiKit.make_action_button("ATACAR [A]", "Iniciar combate", C_RED_DIM, "res://assets/icons/swords.png")
	btn_defend  = UiKit.make_action_button("DEFENDER [D]", "Preparar território", C_BLUE_DIM, "res://assets/icons/shield.png")
	btn_retreat = UiKit.make_action_button("RECUAR [R]", "-3% de Domínio", C_GREEN_DIM, "res://assets/icons/boot.png")
	btn_row.add_child(btn_attack)
	btn_row.add_child(btn_defend)
	btn_row.add_child(btn_retreat)
	btn_attack.pressed.connect(func(): _on_action(GameManager.Action.ATTACK))
	btn_defend.pressed.connect(func(): _on_action(GameManager.Action.DEFEND))
	btn_retreat.pressed.connect(func(): _on_action(GameManager.Action.RETREAT))

	result_vbox = VBoxContainer.new()
	result_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_vbox.add_theme_constant_override("separation", 4)
	result_vbox.visible = false
	center_vbox.add_child(result_vbox)
	lbl_result_title = UiKit.make_label("", 22, Color.WHITE, "Cinzel")
	lbl_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_vbox.add_child(lbl_result_title)
	lbl_result_detail = UiKit.make_label("", 13, C_TEXT_WHITE, "Libre Baskerville")
	lbl_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_result_detail.custom_minimum_size = Vector2(640, 0)
	result_vbox.add_child(lbl_result_detail)
	lbl_result_areas = UiKit.make_label("", 13, C_TEXT_MUTED, "Source Sans 3")
	lbl_result_areas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_areas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_result_areas.custom_minimum_size = Vector2(640, 0)
	result_vbox.add_child(lbl_result_areas)
	btn_continue = UiKit.make_action_button("PRÓXIMA RODADA", "", C_GREEN_DIM, "", Vector2(260, 44))
	btn_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_continue.pressed.connect(_on_continue_pressed)
	result_vbox.add_child(btn_continue)

	UiKit.add_vseparator(main_hbox)

	# --- DIREITA: arquétipo ---
	var right_panel := UiKit.make_section(500, false, bm)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_panel)
	_build_archetype_panel(right_panel)

func _build_archetype_panel(right_panel: Control) -> void:
	var d := ArchetypeData.get_data(GameState.archetype)
	var accent: Color = d.get("color", C_RED_MAIN)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	rv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(rv)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	rv.add_child(head)
	var arch_title := UiKit.make_label("ARQUÉTIPO", 15, C_TEXT_MUTED, "Source Sans 3")
	arch_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(arch_title)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiKit.box(accent.darkened(0.4), accent.lightened(0.3), 1, 6, 5))
	head.add_child(badge)
	badge.add_child(UiKit.make_label(str(d.get("name", "—")).to_upper(), 13, C_TEXT_WHITE, "Cinzel"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	lbl_resources = UiKit.make_label("RE", 16, C_TEXT_GOLD2, "Source Sans 3")
	head.add_child(lbl_resources)

	rv.add_child(UiKit.make_hline())
	rv.add_child(UiKit.make_label("PASSIVA: %s" % d.get("passive_name", ""), 14, C_TEXT_GOLD, "Source Sans 3"))
	var pd := UiKit.make_label(str(d.get("passive_desc", "")), 12, C_TEXT_WHITE, "Libre Baskerville")
	pd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pd.custom_minimum_size = Vector2(430, 0)
	rv.add_child(pd)

	var ah := HBoxContainer.new()
	ah.add_theme_constant_override("separation", 12)
	rv.add_child(ah)
	var at := UiKit.make_label("ATIVA: %s" % d.get("active_name", ""), 14, C_TEXT_GOLD, "Source Sans 3")
	at.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ah.add_child(at)
	btn_skill = Button.new()
	btn_skill.custom_minimum_size = Vector2(120, 28)
	btn_skill.focus_mode = Control.FOCUS_NONE
	btn_skill.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_skill.add_theme_font_size_override("font_size", 12)
	btn_skill.add_theme_color_override("font_color", C_BG_DARK)
	btn_skill.add_theme_color_override("font_hover_color", C_BG_DARK)
	btn_skill.add_theme_color_override("font_disabled_color", C_TEXT_MUTED)
	btn_skill.add_theme_stylebox_override("normal", UiKit.box(C_TEXT_GOLD, C_TEXT_GOLD, 0, 4))
	btn_skill.add_theme_stylebox_override("hover", UiKit.box(C_TEXT_GOLD2, C_TEXT_GOLD2, 0, 4))
	btn_skill.add_theme_stylebox_override("pressed", UiKit.box(C_TEXT_GOLD, C_TEXT_GOLD, 0, 4))
	btn_skill.add_theme_stylebox_override("disabled", UiKit.box(Color8(70, 56, 30), C_BORDER_GOLD, 1, 4))
	btn_skill.pressed.connect(_on_skill_pressed)
	btn_skill.mouse_entered.connect(func(): if not btn_skill.disabled: AudioManager.play_sfx("ui_hover", 0.1))
	ah.add_child(btn_skill)
	var ad := UiKit.make_label("%s (custo: %d RE, 1× por fase, tecla E)" % [d.get("active_desc", ""), d.get("cost", 1)], 12, C_TEXT_WHITE, "Libre Baskerville")
	ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ad.custom_minimum_size = Vector2(430, 0)
	rv.add_child(ad)

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
		# Assim, no terreno de Serra um inimigo visivelmente menor ainda pode valer mais.
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
	_update_round_dots(round_num)
	lbl_timer.text = "%ds" % int(cfg["time"])
	lbl_timer.add_theme_color_override("font_color", C_TEXT_GOLD)

func _on_action(action: GameManager.Action) -> void:
	if not _buttons_enabled or _tutorial_open:
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
	var bell := AccuracyTracker.sound_for(float(info["ip"]))
	if bell != "":
		get_tree().create_timer(0.9).timeout.connect(func(): AudioManager.play_sfx("bell_" + bell))

	_fill_result_text(info)
	_update_dominance(game_manager.dominance)
	_update_area_display(float(info["new_area"]))
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

func _fill_result_text(info: Dictionary) -> void:
	var result: String = info["result"]
	var action: int = info["action"]
	var dom: int = int(round(float(info["dom_delta"])))
	var pct: int = int(round(absf(float(info["area_pct"])) * 100.0))
	var detail := ""
	if result == "WIN":
		lbl_result_title.text = "VITÓRIA"
		lbl_result_title.add_theme_color_override("font_color", Color(0.30, 0.95, 0.45))
		if action == CombatResolver.ACTION_ATTACK:
			detail = "ATACAR: seu território era MAIOR. Domínio +%d%% e área +%d%%." % [dom, pct]
		else:
			detail = "DEFENDER: o inimigo era maior e você resistiu! Domínio +%d%% e área +%d%%." % [dom, pct]
	elif result == "LOSE":
		lbl_result_title.text = "DERROTA"
		lbl_result_title.add_theme_color_override("font_color", Color(0.95, 0.28, 0.28))
		if action == CombatResolver.ACTION_ATTACK:
			detail = "ATACAR FALHOU: o inimigo era maior. Você perdeu %d%% da sua área." % pct
		else:
			detail = "DEFENDER FALHOU: você era o maior, deveria ter atacado! O erro custou %d%% da sua área." % pct
	else:
		lbl_result_title.text = "RECUO"
		lbl_result_title.add_theme_color_override("font_color", Color(0.90, 0.80, 0.30))
		if info["timeout"]:
			detail = "TEMPO ESGOTADO: o relógio acabou e você recuou. O Domínio cai 3%, a área fica intacta."
		else:
			detail = "RECUAR: ação segura. Sua área se mantém intacta, mas o Domínio cai 3%."
	if info["golpe"]:
		detail += " (Golpe Decisivo dobrou o resultado.)"
	lbl_result_detail.text = detail

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
	if _tutorial_open:
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
	var tw := create_tween()
	btn_skill.modulate = col
	tw.tween_property(btn_skill, "rotation_degrees", 5.0, 0.07)
	tw.tween_property(btn_skill, "rotation_degrees", -5.0, 0.14)
	tw.tween_property(btn_skill, "rotation_degrees", 0.0, 0.07)
	tw.parallel().tween_property(btn_skill, "modulate", Color.WHITE, 0.5)

func _on_resources_changed(value: int) -> void:
	GameState.resources = value
	_refresh_skill_ui()

func _refresh_skill_ui() -> void:
	if btn_skill == null or lbl_resources == null:
		return
	var cost := game_manager.skill_cost()
	lbl_resources.text = "RE: %s (%d)" % ["●".repeat(maxi(game_manager.resources, 0)), game_manager.resources]
	if game_manager.skill_used_phase:
		btn_skill.text = " USADA "
		btn_skill.disabled = true
	else:
		btn_skill.text = " ATIVAR (%d) " % cost
		btn_skill.disabled = not game_manager.can_use_skill()

# ─────────────────────────────────────────────
#  ENTRADA
# ─────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if _closed or _tutorial_open:
		return
	if event.is_action_pressed("ui_cancel"):
		_closed = true
		exit_to_map.emit()
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
	var alpha := 1.0 if enabled else 0.38
	btn_attack.modulate.a = alpha
	btn_defend.modulate.a = alpha
	btn_retreat.modulate.a = alpha

func _on_score_updated(_score: int, streak: int) -> void:
	var txt := "%d vitórias" % streak
	var bonus := game_manager.embalo_bonus()
	if bonus > 0.0:
		txt += " (+%d%%)" % int(round(bonus * 100.0))
	lbl_streak.text = txt
	_update_force_labels()

func _on_timer_tick(secs_left: float) -> void:
	var sec_int := ceili(secs_left)
	lbl_timer.text = "%ds" % sec_int
	if secs_left <= 10.0:
		lbl_timer.add_theme_color_override("font_color", C_RED_MAIN)
		if _last_timer_sec == -1 and sec_int > 0:
			_last_timer_sec = 10
			AudioManager.play_sfx("timer_tick")   # batidas de guerra nos últimos 10s
	else:
		lbl_timer.add_theme_color_override("font_color", C_TEXT_GOLD)
		_last_timer_sec = -1

func _update_force_labels() -> void:
	var gm := game_manager
	var boost := (1.0 + gm.embalo_bonus()) * (CombatResolver.WALL_MULT if gm.wall_active else 1.0)
	# seu poder (atacante x bônus) contra o multiplicador de defesa do inimigo
	lbl_atk.text = "×%s" % UnitFormatter.fmt_number(float(gm.terrain["atk"]) * boost, 2)
	lbl_def.text = "×%s" % UnitFormatter.fmt_number(float(gm.terrain["def"]), 2)
	lbl_multiplier.text = str(gm.terrain["name"])
	lbl_terrain.text = "TERRENO:  %s" % str(gm.terrain["name"]).to_upper()

func _update_area_display(area: float) -> void:
	var f := UnitFormatter.format_area(area, cfg)
	lbl_area_value.text = str(f["main"])
	lbl_area_unit.text = str(f["sub"]) if f["sub"] != "" else "ÁREA TOTAL"

func _update_dominance(pct: float) -> void:
	bar_dominance.value = pct
	lbl_dominance_pct.text = "%.0f%%" % pct
	var col := C_BAR_GREEN if pct >= 70.0 else (C_BAR_ORANGE if pct >= 40.0 else C_BAR_GREEN.darkened(0.3))
	bar_dominance.add_theme_stylebox_override("fill", UiKit.box(col, col, 0, 3))

func _update_round_dots(completed: int) -> void:
	for i in hud_round_dots.size():
		var dot := hud_round_dots[i]
		if i < completed - 1:
			dot.color = C_BORDER_GOLD
		elif i == completed - 1:
			dot.color = C_BAR_ORANGE
		else:
			dot.color = C_SEPARATOR
