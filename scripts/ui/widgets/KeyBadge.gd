## KeyBadge.gd — tecla desenhada (A, D, R, E, Enter, Esc) para dicas de atalho.
class_name KeyBadge
extends Control

var text := "A"
var accent := UiKit.C_TEXT_GOLD2

static func make(t: String, size: float = 26.0) -> KeyBadge:
	var k := KeyBadge.new()
	k.text = t
	k.custom_minimum_size = Vector2(maxf(size, 12.0 + t.length() * 11.0), size)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return k

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r.grow(-1), Color(0.08, 0.06, 0.04, 0.9), true)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 5), Color(0.2, 0.15, 0.09, 1.0), true)
	draw_rect(r.grow(-1), accent, false, 1.5)
	var f := UiKit.get_font("Cinzel")
	var fs := int(size.y * 0.55)
	var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, Vector2((size.x - ts.x) / 2.0, (size.y - 4.0) / 2.0 + ts.y * 0.32), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, accent)
