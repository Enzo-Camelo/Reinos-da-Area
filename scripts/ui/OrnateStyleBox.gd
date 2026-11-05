## OrnateStyleBox.gd
## StyleBox medieval desenhado por código: fundo de couro com gradiente, borda dourada dupla,
## rebites nos cantos e sombra interna. Serve para painéis e botões.
class_name OrnateStyleBox
extends StyleBox

@export var bg_top      : Color = Color8(40, 31, 20)
@export var bg_bottom   : Color = Color8(20, 15, 10)
@export var border      : Color = Color8(148, 112, 38)
@export var border_hi   : Color = Color8(230, 195, 100)
@export var border_w    : float = 2.0
@export var cut         : float = 7.0      # tamanho do chanfro nos cantos
@export var studs       : bool  = true     # rebites nos cantos
@export var inner_line  : bool  = true     # filete interno
@export var pad         : float = 12.0

func _init(top: Color = Color8(40, 31, 20), bottom: Color = Color8(20, 15, 10), bord: Color = Color8(148, 112, 38)) -> void:
	bg_top = top
	bg_bottom = bottom
	border = bord
	border_hi = bord.lightened(0.45)
	set_content_margin_all(pad)

## Variantes prontas
static func panel(alpha: float = 0.96) -> OrnateStyleBox:
	var s := OrnateStyleBox.new(Color(0.17, 0.13, 0.085, alpha), Color(0.075, 0.055, 0.035, alpha))
	s.set_content_margin_all(28.0)
	return s

static func button(base: Color, state: String = "normal") -> OrnateStyleBox:
	var top := base.lightened(0.10)
	var bottom := base.darkened(0.25)
	var bord := Color8(148, 112, 38)
	match state:
		"hover":
			top = base.lightened(0.28)
			bottom = base.darkened(0.05)
			bord = Color8(240, 210, 120)
		"pressed":
			top = base.darkened(0.2)
			bottom = base.darkened(0.4)
		"disabled":
			top = base.darkened(0.35)
			bottom = base.darkened(0.55)
			bord = Color8(100, 80, 30, 140)
		"focus":
			top = base.lightened(0.18)
			bottom = base.darkened(0.15)
			bord = Color8(255, 230, 140)
	var s := OrnateStyleBox.new(top, bottom, bord)
	s.cut = 5.0
	s.studs = state != "disabled"
	s.pad = 8.0
	s.set_content_margin_all(8.0)
	return s

static func scroll() -> OrnateStyleBox:
	var s := OrnateStyleBox.new(Color8(222, 200, 154), Color8(190, 163, 112), Color8(110, 78, 30))
	s.border_hi = Color8(150, 110, 50)
	s.cut = 4.0
	s.set_content_margin_all(20.0)
	return s

func _outline(r: Rect2, c: float) -> PackedVector2Array:
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	return PackedVector2Array([
		Vector2(x0 + c, y0), Vector2(x1 - c, y0), Vector2(x1, y0 + c), Vector2(x1, y1 - c),
		Vector2(x1 - c, y1), Vector2(x0 + c, y1), Vector2(x0, y1 - c), Vector2(x0, y0 + c),
		Vector2(x0 + c, y0)])

func _draw(canvas: RID, rect: Rect2) -> void:
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		return
	var c := minf(cut, minf(rect.size.x, rect.size.y) * 0.3)
	var poly := _outline(rect, c)
	poly.remove_at(poly.size() - 1)
	# fundo com gradiente vertical (cor por vértice)
	var colors := PackedColorArray()
	for p in poly:
		colors.append(bg_top.lerp(bg_bottom, clampf((p.y - rect.position.y) / rect.size.y, 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(canvas, poly, colors)
	# sombra interna (faixa escura no topo e na base)
	var sh := Color(0, 0, 0, 0.18)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x + c, rect.position.y + border_w, rect.size.x - 2.0 * c, 3.0), sh)
	# borda externa
	RenderingServer.canvas_item_add_polyline(canvas, _outline(rect.grow(-border_w * 0.5), c), PackedColorArray([border]), border_w, true)
	# filete interno
	if inner_line and rect.size.x > 30.0 and rect.size.y > 24.0:
		var inner := rect.grow(-(border_w + 3.0))
		RenderingServer.canvas_item_add_polyline(canvas, _outline(inner, maxf(c - 2.0, 1.0)), PackedColorArray([Color(border_hi.r, border_hi.g, border_hi.b, 0.42)]), 1.0, true)
	# rebites
	if studs and rect.size.x > 40.0 and rect.size.y > 30.0:
		var off := border_w + 4.0
		for pt in [Vector2(rect.position.x + off + 1, rect.position.y + off + 1), Vector2(rect.end.x - off - 1, rect.position.y + off + 1),
				Vector2(rect.position.x + off + 1, rect.end.y - off - 1), Vector2(rect.end.x - off - 1, rect.end.y - off - 1)]:
			RenderingServer.canvas_item_add_circle(canvas, pt, 2.4, border)
			RenderingServer.canvas_item_add_circle(canvas, pt + Vector2(-0.5, -0.5), 1.0, border_hi)

func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect
