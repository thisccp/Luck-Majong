## AudioManager.gd — Versão 86.0 (Procedural Audio & Buses)
##
## Refatoração: Playlist carredaga dinamicamente da pasta (export-safe),
## roteamento de barramentos (BGM, Cats, SFX), lógicas anti-repetição
## e miados orgânicos (10-60s) via código.

extends Node

# --- CONFIGURAÇÕES DE DIRETÓRIOS ---
const BGM_DIR: String = "res://assets/audio/bgm/"
const CATS_DIR: String = "res://assets/audio/cats/"
const BGM_VOLUME_DEFAULT: float = -8.0

# --- VARIÁVEIS DE SISTEMA (SFX) ---
var sfx_pool: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0
var num_sfx_players: int = 8
var ui_player: AudioStreamPlayer

# --- VARIÁVEIS DE SISTEMA (BGM) ---
var _bgm_player: AudioStreamPlayer
var _bgm_streams: Array[AudioStream] = []
var _last_bgm_track: AudioStream = null
var _is_bgm_active: bool = false
var _saved_position: float = 0.0

# --- VARIÁVEIS DE PROCEDURAL (CATS) ---
var _cat_player: AudioStreamPlayer
var _cat_streams: Array[AudioStream] = []
var _last_cat_track: AudioStream = null
var _cat_timer: Timer

# ═══════════════════════════════════════════════════════════════
# INICIALIZAÇÃO
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	var bgm_bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"
	var sfx_bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"
	var cats_bus = &"Cats" if AudioServer.get_bus_index("Cats") != -1 else &"Master"

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
	
	# Cat Player Setup
	_cat_player = AudioStreamPlayer.new()
	_cat_player.bus = cats_bus
	_cat_player.name = "CatPlayer"
	_cat_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_cat_player.finished.connect(_on_cat_finished)
	add_child(_cat_player)
	
	# Cat Timer Setup
	_cat_timer = Timer.new()
	_cat_timer.name = "CatTimer"
	_cat_timer.one_shot = true
	_cat_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_cat_timer.timeout.connect(_play_random_cat)
	add_child(_cat_timer)
	
	# Load Streams Dynamically
	_load_audio_files()

func _load_audio_files() -> void:
	_bgm_streams = _load_dir_streams(BGM_DIR, ".ogg")
	_cat_streams = _load_dir_streams(CATS_DIR, ".wav")

func _load_dir_streams(path: String, extension: String) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	var loaded_paths: Array[String] = []
	
	var dir = DirAccess.open(path)
	if dir:
		for file in dir.get_files():
			var file_path = ""
			if file.ends_with(extension):
				file_path = path + file if path.ends_with("/") else path + "/" + file
			elif file.ends_with(extension + ".import"):
				var base_file = file.replace(".import", "")
				file_path = path + base_file if path.ends_with("/") else path + "/" + base_file
				
			if file_path != "" and not loaded_paths.has(file_path):
				var stream = load(file_path) as AudioStream
				if stream:
					streams.append(stream)
					loaded_paths.append(file_path)
	return streams

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
# API DE AMBIENTE / BGM & CATS
# ═══════════════════════════════════════════════════════════════

## Inicia ou retoma a playlist global e o timer procedural
func update_ambient(_level: int = 0) -> void:
	if _is_bgm_active:
		return # Já está tocando
		
	_is_bgm_active = true
	
	if _bgm_player.stream != null and _saved_position > 0.0:
		_bgm_player.play(_saved_position)
	else:
		_play_next_bgm()
		
	if _cat_timer.is_stopped() and not _cat_player.playing:
		_start_cat_timer()

## Para a reprodução e salva a posição atual.
func stop_ambient(_with_fade: bool = false) -> void:
	_is_bgm_active = false
	if _bgm_player.playing:
		_saved_position = _bgm_player.get_playback_position()
		_bgm_player.stop()
		
	_cat_timer.stop()
	if _cat_player.playing:
		_cat_player.stop()

# ═══════════════════════════════════════════════════════════════
# LÓGICA INTERNA DE BGM
# ═══════════════════════════════════════════════════════════════

func _play_next_bgm() -> void:
	if not _is_bgm_active or _bgm_streams.is_empty(): 
		return
	
	var next_track: AudioStream = _last_bgm_track
	# Garante a regra anti-repetição
	if _bgm_streams.size() > 1:
		while next_track == _last_bgm_track:
			next_track = _bgm_streams[randi() % _bgm_streams.size()]
	elif _bgm_streams.size() == 1:
		next_track = _bgm_streams[0]
		
	_last_bgm_track = next_track
	_bgm_player.stream = next_track
	_bgm_player.volume_db = BGM_VOLUME_DEFAULT
	_bgm_player.play()
	_saved_position = 0.0 # Reseta posição salva ao iniciar nova música

func _on_bgm_finished() -> void:
	if _is_bgm_active:
		_play_next_bgm()

# ═══════════════════════════════════════════════════════════════
# LÓGICA PROCEDURAL DE GATOS
# ═══════════════════════════════════════════════════════════════

func _start_cat_timer() -> void:
	if _is_bgm_active and not _cat_streams.is_empty():
		var random_time = randf_range(10.0, 60.0)
		_cat_timer.start(random_time)

func _play_random_cat() -> void:
	if not _is_bgm_active or _cat_streams.is_empty():
		return
		
	var next_track: AudioStream = _last_cat_track
	# Garante a regra anti-repetição
	if _cat_streams.size() > 1:
		while next_track == _last_cat_track:
			next_track = _cat_streams[randi() % _cat_streams.size()]
	elif _cat_streams.size() == 1:
		next_track = _cat_streams[0]
		
	_last_cat_track = next_track
	_cat_player.stream = next_track
	_cat_player.play()

func _on_cat_finished() -> void:
	if _is_bgm_active:
		_start_cat_timer()
