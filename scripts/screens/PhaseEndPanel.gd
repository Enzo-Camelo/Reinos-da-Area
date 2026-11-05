## PhaseEndPanel.gd
## Painel de encerramento de fase: estrelas (bronze/prata/ouro), Índice de Precisão, XP e recursos.
extends Control
class_name PhaseEndPanel

signal repeat_pressed
signal next_pressed
signal map_pressed

const STAR_COLORS := [Color8(205, 127, 50), Color8(200, 205, 215), Color8(245, 200, 70)]
const STAR_NAMES  := ["Bronze", "Prata", "Ouro"]
const REASONS := {
	"AREA": "Seu reino foi reduzido a quase nada.",
	"SUDDEN_DEATH": "Morte súbita: a primeira decisão errada encerra a fase.",
	"ROUNDS": "Domínio insuficiente: eram necessários 70% do mapa.",
}

var _title : Label
var _stars : Array[Label] = []
var _star_caption : Label
var _stats : Label
var _ip_lbl : Label
var _dom_lbl : Label
var _reward : Label
var _btn_next : Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -380
	panel.offset_right = 380
	panel.offset_top = -300
	panel.offset_bottom = 300
	UiKit.apply_panel_style(panel, UiKit.C_BG_DARK, UiKit.C_BORDER_GOLD, 3, 3, 3, 3, 8, 24)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	_title = UiKit.make_label("FIM DA FASE", 40, UiKit.C_TEXT_GOLD, "Cinzel")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 24)
	vb.add_child(star_row)
	for i in 3:
		var s := UiKit.make_label("★", 84, Color(0.25, 0.22, 0.18), "Cinzel")
		star_row.add_child(s)
		_stars.append(s)
	_star_caption = UiKit.make_label("", 20, UiKit.C_TEXT_GOLD2, "Cinzel")
	_star_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_star_caption)

	vb.add_child(UiKit.make_hline())
	_ip_lbl = UiKit.make_label("", 28, UiKit.C_BLUE_LIGHT, "Cinzel")
	_ip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_ip_lbl)
	_dom_lbl = UiKit.make_label("", 22, UiKit.C_TEXT_WHITE, "Source Sans 3")
	_dom_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_dom_lbl)
	_stats = UiKit.make_label("", 22, UiKit.C_TEXT_WHITE, "Source Sans 3")
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_stats)
	_reward = UiKit.make_label("", 22, UiKit.C_BAR_ORANGE, "Source Sans 3")
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_reward)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	vb.add_child(btns)
	var b_rep := UiKit.make_menu_button("REPETIR FASE", Vector2(220, 60), UiKit.C_BG_PANEL, 18)
	b_rep.pressed.connect(func(): repeat_pressed.emit())
	btns.add_child(b_rep)
	_btn_next = UiKit.make_menu_button("PRÓXIMA FASE", Vector2(240, 60), UiKit.C_GREEN_DIM, 18)
	_btn_next.pressed.connect(func(): next_pressed.emit())
	btns.add_child(_btn_next)
	var b_map := UiKit.make_menu_button("MAPA", Vector2(160, 60), UiKit.C_BG_PANEL, 18)
	b_map.pressed.connect(func(): map_pressed.emit())
	btns.add_child(b_map)

## summary: dicionário de GameManager.phase_ended. gained_resource: ganhou +1 RE nesta conclusão.
func show_summary(summary: Dictionary, has_next: bool, gained_resource: bool) -> void:
	var won: bool = summary["won"]
	var star_count: int = summary["stars"]
	if won:
		_title.text = "FASE CONCLUÍDA!"
		_title.add_theme_color_override("font_color", UiKit.C_BAR_GREEN)
	else:
		_title.text = "FASE FRACASSADA"
		_title.add_theme_color_override("font_color", UiKit.C_BAR_ORANGE)
	_ip_lbl.text = "ÍNDICE DE PRECISÃO: %d%%" % int(round(summary["ip"]))
	_dom_lbl.text = "DOMÍNIO FINAL: %d%%" % int(summary["dominance"])
	if won:
		_stats.text = "Vitórias: %d  |  Derrotas: %d  |  Recuos: %d" % [summary["wins"], summary["losses"], summary["retreats"]]
		_reward.text = "XP ganho: +%d     Recursos: %s" % [summary["xp"], "+1" if gained_resource else "+0"]
		_star_caption.text = "Insígnia de %s" % STAR_NAMES[star_count - 1] if star_count > 0 else ""
	else:
		_stats.text = "%s\nVitórias: %d  |  Derrotas: %d  |  Recuos: %d" % [REASONS.get(summary["reason"], ""), summary["wins"], summary["losses"], summary["retreats"]]
		_reward.text = "XP ganho: +%d" % summary["xp"]
		_star_caption.text = ""
	_btn_next.visible = won and has_next

	for s in _stars:
		s.add_theme_color_override("font_color", Color(0.25, 0.22, 0.18))
		s.scale = Vector2.ONE
		s.pivot_offset = Vector2(30, 40)
	visible = true
	_animate_stars(star_count)

## Estrelas preenchem com brilho sequencial (1,5s no total).
func _animate_stars(count: int) -> void:
	if count <= 0:
		return
	var tw := create_tween()
	for i in count:
		var s := _stars[i]
		tw.tween_callback(func(): s.add_theme_color_override("font_color", STAR_COLORS[i]))
		tw.tween_property(s, "scale", Vector2(1.35, 1.35), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2.ONE, 0.18)
		tw.tween_interval(0.14)
