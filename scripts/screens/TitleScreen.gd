## TitleScreen.gd
## Tela de abertura: pergaminho, brasão que desce, título dourado com brilho, brasas e "Pressione qualquer tecla".
class_name TitleScreen
extends Control

signal continue_pressed

var _title : Label
var _motto : Label
var _prompt : Label
var _crest : TextureRect
var _sheen_mat : ShaderMaterial
var _ready_for_input := false
var _intro : Tween
var _t := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# fundo: pergaminho escuro + vinheta
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/parchment.gdshader")
	mat.set_shader_parameter("base_color", Color(0.30, 0.22, 0.13))
	mat.set_shader_parameter("stain_color", Color(0.12, 0.08, 0.04))
	mat.set_shader_parameter("ink_color", Color(0.75, 0.6, 0.3))
	mat.set_shader_parameter("motif", 1)
	mat.set_shader_parameter("motif_strength", 0.10)
	mat.set_shader_parameter("rect_size", Vector2(1920, 1080))
	mat.set_shader_parameter("vignette", 0.75)
	bg.material = mat
	add_child(bg)

	_add_embers()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	_crest = TextureRect.new()
	_crest.texture = UiKit.load_texture("res://assets/icons/brasao.png")
	_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crest.custom_minimum_size = Vector2(230, 230)
	_crest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_crest.pivot_offset = Vector2(115, 115)
	vb.add_child(_crest)

	_title = UiKit.make_label("REINOS DA ÁREA", 118, UiKit.C_TEXT_GOLD2, "Cinzel")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.01, 0.95))
	_title.add_theme_constant_override("outline_size", 12)
	_sheen_mat = ShaderMaterial.new()
	_sheen_mat.shader = load("res://shaders/gold_sheen.gdshader")
	_sheen_mat.set_shader_parameter("area_size", Vector2(1100, 140))
	_title.material = _sheen_mat
	_title.resized.connect(func(): _title.pivot_offset = _title.size / 2.0)
	vb.add_child(_title)

	var line := ColorRect.new()
	line.color = UiKit.C_BORDER_GOLD
	line.custom_minimum_size = Vector2(640, 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(line)

	_motto = UiKit.make_label("Conquiste territórios. Calcule para vencer.", 32, UiKit.C_TEXT_WHITE, "Libre Baskerville")
	_motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_motto)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 70)
	vb.add_child(gap)

	_prompt = UiKit.make_label("— PRESSIONE QUALQUER TECLA —", 26, UiKit.C_TEXT_GOLD, "Cinzel")
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_prompt)

	var footer := UiKit.make_label("Enzo Camelo Vieira", 15, UiKit.C_TEXT_MUTED, "Source Sans 3")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -40
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)

	_play_intro()

func _add_embers() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(960, 1100)
	p.amount = 18 if GameState.reduce_motion else 70
	p.lifetime = 7.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(980, 10)
	p.direction = Vector2(0.2, -1)
	p.spread = 14.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.78, 0.3, 0.0))
	grad.add_point(0.2, Color(1.0, 0.72, 0.25, 0.9))
	grad.set_color(grad.get_point_count() - 1, Color(0.9, 0.3, 0.1, 0.0))
	p.color_ramp = grad
	add_child(p)

func _play_intro() -> void:
	_ready_for_input = false
	_crest.modulate.a = 0.0
	_crest.scale = Vector2(1.35, 1.35)
	_title.modulate.a = 0.0
	_title.scale = Vector2(1.06, 1.06)
	_motto.modulate.a = 0.0
	_prompt.modulate.a = 0.0
	_intro = create_tween()
	_intro.tween_property(_crest, "modulate:a", 1.0, 0.7)
	_intro.parallel().tween_property(_crest, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro.tween_property(_title, "modulate:a", 1.0, 0.8)
	_intro.parallel().tween_property(_title, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro.tween_method(func(v: float): _sheen_mat.set_shader_parameter("progress", v), -0.3, 1.3, 0.9)
	_intro.tween_property(_motto, "modulate:a", 1.0, 0.6)
	_intro.tween_property(_prompt, "modulate:a", 1.0, 0.4)
	_intro.tween_callback(func(): _ready_for_input = true)

func _skip_intro() -> void:
	if _intro and _intro.is_valid():
		_intro.kill()
	_crest.modulate.a = 1.0
	_crest.scale = Vector2.ONE
	_title.modulate.a = 1.0
	_title.scale = Vector2.ONE
	_motto.modulate.a = 1.0
	_prompt.modulate.a = 1.0
	_sheen_mat.set_shader_parameter("progress", -0.3)
	_ready_for_input = true

func _process(delta: float) -> void:
	_t += delta
	if _ready_for_input:
		_prompt.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 3.0))
		# a cada ~6 s um brilho atravessa o título
		var ph := fmod(_t, 6.0)
		_sheen_mat.set_shader_parameter("progress", -0.3 + ph * 1.2 if ph < 1.3 else -0.3)

func _go_on() -> void:
	if not _ready_for_input:
		_skip_intro()
		return
	AudioManager.play_sfx("ui_click")
	continue_pressed.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		_go_on()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_go_on()
	elif event is InputEventJoypadButton and event.pressed:
		_go_on()
