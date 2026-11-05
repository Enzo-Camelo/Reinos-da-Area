## Main.gd
## Roteador de telas: menu -> arquétipo -> mapa de campanha -> batalha.
## Também configura janela e cursores customizados.

extends Node2D

const WINDOW_W := 1920
const WINDOW_H := 1080

var _current : Node = null
var _transition : ScreenTransition
## Para onde ir depois de escolher o arquétipo: "map" ou "menu"
var _after_archetype := "map"

func _ready() -> void:
	_setup_cursors()
	RenderingServer.set_default_clear_color(UiKit.C_BG_DARK)
	get_window().size = Vector2i(WINDOW_W, WINDOW_H)
	var screen_size := DisplayServer.screen_get_size()
	get_window().position = (screen_size / 2) - (get_window().size / 2)
	DisplayServer.window_set_title("Reinos da Área")

	_transition = ScreenTransition.new()
	add_child(_transition)

	AudioManager.play_music("bg_music")
	_set_screen(_build_menu())

func _setup_cursors() -> void:
	var cursor_default = load("res://assets/cursor/default.png")
	if cursor_default:
		Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(0, 0))
	var cursor_pointer = load("res://assets/cursor/pointer.png")
	if cursor_pointer:
		Input.set_custom_mouse_cursor(cursor_pointer, Input.CURSOR_POINTING_HAND, Vector2(0, 0))

# ─────────────────────────────────────────────
#  TROCA DE TELAS
# ─────────────────────────────────────────────
func _set_screen(node: Node) -> void:
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = node
	add_child(node)
	AudioManager.play_music("bg_music")

## builder cria a nova tela só quando o pergaminho cobre tudo.
func _go(builder: Callable, kind: String = "unfold") -> void:
	if _transition.is_busy():
		return
	_transition.run(func(): _set_screen(builder.call()), kind)

func _build_menu() -> Node:
	var m := MainMenu.new()
	m.play_pressed.connect(_on_play)
	m.archetype_pressed.connect(func():
		_after_archetype = "menu"
		_go(_build_archetype))
	m.map_pressed.connect(func(): _go(_build_map))
	m.quit_pressed.connect(func(): get_tree().quit())
	return m

func _build_archetype() -> Node:
	var a := ArchetypeSelect.new()
	a.selected.connect(func(_id: String):
		if _after_archetype == "menu":
			_go(_build_menu)
		else:
			_go(_build_map))
	a.back.connect(func():
		if _after_archetype == "menu":
			_go(_build_menu)
		else:
			_go(_build_map))
	return a

func _build_map() -> Node:
	var c := CampaignMap.new()
	c.phase_chosen.connect(func(n: int): _go(func(): return _build_battle(n), "page"))
	c.archetype_requested.connect(func():
		_after_archetype = "map"
		_go(_build_archetype))
	c.back.connect(func(): _go(_build_menu))
	return c

func _build_battle(n: int) -> Node:
	var b := BattleScreen.new()
	b.setup(n)
	b.exit_to_map.connect(func(): _go(_build_map))
	b.go_to_phase.connect(func(p: int): _go(func(): return _build_battle(p), "page"))
	return b

func _on_play() -> void:
	if GameState.archetype == "":
		_after_archetype = "map"
		_go(_build_archetype)
	else:
		_go(_build_map)
