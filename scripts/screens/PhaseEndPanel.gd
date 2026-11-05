## PhaseEndPanel.gd
## "Crônica da batalha": pergaminho com insígnias (bronze/prata/ouro), Índice de Precisão, Domínio, XP e recursos.
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
const INK := Color8(54, 36, 16)
const INK_MUTED := Color8(112, 82, 44)

var _title : Label
var _medals : Array[StarMedal] = []
var _star_caption : Label
var _stats : Label
var _reason : Label
var _dom_val : Label
var _ip_val : Label
var _xp_val : Label
var _reward : Label
var _btn_next : Button
var _btn_repeat : Button
var _panel : PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = UiKit.ornate_panel("scroll")
	_panel.custom_minimum_size = Vector2(840, 0)
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)

	var sup := UiKit.make_label("CRÔNICA DA BATALHA", 16, INK_MUTED, "Cinzel")
	sup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sup)
	_title = UiKit.make_label("FIM DA FASE", 44, INK, "Cinzel")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 26)
	vb.add_child(star_row)
	for i in 3:
		var m := StarMedal.new()
		m.tint = STAR_COLORS[i]
		star_row.add_child(m)
		_medals.append(m)
	_star_caption = UiKit.make_label("", 20, Color8(120, 62, 10), "Cinzel")
	_star_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_star_caption)

	vb.add_child(_rule())
	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 70)
	vb.add_child(cols)
	_dom_val = _stat_col(cols, "DOMÍNIO FINAL")
	_ip_val = _stat_col(cols, "PRECISÃO")
	_xp_val = _stat_col(cols, "XP GANHO")

	_stats = UiKit.make_label("", 20, INK, "Source Sans 3")
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_stats)
	_reason = UiKit.make_label("", 17, Color8(150, 50, 25), "Libre Baskerville")
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_reason)
	_reward = UiKit.make_label("", 20, Color8(120, 62, 10), "Source Sans 3")
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_reward)
	vb.add_child(_rule())

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	vb.add_child(btns)
	_btn_repeat = UiKit.make_menu_button("REPETIR FASE", Vector2(230, 60), UiKit.C_BG_PANEL, 18)
	_btn_repeat.pressed.connect(func(): repeat_pressed.emit())
	btns.add_child(_btn_repeat)
	_btn_next = UiKit.make_menu_button("PRÓXIMA FASE", Vector2(260, 60), UiKit.C_GREEN_DIM, 18)
	_btn_next.pressed.connect(func(): next_pressed.emit())
	btns.add_child(_btn_next)
	var b_map := UiKit.make_menu_button("MAPA  [Esc]", Vector2(190, 60), UiKit.C_BG_PANEL, 18)
	b_map.pressed.connect(func(): map_pressed.emit())
	btns.add_child(b_map)

func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.36, 0.24, 0.1, 0.6)
	r.custom_minimum_size = Vector2(0, 2)
	return r

func _stat_col(parent: Control, title: String) -> Label:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	parent.add_child(v)
	var t := UiKit.make_label(title, 14, INK_MUTED, "Source Sans 3")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var l := UiKit.make_label("0", 40, INK, "Cinzel")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return l

## summary: dicionário de GameManager.phase_ended. gained_resource: ganhou +1 RE nesta conclusão.
func show_summary(summary: Dictionary, has_next: bool, gained_resource: bool) -> void:
	var won: bool = summary["won"]
	var star_count: int = summary["stars"]
	if won:
		_title.text = "FASE CONCLUÍDA!"
		_title.add_theme_color_override("font_color", Color8(30, 90, 50))
		_stats.text = "Vitórias: %d  |  Derrotas: %d  |  Recuos: %d" % [summary["wins"], summary["losses"], summary["retreats"]]
		_reason.text = ""
		_reward.text = "Recursos Estratégicos: %s" % ("+1" if gained_resource else "+0")
		_star_caption.text = "Insígnia de %s" % STAR_NAMES[star_count - 1] if star_count > 0 else ""
	else:
		_title.text = "FASE FRACASSADA"
		_title.add_theme_color_override("font_color", Color8(140, 30, 25))
		_stats.text = "Vitórias: %d  |  Derrotas: %d  |  Recuos: %d" % [summary["wins"], summary["losses"], summary["retreats"]]
		_reason.text = str(REASONS.get(summary["reason"], ""))
		_reward.text = ""
		_star_caption.text = ""
	_btn_next.visible = won and has_next
	_dom_val.text = "0%"
	_ip_val.text = "0%"
	_xp_val.text = "0"
	for m in _medals:
		m.set_lit(0.0)
		m.scale = Vector2.ONE
	visible = true
	(_btn_next if _btn_next.visible else _btn_repeat).grab_focus.call_deferred()

	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.modulate.a = 0.0
	var tw0 := create_tween()
	tw0.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tw0.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_count_up(_dom_val, int(summary["dominance"]), "%d%%", 0.9)
	_count_up(_ip_val, int(round(summary["ip"])), "%d%%", 1.1)
	_count_up(_xp_val, int(summary["xp"]), "%d", 1.3)
	_animate_stars(star_count)

func _count_up(lbl: Label, target: int, fmt: String, dur: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): lbl.text = fmt % int(round(v)), 0.0, float(target), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Medalhões acendem em sequência (cerca de 1,5s no total).
func _animate_stars(count: int) -> void:
	if count <= 0:
		return
	var tw := create_tween()
	for i in count:
		var m := _medals[i]
		tw.tween_method(m.set_lit, 0.0, 1.0, 0.22)
		tw.tween_callback(func(): AudioManager.play_sfx("bell_precise"))
		tw.tween_property(m, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "scale", Vector2.ONE, 0.16)
		tw.tween_interval(0.12)
