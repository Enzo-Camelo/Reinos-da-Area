## DominanceBar.gd — barra de Domínio ornamentada, com bandeira na meta de 70% e preenchimento animado.
class_name DominanceBar
extends Control

const GOAL := 70.0
var value := 0.0          # valor exibido (animado)
var target := 0.0
var _tw : Tween

func _init() -> void:
	custom_minimum_size = Vector2(340, 30)

func set_value_animated(v: float) -> void:
	target = clampf(v, 0.0, 100.0)
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_method(_set_shown, value, target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_value_now(v: float) -> void:
	target = clampf(v, 0.0, 100.0)
	value = target
	queue_redraw()

func _set_shown(x: float) -> void:
	value = x
	queue_redraw()

func _fill_color(v: float) -> Color:
	if v >= GOAL:
		return UiKit.C_BAR_GREEN
	if v >= 40.0:
		return UiKit.C_BAR_ORANGE
	return Color8(150, 110, 60)

func _draw() -> void:
	var bar := Rect2(2, 8, size.x - 4, size.y - 14)
	draw_rect(bar, UiKit.C_BAR_BG, true)
	var w := bar.size.x * value / 100.0
	if w > 0.0:
		draw_rect(Rect2(bar.position, Vector2(w, bar.size.y)), _fill_color(value), true)
		draw_rect(Rect2(bar.position, Vector2(w, bar.size.y * 0.4)), Color(1, 1, 1, 0.14), true)
	for i in range(1, 10):
		var x := bar.position.x + bar.size.x * i / 10.0
		draw_line(Vector2(x, bar.end.y - 5), Vector2(x, bar.end.y), Color(0, 0, 0, 0.45), 1.0)
	draw_rect(bar, UiKit.C_BORDER_GOLD, false, 2.0)
	var gx := bar.position.x + bar.size.x * GOAL / 100.0
	draw_line(Vector2(gx, 1), Vector2(gx, bar.end.y + 3), UiKit.C_TEXT_GOLD2, 2.0)
	var flag := UiKit.C_TEXT_GOLD2 if value >= GOAL else UiKit.C_RED_BORDER
	draw_colored_polygon(PackedVector2Array([Vector2(gx, 1), Vector2(gx + 12, 5), Vector2(gx, 9)]), flag)
