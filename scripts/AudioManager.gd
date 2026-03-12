extends Node

var num_sfx_players: int = 8
var sfx_pool: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0

var bgm_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# --- BGM Variables ---
const BGM_PATHS: Array[String] = [
	"res://assets/audio/bgm/bgm_1.ogg",
	"res://assets/audio/bgm/bgm_2.ogg",
	"res://assets/audio/bgm/bgm_3.ogg"
]
var _unplayed_bgms: Array[String] = []
var _current_bgm_path: String = ""
var _is_bgm_active: bool = false
var _is_bgm_enabled: bool = true # Estado global do botão Toggle
var _fade_tween: Tween

const FADE_DURATION: float = 2.0
const SILENCE_DURATION: float = 15.0
const MAX_BGM_VOLUME: float = -12.0 # Em dB

func _ready() -> void:
	# Configurar BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"BGM"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS # Nunca pausa com o jogo (bom para Ads e Menus)
	add_child(bgm_player)
	
	bgm_player.finished.connect(_on_bgm_finished)
	
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

func stop_bgm(with_fade: bool = false) -> void:
	_is_bgm_active = false
	if with_fade and bgm_player.playing:
		_start_fade(true)
	else:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		bgm_player.stop()

# --- BGM Rotation Logic ---

func start_bgm_rotation() -> void:
	if _is_bgm_active: return
	
	_is_bgm_active = true
	# Só dispara o áudio de fato se o botão global também estiver habilitado
	if _is_bgm_enabled:
		_play_next_bgm()

func set_bgm_enabled(enabled: bool) -> void:
	if _is_bgm_enabled == enabled:
		return
		
	_is_bgm_enabled = enabled
	
	if enabled:
		# Ligar
		if _is_bgm_active: # Se o jogo mandou tocar (não estamos no menu principal quietos)
			_play_next_bgm()
	else:
		# Desligar Imediatamente (sem fade para UI snappier)
		stop_bgm(false)
		# Nota: stop_bgm(false) define _is_bgm_active como false. 
		# Precisamos manter ele true para que volte a tocar sozinho depois (o flow do jogo ainda quer musica)
		_is_bgm_active = true

func _play_next_bgm() -> void:
	if not _is_bgm_active or not _is_bgm_enabled: return
	
	# Se já temos uma música _current_bgm_path salva e foi pausada na metade,
	# no momento vamos apenas mandá-la tocar desde o inicio novamente.
	var needs_new_track = _current_bgm_path == ""
	
	# Refil se estiver vazio e for a hora
	if _unplayed_bgms.is_empty() and needs_new_track:
		_unplayed_bgms = BGM_PATHS.duplicate()
		_unplayed_bgms.shuffle()
		
		# Previne tocar a mesma de forma consecutiva
		if _unplayed_bgms[0] == _current_bgm_path and _unplayed_bgms.size() > 1:
			var temp = _unplayed_bgms[0]
			_unplayed_bgms[0] = _unplayed_bgms[1]
			_unplayed_bgms[1] = temp
	if needs_new_track:
		_current_bgm_path = _unplayed_bgms.pop_front()
	
	var stream = load(_current_bgm_path)
	if stream:
		bgm_player.stream = stream
		bgm_player.volume_db = -80.0
		bgm_player.play()
		_start_fade(false)
		
		# Agendar o Fade out antes de terminar
		var stream_length = stream.get_length() if stream is AudioStream else 0.0
		if stream_length > FADE_DURATION:
			var fade_out_time = stream_length - FADE_DURATION
			get_tree().create_timer(fade_out_time, false).timeout.connect(_on_time_to_fade_out)

func _start_fade(is_fade_out: bool) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Roda mesmo pausado
	
	var target_vol = -80.0 if is_fade_out else MAX_BGM_VOLUME
	
	_fade_tween.tween_property(bgm_player, "volume_db", target_vol, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if is_fade_out:
		_fade_tween.tween_callback(func():
			bgm_player.stop()
			_on_bgm_finished()
		)

func _on_time_to_fade_out() -> void:
	# Só iniciamos o fade out se esta for a trilha certa e ainda estivermos ativos
	if bgm_player.playing and bgm_player.stream != null and bgm_player.stream.resource_path == _current_bgm_path:
		_start_fade(true)

func _on_bgm_finished() -> void:
	if not _is_bgm_active or not _is_bgm_enabled: return
	
	# Evitar triggers múltiplos de fim de música
	if _current_bgm_path == "": return
	
	_current_bgm_path = ""
	bgm_player.stream = null
	
	# Pede 15 segundos de silêncio (não pausa com o jogo)
	get_tree().create_timer(SILENCE_DURATION, false).timeout.connect(
		func(): 
			if _is_bgm_active and _is_bgm_enabled:
				_play_next_bgm()
	)

func play_ui_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null: return
	
	ui_player.stream = stream
	ui_player.pitch_scale = pitch_scale
	ui_player.volume_db = volume_db
	ui_player.play()
