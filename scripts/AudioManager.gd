extends Node

var num_sfx_players: int = 8
var sfx_pool: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0

var bgm_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

func _ready() -> void:
	# Configurar BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"BGM"
	add_child(bgm_player)
	
	# Configurar UI Player
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = &"SFX"
	add_child(ui_player)
	
	# Inicializar Pool de SFX
	for i in num_sfx_players:
		var p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		sfx_pool.append(p)

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null: return
	
	var p = sfx_pool[next_sfx_player]
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	p.play()
	
	next_sfx_player = (next_sfx_player + 1) % num_sfx_players

func play_bgm(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null: return
	
	if bgm_player.stream == stream and bgm_player.playing:
		return # Já está tocando
		
	bgm_player.stream = stream
	bgm_player.volume_db = volume_db
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func play_ui_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null: return
	
	ui_player.stream = stream
	ui_player.pitch_scale = pitch_scale
	ui_player.volume_db = volume_db
	ui_player.play()
