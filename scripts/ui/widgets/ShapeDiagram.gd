## ShapeDiagram.gd — miniatura de um território com quadriculado e medidas (popup, guia e história).
class_name ShapeDiagram
extends Control

const GUTTER_X := 46.0
const GUTTER_Y := 28.0
const FONT_SIZE := 18

var cells : Dictionary = {}
var analysis : Dictionary = {}
var cell_px := 20.0
var fill := Color(0.12, 0.30, 0.66, 0.9)

## px é o tamanho de cada bloco: use o MESMO valor em duas miniaturas para compará-las.
func setup(shape: Dictionary, fill_color: Color, px: float, min_size: Vector2 = Vector2.ZERO) -> void:
	cells = shape
	fill = fill_color
	cell_px = px
	analysis = ShapeAnalyzer.analyze(shape)
	var bb := ShapeAnalyzer.bounds(shape)
	var needed := Vector2(bb.size) * px + Vector2(GUTTER_X, GUTTER_Y) * 2.0
	custom_minimum_size = needed.max(min_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

## Maior bloco (em px) que faz todas as formas caberem em max_size.
static func fit_px(shapes: Array, max_size: Vector2, limit: float = 34.0) -> float:
	var px := limit
	for s in shapes:
		var bb := ShapeAnalyzer.bounds(s)
		px = minf(px, (max_size.x - GUTTER_X * 2.0) / bb.size.x)
		px = minf(px, (max_size.y - GUTTER_Y * 2.0) / bb.size.y)
	return floorf(px)

func _draw() -> void:
	if cells.is_empty():
		return
	var bb := ShapeAnalyzer.bounds(cells)
	var dim := Vector2(bb.size) * cell_px
	var origin := ((size - dim) / 2.0).floor()
	var line_col := Color(1.0, 0.95, 0.8, 0.35)

	# contorno tracejado do retângulo que envolve a forma
	if str(analysis.get("kind", "")) == "BOX":
		var corners := [origin, origin + Vector2(dim.x, 0), origin + dim, origin + Vector2(0, dim.y)]
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], UiKit.C_TEXT_GOLD2, 1.5, 6.0)

	for k in cells.keys():
		var p := origin + Vector2(k - bb.position) * cell_px
		var s := cell_px
		var t: int = cells[k]
		var pts := PackedVector2Array([p, p + Vector2(s, 0), p + Vector2(s, s), p + Vector2(0, s)])
		# o meio-bloco é o quadrado sem o vértice oposto ao ângulo reto
		if t == TerritoryGenerator.NW:
			pts.remove_at(2)
		elif t == TerritoryGenerator.NE:
			pts.remove_at(3)
		elif t == TerritoryGenerator.SE:
			pts.remove_at(0)
		elif t == TerritoryGenerator.SW:
			pts.remove_at(1)
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, line_col, 1.0)

	var f := UiKit.get_font("Cinzel")
	var labels: Dictionary = analysis.get("labels", {})
	if labels.has("top"):
		_text(f, str(labels["top"]), origin + Vector2(dim.x / 2.0, -8.0), 0.5)
	if labels.has("bottom"):
		_text(f, str(labels["bottom"]), origin + Vector2(dim.x / 2.0, dim.y + FONT_SIZE + 4.0), 0.5)
	if labels.has("left"):
		_text(f, str(labels["left"]), origin + Vector2(-8.0, dim.y / 2.0 + 6.0), 1.0)
	if labels.has("right"):
		_text(f, str(labels["right"]), origin + Vector2(dim.x + 8.0, dim.y / 2.0 + 6.0), 0.0)

	# soma de cada linha, à direita (formas irregulares)
	var sums: Array = analysis.get("row_sums", [])
	var row_font := clampi(int(cell_px * 0.75), 10, 16)
	for i in sums.size():
		draw_string(f, origin + Vector2(dim.x + 8.0, i * cell_px + cell_px / 2.0 + row_font * 0.35),
				UnitFormatter.fmt_number(float(sums[i]), 1), HORIZONTAL_ALIGNMENT_LEFT, -1, row_font, UiKit.C_TEXT_GOLD2)

## align: 0 = começa em pos, 0.5 = centralizado, 1 = termina em pos.
func _text(f: Font, txt: String, pos: Vector2, align: float) -> void:
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(f, pos - Vector2(w * align, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, UiKit.C_TEXT_GOLD2)
