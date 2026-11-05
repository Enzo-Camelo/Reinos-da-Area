## PhaseNode.gd — selo de cera de uma fase no mapa: número, estrelas, cadeado e destaque da fase atual.
class_name PhaseNode
extends Button

var phase := 1
var unlocked := false
var stars := 0
var is_current := false
var _hover := 0.0
var _t := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(76, 98)
	size = Vector2(76, 98)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	pivot_offset = Vector2(38, 38)
	mouse_entered.connect(func(): if unlocked: AudioManager.play_sfx("ui_hover", 0.05))
	pressed.connect(func(): AudioManager.play_sfx("ui_click"))

func setup(p: int, is_unlocked: bool, star_count: int, current: bool) -> void:
	phase = p
	unlocked = is_unlocked
	stars = star_count
	is_current = current
	disabled = not is_unlocked
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	var want := 1.0 if (is_hovered() or has_focus()) and unlocked else 0.0
	_hover = move_toward(_hover, want, delta * 7.0)
	scale = Vector2.ONE * (1.0 + 0.14 * _hover)
	queue_redraw()

func _star_poly(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts

func _draw() -> void:
	var c := Vector2(38, 38)
	var r := 28.0
	draw_circle(c + Vector2(2, 4), r + 3.0, Color(0, 0, 0, 0.45))
	var wax := Color(0.52, 0.09, 0.09)
	var rim := Color(0.30, 0.04, 0.04)
	if not unlocked:
		wax = Color(0.36, 0.34, 0.32)
		rim = Color(0.2, 0.19, 0.18)
	elif stars >= 3:
		wax = Color(0.78, 0.60, 0.16)
		rim = Color(0.45, 0.32, 0.06)
	elif stars > 0:
		wax = Color(0.18, 0.34, 0.62)
		rim = Color(0.08, 0.16, 0.34)
	# selo irregular
	var pts := PackedVector2Array()
	for i in 28:
		var a := i * TAU / 28.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r + (2.2 if i % 2 == 0 else 0.0)))
	draw_colored_polygon(pts, rim)
	draw_circle(c, r - 4.0, wax)
	draw_arc(c, r - 8.0, 0.0, TAU, 32, rim, 1.6, true)
	draw_arc(c, r - 4.0, 3.5, 5.2, 10, Color(1, 1, 1, 0.22), 2.0, true)
	if is_current and unlocked:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_arc(c, r + 6.0 + pulse * 3.0, 0.0, TAU, 40, Color(UiKit.C_TEXT_GOLD2.r, UiKit.C_TEXT_GOLD2.g, UiKit.C_TEXT_GOLD2.b, 0.9 - pulse * 0.5), 3.0, true)
	if has_focus():
		draw_arc(c, r + 5.0, 0.0, TAU, 40, UiKit.C_TEXT_GOLD2, 3.0, true)
	var f := UiKit.get_font("Cinzel")
	if unlocked:
		var txt := str(phase)
		var fs := 26
		var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(f, Vector2(c.x - ts.x / 2.0, c.y + ts.y * 0.30), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.98, 0.92, 0.75))
	else:
		# cadeado
		draw_rect(Rect2(c.x - 9, c.y - 2, 18, 14), Color(0.75, 0.72, 0.66))
		draw_arc(c + Vector2(0, -3), 6.5, PI, TAU, 12, Color(0.75, 0.72, 0.66), 3.0, true)
		draw_circle(c + Vector2(0, 5), 2.0, Color(0.25, 0.22, 0.2))
	# estrelas
	if unlocked:
		for i in 3:
			var sc := Vector2(38 + (i - 1) * 22.0, 80.0 - (4.0 if i == 1 else 0.0))
			var got := i < stars
			draw_colored_polygon(_star_poly(sc, 9.0), UiKit.C_TEXT_GOLD2 if got else Color(0.1, 0.08, 0.05, 0.75))
			if not got:
				var poly := _star_poly(sc, 9.0)
				poly.append(poly[0])
				draw_polyline(poly, Color(0.55, 0.45, 0.25, 0.6), 1.0, true)
