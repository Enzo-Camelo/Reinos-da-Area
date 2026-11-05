## CartographerPanel.gd
## A Cartógrafa: guia que comenta o reino inimigo e vai sumindo ao longo da campanha.
## Estados fixos por fase (GDD §16): ACTIVE (fases 1-6), SILENT (7-9, só em derrotas), ABSENT (10+).
extends PanelContainer
class_name CartographerPanel

var mode := "ABSENT"
var _label : Label
var _token := 0

func _ready() -> void:
	custom_minimum_size = Vector2(760, 72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Clique para dispensar"
	var sb := OrnateStyleBox.new(Color(0.17, 0.13, 0.085, 0.96), Color(0.075, 0.055, 0.035, 0.96))
	sb.studs = false
	sb.set_content_margin_all(8.0)
	add_theme_stylebox_override("panel", sb)
	gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_token += 1
			visible = false)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hb)
	var tex := UiKit.load_texture("res://assets/ui/cartografa.png")
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(56, 56)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(tr)
	_label = UiKit.make_label("", 17, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_label)
	modulate.a = 0.0
	visible = false

func configure(new_mode: String) -> void:
	mode = new_mode
	if mode == "ABSENT":
		visible = false

## aspect: largura/altura do reino inimigo.
func on_round_start(aspect: float) -> void:
	if mode != "ACTIVE":
		return
	var text := "Este reino parece amplo. Observe bem sua forma antes de agir."
	if aspect >= 1.35:
		text = "Este reino parece largo, mas não tão alto… decida com cuidado, Arquiteto."
	elif aspect <= 0.75:
		text = "Um reino alto e estreito. Compare com a largura do seu antes de decidir."
	_say(text, 6.0)

## result: "WIN" | "LOSE" | "DRAW"; action: CombatResolver.ACTION_*
func on_result(result: String, action: int) -> void:
	if mode == "ABSENT":
		return
	if mode == "SILENT" and result != "LOSE":
		return
	var text := ""
	if result == "WIN":
		text = "Muito bem. Você viu o que precisava ver."
	elif result == "LOSE":
		if action == CombatResolver.ACTION_DEFEND:
			text = "Você era maior do que pensava. Da próxima vez, observe mais de perto antes de recuar."
		else:
			text = "O reino era maior do que parecia. Observe a forma com mais calma."
	else:
		text = "Recuar também é decidir, Arquiteto. Mas o reino só cresce quando você confia no cálculo."
	_say(text, 6.0)

func _say(text: String, seconds: float) -> void:
	_token += 1
	var my := _token
	_label.text = text
	_label.visible_ratio = 0.0
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(_label, "visible_ratio", 1.0, clampf(text.length() * 0.018, 0.4, 2.0))
	await get_tree().create_timer(seconds).timeout
	if my != _token:
		return
	var tw2 := create_tween()
	tw2.tween_property(self, "modulate:a", 0.0, 0.4)
	await tw2.finished
	if my == _token:
		visible = false
