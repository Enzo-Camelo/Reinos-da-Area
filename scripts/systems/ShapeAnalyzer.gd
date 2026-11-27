## ShapeAnalyzer.gd
## Explica COMO calcular a área de um território, olhando só para as células desenhadas.
## Ordem de preferência: retângulo → trapézio → "retângulo menos recortes" → contagem linha a linha.
## Células: mesmo formato do TerritoryGenerator (0 = inteiro, 1..4 = meio-bloco). Valores em blocos.
class_name ShapeAnalyzer
extends RefCounted

## Acima disso a decomposição "retângulo menos recortes" fica mais difícil que contar.
const MAX_CUTS := 3

## Retorna { kind, title, steps: Array[String], area: float, labels: {top,bottom,left,right},
##           row_sums: Array[float] }.
## kind: "RECT" | "TRAPEZOID" | "BOX" | "COUNT"
static func analyze(cells: Dictionary) -> Dictionary:
	if cells.is_empty():
		return _result("COUNT", "Sem território", [], 0.0)
	var trap := _try_trapezoid(cells, false)
	if trap.is_empty():
		trap = _try_trapezoid(_transpose(cells), true)
	if not trap.is_empty():
		return trap
	var box := _try_box(cells)
	if not box.is_empty():
		return box
	return _count(cells)

static func _result(kind: String, title: String, steps: Array, area: float,
		labels: Dictionary = {}, row_sums: Array = []) -> Dictionary:
	return {"kind": kind, "title": title, "steps": steps, "area": area, "labels": labels, "row_sums": row_sums}

static func _n(v: float) -> String:
	return UnitFormatter.fmt_number(v, 1)

static func bounds(cells: Dictionary) -> Rect2i:
	var mn := Vector2i(1000000, 1000000)
	var mx := Vector2i(-1000000, -1000000)
	for k in cells.keys():
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
		mx = Vector2i(maxi(mx.x, k.x), maxi(mx.y, k.y))
	return Rect2i(mn, mx - mn + Vector2i.ONE)

static func _transpose(cells: Dictionary) -> Dictionary:
	var out := {}
	for k in cells.keys():
		out[Vector2i(k.y, k.x)] = TerritoryGenerator.TRANSPOSE[int(cells[k])]
	return out

# ─────────────────────────────────────────────
#  TRAPÉZIO
# ─────────────────────────────────────────────
## Trapézio com bases horizontais (ou verticais, quando "transposed") e lados inclinados a 45°.
static func _try_trapezoid(cells: Dictionary, transposed: bool) -> Dictionary:
	var bb := bounds(cells)
	var h := bb.size.y
	if h < 2:
		return {}
	var slope := 0          # base de baixo menos base de cima, em cada linha
	var slanted := -1       # quantos lados inclinados (1 ou 2)
	var tops : Array = []
	var bottoms : Array = []
	var lefts : Array = []
	var rights : Array = []
	var left_kinds : Array = []
	var right_kinds : Array = []
	for r in h:
		var y := bb.position.y + r
		var xs : Array = []
		for x in range(bb.position.x, bb.end.x):
			if cells.has(Vector2i(x, y)):
				xs.append(x)
		if xs.is_empty() or int(xs[-1]) - int(xs[0]) + 1 != xs.size():
			return {}
		var top := 0
		var bottom := 0
		var halves := 0
		for i in xs.size():
			var t := int(cells[Vector2i(xs[i], y)])
			if t == TerritoryGenerator.FULL:
				top += 1
				bottom += 1
				continue
			if i != 0 and i != xs.size() - 1:
				return {}
			halves += 1
			if t == TerritoryGenerator.NW or t == TerritoryGenerator.NE:
				top += 1
			else:
				bottom += 1
		if halves < 1 or halves > 2:
			return {}
		if slanted == -1:
			slanted = halves
			slope = bottom - top
		if halves != slanted or bottom - top != slope or absi(slope) != slanted:
			return {}
		if r > 0 and int(bottoms[r - 1]) != top:
			return {}
		tops.append(top)
		bottoms.append(bottom)
		lefts.append(int(xs[0]))
		rights.append(int(xs[-1]))
		left_kinds.append(int(cells[Vector2i(xs[0], y)]))
		right_kinds.append(int(cells[Vector2i(xs[-1], y)]))

	# os meios-blocos das pontas precisam formar uma única linha inclinada
	var grows := slope > 0
	var left_diag := TerritoryGenerator.SE if grows else TerritoryGenerator.NE
	var right_diag := TerritoryGenerator.SW if grows else TerritoryGenerator.NW
	var left_ok := true
	var right_ok := true
	var left_straight := true
	var right_straight := true
	for r in h:
		var step := r * (1 if grows else -1)
		left_ok = left_ok and left_kinds[r] == left_diag and lefts[r] == lefts[0] - step
		right_ok = right_ok and right_kinds[r] == right_diag and rights[r] == rights[0] + step
		left_straight = left_straight and left_kinds[r] == TerritoryGenerator.FULL and lefts[r] == lefts[0]
		right_straight = right_straight and right_kinds[r] == TerritoryGenerator.FULL and rights[r] == rights[0]
	if slanted == 2 and not (left_ok and right_ok):
		return {}
	if slanted == 1 and not ((left_ok and right_straight) or (right_ok and left_straight)):
		return {}

	var first := float(tops[0])
	var last := float(bottoms[h - 1])
	var big := maxf(first, last)
	var small := minf(first, last)
	var area := (big + small) * h / 2.0
	var labels := {}
	if transposed:
		labels = {"left": _n(first), "right": _n(last), "bottom": _n(h)}
	else:
		labels = {"top": _n(first), "bottom": _n(last), "left": _n(h)}
	var steps := [
		"Trapézio: base maior %s, base menor %s, altura %d" % [_n(big), _n(small), h],
		"(B + b) × h ÷ 2",
		"(%s + %s) × %d ÷ 2 = %s" % [_n(big), _n(small), h, _n(area)],
	]
	if transposed:
		steps.insert(1, "(ele está deitado: as bases são os lados verticais)")
	return _result("TRAPEZOID", "Fórmula do trapézio", steps, area, labels)

# ─────────────────────────────────────────────
#  RETÂNGULO / RETÂNGULO MENOS RECORTES
# ─────────────────────────────────────────────
static func _try_box(cells: Dictionary) -> Dictionary:
	var bb := bounds(cells)
	var w := bb.size.x
	var h := bb.size.y
	var halves := 0
	for k in cells.keys():
		if int(cells[k]) != TerritoryGenerator.FULL:
			halves += 1

	var cuts : Array = []   # [largura, altura, é_buraco]
	var seen := {}
	for y in range(bb.position.y, bb.end.y):
		for x in range(bb.position.x, bb.end.x):
			var start := Vector2i(x, y)
			if cells.has(start) or seen.has(start):
				continue
			var comp := {start: true}
			var stack : Array = [start]
			seen[start] = true
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				for d in TerritoryGenerator.DIRECTIONS:
					var nb: Vector2i = p + d
					if bb.has_point(nb) and not cells.has(nb) and not seen.has(nb):
						seen[nb] = true
						comp[nb] = true
						stack.append(nb)
			var cb := bounds(comp)
			if cb.size.x * cb.size.y != comp.size():
				return {}
			var inside := cb.position.x > bb.position.x and cb.position.y > bb.position.y \
				and cb.end.x < bb.end.x and cb.end.y < bb.end.y
			cuts.append([cb.size.x, cb.size.y, inside])
			if cuts.size() > MAX_CUTS:
				return {}

	var labels := {"bottom": str(w), "left": str(h)}
	var total := w * h
	if cuts.is_empty() and halves == 0:
		return _result("RECT", "Retângulo: base × altura", [
			"base × altura",
			"%d × %d = %d" % [w, h, total],
		], float(total), labels)

	var steps : Array = ["Retângulo em volta: %d × %d = %d" % [w, h, total]]
	var area := float(total)
	for c in cuts:
		var cut_area: int = c[0] * c[1]
		area -= cut_area
		steps.append("− %s: %d × %d = %d" % ["buraco" if c[2] else "recorte", c[0], c[1], cut_area])
	if halves > 0:
		area -= halves * 0.5
		steps.append("− metades cortadas: %d × ½ = %s" % [halves, _n(halves * 0.5)])
	steps.append("Sobra: %s" % _n(area))
	return _result("BOX", "Retângulo menos o que falta", steps, area, labels)

# ─────────────────────────────────────────────
#  CONTAGEM
# ─────────────────────────────────────────────
static func _count(cells: Dictionary) -> Dictionary:
	var bb := bounds(cells)
	var full := 0
	var half := 0
	var row_sums : Array = []
	for y in range(bb.position.y, bb.end.y):
		var row := 0.0
		for x in range(bb.position.x, bb.end.x):
			var p := Vector2i(x, y)
			if not cells.has(p):
				continue
			if int(cells[p]) == TerritoryGenerator.FULL:
				full += 1
				row += 1.0
			else:
				half += 1
				row += 0.5
		row_sums.append(row)
	var area := full + half * 0.5
	var parts : Array[String] = []
	for v in row_sums:
		parts.append(_n(v))
	var steps := [
		"Quadrados inteiros: %d" % full,
		"Meios quadrados: %d × ½ = %s" % [half, _n(half * 0.5)],
		"%d + %s = %s" % [full, _n(half * 0.5), _n(area)],
		"Linha a linha: %s" % " + ".join(parts),
	]
	return _result("COUNT", "Forma irregular: some por partes", steps, area, {}, row_sums)
