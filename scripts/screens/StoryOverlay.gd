## StoryOverlay.gd — cenas da história em páginas: retrato, narração e, nas lições, um exemplo desenhado.
class_name StoryOverlay
extends Control

signal finished

var pages : Array = []
var _step := 0
var _portrait : TextureRect
var _title : Label
var _speaker : Label
var _text : Label
var _lesson : VBoxContainer
var _counter : Label
var _prev : Button
var _next : Button
var _type_tween : Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.01, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.ornate_panel("panel", 0.99)
	panel.custom_minimum_size = Vector2(1300, 760)
	center.add_child(panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 34)
	panel.add_child(hb)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(420, 640)
	hb.add_child(_portrait)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)
	hb.add_child(vb)
	_title = _label(vb, 34, UiKit.C_TEXT_GOLD2, "Cinzel")
	vb.add_child(UiKit.make_hline())
	_speaker = _label(vb, 17, UiKit.C_TEXT_GOLD, "Cinzel")
	_text = _label(vb, 25, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	_lesson = VBoxContainer.new()
	_lesson.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lesson.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_lesson)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	vb.add_child(foot)
	_counter = UiKit.make_label("", 16, UiKit.C_TEXT_MUTED, "Source Sans 3")
	_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(_counter)
	var skip := UiKit.make_menu_button("PULAR [Esc]", Vector2(180, 56), UiKit.C_BG_PANEL, 17)
	skip.pressed.connect(_finish)
	foot.add_child(skip)
	_prev = UiKit.make_menu_button("VOLTAR", Vector2(150, 56), UiKit.C_BG_PANEL, 17)
	_prev.pressed.connect(func(): _go(-1))
	foot.add_child(_prev)
	_next = UiKit.make_menu_button("PRÓXIMO", Vector2(210, 56), UiKit.C_GREEN_DIM, 18)
	_next.pressed.connect(func(): _go(1))
	foot.add_child(_next)
	_next.grab_focus.call_deferred()
	_show()

func _label(parent: Control, size_px: int, color: Color, font: String) -> Label:
	var l := UiKit.make_label("", size_px, color, font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(760, 0)
	parent.add_child(l)
	return l

func _show() -> void:
	var page: Dictionary = pages[_step]
	_portrait.texture = UiKit.load_texture(str(page.get("portrait", "")))
	_title.text = str(page["title"])
	_speaker.text = str(page.get("speaker", ""))
	_text.text = str(page["text"])
	for c in _lesson.get_children():
		_lesson.remove_child(c)
		c.queue_free()
	if page.has("shape"):
		var shape: Dictionary = page["shape"]
		var diagram := ShapeDiagram.new()
		diagram.setup(shape, RoundReportPopup.ENEMY_FILL, ShapeDiagram.fit_px([shape], Vector2(700, 250), 44.0))
		diagram.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_lesson.add_child(diagram)
		for s in diagram.analysis["steps"]:
			var l := UiKit.make_label(str(s), 19, UiKit.C_TEXT_GOLD2, "Source Sans 3")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_lesson.add_child(l)
	_counter.text = "%d / %d" % [_step + 1, pages.size()]
	_prev.disabled = _step == 0
	_next.text = "CONTINUAR" if _step == pages.size() - 1 else "PRÓXIMO"
	if _type_tween:
		_type_tween.kill()
	_text.visible_ratio = 1.0
	if not GameState.reduce_motion:
		_text.visible_ratio = 0.0
		_type_tween = create_tween()
		_type_tween.tween_property(_text, "visible_ratio", 1.0, clampf(_text.text.length() * 0.012, 0.4, 2.2))

func _go(dir: int) -> void:
	if _step + dir >= pages.size():
		_finish()
		return
	_step = maxi(0, _step + dir)
	_show()

func _finish() -> void:
	finished.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
