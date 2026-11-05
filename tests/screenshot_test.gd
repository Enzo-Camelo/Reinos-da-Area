## Captura telas para inspeção visual. Uso:
##   Godot.exe --path . --windowed --resolution 1920x1080 res://tests/screenshot_test.tscn -- <pasta_saida>
extends Node

var out_dir := "user://shots"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _run()
	get_tree().quit()

func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])

func _show(node: Node, wait: float, name: String) -> void:
	add_child(node)
	await get_tree().create_timer(wait).timeout
	await _shot(name)
	node.queue_free()
	await get_tree().process_frame

func _battle(n: int, arch: String, tutorial: bool, wait: float, name: String, resolve_action: int = -1, after: float = 0.0) -> void:
	GameState.archetype = arch
	GameState.resources = 3
	GameState.tutorial_done = not tutorial
	var b := BattleScreen.new()
	b.setup(n)
	add_child(b)
	await get_tree().create_timer(wait).timeout
	await _shot(name)
	if resolve_action >= 0:
		b.game_manager.resolve_action(resolve_action)
		await get_tree().create_timer(after).timeout
		await _shot(name + "_result")
	b.queue_free()
	await get_tree().process_frame

func _run() -> void:
	await _show(TitleScreen.new(), 3.5, "00_title")
	await _show(MainMenu.new(), 0.5, "01_menu")
	GameState.archetype = ""
	await _show(ArchetypeSelect.new(), 0.5, "02_archetype")
	GameState.unlocked_phase = 6
	GameState.stars = {1: 3, 2: 2, 3: 1, 4: 1, 5: 2}
	await _show(CampaignMap.new(), 0.5, "03_map")
	await _battle(1, "ESTRATEGISTA", true, 2.5, "04_battle1_tutorial")
	await _battle(1, "GUERREIRO", false, 2.5, "05_battle1", CombatResolver.ACTION_ATTACK, 6.5)
	await _battle(5, "ENGENHEIRO", false, 2.5, "06_battle5_vale")
	await _battle(9, "ESTRATEGISTA", false, 2.5, "07_battle9_serra")
	await _battle(13, "GUERREIRO", false, 2.5, "08_battle13_arq")
	await _battle(17, "ENGENHEIRO", false, 2.5, "09_battle17_abismo")
	# painéis extras
	GameState.archetype = "GUERREIRO"
	GameState.tutorial_done = true
	var b := BattleScreen.new()
	b.setup(5)
	add_child(b)
	await get_tree().create_timer(1.0).timeout
	b.end_panel.show_summary({"won": true, "reason": "ROUNDS", "phase": 5, "dominance": 80.0, "wins": 7, "losses": 1, "retreats": 2, "ip": 88.0, "stars": 3, "xp": 1250, "score": 950}, true, true)
	await get_tree().create_timer(2.6).timeout
	await _shot("10_endpanel_win")
	b.end_panel.show_summary({"won": false, "reason": "ROUNDS", "phase": 5, "dominance": 40.0, "wins": 3, "losses": 5, "retreats": 2, "ip": 41.0, "stars": 0, "xp": 300, "score": 300}, false, false)
	await get_tree().create_timer(1.6).timeout
	await _shot("11_endpanel_lose")
	b.end_panel.visible = false
	b._open_pause()
	await get_tree().create_timer(0.4).timeout
	await _shot("12_pause")
	b.queue_free()
	await get_tree().process_frame
	var m := MainMenu.new()
	add_child(m)
	await get_tree().create_timer(0.4).timeout
	m._open_options()
	await get_tree().create_timer(0.4).timeout
	await _shot("13_options")
	m.queue_free()
	await get_tree().process_frame
	var cm := CampaignMap.new()
	cm.auto_brief = 5
	add_child(cm)
	await get_tree().create_timer(0.8).timeout
	await _shot("14_briefing")
	cm.queue_free()
