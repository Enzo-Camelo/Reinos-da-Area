## GameState.gd (autoload)
## Progresso persistente: arquétipo, fases desbloqueadas, estrelas, recursos, volumes.
extends Node

const SAVE_PATH := "user://reinos_save.cfg"
## Debug: libera todas as fases no mapa de campanha.
const DEBUG_UNLOCK_ALL := false
const START_RESOURCES := 3

var archetype      : String = ""      # "ESTRATEGISTA" | "ENGENHEIRO" | "GUERREIRO" | ""
var unlocked_phase : int    = 1
var stars          : Dictionary = {}  # fase(int) -> estrelas(int)
var best_ip        : Dictionary = {}  # fase(int) -> IP(float)
var resources      : int    = START_RESOURCES
var xp             : int    = 0
var music_volume   : float  = 0.8
var sfx_volume     : float  = 1.0
var tutorial_done  : bool   = false
var fullscreen     : bool   = true
var reduce_motion  : bool   = false
## Cenas da história já vistas: "prologue", "chapter_0" .. "chapter_4".
var story_seen     : Array  = []

func _ready() -> void:
	load_game()

func is_unlocked(phase: int) -> bool:
	return DEBUG_UNLOCK_ALL or (phase <= unlocked_phase and missing_stars(phase) == 0)

func total_stars() -> int:
	var total := 0
	for v in stars.values():
		total += int(v)
	return total

## Quantas estrelas faltam para entrar no terreno dessa fase.
func missing_stars(phase: int) -> int:
	return maxi(0, CampaignData.stars_required(phase) - total_stars())

## Fase mais avançada que pode ser jogada agora.
func latest_playable_phase() -> int:
	var p := clampi(unlocked_phase, 1, CampaignData.TOTAL_PHASES)
	while p > 1 and not is_unlocked(p):
		p -= 1
	return p

## Texto explicando a trava de estrelas que segura o avanço ("" quando não há trava).
func star_gate_text() -> String:
	var missing := missing_stars(unlocked_phase)
	if missing == 0 or DEBUG_UNLOCK_ALL:
		return ""
	var cfg := CampaignData.get_phase(unlocked_phase)
	return "Faltam %d estrela(s) para entrar em %s (%d de %d). Repita fases para melhorar medalhas." % [
		missing, cfg["scenario_name"], total_stars(), CampaignData.stars_required(unlocked_phase)]

func get_stars(phase: int) -> int:
	return int(stars.get(phase, 0))

func get_best_ip(phase: int) -> float:
	return float(best_ip.get(phase, 0.0))

func has_seen(story_key: String) -> bool:
	return story_seen.has(story_key)

func mark_seen(story_key: String) -> void:
	if not has_seen(story_key):
		story_seen.append(story_key)
		save_game()

## Registra o resultado de uma fase concluída. Retorna os RE ganhos: 1 por medalha nova.
func record_phase(phase: int, won: bool, star_count: int, ip: float, xp_gain: int) -> int:
	xp += xp_gain
	var gained := 0
	if won:
		gained = maxi(0, star_count - get_stars(phase))
		resources += gained
		stars[phase] = maxi(get_stars(phase), star_count)
		best_ip[phase] = maxf(get_best_ip(phase), ip)
		if phase >= unlocked_phase:
			unlocked_phase = mini(phase + 1, 20)
	save_game()
	return gained

func reset_progress() -> void:
	archetype = ""
	unlocked_phase = 1
	stars = {}
	best_ip = {}
	resources = START_RESOURCES
	xp = 0
	tutorial_done = false
	story_seen = []
	save_game()

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "archetype", archetype)
	cfg.set_value("player", "unlocked_phase", unlocked_phase)
	cfg.set_value("player", "stars", stars)
	cfg.set_value("player", "best_ip", best_ip)
	cfg.set_value("player", "resources", resources)
	cfg.set_value("player", "xp", xp)
	cfg.set_value("player", "tutorial_done", tutorial_done)
	cfg.set_value("player", "story_seen", story_seen)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "reduce_motion", reduce_motion)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	archetype      = str(cfg.get_value("player", "archetype", ""))
	unlocked_phase = int(cfg.get_value("player", "unlocked_phase", 1))
	stars          = cfg.get_value("player", "stars", {})
	best_ip        = cfg.get_value("player", "best_ip", {})
	resources      = int(cfg.get_value("player", "resources", START_RESOURCES))
	xp             = int(cfg.get_value("player", "xp", 0))
	tutorial_done  = bool(cfg.get_value("player", "tutorial_done", false))
	story_seen     = cfg.get_value("player", "story_seen", [])
	music_volume   = float(cfg.get_value("audio", "music", 0.8))
	sfx_volume     = float(cfg.get_value("audio", "sfx", 1.0))
	fullscreen     = bool(cfg.get_value("display", "fullscreen", true))
	reduce_motion  = bool(cfg.get_value("display", "reduce_motion", false))
