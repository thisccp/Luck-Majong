## AudioManager.gd — Versão 84.2 (Correção de Toggle e Persistência)
##
## Ajuste: Agora o sistema memoriza a faixa atual ao desligar 
## e a retoma corretamente ao ligar o som novamente no mesmo mundo.

extends Node

# --- CONFIGURAÇÕES DE ÁUDIO ---
const MAX_AMB_VOLUME: float = -15.0
const AMB_CROSSFADE_DURATION: float = 3.0
const AMB_SILENCE_MIN: float = 15.0
const AMB_SILENCE_MAX: float = 30.0

const AMBIENT_TRACKS: Dictionary = {
	0: [
		"res://assets/audio/bgm/bgs_forest_1.ogg",
		"res://assets/audio/bgm/bgs_forest_2.ogg",
		"res://assets/audio/bgm/bgs_forest_3.ogg",
		"res://assets/audio/bgm/bgs_forest_4.ogg",
	],
	1: [
		"res://assets/audio/bgm/bgs_house_1.ogg",
		"res://assets/audio/bgm/bgs_house_2.ogg",
	],
	2: [
		"res://assets/audio/bgm/bgs_rain_1.ogg",
		"res://assets/audio/bgm/bgs_rain_2.ogg",
	],
}

# --- VARIÁVEIS DE SISTEMA ---
var sfx_pool: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0
var num_sfx_players: int = 8
var ui_player: AudioStreamPlayer

var _amb_a: AudioStreamPlayer
var _amb_b: AudioStreamPlayer
var _amb_active_player: AudioStreamPlayer
var _amb_inactive_player: AudioStreamPlayer

var _current_world_id: int = -1
var _current_amb_path: String = ""
var _unplayed_amb: Array[String] = []
var _amb_silence_timer: Timer
var _amb_crossfade_tween: Tween
var _is_amb_active: bool = false

# ═══════════════════════════════════════════════════════════════
# INICIALIZAÇÃO
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	var bgm_bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"
	var sfx_bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"

	ui_player = AudioStreamPlayer.new()
	ui_player.bus = sfx_bus
	add_child(ui_player)

	for i in num_sfx_players:
		var p = AudioStreamPlayer.new()
		p.bus = sfx_bus
		add_child(p)
		sfx_pool.append(p)

	_amb_a = _create_amb_player(bgm_bus, "AmbPlayerA")
	_amb_b = _create_amb_player(bgm_bus, "AmbPlayerB")
	_amb_active_player = _amb_a
	_amb_inactive_player = _amb_b

	_amb_silence_timer = Timer.new()
	_amb_silence_timer.one_shot = true
	_amb_silence_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_amb_silence_timer)

func _create_amb_player(bus_name: StringName, p_name: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.bus = bus_name
	p.name = p_name
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p

# ═══════════════════════════════════════════════════════════════
# API DE SFX
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
# API DE AMBIENTE
# ═══════════════════════════════════════════════════════════════

func update_ambient(level: int) -> void:
	var world_id: int = int(floor(float(level - 1) / 10.0)) % 3
	
	# Caso 1: O som estava desligado e foi ligado no mesmo mundo
	if world_id == _current_world_id and not _is_amb_active:
		_is_amb_active = true
		if _current_amb_path != "":
			_resume_specific_track(_current_amb_path)
		else:
			_start_amb_world(world_id, false)
		return

	# Caso 2: Mudança de mundo
	if world_id != _current_world_id:
		var should_fade = _current_world_id >= 0 and _is_amb_active
		_current_world_id = world_id
		_is_amb_active = true
		_start_amb_world(world_id, should_fade)
		return
	
	# Caso 3: Mesmo mundo e já está ativo (ex: mudou de fase comum)
	# Não fazemos nada para manter a música fluindo sem cortes

func stop_ambient(with_fade: bool = true) -> void:
	_is_amb_active = false
	_clear_amb_timer()
	
	if _amb_crossfade_tween and _amb_crossfade_tween.is_valid():
		_amb_crossfade_tween.kill()
		
	if with_fade:
		var t = create_tween()
		if _amb_active_player.playing:
			t.tween_property(_amb_active_player, "volume_db", -80.0, 1.5)
		t.tween_callback(func(): 
			_amb_a.stop()
			_amb_b.stop()
		)
	else:
		_amb_a.stop()
		_amb_b.stop()

# ═══════════════════════════════════════════════════════════════
# LÓGICA INTERNA
# ═══════════════════════════════════════════════════════════════

func _start_amb_world(world_id: int, do_crossfade: bool) -> void:
	_clear_amb_timer()
	# Aqui zeramos o path para forçar uma escolha aleatória do novo mundo
	_current_amb_path = ""
	_unplayed_amb.clear()
	_refill_amb_pool(world_id)
	_play_next_amb(do_crossfade)

func _resume_specific_track(path: String) -> void:
	"""Retoma uma faixa específica (usado ao ligar o som no menu)."""
	var stream = load(path)
	if not stream:
		_play_next_amb(false)
		return
		
	_amb_active_player.stream = stream
	_amb_active_player.volume_db = -80.0
	_amb_active_player.play()
	
	var t = create_tween()
	t.tween_property(_amb_active_player, "volume_db", MAX_AMB_VOLUME, 1.5)
	_schedule_amb_end(stream)

func _refill_amb_pool(world_id: int) -> void:
	var tracks = AMBIENT_TRACKS.get(world_id, [])
	_unplayed_amb.clear()
	for p in tracks:
		_unplayed_amb.append(str(p))
	_unplayed_amb.shuffle()

func _play_next_amb(do_crossfade: bool = false) -> void:
	if not _is_amb_active: return
	if _unplayed_amb.is_empty(): _refill_amb_pool(_current_world_id)
	if _unplayed_amb.is_empty(): return

	_current_amb_path = _unplayed_amb.pop_front()
	var stream = load(_current_amb_path)
	
	if not stream: return

	if do_crossfade:
		_do_crossfade(stream)
	else:
		_amb_active_player.stream = stream
		_amb_active_player.volume_db = -80.0
		_amb_active_player.play()
		var t = create_tween()
		t.tween_property(_amb_active_player, "volume_db", MAX_AMB_VOLUME, AMB_CROSSFADE_DURATION)

	_schedule_amb_end(stream)

func _do_crossfade(new_stream: AudioStream) -> void:
	if _amb_crossfade_tween and _amb_crossfade_tween.is_valid():
		_amb_crossfade_tween.kill()

	_amb_inactive_player.stream = new_stream
	_amb_inactive_player.volume_db = -80.0
	_amb_inactive_player.play()

	var old_p = _amb_active_player
	var new_p = _amb_inactive_player
	_amb_active_player = new_p
	_amb_inactive_player = old_p

	_amb_crossfade_tween = create_tween().set_parallel(true)
	_amb_crossfade_tween.tween_property(new_p, "volume_db", MAX_AMB_VOLUME, AMB_CROSSFADE_DURATION)
	_amb_crossfade_tween.tween_property(old_p, "volume_db", -80.0, AMB_CROSSFADE_DURATION)
	_amb_crossfade_tween.chain().tween_callback(old_p.stop)

func _schedule_amb_end(stream: AudioStream) -> void:
	var length = stream.get_length() if stream else 120.0
	if length < 0.1: length = 120.0
	
	_clear_amb_timer()
	_amb_silence_timer.timeout.connect(_on_amb_track_finished)
	_amb_silence_timer.start(length)

func _on_amb_track_finished() -> void:
	_clear_amb_timer()
	if not _is_amb_active: return

	var silence = randf_range(AMB_SILENCE_MIN, AMB_SILENCE_MAX)
	
	var t = create_tween()
	t.tween_property(_amb_active_player, "volume_db", -80.0, 2.0)
	t.tween_callback(_amb_active_player.stop)

	_amb_silence_timer.timeout.connect(_on_amb_silence_finished)
	_amb_silence_timer.start(silence)

func _on_amb_silence_finished() -> void:
	_clear_amb_timer()
	if _is_amb_active: _play_next_amb(false)

func _clear_amb_timer() -> void:
	_amb_silence_timer.stop()
	for sig in _amb_silence_timer.timeout.get_connections():
		_amb_silence_timer.timeout.disconnect(sig.callable)