## AudioManager.gd
## Autoload global para tocar efeitos sonoros e músicas sem interrupções.
## Cria os buses "Music" e "SFX" em tempo de execução; os volumes ficam salvos no GameState.

extends Node

# Dicionário centralizando os caminhos dos arquivos de áudio.
var _sounds := {
	# Músicas
	"bg_music": "res://assets/audios/background.mp3",
	"phase_win": "res://assets/audios/resumo_vitoria.mp3",
	"phase_lose": "res://assets/audios/resumo_derrota.mp3",

	# Interface
	"ui_hover": "res://assets/audios/hover.mp3",
	"ui_click": "res://assets/audios/click.mp3",
	"page_turn": "res://assets/audios/pagina.wav",

	# Ações da rodada
	"map_unroll": "res://assets/audios/inicio_da_rodada.mp3",
	"action_attack": "res://assets/audios/atacar.mp3",
	"action_defend": "res://assets/audios/defender.mp3",
	"action_retreat": "res://assets/audios/recuar.mp3",
	"timer_tick": "res://assets/audios/tempo_esgotando.mp3",

	# Resultados
	"result_win": "res://assets/audios/brilho_da_vitoria.mp3",
	"result_lose": "res://assets/audios/derrota.mp3",
	"result_draw": "res://assets/audios/vento.mp3",

	# Feedback de precisão das estimativas (sem texto de punição)
	"bell_precise": "res://assets/audios/sino_preciso.wav",
	"bell_imprecise": "res://assets/audios/sino_impreciso.wav",
}

var _loaded_streams := {}
var bgm_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8
const BGM_BASE_DB := -15.0

func _ready() -> void:
	for key in _sounds.keys():
		var path = _sounds[key]
		if ResourceLoader.exists(path):
			_loaded_streams[key] = load(path)
		else:
			push_warning("AudioManager: Áudio não encontrado no caminho: " + path)

	_ensure_bus("Music")
	_ensure_bus("SFX")

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	bgm_player.volume_db = BGM_BASE_DB
	add_child(bgm_player)

	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_pool.append(p)

	var gs = get_node_or_null("/root/GameState")
	if gs:
		set_music_volume(gs.music_volume)
		set_sfx_volume(gs.sfx_volume)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func _set_bus_linear(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	v = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))

func set_music_volume(v: float) -> void:
	_set_bus_linear("Music", v)

func set_sfx_volume(v: float) -> void:
	_set_bus_linear("SFX", v)

# Toca um efeito sonoro na primeira "fenda" livre da pool
func play_sfx(sound_name: String, pitch_randomness: float = 0.0) -> void:
	if not _loaded_streams.has(sound_name):
		return
	for p in sfx_pool:
		if not p.playing:
			p.stream = _loaded_streams[sound_name]
			if pitch_randomness > 0.0:
				p.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
			else:
				p.pitch_scale = 1.0
			p.play()
			return

# Toca uma música de fundo (interrompendo a anterior)
func play_music(sound_name: String) -> void:
	if not _loaded_streams.has(sound_name):
		return
	if bgm_player.stream == _loaded_streams[sound_name] and bgm_player.playing:
		return
	bgm_player.stream = _loaded_streams[sound_name]
	bgm_player.play()

func stop_music() -> void:
	bgm_player.stop()

func set_bgm_volume(volume_db: float) -> void:
	if bgm_player:
		bgm_player.volume_db = volume_db
