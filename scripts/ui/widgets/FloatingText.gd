## FloatingText.gd — texto que sobe e some ("+10%", "-20%"). Uso: FloatingText.spawn(parent, pos, texto, cor).
class_name FloatingText
extends Label

static func spawn(parent: Node, pos: Vector2, txt: String, col: Color, font_size: int = 26) -> void:
	var l := FloatingText.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	var f := UiKit.get_font("Cinzel")
	if f:
		l.add_theme_font_override("font", f)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.z_index = 50
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", pos.y - 46.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.5)
	tw.tween_callback(l.queue_free)
