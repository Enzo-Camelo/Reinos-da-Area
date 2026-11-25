## TutorialOverlay.gd
## Tutorial guiado pela Cartógrafa na primeira Fase 1 (6 passos, com opção de pular).
## Cada passo escurece a tela e deixa um "holofote" no alvo (targets[i], em coordenadas de tela).
extends Control
class_name TutorialOverlay

signal finished

const STEPS := [
	"Este é o seu reino, Arquiteto-Rei. Cada quadradinho vale uma unidade de área. Não conte um por um: multiplique a base pela altura.",
	"À direita está o reino inimigo, liso por dentro. Use a malha ao redor como régua: quantos quadrados tem a base? E a altura? Multiplique.",
	"Se a SUA força for maior, ATAQUE (A). Se o INIMIGO for mais forte, DEFENDA (D). Em dúvida, RECUE (R): custa 3% de Domínio. O terreno multiplica as forças!",
	"Fique de olho no relógio: quando ele zera, você recua. Errar custa território: atacar errado tira 20% da área; defender errado, 10%.",
	"Cada vitória vale 10% de Domínio: termine as 10 rodadas com 60% ou mais para passar. Depois de cada rodada, um relatório compara os reinos e mostra o cálculo. É assim que se aprende!",
	"Aqui está a habilidade do seu conselheiro (E), 1× por fase. E se esquecer alguma regra, abra COMO JOGAR (H): o relógio para enquanto você lê.",
]
## Posição do painel da Cartógrafa em cada passo (fora do alvo destacado).
const PANEL_POS := [Vector2(1010, 330), Vector2(40, 330), Vector2(520, 170), Vector2(520, 300), Vector2(520, 300), Vector2(520, 300)]

var targets : Array = []
var _step := 0
var _text : Label
var _counter : Label
var _next : Button
var _panel : PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(880, 0)
	_panel.add_theme_stylebox_override("panel", OrnateStyleBox.new(Color(0.17, 0.13, 0.085, 0.98), Color(0.075, 0.055, 0.035, 0.98)))
	add_child(_panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 22)
	_panel.add_child(hb)
	var tex := UiKit.load_texture("res://assets/ui/cartografa.png")
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(130, 180)
		hb.add_child(tr)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	hb.add_child(vb)
	vb.add_child(UiKit.make_label("A CARTÓGRAFA", 22, UiKit.C_TEXT_GOLD, "Cinzel"))
	_text = UiKit.make_label("", 20, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(620, 90)
	vb.add_child(_text)
	_counter = UiKit.make_label("", 15, UiKit.C_TEXT_MUTED, "Source Sans 3")
	vb.add_child(_counter)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.add_theme_constant_override("separation", 14)
	vb.add_child(btns)
	var skip := UiKit.make_menu_button("PULAR", Vector2(140, 48), UiKit.C_BG_PANEL, 16)
	skip.pressed.connect(_finish)
	btns.add_child(skip)
	_next = UiKit.make_menu_button("PRÓXIMO", Vector2(180, 48), UiKit.C_GREEN_DIM, 16)
	_next.pressed.connect(_advance)
	btns.add_child(_next)
	_next.grab_focus.call_deferred()
	_show_step()

func _target() -> Rect2:
	if _step < targets.size():
		return targets[_step]
	return Rect2()

func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	var dim := Color(0.02, 0.015, 0.01, 0.72)
	var hole := _target().intersection(full)
	if hole.size == Vector2.ZERO:
		draw_rect(full, dim)
		return
	draw_rect(Rect2(0, 0, size.x, hole.position.y), dim)
	draw_rect(Rect2(0, hole.end.y, size.x, size.y - hole.end.y), dim)
	draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), dim)
	draw_rect(Rect2(hole.end.x, hole.position.y, size.x - hole.end.x, hole.size.y), dim)
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 220.0)
	draw_rect(hole, Color(UiKit.C_TEXT_GOLD2.r, UiKit.C_TEXT_GOLD2.g, UiKit.C_TEXT_GOLD2.b, pulse), false, 3.0)

func _process(_d: float) -> void:
	queue_redraw()

func _show_step() -> void:
	_text.text = STEPS[_step]
	_counter.text = "%d / %d" % [_step + 1, STEPS.size()]
	_next.text = "COMEÇAR" if _step == STEPS.size() - 1 else "PRÓXIMO"
	_panel.position = PANEL_POS[_step]
	queue_redraw()

func _advance() -> void:
	_step += 1
	if _step >= STEPS.size():
		_finish()
	else:
		_show_step()

func _finish() -> void:
	finished.emit()
	queue_free()
