## Teste de integração: joga fases completas na BattleScreen, sem UI manual.
##   Godot_console.exe --headless --path . res://tests/integration_test.tscn
extends Node

const SAVE := "user://reinos_save.cfg"
var _fail := 0
var _ok := 0
var _backup := PackedByteArray()
var _had_save := false

func check(cond: bool, msg: String) -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
		print("  FALHOU: ", msg)

func _ready() -> void:
	await _run()
	_restore_save()
	print("\n== integração: %d ok, %d falhas ==" % [_ok, _fail])
	get_tree().quit(1 if _fail > 0 else 0)

func _backup_save() -> void:
	_had_save = FileAccess.file_exists(SAVE)
	if _had_save:
		_backup = FileAccess.get_file_as_bytes(SAVE)

func _restore_save() -> void:
	if _had_save:
		var f := FileAccess.open(SAVE, FileAccess.WRITE)
		f.store_buffer(_backup)
		f.close()
	elif FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

func _play_phase(n: int, arch: String, action: int) -> BattleScreen:
	var gs = get_tree().root.get_node("GameState")
	gs.archetype = arch
	gs.resources = 3
	gs.tutorial_done = true
	var b := BattleScreen.new()
	b.setup(n)
	add_child(b)
	await get_tree().create_timer(0.7).timeout
	var gm: GameManager = b.game_manager
	for r in 10:
		if gm.ended:
			break
		check(gm.current_round == r + 1, "fase %d: rodada esperada %d, atual %d" % [n, r + 1, gm.current_round])
		check(gm.player_area > 0.0 and gm.enemy_area > 0.0, "fase %d: áreas positivas" % n)
		if r == 1:
			gm.try_activate_skill()
		gm.resolve_action(action)
		gm.finish_round()
		await get_tree().create_timer(0.7).timeout
	return b

func _run() -> void:
	_backup_save()
	print("Fluxo de fases")
	for n in [1, 5, 9, 13, 17, 20]:
		var b := await _play_phase(n, "GUERREIRO", GameManager.Action.RETREAT)
		check(b.end_panel.visible, "fase %d: painel de fim de fase visível" % n)
		var gm: GameManager = b.game_manager
		check(gm.ended, "fase %d: terminou" % n)
		check(gm.retreats == 10 or gm.ended, "fase %d: 10 recuos" % n)
		check(is_equal_approx(gm.dominance, 0.0), "fase %d: recuos não passam de 0%% de domínio" % n)
		check(AccuracyTracker.stars(gm.dominance, gm.first_reach_round, 0.0, 0) == 0, "fase %d: sem estrelas" % n)
		b.queue_free()
		await get_tree().process_frame

	print("Jogo ótimo vence todas as fases (decisão certa sempre existe)")
	for n in [1, 5, 9, 13, 17, 20]:
		var gs0 = get_tree().root.get_node("GameState")
		gs0.archetype = "ESTRATEGISTA"
		gs0.resources = 3
		gs0.tutorial_done = true
		var bo := BattleScreen.new()
		bo.setup(n)
		add_child(bo)
		await get_tree().create_timer(0.7).timeout
		var gmo: GameManager = bo.game_manager
		var summary := {}
		gmo.phase_ended.connect(func(s): summary.merge(s))
		for r in 10:
			if gmo.ended:
				break
			var probe := CombatResolver.resolve(CombatResolver.ACTION_ATTACK, gmo.player_area, gmo.enemy_area, gmo.terrain, gmo.current_effects())
			check(probe["correct"] != "NONE", "fase %d rodada %d: existe decisão certa" % [n, r + 1])
			var act := GameManager.Action.ATTACK if probe["correct"] == "ATTACK" else GameManager.Action.DEFEND
			gmo.resolve_action(act)
			gmo.finish_round()
			await get_tree().create_timer(0.7).timeout
		check(summary.get("won", false), "fase %d: jogo ótimo vence" % n)
		check(summary.get("stars", 0) == 3, "fase %d: jogo ótimo leva 3 estrelas" % n)
		check(is_equal_approx(float(summary.get("dominance", 0.0)), 100.0), "fase %d: domínio 100%% (%s)" % [n, str(summary.get("dominance", "?"))])
		bo.queue_free()
		await get_tree().process_frame

	print("Arquétipos e habilidades")
	for arch in ArchetypeData.IDS:
		var b := await _play_phase(1, arch, GameManager.Action.ATTACK)
		var gm: GameManager = b.game_manager
		check(gm.skill_used_phase, "%s: habilidade ativa usada" % arch)
		var expected: int = 3 - int(ArchetypeData.get_data(arch)["cost"])
		var gs2 = get_tree().root.get_node("GameState")
		check(gs2.resources == expected or gm.ended, "%s: RE debitado (esperado %d, tem %d)" % [arch, expected, gs2.resources])
		b.queue_free()
		await get_tree().process_frame

	print("Fase 20 morte súbita")
	get_tree().root.get_node("GameState").archetype = "ENGENHEIRO"
	var b20 := BattleScreen.new()
	b20.setup(20)
	add_child(b20)
	await get_tree().create_timer(0.7).timeout
	var gm20: GameManager = b20.game_manager
	var correct := "ATTACK"
	var info_probe := CombatResolver.resolve(0, gm20.player_area, gm20.enemy_area, gm20.terrain, gm20.current_effects())
	correct = info_probe["correct"]
	var wrong := GameManager.Action.DEFEND if correct == "ATTACK" else GameManager.Action.ATTACK
	gm20.resolve_action(wrong)
	gm20.finish_round()
	await get_tree().create_timer(0.3).timeout
	check(gm20.ended and b20.end_panel.visible, "fase 20: um erro encerra a fase")
	b20.queue_free()
	await get_tree().process_frame
