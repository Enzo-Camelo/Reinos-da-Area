## TimerMedallion.gd — anel de tempo circular com número; vermelho e pulsando nos últimos 10 s.
class_name TimerMedallion
extends Control

var total := 60.0
var left := 60.0
var _t := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(84, 84)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(total_seconds: float) -> void:
	total = maxf(total_seconds, 1.0)
	left = total
	queue_redraw()

func set_left(s: float) -> void:
	left = clampf(s, 0.0, total)
	queue_redraw()

func _process(delta: float) -> void:
	if left <= 10.0:
		_t += delta
		queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	var urgent := left <= 10.0 and left > 0.0
	var pulse := 1.0 + (0.05 * sin(_t * 9.0) if urgent else 0.0)
	var col := UiKit.C_RED_BORDER if urgent else UiKit.C_TEXT_GOLD
	draw_circle(c, r * pulse + 3.0, Color(0, 0, 0, 0.5))
	draw_circle(c, r * pulse, Color(0.09, 0.065, 0.04, 0.96))
	draw_arc(c, r * pulse, 0.0, TAU, 48, UiKit.C_BORDER_GOLD, 3.0, true)
	var frac := left / total
	if frac > 0.0:
		draw_arc(c, (r - 7.0) * pulse, -PI / 2.0, -PI / 2.0 + TAU * frac, 48, col, 5.0, true)
	var f := UiKit.get_font("Cinzel")
	var txt := str(ceili(left))
	var fs := 26
	var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, Vector2(c.x - ts.x / 2.0, c.y + ts.y * 0.28), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
