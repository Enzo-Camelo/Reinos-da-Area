## PauseMenu.gd — menu de pausa da batalha: Continuar, Opções, Abandonar fase (com confirmação).
class_name PauseMenu
extends Control

signal resumed
signal quit_to_map

var _quit_btn : Button
var _quit_armed := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.ornate_panel()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var t := UiKit.make_label("PAUSA", 44, UiKit.C_TEXT_GOLD, "Cinzel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sub := UiKit.make_label("O relógio está parado.", 17, UiKit.C_TEXT_MUTED, "Libre Baskerville")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	vb.add_child(UiKit.make_hline())

	var b_resume := UiKit.make_menu_button("CONTINUAR", Vector2(360, 58), UiKit.C_GREEN_DIM, 22)
	var b_opt := UiKit.make_menu_button("OPÇÕES", Vector2(360, 58), UiKit.C_BG_PANEL, 22)
	_quit_btn = UiKit.make_menu_button("ABANDONAR FASE", Vector2(360, 58), UiKit.C_RED_DIM, 22)
	for b in [b_resume, b_opt, _quit_btn]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(b)
	b_resume.pressed.connect(_resume)
	b_opt.pressed.connect(func(): add_child(OptionsPanel.new()))
	_quit_btn.pressed.connect(_on_quit)
	b_resume.grab_focus.call_deferred()

func _on_quit() -> void:
	if not _quit_armed:
		_quit_armed = true
		_quit_btn.text = "CONFIRMAR? (PERDE A FASE)"
		return
	quit_to_map.emit()

func _resume() -> void:
	resumed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_resume()
