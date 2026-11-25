## RoundReportPopup.gd
## Relatório pós-rodada: os dois reinos lado a lado, como calcular cada área e quem era mais forte.
class_name RoundReportPopup
extends Control

signal continue_pressed
signal hide_pressed

const PLAYER_FILL := Color(0.16, 0.38, 0.76, 0.95)
const ENEMY_FILL  := Color(0.66, 0.15, 0.13, 0.95)
const COL_W       := 600.0
const DIAGRAM_H   := 250.0
const WIN_COLOR   := Color(0.45, 0.95, 0.55)
const LOSE_COLOR  := Color(0.95, 0.35, 0.32)
const DRAW_COLOR  := Color(0.90, 0.80, 0.30)

var _body : VBoxContainer
var _panel : PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = UiKit.ornate_panel("panel", 0.99)
	_panel.custom_minimum_size = Vector2(COL_W * 2.0 + 140.0, 0)
	center.add_child(_panel)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_panel.add_child(_body)

## data: { info (CombatResolver + GameManager), cfg, player_cells, enemy_cells, terrain_name,
##         detail (frase do resultado), comment (fala da Cartógrafa ou ""), last (bool) }
func show_report(data: Dictionary) -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	var info: Dictionary = data["info"]
	var cfg: Dictionary = data["cfg"]
	var result: String = info["result"]

	var titles := {"WIN": "VITÓRIA", "LOSE": "DERROTA", "DRAW": "RECUO"}
	var colors := {"WIN": WIN_COLOR, "LOSE": LOSE_COLOR, "DRAW": DRAW_COLOR}
	_center(UiKit.make_label("RELATÓRIO DA RODADA %d" % int(info["round"]), 15, UiKit.C_TEXT_MUTED, "Cinzel"))
	var title := UiKit.make_label(titles[result], 44, colors[result], "Cinzel")
	_center(title)
	_center(_wrapped(str(data["detail"]), 17, UiKit.C_TEXT_WHITE, "Libre Baskerville", COL_W * 2.0))

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 12)
	_body.add_child(chips)
	var dom := int(round(float(info["dom_delta"])))
	var ap := int(round(float(info["area_pct"]) * 100.0))
	_chip(chips, "Domínio %+d%%" % dom, UiKit.C_BAR_GREEN if dom > 0 else (UiKit.C_RED_BORDER if dom < 0 else UiKit.C_TEXT_WHITE))
	_chip(chips, "Sua área %+d%%" % ap, UiKit.C_BLUE_LIGHT if ap > 0 else (UiKit.C_RED_BORDER if ap < 0 else UiKit.C_TEXT_WHITE))
	_chip(chips, "Precisão da rodada: %d%%" % int(round(float(info["ip"]))), UiKit.C_TEXT_GOLD2)

	_body.add_child(UiKit.make_hline())

	var p_cells: Dictionary = data["player_cells"]
	var e_cells: Dictionary = data["enemy_cells"]
	var px := ShapeDiagram.fit_px([p_cells, e_cells], Vector2(COL_W, DIAGRAM_H))
	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 14)
	_body.add_child(cols)

	var boost := (1.0 + float(info["embalo"])) * (CombatResolver.WALL_MULT if info["muralha"] else 1.0)
	var tags : Array[String] = []
	if not is_equal_approx(float(info["atk"]), 1.0):
		tags.append("terreno %s" % data["terrain_name"])
	if float(info["embalo"]) > 0.0:
		tags.append("Embalo")
	if info["muralha"]:
		tags.append("Muralha")
	_column(cols, "SEU REINO", UiKit.C_BLUE_LIGHT, p_cells, PLAYER_FILL, px, cfg,
			float(info["area_j"]), float(info["atk"]) * boost, float(info["force_player"]), tags)
	UiKit.add_vseparator(cols)
	var etags : Array[String] = []
	if not is_equal_approx(float(info["def"]), 1.0):
		etags.append("terreno %s" % data["terrain_name"])
	_column(cols, "REINO INIMIGO", Color8(235, 130, 120), e_cells, ENEMY_FILL, px, cfg,
			float(info["area_i"]), float(info["def"]), float(info["force_enemy"]), etags)

	_body.add_child(UiKit.make_hline())
	_verdict(info, cfg)

	var comment: String = data.get("comment", "")
	if comment != "":
		_center(_wrapped("Cartógrafa: “%s”" % comment, 16, UiKit.C_TEXT_GOLD, "Libre Baskerville", COL_W * 2.0))

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 20)
	_body.add_child(btns)
	var b_hide := UiKit.make_action_button("VER NO CAMPO", "", UiKit.C_BG_PANEL, "", Vector2(300, 56))
	b_hide.pressed.connect(func(): hide_pressed.emit())
	btns.add_child(b_hide)
	_badge(b_hide, "V")
	var b_next := UiKit.make_action_button("VER RESUMO" if data["last"] else "PRÓXIMA RODADA", "", UiKit.C_GREEN_DIM, "", Vector2(400, 56))
	b_next.pressed.connect(func(): continue_pressed.emit())
	btns.add_child(b_next)
	_badge(b_next, "Enter")

	open()

func open() -> void:
	if visible:
		return
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)

func _column(parent: Control, who: String, who_color: Color, cells: Dictionary, fill: Color, px: float,
		cfg: Dictionary, area: float, mult: float, force: float, tags: Array[String]) -> void:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(COL_W, 0)
	v.add_theme_constant_override("separation", 3)
	parent.add_child(v)
	_center(UiKit.make_label(who, 22, who_color, "Cinzel"), v)
	var diagram := ShapeDiagram.new()
	diagram.setup(cells, fill, px, Vector2(COL_W, DIAGRAM_H))
	v.add_child(diagram)

	var a: Dictionary = diagram.analysis
	_center(UiKit.make_label("COMO CALCULAR — %s" % str(a["title"]), 15, UiKit.C_TEXT_GOLD, "Source Sans 3"), v)
	var steps := VBoxContainer.new()
	steps.add_theme_constant_override("separation", 0)
	steps.custom_minimum_size = Vector2(0, 118)
	v.add_child(steps)
	for s in a["steps"]:
		_center(_wrapped(str(s), 17, UiKit.C_TEXT_WHITE, "Source Sans 3", COL_W - 20.0), steps)

	var f := UnitFormatter.format_area(area, cfg)
	var unit_line := "Área: %s blocos" % UnitFormatter.fmt_number(area, 1)
	var scale := float(cfg.get("unit_scale", 1.0))
	if not is_equal_approx(scale, 1.0) or str(cfg.get("unit_mode", "")) != "m2":
		unit_line += "  =  %s" % f["main"]
	else:
		unit_line = "Área: %s" % f["main"]
	_center(UiKit.make_label(unit_line, 21, who_color, "Cinzel"), v)

	var why := "" if tags.is_empty() else "  (%s)" % ", ".join(tags)
	_center(_wrapped("Força: %s × %s = %s%s" % [UnitFormatter.fmt_number(area, 1), UnitFormatter.fmt_number(mult, 2),
			UnitFormatter.fmt_number(force, 2), why], 18, UiKit.C_TEXT_GOLD2, "Source Sans 3", COL_W - 20.0), v)

func _verdict(info: Dictionary, cfg: Dictionary) -> void:
	var fj := float(info["force_player"])
	var fi := float(info["force_enemy"])
	var correct: String = info["correct"]
	var sign := ">" if fj > fi else ("<" if fj < fi else "=")
	var best := "EMPATE"
	if correct == "ATTACK":
		best = "o certo era ATACAR"
	elif correct == "DEFEND":
		best = "o certo era DEFENDER"
	var diff := absf(fj - fi) / maxf(maxf(fj, fi), 0.001) * 100.0
	_center(UiKit.make_label("Sua força %s  %s  Força inimiga %s   →   %s" % [
		UnitFormatter.fmt_number(fj, 2), sign, UnitFormatter.fmt_number(fi, 2), best], 24, UiKit.C_TEXT_WHITE, "Cinzel"))
	var chosen := ["ATACAR", "DEFENDER", "RECUAR"][int(info["action"])] as String
	var mark := "acertou" if info["result"] == "WIN" else ("errou" if info["result"] == "LOSE" else "jogou seguro")
	if info.get("timeout", false):
		chosen = "nada (tempo esgotado)"
		mark = "recuo automático"
	_center(UiKit.make_label("Você escolheu %s — %s.   Diferença entre as forças: %s%%" % [
		chosen, mark, UnitFormatter.fmt_number(diff, 1)], 17, UiKit.C_TEXT_MUTED, "Source Sans 3"))

func _center(l: Label, parent: Control = null) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	(parent if parent else _body).add_child(l)

func _wrapped(text: String, size_px: int, color: Color, font: String, width: float) -> Label:
	var l := UiKit.make_label(text, size_px, color, font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l

func _chip(parent: Control, text: String, color: Color) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.075, 0.045, 0.95), UiKit.C_BORDER_GOLD, 1, 4, 5))
	parent.add_child(p)
	p.add_child(UiKit.make_label(text, 16, color, "Source Sans 3"))

func _badge(btn: Control, key: String) -> void:
	var k := KeyBadge.make(key, 28.0)
	k.position = Vector2(btn.custom_minimum_size.x - k.custom_minimum_size.x - 10.0, 12.0)
	btn.add_child(k)
