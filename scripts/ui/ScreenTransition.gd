## ScreenTransition.gd
## Transição entre telas: pergaminho que se desdobra (menu/mapa) ou vira a página (entre fases).
## Feita só com Tween (sem sprites).
extends CanvasLayer
class_name ScreenTransition

var _rect : Control
var _busy := false
var _rosa : TextureRect

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	(_rect as ColorRect).color = UiKit.C_PARCHMENT
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/parchment.gdshader")
	mat.set_shader_parameter("rect_size", Vector2(1920, 1080))
	mat.set_shader_parameter("burn", 0.8)
	mat.set_shader_parameter("vignette", 0.35)
	mat.set_shader_parameter("motif", 1)
	mat.set_shader_parameter("motif_strength", 0.1)
	_rect.material = mat
	_rect.visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_rect)

	var rosa := UiKit.load_texture("res://assets/ui/rosa-dos-ventos.png")
	if rosa:
		var tr := TextureRect.new()
		tr.texture = rosa
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(300, 300)
		tr.size = Vector2(300, 300)
		tr.modulate.a = 0.55
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.pivot_offset = Vector2(150, 150)
		_rosa = tr
		_rect.add_child(tr)

func is_busy() -> bool:
	return _busy

## kind: "unfold" (mapa se desdobra, vertical) ou "page" (página vira, horizontal).
## swap é chamado quando a tela está totalmente coberta.
func run(swap: Callable, kind: String = "unfold") -> void:
	if _busy:
		return
	_busy = true
	var vp := get_viewport().get_visible_rect().size
	_rect.position = Vector2.ZERO
	_rect.size = vp
	_rect.pivot_offset = vp / 2.0
	_rect.visible = true
	if _rosa:
		_rosa.position = (vp - _rosa.size) / 2.0
	var start := Vector2(1, 0) if kind == "unfold" else Vector2(0, 1)
	_rect.scale = start
	if kind == "page":
		AudioManager.play_sfx("page_turn")
	else:
		AudioManager.play_sfx("map_unroll")

	if _rosa and not GameState.reduce_motion:
		_rosa.rotation = 0.0
		create_tween().tween_property(_rosa, "rotation", TAU * 0.5, 0.95)
	var tw := create_tween()
	tw.tween_property(_rect, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	swap.call()
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_rect, "scale", start, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw2.finished
	_rect.visible = false
	_busy = false
