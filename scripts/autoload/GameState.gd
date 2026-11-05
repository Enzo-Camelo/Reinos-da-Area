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

func _ready() -> void:
	load_game()

func is_unlocked(phase: int) -> bool:
	return DEBUG_UNLOCK_ALL or phase <= unlocked_phase

func get_stars(phase: int) -> int:
	return int(stars.get(phase, 0))

func get_best_ip(phase: int) -> float:
	return float(best_ip.get(phase, 0.0))

## Registra o resultado de uma fase concluída.
func record_phase(phase: int, won: bool, star_count: int, ip: float, xp_gain: int) -> void:
	xp += xp_gain
	if won:
		stars[phase] = maxi(get_stars(phase), star_count)
		best_ip[phase] = maxf(get_best_ip(phase), ip)
		if phase >= unlocked_phase:
			unlocked_phase = mini(phase + 1, 20)
			resources += 1   # +1 RE por fase nova concluída
	save_game()

func reset_progress() -> void:
	archetype = ""
	unlocked_phase = 1
	stars = {}
	best_ip = {}
	resources = START_RESOURCES
	xp = 0
	tutorial_done = false
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
	music_volume   = float(cfg.get_value("audio", "music", 0.8))
	sfx_volume     = float(cfg.get_value("audio", "sfx", 1.0))
	fullscreen     = bool(cfg.get_value("display", "fullscreen", true))
	reduce_motion  = bool(cfg.get_value("display", "reduce_motion", false))
