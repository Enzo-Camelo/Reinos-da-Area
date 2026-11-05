## TutorialOverlay.gd
## Tutorial guiado pela Cartógrafa na primeira Fase 1 (5 passos, com opção de pular).
extends Control
class_name TutorialOverlay

signal finished

const STEPS := [
	"Este é o seu reino, Arquiteto-Rei. O quadriculado azul, à esquerda, mostra a sua área exata: cada quadrado vale uma unidade.",
	"À direita está o reino inimigo. Ele aparece liso, sem quadriculado — só a malha ao redor serve de medida. Estime quantos quadrados cabem ali dentro.",
	"Se achar que o SEU reino é maior, ATAQUE (tecla A). Se o INIMIGO for maior, DEFENDA (tecla D). Em dúvida, RECUE (tecla R): custa apenas 3% de Domínio.",
	"Errar custa território: atacar errado tira 20% da sua área; defender errado, 10%. E fique de olho no relógio: o tempo se esgota.",
	"Depois de cada rodada o quadriculado do inimigo é revelado. Compare com a sua estimativa — é assim que se aprende. Conquiste 70% do mapa em 10 rodadas!",
]

var _step := 0
var _text : Label
var _counter : Label
var _next : Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.18)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -440
	panel.offset_right = 440
	panel.offset_top = 50
	panel.offset_bottom = 320
	UiKit.apply_panel_style(panel, Color(0.1, 0.075, 0.04, 0.97), UiKit.C_BORDER_GOLD, 3, 3, 3, 3, 8, 22)
	add_child(panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 22)
	panel.add_child(hb)
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
	vb.add_theme_constant_override("separation", 12)
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
	_show_step()

func _show_step() -> void:
	_text.text = STEPS[_step]
	_counter.text = "%d / %d" % [_step + 1, STEPS.size()]
	_next.text = "COMEÇAR" if _step == STEPS.size() - 1 else "PRÓXIMO"

func _advance() -> void:
	_step += 1
	if _step >= STEPS.size():
		_finish()
	else:
		_show_step()

func _finish() -> void:
	finished.emit()
	queue_free()
