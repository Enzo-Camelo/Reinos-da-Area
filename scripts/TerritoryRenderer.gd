## TerritoryRenderer.gd
## Node2D que desenha o grid e os dois territórios usando _draw().
## Células: 0 = bloco inteiro, 1..4 = meio-bloco triangular (ver TerritoryGenerator).
## Direção de arte: cartografia medieval com grid em pergaminho.

extends Node2D
class_name TerritoryRenderer
## Parâmetros do pergaminho por cenário: base, mancha, tinta, motivo, intensidade, cor da grade
const SCENARIO_LOOK := [
	{"base": Color(0.80, 0.72, 0.52), "stain": Color(0.55, 0.42, 0.22), "ink": Color(0.25, 0.17, 0.08), "motif": 0, "str": 0.0, "grid": Color(0.28, 0.18, 0.08, 0.40)},
	{"base": Color(0.77, 0.67, 0.46), "stain": Color(0.50, 0.38, 0.20), "ink": Color(0.30, 0.20, 0.08), "motif": 1, "str": 0.16, "grid": Color(0.28, 0.18, 0.08, 0.40)},
	{"base": Color(0.67, 0.63, 0.56), "stain": Color(0.36, 0.33, 0.28), "ink": Color(0.18, 0.16, 0.14), "motif": 2, "str": 0.14, "grid": Color(0.15, 0.13, 0.11, 0.42)},
	{"base": Color(0.56, 0.67, 0.72), "stain": Color(0.25, 0.38, 0.50), "ink": Color(0.10, 0.20, 0.30), "motif": 3, "str": 0.16, "grid": Color(0.07, 0.15, 0.25, 0.42)},
	{"base": Color(0.32, 0.27, 0.40), "stain": Color(0.12, 0.08, 0.18), "ink": Color(0.85, 0.65, 0.95), "motif": 4, "str": 0.20, "grid": Color(0.88, 0.78, 1.00, 0.34)},
]
var grid_line_color : Color = COLOR_GRID_LINE
var _bg : ColorRect
var _bg_mat : ShaderMaterial

# ─────────────────────────────────────────────
#  PALETA MEDIEVAL
# ─────────────────────────────────────────────
const COLOR_GRID_BG       := Color("#bba375")
const COLOR_GRID_LINE     := Color(0.28, 0.18, 0.08, 0.40)
const COLOR_PLAYER_FILL   := Color(0.12, 0.30, 0.66, 0.74)
const COLOR_PLAYER_BORDER := Color(0.55, 0.76, 1.00, 0.85)
const COLOR_PLAYER_INK    := Color(0.05, 0.10, 0.28, 0.95)
const COLOR_ENEMY_INK     := Color(0.28, 0.04, 0.04, 0.95)
const COLOR_PLAYER_INNER  := Color(0.20, 0.50, 0.85, 0.18)
const COLOR_ENEMY_FILL    := Color(0.60, 0.10, 0.10, 0.84)
const COLOR_ENEMY_BORDER  := Color(0.95, 0.55, 0.45, 0.70)
const COLOR_GOLD          := Color(0.96, 0.78, 0.30, 1.0)
const COLOR_DIVIDER       := Color(0.76, 0.58, 0.18, 0.82)

const GRID_LINE_WIDTH     := 1.0
const BORDER_LINE_WIDTH   := 3.5
const DIVIDER_WIDTH       := 3.5

# lados completos de cada tipo de célula: 0 topo, 1 base, 2 esquerda, 3 direita
const FULL_SIDES := [[0, 1, 2, 3], [0, 2], [0, 3], [3, 1], [2, 1]]
const OPPOSITE   := [1, 0, 3, 2]
const SIDE_DIRS  := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

var cell_size      : int        = 60
var grid_cols      : int        = 32
var grid_rows      : int        = 14
var player_cells   : Dictionary = {}
var enemy_cells    : Dictionary = {}
var enemy_revealed : bool       = false
## Anel de células de referência (grid) ao redor do inimigo. >= 99: grid em todo o mapa.
var reference_ring : int        = 99
var temp_reveal    : bool       = false
var pulse_enemy    : bool       = false

var _anim_progress   : float = 0.0
var _animating       : bool  = false
var _reveal_progress : float = 1.0
var _ink_progress    : float = 0.0
var _ink_active      : bool  = false
var _defeat_time     : float = 0.0
var _pulse_t         : float = 0.0
var _flash_color     : Color = Color.TRANSPARENT
var _flash_alpha     : float = 0.0
var _particles       : Array[Dictionary] = []
var _result_type     : String = ""
var _enemy_min_x     : int = 0
var _enemy_span      : int = 1
var _ring_cells      : Dictionary = {}
var _enemy_hollow    : Dictionary = {}
var _temp_token      : int = 0
var vs_icon          : Sprite2D

func _ready() -> void:
	set_process(true)
	_bg = ColorRect.new()
	_bg.show_behind_parent = true
	_bg.size = Vector2(cell_size * grid_cols, cell_size * grid_rows)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_mat = ShaderMaterial.new()
	_bg_mat.shader = load("res://shaders/parchment.gdshader")
	_bg_mat.set_shader_parameter("rect_size", _bg.size)
	_bg_mat.set_shader_parameter("burn", 0.3)
	_bg_mat.set_shader_parameter("vignette", 0.32)
	_bg.material = _bg_mat
	add_child(_bg)
	set_scenario(0)
	vs_icon = Sprite2D.new()
	if ResourceLoader.exists("res://assets/icons/vs.png"):
		vs_icon.texture = load("res://assets/icons/vs.png")
	vs_icon.scale = Vector2(0.3, 0.3)
	vs_icon.modulate.a = 0.0
	vs_icon.z_index = 10
	add_child(vs_icon)

func _process(delta: float) -> void:
	var changed := false
	if _animating:
		# Transição interpolada: jogador surge em fade e o inimigo é revelado por varredura de colunas
		_anim_progress = minf(_anim_progress + delta * 1.1, 1.0)
		if _anim_progress >= 1.0:
			_animating = false
		changed = true
	if enemy_revealed and _reveal_progress < 1.0:
		_reveal_progress = minf(_reveal_progress + delta / 0.4, 1.0)
		changed = true
	if _ink_active and _ink_progress < 1.0:
		_ink_progress = minf(_ink_progress + delta / 0.6, 1.0)
		changed = true
	if _defeat_time > 0.0:
		_defeat_time = maxf(0.0, _defeat_time - delta)
		changed = true
	if pulse_enemy:
		_pulse_t += delta
		changed = true

	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta)
		for p in _particles:
			if _result_type == "WIN" or _result_type == "LOSE":
				p.rot += delta * p.speed
				p.phase += delta * 8.0
			elif _result_type == "DRAW":
				p.pos.x += delta * p.speed
				p.pos.y += sin(p.phase) * delta * 15.0
				p.phase += delta * 10.0
		changed = true
	if changed:
		queue_redraw()

# ─────────────────────────────────────────────
#  API
# ─────────────────────────────────────────────
## Aparência do pergaminho por cenário (0..4).
func set_scenario(index: int) -> void:
	var look: Dictionary = SCENARIO_LOOK[clampi(index, 0, SCENARIO_LOOK.size() - 1)]
	_bg_mat.set_shader_parameter("base_color", look["base"])
	_bg_mat.set_shader_parameter("stain_color", look["stain"])
	_bg_mat.set_shader_parameter("ink_color", look["ink"])
	_bg_mat.set_shader_parameter("motif", look["motif"])
	_bg_mat.set_shader_parameter("motif_strength", look["str"])
	grid_line_color = look["grid"]
	queue_redraw()

func set_territories(p_cells: Dictionary, e_cells: Dictionary) -> void:
	player_cells   = p_cells
	enemy_cells    = e_cells
	enemy_revealed = false
	temp_reveal    = false
	_temp_token   += 1
	_reveal_progress = 0.0
	_ink_active    = false
	_ink_progress  = 0.0
	_defeat_time   = 0.0
	_anim_progress = 0.0
	_animating     = true
	_compute_enemy_info()
	_rebuild_ring()
	queue_redraw()

func set_reference_ring(ring: int) -> void:
	reference_ring = ring
	_rebuild_ring()
	queue_redraw()

func reveal_enemy_grid() -> void:
	enemy_revealed = true
	_reveal_progress = 0.0
	queue_redraw()

## Grid do inimigo visível por alguns segundos (Análise de Campo).
func reveal_enemy_temporarily(seconds: float) -> void:
	temp_reveal = true
	_temp_token += 1
	var token := _temp_token
	queue_redraw()
	await get_tree().create_timer(seconds).timeout
	if token == _temp_token:
		temp_reveal = false
		queue_redraw()

func set_enemy_pulse(on: bool) -> void:
	pulse_enemy = on
	_pulse_t = 0.0
	queue_redraw()

func play_ink_spread() -> void:
	_ink_active = true
	_ink_progress = 0.0

func play_defeat_pulse() -> void:
	_defeat_time = 2.0

func play_result_flash(type: String) -> void:
	_result_type = type
	_flash_alpha = 1.0
	_particles.clear()
	var total_w := cell_size * grid_cols
	var total_h := cell_size * grid_rows
	if type == "WIN":
		_flash_color = Color(1.0, 0.85, 0.40, 1.0)
		for i in (8 if GameState.reduce_motion else 40):
			_particles.append({
				"pos": Vector2(randf_range(0, total_w), randf_range(0, total_h)),
				"size": randf_range(10.0, 30.0),
				"rot": randf_range(0, PI),
				"speed": randf_range(1.5, 4.0) * (1 if randi() % 2 == 0 else -1),
				"phase": randf_range(0, PI * 2)
			})
	elif type == "LOSE":
		_flash_color = Color(0.95, 0.15, 0.15, 1.0)
		for i in (8 if GameState.reduce_motion else 40):
			_particles.append({
				"pos": Vector2(randf_range(0, total_w), randf_range(0, total_h)),
				"size": randf_range(12.0, 32.0),
				"rot": randf_range(0, PI),
				"speed": randf_range(0.5, 2.0) * (1 if randi() % 2 == 0 else -1),
				"phase": randf_range(0, PI * 2)
			})
	elif type == "DRAW":
		_flash_color = Color(0.85, 0.85, 0.85, 1.0)
		for i in (6 if GameState.reduce_motion else 35):
			_particles.append({
				"pos": Vector2(randf_range(-total_w * 0.8, total_w * 0.1), randf_range(0, total_h)),
				"length": randf_range(80.0, 300.0),
				"speed": randf_range(1200.0, 2500.0),
				"phase": randf_range(0, PI * 2),
				"thickness": randf_range(1.0, 4.0)
			})
	queue_redraw()

func play_vs_animation() -> void:
	if not vs_icon or not vs_icon.texture:
		return
	var total_w := cell_size * grid_cols
	var total_h := cell_size * grid_rows
	var center := Vector2(total_w / 2.0, total_h / 2.0)
	vs_icon.position = center - Vector2(0, 250)
	vs_icon.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(vs_icon, "position", center, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(vs_icon, "modulate:a", 1.0, 0.25)
	tween.set_parallel(false)
	tween.tween_interval(0.4)
	tween.tween_property(vs_icon, "modulate:a", 0.0, 0.2)

# ─────────────────────────────────────────────
#  PRÉ-CÁLCULOS
# ─────────────────────────────────────────────
func _compute_enemy_info() -> void:
	var mn := 100000
	var mx := -100000
	for k in enemy_cells.keys():
		mn = mini(mn, k.x)
		mx = maxi(mx, k.x)
	if enemy_cells.is_empty():
		mn = 0
		mx = 0
	_enemy_min_x = mn
	_enemy_span = maxi(1, mx - mn + 1)
	_enemy_hollow = _find_holes(enemy_cells)

## Células vazias totalmente cercadas pelo território (áreas vazadas).
func _find_holes(cells: Dictionary) -> Dictionary:
	var holes := {}
	if cells.is_empty():
		return holes
	var mn := Vector2i(100000, 100000)
	var mx := Vector2i(-100000, -100000)
	for k in cells.keys():
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
		mx = Vector2i(maxi(mx.x, k.x), maxi(mx.y, k.y))
	var seen := {}
	var stack : Array = []
	for x in range(mn.x - 1, mx.x + 2):
		for y in range(mn.y - 1, mx.y + 2):
			if x == mn.x - 1 or x == mx.x + 1 or y == mn.y - 1 or y == mx.y + 1:
				stack.append(Vector2i(x, y))
				seen[Vector2i(x, y)] = true
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in SIDE_DIRS:
			var nb: Vector2i = p + d
			if nb.x < mn.x - 1 or nb.x > mx.x + 1 or nb.y < mn.y - 1 or nb.y > mx.y + 1:
				continue
			if not cells.has(nb) and not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	for x in range(mn.x, mx.x + 1):
		for y in range(mn.y, mx.y + 1):
			var q := Vector2i(x, y)
			if not cells.has(q) and not seen.has(q):
				holes[q] = true
	return holes

func _rebuild_ring() -> void:
	_ring_cells.clear()
	if reference_ring >= 99 or reference_ring < 0:
		return
	for k in enemy_cells.keys():
		for dx in range(-reference_ring, reference_ring + 1):
			for dy in range(-reference_ring, reference_ring + 1):
				_ring_cells[Vector2i(k.x + dx, k.y + dy)] = true

func _enemy_grid_open() -> bool:
	return enemy_revealed or temp_reveal

## Uma célula tem grid visível?
func _grid_visible(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_cols or cell.y >= grid_rows:
		return false
	if enemy_cells.has(cell) or _enemy_hollow.has(cell):
		if not _enemy_grid_open():
			return false
		if enemy_revealed and not temp_reveal:
			# varredura "desenhada à mão": colunas surgem da esquerda para a direita
			return float(cell.x - _enemy_min_x) / float(_enemy_span) <= _reveal_progress
		return true
	if reference_ring >= 99:
		return true
	if cell.x < grid_cols / 2:
		return true
	return _ring_cells.has(cell)

func _enemy_visible(cell: Vector2i) -> bool:
	# o inimigo é desvendado por varredura de colunas ao entrar na rodada
	return float(cell.x - _enemy_min_x) / float(_enemy_span) <= _anim_progress * 1.2

# ─────────────────────────────────────────────
#  DESENHO
# ─────────────────────────────────────────────
func _cell_points(cell: Vector2i, t: int) -> PackedVector2Array:
	var px: float = cell.x * cell_size
	var py: float = cell.y * cell_size
	var s := float(cell_size)
	match t:
		1: return PackedVector2Array([Vector2(px, py), Vector2(px + s, py), Vector2(px, py + s)])
		2: return PackedVector2Array([Vector2(px, py), Vector2(px + s, py), Vector2(px + s, py + s)])
		3: return PackedVector2Array([Vector2(px + s, py), Vector2(px + s, py + s), Vector2(px, py + s)])
		4: return PackedVector2Array([Vector2(px, py), Vector2(px + s, py + s), Vector2(px, py + s)])
	return PackedVector2Array([Vector2(px, py), Vector2(px + s, py), Vector2(px + s, py + s), Vector2(px, py + s)])

func _fill_cell(cell: Vector2i, t: int, col: Color) -> void:
	if t == 0:
		draw_rect(Rect2(cell.x * cell_size, cell.y * cell_size, cell_size, cell_size), col)
	else:
		draw_colored_polygon(_cell_points(cell, t), col)

func _has_full_side(t: int, side: int) -> bool:
	return FULL_SIDES[t].has(side)

func _draw() -> void:
	var total_w := cell_size * grid_cols
	var total_h := cell_size * grid_rows
	var mid_x := (grid_cols / 2) * cell_size

	_draw_territory(player_cells, COLOR_PLAYER_FILL, COLOR_PLAYER_BORDER, true)
	_draw_territory(enemy_cells, COLOR_ENEMY_FILL, COLOR_ENEMY_BORDER, false)
	_draw_ink()
	_draw_grid()

	# bordas de destaque (seleção do inimigo e derrota)
	if pulse_enemy:
		var a := 0.55 + 0.45 * sin(_pulse_t * TAU / 0.8)
		_draw_border(enemy_cells, Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, a), 5.0, false)
	if _defeat_time > 0.0:
		var a2 := (0.5 + 0.5 * sin(_defeat_time * TAU * 2.0)) * clampf(_defeat_time, 0.0, 1.0)
		_draw_border(player_cells, Color(0.95, 0.15, 0.15, a2), 6.0, true)

	var dash := 22.0
	var y := 0.0
	while y < total_h:
		draw_line(Vector2(mid_x, y), Vector2(mid_x, minf(y + dash, total_h)), COLOR_DIVIDER, DIVIDER_WIDTH)
		y += dash * 1.7

	# overlay de brilho e partículas
	if _flash_alpha > 0.0:
		var fc := _flash_color
		fc.a = _flash_alpha * (0.26 if _result_type != "DRAW" else 0.12)
		draw_rect(Rect2(0, 0, total_w, total_h), fc)
		for p in _particles:
			if _result_type == "WIN":
				_draw_star_sparkle(p.pos, p.size, p.rot, _flash_alpha, p.phase)
			elif _result_type == "LOSE":
				_draw_red_x(p.pos, p.size, p.rot, _flash_alpha, p.phase)
			elif _result_type == "DRAW":
				_draw_wind_line(p.pos, p.length, _flash_alpha, p.thickness)

func _draw_territory(cells: Dictionary, fill_col: Color, border_col: Color, is_player: bool) -> void:
	if cells.is_empty():
		return
	var alpha_mult := _anim_progress if is_player else 1.0
	for key in cells.keys():
		var cell: Vector2i = key
		if not is_player and not _enemy_visible(cell):
			continue
		var c := fill_col
		c.a *= alpha_mult
		_fill_cell(cell, int(cells[cell]), c)
	var ink := COLOR_PLAYER_INK if is_player else COLOR_ENEMY_INK
	ink.a *= alpha_mult
	_draw_border(cells, ink, BORDER_LINE_WIDTH + 1.5, is_player)
	var bc := border_col
	bc.a *= alpha_mult
	if bc.a > 0.0:
		_draw_border(cells, bc, 1.4, is_player)

## Contorno do território: lados completos sem vizinho coberto + diagonal dos meios-blocos.
func _draw_border(cells: Dictionary, col: Color, width: float, is_player: bool) -> void:
	for key in cells.keys():
		var cell: Vector2i = key
		if not is_player and not _enemy_visible(cell):
			continue
		var t: int = cells[cell]
		var px: float = cell.x * cell_size
		var py: float = cell.y * cell_size
		var s := float(cell_size)
		var edges := [
			[Vector2(px, py), Vector2(px + s, py)],
			[Vector2(px, py + s), Vector2(px + s, py + s)],
			[Vector2(px, py), Vector2(px, py + s)],
			[Vector2(px + s, py), Vector2(px + s, py + s)],
		]
		for side in 4:
			if not _has_full_side(t, side):
				continue
			var nb: Vector2i = cell + SIDE_DIRS[side]
			if cells.has(nb) and _has_full_side(int(cells[nb]), OPPOSITE[side]):
				continue
			draw_line(edges[side][0], edges[side][1], col, width)
		if t != 0:
			var pts := _cell_points(cell, t)
			# a diagonal liga os dois vértices que não formam o ângulo reto
			var a: Vector2 = pts[1]
			var b: Vector2 = pts[2]
			if t == 2:
				a = pts[0]
				b = pts[2]
			elif t == 4:
				a = pts[0]
				b = pts[1]
			elif t == 3:
				a = pts[0]
				b = pts[2]
			draw_line(a, b, col, width)

func _draw_ink() -> void:
	if not _ink_active or enemy_cells.is_empty():
		return
	var centroid := Vector2.ZERO
	for k in enemy_cells.keys():
		centroid += Vector2(k.x, k.y)
	centroid /= float(enemy_cells.size())
	var max_d := 1.0
	for k in enemy_cells.keys():
		max_d = maxf(max_d, Vector2(k.x, k.y).distance_to(centroid))
	for k in enemy_cells.keys():
		var d := Vector2(k.x, k.y).distance_to(centroid) / max_d
		if d <= _ink_progress:
			var c := COLOR_PLAYER_FILL
			c.a = 0.85
			_fill_cell(k, int(enemy_cells[k]), c)

func _draw_grid() -> void:
	var s := cell_size
	for cx in grid_cols:
		for cy in grid_rows:
			var cell := Vector2i(cx, cy)
			if not _grid_visible(cell):
				continue
			var x := cx * s
			var y := cy * s
			# topo e esquerda sempre; base e direita só na fronteira do grid visível
			draw_line(Vector2(x, y + 0.5), Vector2(x + s, y + 0.5), grid_line_color, GRID_LINE_WIDTH)
			draw_line(Vector2(x + 0.5, y), Vector2(x + 0.5, y + s), grid_line_color, GRID_LINE_WIDTH)
			if not _grid_visible(Vector2i(cx + 1, cy)):
				draw_line(Vector2(x + s - 0.5, y), Vector2(x + s - 0.5, y + s), grid_line_color, GRID_LINE_WIDTH)
			if not _grid_visible(Vector2i(cx, cy + 1)):
				draw_line(Vector2(x, y + s - 0.5), Vector2(x + s, y + s - 0.5), grid_line_color, GRID_LINE_WIDTH)

func _draw_star_sparkle(pos: Vector2, size: float, rot: float, alpha: float, phase: float) -> void:
	var pulse := (sin(phase) * 0.4 + 0.6) * alpha
	var c := Color(1.0, 0.92, 0.55, pulse)
	var dir1 := Vector2(cos(rot), sin(rot)) * size
	var dir2 := Vector2(cos(rot + PI / 2.0), sin(rot + PI / 2.0)) * size
	draw_line(pos - dir1, pos + dir1, c, 2.5, true)
	draw_line(pos - dir2, pos + dir2, c, 2.5, true)
	var dir3 := Vector2(cos(rot + PI / 4.0), sin(rot + PI / 4.0)) * (size * 0.4)
	var dir4 := Vector2(cos(rot - PI / 4.0), sin(rot - PI / 4.0)) * (size * 0.4)
	draw_line(pos - dir3, pos + dir3, c, 1.2, true)
	draw_line(pos - dir4, pos + dir4, c, 1.2, true)
	draw_circle(pos, size * 0.15, Color(1.0, 1.0, 1.0, pulse * 1.5))

func _draw_red_x(pos: Vector2, size: float, rot: float, alpha: float, phase: float) -> void:
	var pulse := (sin(phase) * 0.3 + 0.7) * alpha
	var c_glow := Color(0.95, 0.1, 0.1, pulse * 0.5)
	var c_core := Color(1.0, 0.6, 0.6, pulse)
	var dir1 := Vector2(cos(rot + PI / 4.0), sin(rot + PI / 4.0)) * size
	var dir2 := Vector2(cos(rot - PI / 4.0), sin(rot - PI / 4.0)) * size
	draw_line(pos - dir1, pos + dir1, c_glow, 6.0, true)
	draw_line(pos - dir2, pos + dir2, c_glow, 6.0, true)
	draw_line(pos - dir1, pos + dir1, c_core, 2.5, true)
	draw_line(pos - dir2, pos + dir2, c_core, 2.5, true)

func _draw_wind_line(pos: Vector2, length: float, alpha: float, thickness: float) -> void:
	var c := Color(1.0, 1.0, 1.0, alpha * 0.8)
	draw_line(pos, pos + Vector2(length, 0), c, thickness, true)
