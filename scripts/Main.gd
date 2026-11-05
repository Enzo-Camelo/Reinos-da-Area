## Main.gd
## Roteador de telas: menu -> arquétipo -> mapa de campanha -> batalha.
## Também configura janela e cursores customizados.

class_name Main
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
	get_tree().root.theme = MedievalTheme.get_theme()
	apply_display()
	DisplayServer.window_set_title("Reinos da Área")

	_transition = ScreenTransition.new()
	add_child(_transition)
	# a janela pode mudar de tamanho depois do início (tela cheia): reajusta a tela atual
	get_viewport().size_changed.connect(_fit_current)

	AudioManager.play_music("bg_music")
	_set_screen(_build_title())
	for i in 3:
		await get_tree().process_frame
		_fit_current()

## Aplica tela cheia ou janela conforme o progresso salvo.
## Em janela, o tamanho 1920x1080 é reduzido (16:9) se não couber na área útil da tela
## e a janela é centralizada nessa área. O conteúdo escala sozinho (stretch canvas_items).
static func apply_display() -> void:
	var win := DisplayServer.window_get_mode()
	if GameState.fullscreen:
		if win != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if win != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var target := Vector2i(WINDOW_W, WINDOW_H)
	var limit := Vector2(usable.size) * 0.94
	var k := minf(1.0, minf(limit.x / WINDOW_W, limit.y / WINDOW_H))
	target = Vector2i(int(WINDOW_W * k), int(WINDOW_H * k))
	DisplayServer.window_set_size(target)
	DisplayServer.window_set_position(usable.position + (usable.size - target) / 2)

## Telas baseadas em Control ocupam sempre a área visível inteira.
func _fit_current() -> void:
	if _current is Control and is_instance_valid(_current):
		var c := _current as Control
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.position = Vector2.ZERO
		c.size = get_viewport().get_visible_rect().size

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
	_fit_current()
	_fit_current.call_deferred()
	AudioManager.play_music("bg_music")

## builder cria a nova tela só quando o pergaminho cobre tudo.
func _go(builder: Callable, kind: String = "unfold") -> void:
	if _transition.is_busy():
		return
	_transition.run(func(): _set_screen(builder.call()), kind)

func _build_title() -> Node:
	var t := TitleScreen.new()
	t.continue_pressed.connect(func(): _go(_build_menu))
	return t

func _build_menu() -> Node:
	var m := MainMenu.new()
	m.play_pressed.connect(_on_play)
	m.continue_pressed.connect(func(): _go(func(): return _build_map(GameState.unlocked_phase)))
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

func _build_map(brief_phase: int = 0) -> Node:
	var c := CampaignMap.new()
	c.auto_brief = brief_phase
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
