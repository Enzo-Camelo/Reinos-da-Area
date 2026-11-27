## GuidePanel.gd — "Como Jogar": guia consultável a qualquer momento (menu, mapa e batalha).
class_name GuidePanel
extends Control

signal closed
signal tutorial_requested

const TABS := ["Objetivo", "A rodada", "Calcular áreas", "Terreno e habilidades", "Medalhas", "Controles"]
const SHAPES := [
	["RECT", "Retângulo"], ["HALF", "Cantos cortados"], ["TRAPEZOID", "Trapézio"],
	["COMPOSITE", "Forma em L"], ["HOLLOW", "Com buracos"], ["COMPLEX", "Irregular"],
]

## Aberto durante uma batalha: "Rever tutorial" começa na hora.
var in_battle := false

var _content : VBoxContainer
var _tab_buttons : Array[Button] = []
var _tutorial_btn : Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.ornate_panel("panel", 0.99)
	panel.custom_minimum_size = Vector2(1560, 940)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := UiKit.make_label("COMO JOGAR", 38, UiKit.C_TEXT_GOLD2, "Cinzel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	vb.add_child(UiKit.make_hline())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(body)
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	body.add_child(tabs)
	for i in TABS.size():
		var b := UiKit.make_menu_button(TABS[i], Vector2(330, 56), UiKit.C_BG_PANEL, 17)
		b.pressed.connect(_show_tab.bind(i))
		tabs.add_child(b)
		_tab_buttons.append(b)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	body.add_child(_content)

	vb.add_child(UiKit.make_hline())
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	vb.add_child(foot)
	var b_story := UiKit.make_menu_button("REVER A HISTÓRIA", Vector2(300, 56), UiKit.C_BG_PANEL, 17)
	b_story.pressed.connect(_replay_story)
	foot.add_child(b_story)
	_tutorial_btn = UiKit.make_menu_button("REVER TUTORIAL", Vector2(380, 56), UiKit.C_BG_PANEL, 17)
	_tutorial_btn.pressed.connect(_replay_tutorial)
	foot.add_child(_tutorial_btn)
	var b_close := UiKit.make_menu_button("FECHAR  [Esc]", Vector2(260, 56), UiKit.C_GREEN_DIM, 18)
	b_close.pressed.connect(_close)
	foot.add_child(b_close)
	b_close.grab_focus.call_deferred()
	_show_tab(0)

func _show_tab(index: int) -> void:
	for i in _tab_buttons.size():
		_tab_buttons[i].modulate = Color.WHITE if i == index else Color(1, 1, 1, 0.6)
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_heading(TABS[index].to_upper())
	match index:
		0:
			_p("Você é o Arquiteto-Rei. Para libertar cada região do Império das Formas, termine as 10 rodadas de cada fase com pelo menos 60% de Domínio.")
			_p("Cada vitória vale +10% de Domínio. Na prática: vença pelo menos 6 das 10 rodadas.")
			_p("Recuar custa 3% de Domínio. Se sua área cair abaixo de 4 quadrados, a fase termina.")
			_p("A linha dourada acima dos botões mostra, o tempo todo, quantas vitórias ainda faltam.")
		1:
			_p("1.  OBSERVE — seu reino (azul, à esquerda) e o inimigo (vermelho, à direita). No canto superior esquerdo, abaixo da sua área, está quanto mede 1 quadrado: 1 m de lado nas fases 1–4, 10 m nas 5–8, 100 m nas 9–12 e 1 km da 13 em diante.")
			_p("2.  ESTIME — calcule quantos quadrados cabem no inimigo. Aplique o multiplicador do terreno que aparece nas faixas sobre o campo.")
			_p("3.  DECIDA antes do relógio zerar:\n      ATACAR [A] se a SUA força é maior.\n      DEFENDER [D] se a força do INIMIGO é maior.\n      RECUAR [R] se estiver em dúvida.")
			_p("4.  APRENDA — o relatório compara os dois reinos lado a lado e mostra como calcular cada área.")
			_p("Errar ao atacar tira 20% da sua área; errar ao defender, 10%. Se o tempo acabar, você recua.")
		2:
			_p("Não conte quadrado por quadrado: escolha o atalho certo para cada forma.")
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 18)
			grid.add_theme_constant_override("v_separation", 10)
			_content.add_child(grid)
			var shapes : Array = []
			for s in SHAPES:
				shapes.append(StoryData.example(s[0]))
			var px := ShapeDiagram.fit_px(shapes, Vector2(370, 170))
			for i in SHAPES.size():
				var cell := VBoxContainer.new()
				cell.add_theme_constant_override("separation", 0)
				cell.custom_minimum_size = Vector2(380, 0)
				grid.add_child(cell)
				var name_lbl := UiKit.make_label(SHAPES[i][1], 19, UiKit.C_TEXT_GOLD, "Cinzel")
				name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cell.add_child(name_lbl)
				var d := ShapeDiagram.new()
				d.setup(shapes[i], RoundReportPopup.ENEMY_FILL, px, Vector2(380, 170))
				cell.add_child(d)
				for step in d.analysis["steps"]:
					var l := UiKit.make_label(str(step), 15, UiKit.C_TEXT_WHITE, "Source Sans 3")
					l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					l.custom_minimum_size = Vector2(380, 0)
					cell.add_child(l)
		3:
			_p("FORÇA = área × multiplicador. O seu usa o valor de ATAQUE do terreno; o do inimigo, o de DEFESA.")
			_p("Plano ×1,00 | ×1,00        Vale ×1,00 | ×1,25        Serra ×0,85 | ×1,25        Costeiro ×1,10 | ×0,90\n(ataque | defesa; no Abismo o terreno é sorteado a cada rodada)")
			_p("Exemplo na Serra: você tem 40, o inimigo tem 34. Sua força 40 × 0,85 = 34; a dele 34 × 1,25 = 42,5. Defenda!")
			for id in ArchetypeData.IDS:
				var d := ArchetypeData.get_data(id)
				_p("%s — %s: %s\n%s [E], %d RE: %s" % [str(d["name"]).to_upper(), d["passive_name"], d["passive_desc"],
					d["active_name"], d["cost"], d["active_desc"]], 17)
		4:
			_p("A medalha depende do DOMÍNIO no fim da fase. Sem o Bronze, a fase é perdida.")
			_p("BRONZE — %d%% de Domínio (passa de fase).    +%d XP\nPRATA — %d%% de Domínio.    +%d XP\nOURO — %d%% de Domínio.    +%d XP" % [
				int(AccuracyTracker.BRONZE_MIN_DOM), AccuracyTracker.STAR_XP[1], int(AccuracyTracker.SILVER_MIN_DOM),
				AccuracyTracker.STAR_XP[2], int(AccuracyTracker.GOLD_MIN_DOM), AccuracyTracker.STAR_XP[3]])
			_p("NOVOS TERRENOS exigem estrelas somadas, além da fase anterior vencida: Vales 8, Serra 16, Arquipélago 24 e Abismo 32. Repita fases para melhorar medalhas.")
			_p("Cada medalha NOVA também rende 1 Recurso Estratégico (RE), usado nas habilidades. Ouro de primeira = +3 RE. Melhorar uma medalha depois paga a diferença.")
			_p("A Precisão mostrada na batalha é um termômetro das suas decisões; ela não muda a medalha.")
		5:
			_p("A — Atacar\nD — Defender\nR — Recuar\nE — Habilidade do conselheiro (1× por fase)\nH — Abrir este guia na batalha (o relógio para)\nV — Mostrar ou esconder o relatório da rodada\nEnter / Espaço — Próxima rodada\nEsc — Pausar ou voltar")

func _heading(text: String) -> void:
	_content.add_child(UiKit.make_label(text, 26, UiKit.C_TEXT_GOLD, "Cinzel"))

func _p(text: String, size_px: int = 21) -> void:
	var l := UiKit.make_label(text, size_px, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1130, 0)
	_content.add_child(l)

func _replay_story() -> void:
	var s := StoryOverlay.new()
	s.pages = StoryData.prologue()
	add_child(s)

func _replay_tutorial() -> void:
	if in_battle:
		tutorial_requested.emit()
		_close()
		return
	GameState.tutorial_done = false
	GameState.save_game()
	_tutorial_btn.text = "ATIVADO: ABRA A FASE 1"
	_tutorial_btn.disabled = true

func _close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
