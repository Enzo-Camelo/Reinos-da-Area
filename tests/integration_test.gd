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

## Treino: não vale nada, não gasta RE e depois dele começa a rodada 1.
func _test_training() -> void:
	var gs = get_tree().root.get_node("GameState")
	# [fase, tutorial já feito, tipo esperado]
	for case in [[1, false, "BASICS"], [5, true, "TERRAIN"], [9, true, "TERRAIN"], [13, true, "TERRAIN"], [17, true, "TERRAIN"]]:
		for attempt in 6:
			gs.archetype = "GUERREIRO"
			gs.resources = 3
			gs.tutorial_done = case[1]
			gs.story_seen = []
			var b := BattleScreen.new()
			b.setup(case[0])
			add_child(b)
			await get_tree().create_timer(0.7).timeout
			var gm: GameManager = b.game_manager
			check(b._training_kind == case[2] and gm.training, "fase %d: treino %s (%s)" % [case[0], case[2], b._training_kind])
			check(gm.current_round == 0 and not gm.timer_active, "fase %d: treino sem rodada e sem relógio" % case[0])
			check(not gm.try_activate_skill() and gm.resources == 3, "fase %d: treino não gasta RE" % case[0])
			if case[2] == "TERRAIN":
				var atk := float(gm.terrain["atk"])
				var def := float(gm.terrain["def"])
				check((gm.enemy_area < gm.player_area) == (atk < def),
						"fase %d: no treino o tamanho engana (J %s, I %s, ×%s/×%s)" % [case[0], gm.player_area, gm.enemy_area, atk, def])
			var area := gm.carry_area
			var player := gm.player_area
			gm.resolve_action(GameManager.Action.ATTACK)
			check(gm.ip_values.is_empty() and gm.wins + gm.losses + gm.retreats == 0, "fase %d: treino fora das estatísticas" % case[0])
			check(is_equal_approx(gm.dominance, 0.0) and is_equal_approx(gm.carry_area, area) and gm.player_score == 0,
					"fase %d: treino não muda Domínio, área nem pontos" % case[0])
			check(is_equal_approx(float(gm.last_info["new_area"]), player), "fase %d: treino mantém a área" % case[0])
			gm.finish_round()
			await get_tree().create_timer(0.7).timeout
			check(not gm.training and gm.current_round == 1 and gm.timer_active, "fase %d: depois do treino vale a rodada 1" % case[0])
			check(b._training_kind == "" and b.timer_medallion.visible, "fase %d: relógio de volta" % case[0])
			if case[2] == "BASICS":
				check(gs.tutorial_done, "fase 1: tutorial marcado após o treino")
			else:
				check(gs.has_seen("terrain_lesson"), "fase %d: lição de terreno marcada" % case[0])
			b.queue_free()
			await get_tree().process_frame

	# pular o treino também leva à rodada 1, e a lição não se repete
	gs.tutorial_done = true
	gs.story_seen = []
	var b2 := BattleScreen.new()
	b2.setup(5)
	add_child(b2)
	await get_tree().create_timer(0.7).timeout
	b2._tutorial_open = false
	b2._skip_training()
	await get_tree().create_timer(0.7).timeout
	check(b2.game_manager.current_round == 1 and not b2.game_manager.training, "pular o treino começa a rodada 1")
	b2.queue_free()
	await get_tree().process_frame
	var b3 := BattleScreen.new()
	b3.setup(6)
	add_child(b3)
	await get_tree().create_timer(0.7).timeout
	check(b3._training_kind == "" and b3.game_manager.current_round == 1, "lição de terreno aparece uma vez só")
	b3.queue_free()
	await get_tree().process_frame

func _run() -> void:
	_backup_save()
	print("Treino e lição de terreno")
	await _test_training()
	get_tree().root.get_node("GameState").story_seen = ["terrain_lesson"]
	print("Fluxo de fases")
	for n in [1, 5, 9, 13, 17, 20]:
		var b := await _play_phase(n, "GUERREIRO", GameManager.Action.RETREAT)
		check(b.end_panel.visible, "fase %d: painel de fim de fase visível" % n)
		var gm: GameManager = b.game_manager
		check(gm.ended, "fase %d: terminou" % n)
		check(gm.retreats == 10 or gm.ended, "fase %d: 10 recuos" % n)
		check(is_equal_approx(gm.dominance, 0.0), "fase %d: recuos não passam de 0%% de domínio" % n)
		check(AccuracyTracker.stars(gm.dominance) == 0, "fase %d: sem estrelas" % n)
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

	print("Vitória, derrota e trava de estrelas")
	var gs3 = get_tree().root.get_node("GameState")
	for case in [[5, false, 0], [6, true, 1]]:
		gs3.archetype = "ENGENHEIRO"
		gs3.tutorial_done = true
		var bw := BattleScreen.new()
		bw.setup(1)
		add_child(bw)
		await get_tree().create_timer(0.7).timeout
		var gmw: GameManager = bw.game_manager
		var result := {}
		gmw.phase_ended.connect(func(s): result.merge(s))
		# vence as N primeiras rodadas; nas demais erra (derrota não tira Domínio)
		for r in 10:
			var right: String = CombatResolver.resolve(0, gmw.player_area, gmw.enemy_area, gmw.terrain, gmw.current_effects())["correct"]
			var attack: bool = (right == "ATTACK") == (r < case[0])
			gmw.resolve_action(GameManager.Action.ATTACK if attack else GameManager.Action.DEFEND)
			gmw.finish_round()
			if gmw.ended:
				break
			await get_tree().create_timer(0.7).timeout
		check(result.get("rounds", 0) == 10, "fase deve ir até a rodada 10")
		check(result.get("won") == case[1] and result.get("stars") == case[2],
				"%d vitórias: venceu=%s estrelas=%d (%s)" % [case[0], case[1], case[2], str(result)])
		bw.queue_free()
		await get_tree().process_frame

	gs3.unlocked_phase = 5
	gs3.stars = {1: 2, 2: 2, 3: 2, 4: 1}
	check(gs3.is_unlocked(4) and not gs3.is_unlocked(5), "7 estrelas não abrem o terreno II")
	check(gs3.latest_playable_phase() == 4 and gs3.star_gate_text() != "", "continua na fase 4, com aviso")
	gs3.stars = {1: 2, 2: 2, 3: 2, 4: 2}
	check(gs3.is_unlocked(5) and gs3.star_gate_text() == "", "8 estrelas abrem o terreno II")
	gs3.unlocked_phase = 9
	gs3.stars = {1: 3, 2: 3, 3: 3, 4: 3, 5: 1, 6: 1, 7: 1}
	check(not gs3.is_unlocked(9), "15 estrelas não abrem o terreno III")
	gs3.stars[8] = 1
	check(gs3.is_unlocked(9), "16 estrelas abrem o terreno III")

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
