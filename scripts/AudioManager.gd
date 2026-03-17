## AudioManager.gd — Gerenciador de Áudio do Neko Mahjong (Godot 4.x)
##
## Responsável por:
## - Pool de SFX (8 players em round-robin)
## - Player de UI dedicado (não interrompe SFX de gameplay)
## - Sistema de Atmosfera Zen por Mundo (PlayerA + PlayerB dual cross-fade)

extends Node

# ═══════════════════════════════════════════════════════════════
# SFX Pool
# ═══════════════════════════════════════════════════════════════

var num_sfx_players: int = 8
var sfx_pool: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0
var ui_player: AudioStreamPlayer

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null: return
	var p = sfx_pool[next_sfx_player]
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	p.play()
	next_sfx_player = (next_sfx_player + 1) % num_sfx_players

func play_ui_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null: return
	ui_player.stream = stream
	ui_player.pitch_scale = pitch_scale
	ui_player.volume_db = volume_db
	ui_player.play()


# ═══════════════════════════════════════════════════════════════
# SISTEMA DE ATMOSFERA ZEN POR MUNDO
# ═══════════════════════════════════════════════════════════════

## Volume máximo do ambiente — baixo para não abafar SFX
const MAX_AMB_VOLUME: float = -18.0
## Duração do cross-fade ao mudar de mundo (segundos)
const AMB_CROSSFADE_DURATION: float = 3.0
## Intervalo de silêncio (min e max) entre faixas do mesmo mundo
const AMB_SILENCE_MIN: float = 15.0
const AMB_SILENCE_MAX: float = 30.0

## Playlists por mundo (world_id 0, 1, 2)
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

## Dois players para cross-fade sem cortes
var _amb_a: AudioStreamPlayer
var _amb_b: AudioStreamPlayer
## Qual player está ativo agora
var _amb_active_player: AudioStreamPlayer
var _amb_inactive_player: AudioStreamPlayer

## Estado do mundo atual (-1 = nenhum iniciado)
var _current_world_id: int = -1
## Caminho da faixa atual de ambiente
var _current_amb_path: String = ""
## Pool de faixas não tocadas ainda
var _unplayed_amb: Array[String] = []

## Timer de silêncio entre faixas ambientes
var _amb_silence_timer: Timer
## Tween de cross-fade
var _amb_crossfade_tween: Tween

## Se o sistema de ambiente está ativo
var _is_amb_active: bool = false

## ─── API Pública ───────────────────────────────────────────────

func update_ambient(level: int) -> void:
	"""Chamado pelo GameManager ao iniciar cada nível.
	Calcula o mundo e decide se deve cross-fade ou manter o atual."""
	var world_id: int = int(floor(float(level - 1) / 10.0)) % 3

	# Mesmo mundo: deixar o áudio correr sem interrupção
	if world_id == _current_world_id and _is_amb_active:
		return

	# Novo mundo: iniciar cross-fade
	_current_world_id = world_id
	_is_amb_active = true
	_start_amb_world(world_id, _current_world_id >= 0)

func stop_ambient(with_fade: bool = true) -> void:
	"""Para o sistema de ambiente (ads, menus)."""
	_is_amb_active = false
	_clear_amb_timer()
	if _amb_crossfade_tween and _amb_crossfade_tween.is_valid():
		_amb_crossfade_tween.kill()
	if with_fade:
		var t = create_tween()
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if is_instance_valid(_amb_active_player) and _amb_active_player.playing:
			t.tween_property(_amb_active_player, "volume_db", -80.0, AMB_CROSSFADE_DURATION)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_callback(func():
			if is_instance_valid(_amb_a): _amb_a.stop()
			if is_instance_valid(_amb_b): _amb_b.stop()
		)
	else:
		_amb_a.stop()
		_amb_b.stop()

## ─── Lógica Interna ────────────────────────────────────────────

func _start_amb_world(world_id: int, do_crossfade: bool) -> void:
	"""Seleciona playlist do mundo, para o timer de silêncio e inicia a próxima faixa."""
	_clear_amb_timer()
	_current_amb_path = "" # Força escolha de nova faixa
	_unplayed_amb.clear()
	_refill_amb_pool(world_id)
	_play_next_amb(do_crossfade)

func _refill_amb_pool(world_id: int) -> void:
	"""Reabastece a fila de faixas embaralhadas para o mundo dado."""
	var tracks: Array = AMBIENT_TRACKS.get(world_id, [])
	_unplayed_amb.clear()
	for path in tracks:
		_unplayed_amb.append(str(path))
	_unplayed_amb.shuffle()
	# Anti-repetição: se a primeira faixa for a mesma que a anterior, trocar
	if _unplayed_amb.size() > 1 and _unplayed_amb[0] == _current_amb_path:
		var tmp = _unplayed_amb[0]
		_unplayed_amb[0] = _unplayed_amb[1]
		_unplayed_amb[1] = tmp

func _play_next_amb(do_crossfade: bool = false) -> void:
	"""Pega a próxima faixa da fila e toca com ou sem cross-fade."""
	if not _is_amb_active: return

	if _unplayed_amb.is_empty():
		_refill_amb_pool(_current_world_id)

	if _unplayed_amb.is_empty():
		return # Nenhuma faixa configurada para este mundo

	_current_amb_path = _unplayed_amb.pop_front()

	# Verificar se arquivo existe antes de carregar
	if not FileAccess.file_exists(_current_amb_path):
		push_warning("[AudioManager] Faixa de ambiente não encontrada: " + _current_amb_path)
		return

	var stream: AudioStream = load(_current_amb_path)
	if stream == null:
		return

	if do_crossfade and is_instance_valid(_amb_active_player) and _amb_active_player.playing:
		_do_crossfade(stream)
	else:
		# Fade in direto no player ativo (sem player anterior tocando)
		_amb_active_player.stream = stream
		_amb_active_player.volume_db = -80.0
		_amb_active_player.play()
		_fade_in_player(_amb_active_player)

	# Agendar o fim da faixa para o timer de silêncio
	_schedule_amb_end(stream)

func _do_crossfade(new_stream: AudioStream) -> void:
	"""Cross-fade: faz fade-out no player ativo e fade-in no inativo."""
	if _amb_crossfade_tween and _amb_crossfade_tween.is_valid():
		_amb_crossfade_tween.kill()

	# O inativo recebe a nova faixa
	_amb_inactive_player.stream = new_stream
	_amb_inactive_player.volume_db = -80.0
	_amb_inactive_player.play()

	var old_player = _amb_active_player
	var new_player = _amb_inactive_player

	# Trocar referências
	_amb_active_player = new_player
	_amb_inactive_player = old_player

	_amb_crossfade_tween = create_tween()
	_amb_crossfade_tween.set_parallel(true)
	_amb_crossfade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	_amb_crossfade_tween.tween_property(new_player, "volume_db", MAX_AMB_VOLUME, AMB_CROSSFADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_amb_crossfade_tween.tween_property(old_player, "volume_db", -80.0, AMB_CROSSFADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_amb_crossfade_tween.chain().tween_callback(func():
		old_player.stop()
	)

func _fade_in_player(player: AudioStreamPlayer) -> void:
	"""Fade in simples para o player dado."""
	var t = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(player, "volume_db", MAX_AMB_VOLUME, AMB_CROSSFADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _schedule_amb_end(stream: AudioStream) -> void:
	"""Agenda o silêncio após o término da faixa de ambiente."""
	var length: float = stream.get_length() if stream != null else 0.0
	if length <= 0.1: return

	_clear_amb_timer()
	_amb_silence_timer.timeout.connect(_on_amb_track_finished)
	_amb_silence_timer.start(length)

func _on_amb_track_finished() -> void:
	"""Sinal de fim de faixa: iniciar pausa zen aleatória."""
	if not _is_amb_active: return
	_clear_amb_timer()

	# Silêncio aleatório entre 15 e 30 segundos
	var silence_duration: float = randf_range(AMB_SILENCE_MIN, AMB_SILENCE_MAX)

	# Fade-out suave antes do silêncio
	if is_instance_valid(_amb_active_player) and _amb_active_player.playing:
		var t = create_tween()
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(_amb_active_player, "volume_db", -80.0, AMB_CROSSFADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_callback(func(): _amb_active_player.stop())

	# Agendar a próxima faixa após o silêncio
	_amb_silence_timer.timeout.connect(_on_amb_silence_finished)
	_amb_silence_timer.start(silence_duration)

func _on_amb_silence_finished() -> void:
	_clear_amb_timer()
	if _is_amb_active:
		_play_next_amb(false)

func _clear_amb_timer() -> void:
	_amb_silence_timer.stop()
	if _amb_silence_timer.timeout.is_connected(_on_amb_track_finished):
		_amb_silence_timer.timeout.disconnect(_on_amb_track_finished)
	if _amb_silence_timer.timeout.is_connected(_on_amb_silence_finished):
		_amb_silence_timer.timeout.disconnect(_on_amb_silence_finished)

# ═══════════════════════════════════════════════════════════════
# INICIALIZAÇÃO
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# ── UI Player ──
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = &"SFX"
	add_child(ui_player)

	# ── Pool de SFX ──
	for i in num_sfx_players:
		var p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		sfx_pool.append(p)


	# ── Ambient Players A e B (cross-fade) ──
	_amb_a = AudioStreamPlayer.new()
	_amb_a.bus = &"BGM"
	_amb_a.process_mode = Node.PROCESS_MODE_ALWAYS
	_amb_a.name = "AmbPlayerA"
	add_child(_amb_a)

	_amb_b = AudioStreamPlayer.new()
	_amb_b.bus = &"BGM"
	_amb_b.process_mode = Node.PROCESS_MODE_ALWAYS
	_amb_b.name = "AmbPlayerB"
	add_child(_amb_b)

	_amb_active_player = _amb_a
	_amb_inactive_player = _amb_b

	# ── Timer de Silêncio Ambiente ──
	_amb_silence_timer = Timer.new()
	_amb_silence_timer.name = "AmbSilenceTimer"
	_amb_silence_timer.one_shot = true
	_amb_silence_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_amb_silence_timer)
