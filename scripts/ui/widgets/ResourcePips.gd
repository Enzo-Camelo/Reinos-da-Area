## ResourcePips.gd — moedas de ouro dos Recursos Estratégicos (RE), com animação ao gastar/ganhar.
class_name ResourcePips
extends Control

var count := 0
var max_shown := 6
var _pop := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(160, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_count(n: int) -> void:
	if n != count:
		_pop = 1.0
		var tw := create_tween()
		tw.tween_property(self, "_pop", 0.0, 0.4)
	count = n
	queue_redraw()

func _process(_d: float) -> void:
	if _pop > 0.0:
		queue_redraw()

func _draw() -> void:
	var shown := mini(maxi(count, 3), max_shown)
	for i in shown:
		var c := Vector2(14.0 + i * 26.0, size.y / 2.0)
		var has := i < count
		var r := 10.0 + (2.0 * _pop if i == count - 1 else 0.0)
		draw_circle(c, r, UiKit.C_BORDER_GOLD if has else Color(0.2, 0.16, 0.1))
		draw_circle(c, r - 2.5, UiKit.C_TEXT_GOLD2 if has else Color(0.12, 0.09, 0.06))
		if has:
			draw_arc(c, r - 5.0, 0.3, 2.2, 8, Color(1, 1, 1, 0.55), 1.5, true)
	if count > max_shown:
		draw_string(UiKit.get_font("Source Sans 3"), Vector2(14.0 + shown * 26.0, size.y / 2.0 + 6.0), "+%d" % (count - max_shown), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.C_TEXT_GOLD2)
