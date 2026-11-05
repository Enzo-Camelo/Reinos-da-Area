## ArchetypeSelect.gd
## Escolha do conselheiro (arquétipo): três estandartes heráldicos — Estrategista, Engenheiro e Guerreiro.
extends Control
class_name ArchetypeSelect

signal selected(id: String)
signal back

const ICONS := {
	"ESTRATEGISTA": "res://assets/ui/rosa-dos-ventos.png",
	"ENGENHEIRO": "res://assets/icons/shield.png",
	"GUERREIRO": "res://assets/icons/swords.png",
}

var _first_btn : Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/parchment.gdshader")
	mat.set_shader_parameter("base_color", Color(0.30, 0.22, 0.13))
	mat.set_shader_parameter("stain_color", Color(0.12, 0.08, 0.04))
	mat.set_shader_parameter("ink_color", Color(0.75, 0.6, 0.3))
	mat.set_shader_parameter("motif", 1)
	mat.set_shader_parameter("motif_strength", 0.07)
	mat.set_shader_parameter("rect_size", Vector2(1920, 1080))
	mat.set_shader_parameter("vignette", 0.7)
	bg.material = mat
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.offset_left = 60
	root.offset_right = -60
	root.offset_top = 36
	root.offset_bottom = -30
	add_child(root)

	var title := UiKit.make_label("ESCOLHA SEU CONSELHEIRO", 52, UiKit.C_TEXT_GOLD, "Cinzel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 6)
	root.add_child(title)
	var sub := UiKit.make_label("Antes das trombetas soarem, o Rei confia em apenas um dos seus três conselheiros.", 20, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 40)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cards)
	for id in ArchetypeData.IDS:
		cards.add_child(_make_card(id))

	var b_back := UiKit.make_menu_button("VOLTAR  [Esc]", Vector2(260, 56), UiKit.C_BG_PANEL, 20)
	b_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_back.pressed.connect(func(): back.emit())
	root.add_child(b_back)
	if _first_btn:
		_first_btn.grab_focus.call_deferred()

func _make_card(id: String) -> Control:
	var d := ArchetypeData.get_data(id)
	var is_current: bool = GameState.archetype == id
	var accent: Color = d["color"]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 700)
	var sb := OrnateStyleBox.new(Color(0.19, 0.145, 0.095), Color(0.075, 0.055, 0.035), UiKit.C_TEXT_GOLD2 if is_current else UiKit.C_BORDER_GOLD)
	sb.border_w = 4.0 if is_current else 2.0
	sb.set_content_margin_all(22.0)
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	# faixa heráldica com emblema
	var header := PanelContainer.new()
	var hs := OrnateStyleBox.new(accent.darkened(0.2), accent.darkened(0.6), accent.lightened(0.35))
	hs.studs = false
	hs.set_content_margin_all(12.0)
	header.add_theme_stylebox_override("panel", hs)
	vb.add_child(header)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	header.add_child(hv)
	var icon := TextureRect.new()
	icon.texture = UiKit.load_texture(ICONS.get(id, ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, 84)
	hv.add_child(icon)
	var name_lbl := UiKit.make_label(str(d["name"]).to_upper(), 36, UiKit.C_TEXT_WHITE, "Cinzel")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(name_lbl)
	var tag := UiKit.make_label(str(d["tagline"]), 18, UiKit.C_TEXT_GOLD2, "Libre Baskerville")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(tag)

	_add_block(vb, "PASSIVA — %s" % d["passive_name"], str(d["passive_desc"]))
	_add_block(vb, "ATIVA — %s  (custo: %d Recurso%s)" % [d["active_name"], d["cost"], "s" if int(d["cost"]) > 1 else ""], str(d["active_desc"]))
	_add_block(vb, "OBJETIVO", str(d["goal"]))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var btn := UiKit.make_menu_button("ESCOLHIDO" if is_current else "ESCOLHER", Vector2(0, 60), accent.darkened(0.4), 22)
	btn.pressed.connect(func():
		GameState.archetype = id
		GameState.save_game()
		selected.emit(id))
	vb.add_child(btn)
	if _first_btn == null or is_current:
		_first_btn = btn

	# a carta sobe um pouco ao passar o mouse ou receber foco
	card.pivot_offset = Vector2(260, 350)
	var lift := func(on: bool):
		var tw := card.create_tween()
		tw.tween_property(card, "scale", Vector2.ONE * (1.025 if on else 1.0), 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	card.mouse_entered.connect(lift.bind(true))
	card.mouse_exited.connect(lift.bind(false))
	btn.focus_entered.connect(lift.bind(true))
	btn.focus_exited.connect(lift.bind(false))
	return card

func _add_block(parent: Control, title: String, body: String) -> void:
	var t := UiKit.make_label(title, 17, UiKit.C_TEXT_GOLD, "Source Sans 3")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(t)
	var b := UiKit.make_label(body, 17, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(440, 0)
	parent.add_child(b)
	parent.add_child(UiKit.make_hline())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back.emit()
