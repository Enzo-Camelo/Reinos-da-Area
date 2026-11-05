## RoundTracker.gd — 10 escudos com o histórico da fase (vitória/derrota/recuo) e a rodada atual.
class_name RoundTracker
extends Control

const TOTAL := 10
var results : Array = []     # "WIN" | "LOSE" | "DRAW" por rodada concluída
var current := 0             # rodada em andamento (1..10), 0 = nenhuma
var _t := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(TOTAL * 30.0, 30)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func reset() -> void:
	results.clear()
	current = 0
	queue_redraw()

func set_current(n: int) -> void:
	current = n
	queue_redraw()

func add_result(res: String) -> void:
	results.append(res)
	queue_redraw()

func _shield(c: Vector2, s: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-s, -s), c + Vector2(s, -s), c + Vector2(s, s * 0.25), c + Vector2(0, s * 1.15), c + Vector2(-s, s * 0.25)])

func _draw() -> void:
	var step := size.x / TOTAL
	for i in TOTAL:
		var c := Vector2(step * (i + 0.5), size.y * 0.42)
		var s := 9.0
		var fill := Color(0.16, 0.12, 0.07)
		var line := UiKit.C_SEPARATOR
		if i < results.size():
			match results[i]:
				"WIN":
					fill = UiKit.C_BLUE_MAIN
					line = UiKit.C_BLUE_LIGHT
				"LOSE":
					fill = UiKit.C_RED_MAIN
					line = UiKit.C_RED_BORDER
				_:
					fill = Color8(110, 105, 95)
					line = Color8(190, 185, 170)
		elif i == current - 1:
			line = UiKit.C_TEXT_GOLD2
			fill = Color(0.3, 0.22, 0.1)
			s = 9.0 + 1.2 * sin(_t * 5.0)
		var pts := _shield(c, s)
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, line, 2.0, true)
