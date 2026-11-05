## OptionsPanel.gd — Opções (música, efeitos, tela cheia, reduzir movimento, reiniciar progresso).
## Usado no menu principal e no menu de pausa da batalha.
class_name OptionsPanel
extends Control

signal closed
signal progress_reset

var _reset_btn : Button
var _reset_armed := false
var _first_focus : Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.ornate_panel()
	panel.custom_minimum_size = Vector2(680, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	var t := UiKit.make_label("OPÇÕES", 40, UiKit.C_TEXT_GOLD, "Cinzel")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UiKit.make_hline())

	_first_focus = _add_slider(vb, "Música", GameState.music_volume, func(v: float):
		GameState.music_volume = v
		AudioManager.set_music_volume(v))
	_add_slider(vb, "Efeitos sonoros", GameState.sfx_volume, func(v: float):
		GameState.sfx_volume = v
		AudioManager.set_sfx_volume(v)
		AudioManager.play_sfx("ui_click"))
	_add_toggle(vb, "Tela cheia", GameState.fullscreen, func(on: bool):
		GameState.fullscreen = on
		Main.apply_display()
		GameState.save_game())
	_add_toggle(vb, "Reduzir movimento (sem tremor e partículas)", GameState.reduce_motion, func(on: bool):
		GameState.reduce_motion = on
		GameState.save_game())

	vb.add_child(UiKit.make_hline())
	_reset_btn = UiKit.make_menu_button("REINICIAR PROGRESSO", Vector2(380, 52), UiKit.C_RED_DIM, 18)
	_reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reset_btn.pressed.connect(_on_reset_pressed)
	vb.add_child(_reset_btn)
	var close := UiKit.make_menu_button("FECHAR  [Esc]", Vector2(260, 52), UiKit.C_GREEN_DIM, 18)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close)
	vb.add_child(close)
	close.grab_focus.call_deferred()

func _add_slider(parent: Control, text: String, value: float, on_change: Callable) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	parent.add_child(hb)
	var l := UiKit.make_label(text, 22, UiKit.C_TEXT_WHITE, "Source Sans 3")
	l.custom_minimum_size = Vector2(220, 0)
	hb.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(300, 28)
	s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	s.value_changed.connect(on_change)
	s.drag_ended.connect(func(_c: bool): GameState.save_game())
	hb.add_child(s)
	return s

func _add_toggle(parent: Control, text: String, value: bool, on_change: Callable) -> void:
	var cb := CheckButton.new()
	cb.text = text
	cb.button_pressed = value
	cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cb.toggled.connect(on_change)
	parent.add_child(cb)

func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = "CONFIRMAR? (APAGA TUDO)"
		return
	GameState.reset_progress()
	_reset_armed = false
	_reset_btn.text = "PROGRESSO REINICIADO"
	progress_reset.emit()

func _close() -> void:
	GameState.save_game()
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
