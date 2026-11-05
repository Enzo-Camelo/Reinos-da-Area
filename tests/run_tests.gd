## Testes headless:
##   Godot_console.exe --headless --path . --script res://tests/run_tests.gd
## (abra o projeto no editor uma vez, ou rode com --import, para registrar os class_name)
extends SceneTree

var _fail := 0
var _ok := 0

func check(cond: bool, msg: String) -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
		print("  FALHOU: ", msg)

func _init() -> void:
	test_combat()
	test_combat_properties()
	test_accuracy()
	test_units()
	test_campaign()
	test_generator()
	print("\n== %d ok, %d falhas ==" % [_ok, _fail])
	quit(1 if _fail > 0 else 0)

func test_combat() -> void:
	print("CombatResolver")
	var plain := {"atk": 1.0, "def": 1.0}
	var r := CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 40.0, 30.0, plain, {})
	check(r["result"] == "WIN" and is_equal_approx(r["dom_delta"], 10.0) and is_equal_approx(r["area_pct"], 0.10), "atacar maior vence +10%/+10%")
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 30.0, 40.0, plain, {})
	check(r["result"] == "LOSE" and is_equal_approx(r["area_pct"], -0.20), "atacar menor perde 20%")
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 30.0, 40.0, plain, {"consolidacao": true})
	check(is_equal_approx(r["area_pct"], -0.15), "consolidação reduz a 15%")
	r = CombatResolver.resolve(CombatResolver.ACTION_DEFEND, 30.0, 40.0, plain, {})
	check(r["result"] == "WIN" and is_equal_approx(r["area_pct"], 0.05), "defender inimigo maior vence +5% área")
	r = CombatResolver.resolve(CombatResolver.ACTION_DEFEND, 40.0, 30.0, plain, {})
	check(r["result"] == "LOSE" and is_equal_approx(r["area_pct"], -0.10), "defender errado perde 10%")
	r = CombatResolver.resolve(CombatResolver.ACTION_RETREAT, 40.0, 30.0, plain, {})
	check(r["result"] == "DRAW" and is_equal_approx(r["dom_delta"], -3.0) and is_equal_approx(r["area_pct"], 0.0), "recuar -3% domínio, sem perda de área")
	var serra := {"atk": 0.85, "def": 1.25}
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 40.0, 34.0, serra, {})
	check(r["result"] == "LOSE", "serra: inimigo menor mas defensor x1.25 vence")
	check(is_equal_approx(r["force_enemy"], 42.5) and is_equal_approx(r["force_player"], 34.0), "serra: forças 34.0 vs 42.5")
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 40.0, 45.0, plain, {"muralha": true})
	check(r["result"] == "WIN", "muralha 40*1.25=50 > 45")
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 40.0, 45.0, plain, {"embalo": 0.15})
	check(r["result"] == "WIN", "embalo 40*1.15=46 > 45")
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 40.0, 30.0, plain, {"golpe": true})
	check(is_equal_approx(r["dom_delta"], 20.0) and is_equal_approx(r["area_pct"], 0.20), "golpe dobra ganho")
	r = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 30.0, 40.0, plain, {"golpe": true})
	check(is_equal_approx(r["area_pct"], -0.40), "golpe dobra perda")
	# Vale: defensor x1,25. 40 vs 36 -> atacar: 40 vs 45 perde; defender é a decisão certa
	var vale := {"atk": 1.0, "def": 1.25}
	check(CombatResolver.resolve(CombatResolver.ACTION_ATTACK, 40.0, 36.0, vale, {})["result"] == "LOSE", "vale: inimigo levemente menor vence o ataque")
	check(CombatResolver.resolve(CombatResolver.ACTION_DEFEND, 40.0, 36.0, vale, {})["result"] == "WIN", "vale: defender é a decisão certa")
	check(not CombatResolver.is_unambiguous(40.0, 40.0, 1.0, 1.0), "empate é ambíguo")
	check(CombatResolver.is_unambiguous(40.0, 30.0, 1.0, 1.0), "40x30 inequívoco")

func test_combat_properties() -> void:
	print("Combate: exatamente uma decisão certa e equilíbrio por fase")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var terrains := [[1.0, 1.0], [1.0, 1.25], [0.85, 1.25], [1.10, 0.90]]
	for i in 400:
		var t: Array = terrains[rng.randi() % 4]
		var terr := {"atk": t[0], "def": t[1]}
		var pj := rng.randf_range(10.0, 100.0)
		var ei := rng.randf_range(10.0, 130.0)
		if not CombatResolver.is_unambiguous(pj, ei, t[0], t[1]):
			continue
		var a: String = CombatResolver.resolve(CombatResolver.ACTION_ATTACK, pj, ei, terr, {})["result"]
		var d: String = CombatResolver.resolve(CombatResolver.ACTION_DEFEND, pj, ei, terr, {})["result"]
		check((a == "WIN") != (d == "WIN"), "atacar e defender são complementares (%.1f vs %.1f, %s)" % [pj, ei, str(t)])
	# Mesma fórmula do BattleScreen para o tamanho do inimigo: nenhuma fase pode ter decisão degenerada
	for n in range(1, 21):
		var cfg := CampaignData.get_phase(n)
		var attack_correct := 0
		var total := 300
		for i in total:
			var atk: float = cfg["terrain_atk"]
			var def: float = cfg["terrain_def"]
			if cfg["mixed_terrain"]:
				var mt: Array = CampaignData.MIXED_TERRAINS[rng.randi() % 4]
				atk = mt[0]
				def = mt[1]
			var d := rng.randf_range(cfg["diff_min"], cfg["diff_max"])
			var dir := 1.0 if rng.randi() % 2 == 0 else -1.0
			var pj := 40.0
			var ei := pj * atk / (def * (1.0 + dir * d))
			var r := CombatResolver.resolve(CombatResolver.ACTION_ATTACK, pj, ei, {"atk": atk, "def": def}, {})
			if r["correct"] == "ATTACK":
				attack_correct += 1
		var share := float(attack_correct) / total
		check(share > 0.3 and share < 0.7, "fase %d: Atacar certo em %.0f%% das rodadas (esperado 30-70%%)" % [n, share * 100.0])

func test_accuracy() -> void:
	print("AccuracyTracker")
	check(AccuracyTracker.round_ip({"result": "WIN", "margin": 0.2, "action": 0}) == 100.0, "vitória = 100")
	check(AccuracyTracker.round_ip({"result": "LOSE", "margin": 0.03, "action": 0}) == 50.0, "erro com margem <5% = 50")
	check(AccuracyTracker.round_ip({"result": "LOSE", "margin": 0.10, "action": 0}) == 25.0, "erro margem <15% = 25")
	check(AccuracyTracker.round_ip({"result": "LOSE", "margin": 0.30, "action": 1}) == 0.0, "erro óbvio = 0")
	check(AccuracyTracker.round_ip({"result": "DRAW", "margin": 0.03, "action": 2}) == 70.0, "recuo margem pequena = 70")
	check(AccuracyTracker.round_ip({"result": "DRAW", "margin": 0.30, "action": 2}) == 40.0, "recuo margem grande = 40")
	check(AccuracyTracker.sound_for(95.0) == "precise" and AccuracyTracker.sound_for(60.0) == "" and AccuracyTracker.sound_for(20.0) == "imprecise", "faixas de som")
	check(AccuracyTracker.stars(60.0, 0, 90.0, 0) == 0, "sem 70% = 0 estrelas")
	check(AccuracyTracker.stars(80.0, 9, 70.0, 2) == 1, "bronze")
	check(AccuracyTracker.stars(80.0, 6, 70.0, 2) == 2, "prata (70% até rodada 6)")
	check(AccuracyTracker.stars(80.0, 9, 90.0, 0) == 3, "ouro (IP>=85, sem derrota)")
	check(AccuracyTracker.stars(80.0, 6, 90.0, 1) == 2, "uma derrota impede ouro")

func test_units() -> void:
	print("UnitFormatter")
	check(UnitFormatter.fmt_number(2500000.0, 0) == "2.500.000", "milhar pt-BR")
	check(UnitFormatter.fmt_number(2.5, 1) == "2,5", "decimal pt-BR")
	var p1 := CampaignData.get_phase(1)
	check(UnitFormatter.format_area(15.0, p1)["main"] == "15 m²", "planície em m²")
	var p5 := CampaignData.get_phase(5)
	check(str(UnitFormatter.format_area(20.0, p5)["main"]).ends_with(" m²"), "vale abaixo de 10.000 m² fica em m²")
	check(str(UnitFormatter.format_area(30.0, p5)["main"]).ends_with(" km²"), "vale acima de 10.000 m² vira km²")
	var p9 := CampaignData.get_phase(9)
	check(UnitFormatter.format_area(50.0, p9)["main"] == "2,5 km²" and UnitFormatter.format_area(50.0, p9)["sub"] == "= 2.500.000 m²", "serra: 2,5 km² = 2.500.000 m²")
	var p13 := CampaignData.get_phase(13)
	check(UnitFormatter.format_area(45.0, p13)["main"] == "45 ha", "arquipélago em hectares")

func test_campaign() -> void:
	print("CampaignData")
	for n in range(1, 21):
		var c := CampaignData.get_phase(n)
		check(c["diff_min"] < c["diff_max"], "fase %d diff_min<diff_max" % n)
	check(CampaignData.get_phase(4)["scenario_idx"] == 0 and CampaignData.get_phase(5)["scenario_idx"] == 1, "limite cenário 1/2")
	check(CampaignData.get_phase(14)["time"] == 45.0 and CampaignData.get_phase(18)["time"] == 30.0, "tempos 45s e 30s")
	check(CampaignData.get_phase(20)["sudden_death"] and not CampaignData.get_phase(19)["sudden_death"], "morte súbita só na 20")
	check(CampaignData.get_phase(9)["cartographer"] == "SILENT" and CampaignData.get_phase(10)["cartographer"] == "ABSENT", "cartógrafa some na fase 10")

func _connected(c: Dictionary) -> bool:
	if c.is_empty():
		return false
	var start: Vector2i = c.keys()[0]
	var seen := {start: true}
	var stack: Array = [start]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in TerritoryGenerator.DIRECTIONS:
			var nb: Vector2i = p + d
			if c.has(nb) and not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	return seen.size() == c.size()

func _count_holes(c: Dictionary) -> int:
	var mn := Vector2i(1000, 1000)
	var mx := Vector2i(-1, -1)
	for k in c.keys():
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
		mx = Vector2i(maxi(mx.x, k.x), maxi(mx.y, k.y))
	var seen := {}
	var stack: Array = []
	for x in range(mn.x - 1, mx.x + 2):
		for y in range(mn.y - 1, mx.y + 2):
			if x == mn.x - 1 or x == mx.x + 1 or y == mn.y - 1 or y == mx.y + 1:
				stack.append(Vector2i(x, y))
				seen[Vector2i(x, y)] = true
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in TerritoryGenerator.DIRECTIONS:
			var nb: Vector2i = p + d
			if nb.x < mn.x - 1 or nb.x > mx.x + 1 or nb.y < mn.y - 1 or nb.y > mx.y + 1:
				continue
			if not c.has(nb) and not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	var holes := 0
	for x in range(mn.x, mx.x + 1):
		for y in range(mn.y, mx.y + 1):
			if not c.has(Vector2i(x, y)) and not seen.has(Vector2i(x, y)):
				holes += 1
	return holes

func test_generator() -> void:
	print("TerritoryGenerator")
	var gen := TerritoryGenerator.new()
	gen.grid_cols = 32
	gen.grid_rows = 13
	var shapes := {"RECT": 16.0, "HALF_DIAGONAL": 25.0, "TRAPEZOID": 35.0, "COMPLEX": 45.0, "HOLLOW": 60.0}
	for shape in shapes.keys():
		var target: float = shapes[shape]
		var max_err := 0.0
		var bad_region := 0
		var disconnected := 0
		var halves := 0
		var holes_total := 0
		for i in 60:
			for side in 2:
				var ox := 16 * side
				var c := gen.generate(target, ox, 16, 1, shape)
				var a := TerritoryGenerator.area_of(c)
				max_err = maxf(max_err, absf(a - target))
				for k in c.keys():
					if k.x < ox + 1 or k.x >= ox + 15 or k.y < 1 or k.y >= 12:
						bad_region += 1
					if int(c[k]) != 0:
						halves += 1
				if not _connected(c):
					disconnected += 1
				holes_total += _count_holes(c)
		check(bad_region == 0, "%s: células fora da região (%d)" % [shape, bad_region])
		check(disconnected == 0, "%s: %d territórios desconexos" % [shape, disconnected])
		print("  %-14s erro máx de área: %.1f | meios-blocos: %d | buracos: %d" % [shape, max_err, halves, holes_total])
		check(max_err <= 4.0, "%s: erro de área alto (%.1f)" % [shape, max_err])
		if shape == "HOLLOW":
			check(holes_total > 0, "HOLLOW deve gerar buracos")
		if shape == "HALF_DIAGONAL" or shape == "TRAPEZOID":
			check(halves > 0, "%s deve gerar meios-blocos" % shape)
		if shape == "RECT":
			check(halves == 0 and holes_total == 0, "RECT sem meios-blocos nem buracos")
	var big := gen.generate(140.0, 0, 16, 1, "COMPLEX")
	check(TerritoryGenerator.area_of(big) >= 120.0, "área grande (140) é atingida (>=120): %.1f" % TerritoryGenerator.area_of(big))
