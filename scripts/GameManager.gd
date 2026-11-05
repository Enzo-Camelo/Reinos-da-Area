## GameManager.gd
## Controlador de uma fase (10 rodadas): estado, timer, combate, arquétipo, pontuação e fim de fase.
## Lógica pura, sem visual. A tela de batalha (BattleScreen) escuta os sinais.

extends Node
class_name GameManager

# ─────────────────────────────────────────────
#  SINAIS
# ─────────────────────────────────────────────
signal phase_changed(new_phase: String)          # ANALYSIS | DECISION | RESULT | RESTART
signal round_started(round_number: int)
signal round_resolved(info: Dictionary)
signal phase_ended(summary: Dictionary)
signal score_updated(score: int, streak: int)
signal timer_tick(seconds_left: float)
signal skill_activated(skill_id: String)
signal skill_denied()
signal resources_changed(value: int)

enum Phase { ANALYSIS, DECISION, RESULT, RESTART }
enum Action { ATTACK, DEFEND, RETREAT }
enum Result { WIN, LOSE, DRAW }

# ─────────────────────────────────────────────
#  CONSTANTES
# ─────────────────────────────────────────────
const TOTAL_ROUNDS      := 10
const MIN_AREA          := 4.0     # rede de segurança: área abaixo disso encerra a fase
const MAX_AREA          := 100.0
const SCORE_WIN_BASE    := 100
const SCORE_STREAK_MULT := 50
const SCORE_SPEED_BONUS := 200
const ANALYSIS_SECONDS  := 5.0

# ─────────────────────────────────────────────
#  ESTADO DA FASE
# ─────────────────────────────────────────────
var cfg              : Dictionary = {}
var archetype        : String = ""
var current_phase    : Phase  = Phase.ANALYSIS
var current_round    : int    = 0
var player_score     : int    = 0
var win_streak       : int    = 0
var dominance        : float  = 0.0
var first_reach_round: int    = 0
var wins             : int    = 0
var losses           : int    = 0
var retreats         : int    = 0
var ip_values        : Array  = []
var resources        : int    = 0
var skill_used_phase : bool   = false
var wall_active      : bool   = false
var strike_active    : bool   = false
var ended            : bool   = false
var carry_area       : float  = 0.0   # área do jogador que segue para a próxima rodada

var player_area      : float  = 0.0
var enemy_area       : float  = 0.0
var terrain          : Dictionary = {"atk": 1.0, "def": 1.0, "name": "Plano"}
var round_time_left  : float  = 60.0
var round_start_time : float  = 0.0
var timer_active     : bool   = false
var timer_paused     : bool   = false
var last_info        : Dictionary = {}

var _countdown_timer : Timer

func _ready() -> void:
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 0.1
	_countdown_timer.autostart = false
	_countdown_timer.timeout.connect(_on_timer_tick)
	add_child(_countdown_timer)

func _on_timer_tick() -> void:
	if not timer_active or timer_paused:
		return
	round_time_left -= 0.1
	timer_tick.emit(round_time_left)
	if round_time_left <= 0.0:
		timer_active = false
		_countdown_timer.stop()
		resolve_action(Action.RETREAT, true)   # tempo esgotado = recuo forçado

func set_timer_paused(p: bool) -> void:
	timer_paused = p

# ─────────────────────────────────────────────
#  CICLO DA FASE
# ─────────────────────────────────────────────
func start_phase(phase_cfg: Dictionary, arch: String, available_resources: int) -> void:
	cfg = phase_cfg
	archetype = arch
	resources = available_resources
	current_round = 0
	player_score = 0
	win_streak = 0
	dominance = 0.0
	first_reach_round = 0
	wins = 0
	losses = 0
	retreats = 0
	ip_values = []
	skill_used_phase = false
	wall_active = false
	strike_active = false
	ended = false
	timer_active = false
	timer_paused = false
	carry_area = float(randi_range(int(cfg["area_min"]), int(cfg["area_max"])))
	resources_changed.emit(resources)

## Terreno da rodada (no Abismo é sorteado entre os 4 modificadores).
func pick_terrain() -> Dictionary:
	if cfg.get("mixed_terrain", false):
		var t: Array = CampaignData.MIXED_TERRAINS[randi() % CampaignData.MIXED_TERRAINS.size()]
		return {"atk": t[0], "def": t[1], "name": t[2]}
	return {"atk": cfg["terrain_atk"], "def": cfg["terrain_def"], "name": cfg["terrain_name"]}

func start_new_round(p_area: float, e_area: float, round_terrain: Dictionary) -> void:
	current_round += 1
	player_area = p_area
	enemy_area = e_area
	terrain = round_terrain
	wall_active = false
	strike_active = false
	current_phase = Phase.ANALYSIS
	round_time_left = float(cfg["time"])
	round_start_time = Time.get_ticks_msec() / 1000.0
	timer_active = true
	_countdown_timer.start()
	phase_changed.emit("ANALYSIS")
	round_started.emit(current_round)

func enter_decision_phase() -> void:
	current_phase = Phase.DECISION
	phase_changed.emit("DECISION")

## Efeitos (passivas + ativas) válidos para a rodada corrente.
func current_effects() -> Dictionary:
	return {
		"embalo": embalo_bonus(),
		"muralha": wall_active,
		"golpe": strike_active,
		"consolidacao": archetype == "ENGENHEIRO",
	}

func embalo_bonus() -> float:
	if archetype != "GUERREIRO":
		return 0.0
	return minf(win_streak * 0.05, 0.15)

## Anel extra de grid de referência (Olho de Águia: +2 células).
func extra_reference_ring() -> int:
	return 2 if archetype == "ESTRATEGISTA" else 0

func skill_cost() -> int:
	return int(ArchetypeData.get_data(archetype).get("cost", 1))

func can_use_skill() -> bool:
	return archetype != "" and not skill_used_phase and not ended \
		and (current_phase == Phase.ANALYSIS or current_phase == Phase.DECISION)

## Tenta ativar a habilidade ativa do arquétipo. Retorna false (e emite skill_denied) sem recursos.
func try_activate_skill() -> bool:
	if not can_use_skill():
		return false
	if resources < skill_cost():
		skill_denied.emit()
		return false
	resources -= skill_cost()
	skill_used_phase = true
	resources_changed.emit(resources)
	var id := ""
	if archetype == "ESTRATEGISTA":
		id = "ANALISE_CAMPO"
	elif archetype == "ENGENHEIRO":
		id = "MURALHA"
		wall_active = true
	else:
		id = "GOLPE"
		strike_active = true
	skill_activated.emit(id)
	return true

## Resolve a ação do jogador. forced_timeout: tempo esgotado (recuo sem bônus).
func resolve_action(action: Action, forced_timeout: bool = false) -> void:
	if ended or current_phase == Phase.RESULT:
		return
	timer_active = false
	_countdown_timer.stop()
	current_phase = Phase.RESULT

	var info := CombatResolver.resolve(int(action), player_area, enemy_area, terrain, current_effects())
	info["timeout"] = forced_timeout
	info["round"] = current_round
	var ip := AccuracyTracker.round_ip(info)
	info["ip"] = ip
	ip_values.append(ip)

	var time_taken := (Time.get_ticks_msec() / 1000.0) - round_start_time
	_apply_result(info, time_taken, forced_timeout)
	last_info = info
	round_resolved.emit(info)
	phase_changed.emit("RESULT")

func _apply_result(info: Dictionary, time_taken: float, timeout: bool) -> void:
	var result: String = info["result"]
	if result == "WIN":
		wins += 1
		win_streak += 1
		var speed_bonus := 0
		if not timeout:
			var ratio := clampf(1.0 - (time_taken / float(cfg["time"])), 0.0, 1.0)
			speed_bonus = int(ratio * SCORE_SPEED_BONUS)
		player_score += SCORE_WIN_BASE + (win_streak - 1) * SCORE_STREAK_MULT + speed_bonus
	elif result == "LOSE":
		losses += 1
		win_streak = 0
		player_score = maxi(0, player_score - 50)
	else:
		retreats += 1
		win_streak = 0

	dominance = clampf(dominance + float(info["dom_delta"]), 0.0, 100.0)
	if first_reach_round == 0 and dominance >= AccuracyTracker.BRONZE_MIN_DOM:
		first_reach_round = current_round
	carry_area = clampf(player_area * (1.0 + float(info["area_pct"])), 0.0, MAX_AREA)
	info["new_area"] = carry_area
	score_updated.emit(player_score, win_streak)

## Chamado depois que o jogador confirma o resultado: encerra a fase ou prepara a próxima rodada.
func finish_round() -> void:
	var reason := ""
	if carry_area < MIN_AREA:
		reason = "AREA"
	elif cfg.get("sudden_death", false) and last_info.get("result", "") == "LOSE":
		reason = "SUDDEN_DEATH"
	elif current_round >= TOTAL_ROUNDS:
		reason = "ROUNDS"
	if reason != "":
		_end_phase(reason)
	else:
		current_phase = Phase.RESTART
		phase_changed.emit("RESTART")

func _end_phase(reason: String) -> void:
	ended = true
	var won := reason == "ROUNDS" and dominance >= AccuracyTracker.BRONZE_MIN_DOM
	var ip := AccuracyTracker.phase_ip(ip_values)
	var star_count := 0
	if won:
		star_count = AccuracyTracker.stars(dominance, first_reach_round, ip, losses)
	var xp := player_score + star_count * 100
	phase_ended.emit({
		"won": won, "reason": reason, "phase": cfg["phase"],
		"dominance": dominance, "wins": wins, "losses": losses, "retreats": retreats,
		"ip": ip, "stars": star_count, "xp": xp, "score": player_score,
		"rounds": current_round, "resources_gain": 1 if won else 0,
	})
