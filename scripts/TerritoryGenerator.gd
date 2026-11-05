## TerritoryGenerator.gd
## Gera territórios alinhados ao grid. Cada célula do Dictionary (Vector2i -> int) é:
##   0 = bloco inteiro | 1..4 = meio-bloco triangular (NW, NE, SE, SW; o canto indica o ângulo reto)
## Estratégias: RECT, HALF_DIAGONAL, TRAPEZOID, COMPOSITE, COMPLEX (blob orgânico), HOLLOW (áreas vazadas).

extends RefCounted
class_name TerritoryGenerator

const FULL := 0
const NW := 1
const NE := 2
const SE := 3
const SW := 4

const FLIP_H    := [0, 2, 1, 4, 3]
const FLIP_V    := [0, 4, 3, 2, 1]
const TRANSPOSE := [0, 1, 4, 3, 2]

const DIRECTIONS := [
	Vector2i( 1,  0),
	Vector2i(-1,  0),
	Vector2i( 0,  1),
	Vector2i( 0, -1),
]

var grid_cols  : int = 20
var grid_rows  : int = 16
var min_cells  : int = 10
var max_cells  : int = 140
var seed_value : int = 0   # 0 = aleatório

var _rng : RandomNumberGenerator

func _init() -> void:
	_rng = RandomNumberGenerator.new()

# ─────────────────────────────────────────────
#  API
# ─────────────────────────────────────────────
## Área em unidades de bloco (meio-bloco vale 0,5).
static func area_of(cells: Dictionary) -> float:
	var a := 0.0
	for k in cells.keys():
		a += 1.0 if int(cells[k]) == FULL else 0.5
	return a

## Gera um território de área aproximada target_area dentro da região [offset_x, offset_x+region_width).
func generate(
	target_area     : float,
	region_offset_x : int,
	region_width    : int,
	margin          : int = 1,
	shape           : String = "COMPLEX"
) -> Dictionary:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

	target_area = clampf(target_area, float(min_cells), float(max_cells))
	var max_w := region_width - 2 * margin
	var max_h := grid_rows - 2 * margin
	var tries := 300
	if shape == "COMPLEX" or shape == "HOLLOW":
		tries = 40

	var best : Dictionary = {}
	var best_err := INF
	for i in tries:
		var shp := _make_shape(shape, target_area, max_w, max_h)
		if shp.is_empty():
			continue
		shp = _normalize(shp)
		var bb := _bbox(shp)
		if bb.x > max_w or bb.y > max_h:
			continue
		var err := absf(area_of(shp) - target_area)
		if err < best_err:
			best = shp
			best_err = err
		if err < 0.01:
			break

	if best.is_empty():
		best = _best_rect(target_area, max_w, max_h)

	var size := _bbox(best)
	var ox := region_offset_x + margin + _rng.randi_range(0, maxi(0, max_w - size.x))
	var oy := margin + _rng.randi_range(0, maxi(0, max_h - size.y))
	var out := {}
	for k in best.keys():
		out[Vector2i(k.x + ox, k.y + oy)] = best[k]
	return out

# ─────────────────────────────────────────────
#  FORMAS
# ─────────────────────────────────────────────
func _make_shape(shape: String, t: float, max_w: int, max_h: int) -> Dictionary:
	if shape == "RECT":
		return _shape_rect(t, max_w, max_h)
	if shape == "HALF_DIAGONAL":
		return _shape_half_diag(t, max_w, max_h)
	if shape == "TRAPEZOID":
		# Serra mistura trapézios e formas compostas
		if _rng.randf() < 0.6:
			return _shape_trapezoid(t, max_w, max_h)
		return _shape_composite(max_w, max_h)
	if shape == "COMPOSITE":
		return _shape_composite(max_w, max_h)
	if shape == "HOLLOW":
		return _shape_hollow(t, max_w, max_h)
	return _shape_complex(t, max_w, max_h)

func _rect(w: int, h: int) -> Dictionary:
	var c := {}
	for x in w:
		for y in h:
			c[Vector2i(x, y)] = FULL
	return c

## Retângulo cuja área mais se aproxima do alvo (fallback seguro).
func _best_rect(t: float, max_w: int, max_h: int) -> Dictionary:
	var bw := 2
	var bh := 2
	var best_err := INF
	for w in range(2, max_w + 1):
		for h in range(2, max_h + 1):
			var err := absf(float(w * h) - t)
			if err < best_err:
				best_err = err
				bw = w
				bh = h
	return _rect(bw, bh)

func _shape_rect(t: float, max_w: int, max_h: int) -> Dictionary:
	var w := _rng.randi_range(2, max_w)
	var h := clampi(int(round(t / float(w))), 2, max_h)
	# Fases iniciais: ampla discrepância entre os lados
	if t >= 12.0 and float(maxi(w, h)) / float(mini(w, h)) < 1.4:
		return {}
	return _rect(w, h)

func _shape_half_diag(t: float, max_w: int, max_h: int) -> Dictionary:
	var k := _rng.randi_range(1, 4)
	var w := _rng.randi_range(3, max_w)
	var h := clampi(int(round((t + 0.5 * k) / float(w))), 3, max_h)
	var c := _rect(w, h)
	_chamfer(c, k)
	return c

func _shape_trapezoid(t: float, max_w: int, max_h: int) -> Dictionary:
	var h := _rng.randi_range(3, mini(6, max_h))
	var asym := _rng.randf() < 0.4
	var wt: int
	if asym:
		wt = int(round((t - 0.5 * h * h) / float(h)))
	else:
		wt = int(round(t / float(h))) - h
	if wt < 2:
		return {}
	var c := {}
	var left := h
	var right := h + wt
	for r in h:
		if asym:
			for x in range(0, wt + r):
				c[Vector2i(x, r)] = FULL
			c[Vector2i(wt + r, r)] = SW
		else:
			for x in range(left - r, right + r):
				c[Vector2i(x, r)] = FULL
			c[Vector2i(left - r - 1, r)] = SE
			c[Vector2i(right + r, r)] = SW
	return _random_orient(c)

func _shape_composite(max_w: int, max_h: int) -> Dictionary:
	if max_w < 5 or max_h < 4:
		return {}
	var kind := _rng.randi_range(0, 2)
	var c := {}
	if kind == 0:      # L
		var w := _rng.randi_range(4, max_w)
		var h := _rng.randi_range(4, max_h)
		var cw := _rng.randi_range(1, w - 2)
		var ch := _rng.randi_range(1, h - 2)
		c = _rect(w, h)
		for x in range(w - cw, w):
			for y in range(0, ch):
				c.erase(Vector2i(x, y))
	elif kind == 1:    # T
		var w := _rng.randi_range(5, max_w)
		var bar := _rng.randi_range(1, 3)
		var s := _rng.randi_range(1, w - 2)
		if (w - s) % 2 != 0:
			s -= 1
		if s < 1 or max_h - bar < 2:
			return {}
		var stem_h := _rng.randi_range(2, max_h - bar)
		for x in w:
			for y in bar:
				c[Vector2i(x, y)] = FULL
		var sx := (w - s) / 2
		for x in range(sx, sx + s):
			for y in range(bar, bar + stem_h):
				c[Vector2i(x, y)] = FULL
	else:              # U
		var w := _rng.randi_range(5, max_w)
		var h := _rng.randi_range(4, max_h)
		var cw := _rng.randi_range(1, w - 2)
		if (w - cw) % 2 != 0:
			cw -= 1
		if cw < 1:
			return {}
		var ch := _rng.randi_range(1, h - 2)
		c = _rect(w, h)
		var nx := (w - cw) / 2
		for x in range(nx, nx + cw):
			for y in range(0, ch):
				c.erase(Vector2i(x, y))
	return _random_orient(c)

func _shape_complex(t: float, max_w: int, max_h: int) -> Dictionary:
	var m := _rng.randi_range(1, 3)
	var n0 := mini(int(round(t)) + m, max_w * max_h)
	var c := _blob(n0, max_w, max_h)
	_fill_holes(c, max_w, max_h)
	_chamfer(c, 2 * m)
	var guard := 0
	while area_of(c) - t > 0.5 and guard < 30:
		if not _remove_safe(c):
			break
		guard += 1
	guard = 0
	while t - area_of(c) > 0.5 and guard < 30:
		if not _add_cell(c, max_w, max_h):
			break
		guard += 1
	return _random_orient(c)

func _shape_hollow(t: float, max_w: int, max_h: int) -> Dictionary:
	var sizes : Array[Vector2i] = []
	var pool : Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)]
	var total_hole := 0
	for i in _rng.randi_range(1, 3):
		var s: Vector2i = pool[_rng.randi_range(0, pool.size() - 1)]
		sizes.append(s)
		total_hole += s.x * s.y
	var base : Dictionary
	if _rng.randf() < 0.5:
		base = _shape_complex(t + total_hole, max_w, max_h)
	else:
		base = _shape_half_diag(t + total_hole, max_w, max_h)
	if base.is_empty():
		return {}
	base = _normalize(base)
	var bb := _bbox(base)
	for s in sizes:
		var placed := false
		for attempt in 30:
			if bb.x < s.x + 2 or bb.y < s.y + 2:
				break
			var hx := _rng.randi_range(1, bb.x - s.x - 1)
			var hy := _rng.randi_range(1, bb.y - s.y - 1)
			if _ring_is_full(base, hx, hy, s):
				for x in range(hx, hx + s.x):
					for y in range(hy, hy + s.y):
						base.erase(Vector2i(x, y))
				placed = true
				break
		if not placed:
			return {}
	return base

# ─────────────────────────────────────────────
#  OPERAÇÕES SOBRE FORMAS
# ─────────────────────────────────────────────
## O retângulo do buraco + anel de 1 bloco ao redor deve estar todo preenchido (blocos inteiros).
func _ring_is_full(c: Dictionary, hx: int, hy: int, s: Vector2i) -> bool:
	for x in range(hx - 1, hx + s.x + 1):
		for y in range(hy - 1, hy + s.y + 1):
			if int(c.get(Vector2i(x, y), -1)) != FULL:
				return false
	return true

## Troca blocos de canto por meios-blocos, criando arestas diagonais. Retorna quantos foram trocados.
func _chamfer(c: Dictionary, count: int) -> int:
	var cands : Array = []
	for key in c.keys():
		var p: Vector2i = key
		if int(c[p]) != FULL:
			continue
		var n := c.has(p + Vector2i(0, -1))
		var s := c.has(p + Vector2i(0, 1))
		var w := c.has(p + Vector2i(-1, 0))
		var e := c.has(p + Vector2i(1, 0))
		var kind := 0
		if not n and not w and s and e:
			kind = SE
		elif not n and not e and s and w:
			kind = SW
		elif not s and not e and n and w:
			kind = NW
		elif not s and not w and n and e:
			kind = NE
		if kind != 0:
			cands.append([p, kind])
	_shuffle(cands)
	var done := 0
	for i in mini(count, cands.size()):
		c[cands[i][0]] = cands[i][1]
		done += 1
	return done

func _blob(n: int, w: int, h: int) -> Dictionary:
	var occ := {}
	var start := Vector2i(
		_rng.randi_range(int(w * 0.25), int(w * 0.75)),
		_rng.randi_range(int(h * 0.25), int(h * 0.75)))
	occ[start] = FULL
	var frontier : Array = [start]
	var guard := 0
	while occ.size() < n and frontier.size() > 0 and guard < 5000:
		guard += 1
		_shuffle(frontier)
		var cur: Vector2i = frontier.pop_front()
		var has_free := false
		for dir in DIRECTIONS:
			if occ.size() >= n:
				break
			var nb: Vector2i = cur + dir
			if nb.x < 0 or nb.x >= w or nb.y < 0 or nb.y >= h or occ.has(nb):
				continue
			has_free = true
			if _rng.randf() < _dist_weight(nb, start, w):
				occ[nb] = FULL
				frontier.append(nb)
		if has_free:
			frontier.append(cur)
	return occ

## Preenche cavidades fechadas (figuras preenchidas; buracos só no Abismo, via HOLLOW).
func _fill_holes(c: Dictionary, w: int, h: int) -> void:
	var seen := {}
	var stack : Array = []
	for x in range(-1, w + 1):
		for y in range(-1, h + 1):
			if x == -1 or y == -1 or x == w or y == h:
				stack.append(Vector2i(x, y))
				seen[Vector2i(x, y)] = true
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in DIRECTIONS:
			var nb: Vector2i = p + d
			if nb.x < -1 or nb.x > w or nb.y < -1 or nb.y > h:
				continue
			if not c.has(nb) and not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	for x in w:
		for y in h:
			var q := Vector2i(x, y)
			if not c.has(q) and not seen.has(q):
				c[q] = FULL

func _dist_weight(cell: Vector2i, origin: Vector2i, region_width: int) -> float:
	var dist := Vector2(cell).distance_to(Vector2(origin))
	var max_d := float(region_width) * 0.6
	return clampf(1.0 - (dist / max_d) * 0.3, 0.45, 1.0)

func _remove_safe(c: Dictionary) -> bool:
	var keys : Array = c.keys()
	_shuffle(keys)
	for k in keys:
		var p: Vector2i = k
		if int(c[p]) != FULL:
			continue
		var neighbors := 0
		for d in DIRECTIONS:
			if c.has(p + d):
				neighbors += 1
		if neighbors == 4:
			continue
		var trial := c.duplicate()
		trial.erase(p)
		if _is_connected(trial):
			c.erase(p)
			return true
	return false

func _add_cell(c: Dictionary, w: int, h: int) -> bool:
	var opts : Array = []
	for k in c.keys():
		for d in DIRECTIONS:
			var nb: Vector2i = k + d
			if nb.x >= 0 and nb.x < w and nb.y >= 0 and nb.y < h and not c.has(nb) and not opts.has(nb):
				opts.append(nb)
	if opts.is_empty():
		return false
	c[opts[_rng.randi_range(0, opts.size() - 1)]] = FULL
	return true

func _is_connected(c: Dictionary) -> bool:
	if c.is_empty():
		return true
	var start: Vector2i = c.keys()[0]
	var seen := {start: true}
	var stack : Array = [start]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in DIRECTIONS:
			var nb: Vector2i = p + d
			if c.has(nb) and not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	return seen.size() == c.size()

func _transform(c: Dictionary, mode: String) -> Dictionary:
	var out := {}
	for k in c.keys():
		var p: Vector2i = k
		var t: int = c[k]
		if mode == "H":
			out[Vector2i(-p.x, p.y)] = FLIP_H[t]
		elif mode == "V":
			out[Vector2i(p.x, -p.y)] = FLIP_V[t]
		else:
			out[Vector2i(p.y, p.x)] = TRANSPOSE[t]
	return out

func _random_orient(c: Dictionary) -> Dictionary:
	if _rng.randf() < 0.5:
		c = _transform(c, "T")
	if _rng.randf() < 0.5:
		c = _transform(c, "H")
	if _rng.randf() < 0.5:
		c = _transform(c, "V")
	return c

func _bbox_min(c: Dictionary) -> Vector2i:
	var mn := Vector2i(1000000, 1000000)
	for k in c.keys():
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
	return mn

func _bbox(c: Dictionary) -> Vector2i:
	var mn := Vector2i(1000000, 1000000)
	var mx := Vector2i(-1000000, -1000000)
	for k in c.keys():
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
		mx = Vector2i(maxi(mx.x, k.x), maxi(mx.y, k.y))
	return mx - mn + Vector2i.ONE

func _normalize(c: Dictionary) -> Dictionary:
	var mn := _bbox_min(c)
	var out := {}
	for k in c.keys():
		out[Vector2i(k.x - mn.x, k.y - mn.y)] = c[k]
	return out

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
