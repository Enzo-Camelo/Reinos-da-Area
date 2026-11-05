## ArchetypeSelect.gd
## Escolha do conselheiro (arquétipo): Estrategista, Engenheiro ou Guerreiro.
extends Control
class_name ArchetypeSelect

signal selected(id: String)
signal back

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.C_BG_DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var tex := UiKit.load_texture("res://assets/ui/mapa.png")
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.modulate = Color(1, 1, 1, 0.18)
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(t)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	root.offset_left = 60
	root.offset_right = -60
	root.offset_top = 40
	root.offset_bottom = -30
	add_child(root)

	var title := UiKit.make_label("ESCOLHA SEU CONSELHEIRO", 52, UiKit.C_TEXT_GOLD, "Cinzel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	var b_back := UiKit.make_menu_button("VOLTAR", Vector2(240, 56), UiKit.C_BG_PANEL, 20)
	b_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_back.pressed.connect(func(): back.emit())
	root.add_child(b_back)

func _make_card(id: String) -> Control:
	var d := ArchetypeData.get_data(id)
	var is_current: bool = GameState.archetype == id
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 640)
	var accent: Color = d["color"]
	var sb := UiKit.box(UiKit.C_BG_PANEL, UiKit.C_TEXT_GOLD2 if is_current else UiKit.C_BORDER_GOLD, 4 if is_current else 2, 10, 24)
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UiKit.box(accent.darkened(0.35), accent, 2, 6, 10))
	vb.add_child(header)
	var hv := VBoxContainer.new()
	header.add_child(hv)
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
