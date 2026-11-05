## StarMedal.gd — medalhão de insígnia (bronze/prata/ouro) que acende com brilho.
class_name StarMedal
extends Control

var tint := Color8(245, 200, 70)
var lit := 0.0          # 0 apagado, 1 aceso
var _t := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(120, 120)
	pivot_offset = Vector2(60, 60)

func set_lit(v: float) -> void:
	lit = v
	queue_redraw()

func _process(delta: float) -> void:
	if lit >= 1.0:
		_t += delta
		queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	var base := Color(0.17, 0.14, 0.1)
	var ring := Color(0.4, 0.32, 0.18)
	var col := base.lerp(tint, lit)
	draw_circle(c + Vector2(2, 4), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, ring.lerp(tint.darkened(0.35), lit))
	draw_circle(c, r - 6.0, base.lerp(tint.darkened(0.55), lit))
	var pts := PackedVector2Array()
	for i in 10:
		var rr := (r - 14.0) if i % 2 == 0 else (r - 14.0) * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
	if lit >= 1.0:
		var glow := 0.5 + 0.5 * sin(_t * 3.0)
		draw_arc(c, r + 2.0, 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, 0.35 + 0.35 * glow), 3.0, true)
