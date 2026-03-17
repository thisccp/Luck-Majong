## AudioManager.gd — Versão 85.0 (Playlist Contínua e Bag Shuffle)
##
## Refatoração: Playlist única, Gapless Playback (sem Tweens no BGM)
## e Memória de Estado (Resume position).

extends Node

# --- CONFIGURAÇÕES DE ÁUDIO ---
const BGM_PLAYLIST: Array[String] = [
	"res://assets/audio/bgm/bgs_house_cats.ogg",
	"res://assets/audio/bgm/bgs_forest_1.ogg",
	"res://assets/audio/bgm/bgs_forest_1_cats.ogg",
	"res://assets/audio/bgm/bgs_forest_2.ogg",
	"res://assets/audio/bgm/bgs_forest_2_cats.ogg",
	"res://assets/audio/bgm/bgs_rain_1.ogg",
	"res://assets/audio/bgm/bgs_rain_1_cats.ogg"
]

const BGM_VOLUME_DEFAULT: float = -8.0

# --- VARIÁVEIS DE SISTEMA (SFX) ---
var sfx_pool: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0
var num_sfx_players: int = 8
var ui_player: AudioStreamPlayer

# --- VARIÁVEIS DE SISTEMA (BGM) ---
var _bgm_player: AudioStreamPlayer
var _unplayed_tracks: Array[String] = []
var _last_track_path: String = ""
var _is_bgm_active: bool = false
var _saved_position: float = 0.0
var _current_track_path: String = ""

# ═══════════════════════════════════════════════════════════════
# INICIALIZAÇÃO
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	var bgm_bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"
	var sfx_bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"

	# UI SFX Setup
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = sfx_bus
	add_child(ui_player)

	# SFX Pool Setup
	for i in num_sfx_players:
		var p = AudioStreamPlayer.new()
		p.bus = sfx_bus
		add_child(p)
		sfx_pool.append(p)

	# BGM Player Setup
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = bgm_bus
	_bgm_player.name = "BGMPlayer"
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

# ═══════════════════════════════════════════════════════════════
# API DE SFX (Mantida Intacta)
# ═══════════════════════════════════════════════════════════════

func play_sfx(stream: AudioStream, pitch: float = 1.0, volume: float = 0.0) -> void:
	if not stream: return
	var p = sfx_pool[next_sfx_player]
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume
	p.play()
	next_sfx_player = (next_sfx_player + 1) % num_sfx_players

func play_ui_sfx(stream: AudioStream, pitch: float = 1.0, volume: float = 0.0) -> void:
	if not stream: return
	ui_player.stream = stream
	ui_player.pitch_scale = pitch
	ui_player.volume_db = volume
	ui_player.play()

# ═══════════════════════════════════════════════════════════════
# API DE AMBIENTE / BGM
# ═══════════════════════════════════════════════════════════════

## Inicia ou retoma a playlist global.
## Parâmetro 'level' mantido para compatibilidade, mas ignorado na nova lógica.
func update_ambient(_level: int = 0) -> void:
	if _is_bgm_active:
		return # Já está tocando
		
	_is_bgm_active = true
	
	if _current_track_path != "":
		_resume_bgm()
	else:
		_play_next_track()

## Para a reprodução e salva a posição atual.
func stop_ambient(_with_fade: bool = false) -> void:
	_is_bgm_active = false
	if _bgm_player.playing:
		_saved_position = _bgm_player.get_playback_position()
		_current_track_path = _bgm_player.stream.resource_path
		_bgm_player.stop()

# ═══════════════════════════════════════════════════════════════
# LÓGICA INTERNA DE BGM
# ═══════════════════════════════════════════════════════════════

func _play_next_track() -> void:
	if not _is_bgm_active: return
	
	if _unplayed_tracks.is_empty():
		_refill_and_shuffle()
		
	# Garante que não repita a mesma música seguida na virada do "saco"
	if _unplayed_tracks.size() > 1 and _unplayed_tracks[0] == _last_track_path:
		_unplayed_tracks.shuffle()
	
	var next_path = _unplayed_tracks.pop_front()
	_last_track_path = next_path
	_current_track_path = next_path
	
	var stream = load(next_path)
	if stream:
		_bgm_player.stream = stream
		_bgm_player.volume_db = BGM_VOLUME_DEFAULT
		_bgm_player.play()
		_saved_position = 0.0 # Reseta posição salva ao iniciar nova música

func _resume_bgm() -> void:
	var stream = load(_current_track_path)
	if stream:
		_bgm_player.stream = stream
		_bgm_player.volume_db = BGM_VOLUME_DEFAULT
		_bgm_player.play(_saved_position)

func _refill_and_shuffle() -> void:
	_unplayed_tracks = BGM_PLAYLIST.duplicate()
	_unplayed_tracks.shuffle()

func _on_bgm_finished() -> void:
	if _is_bgm_active:
		_play_next_track()