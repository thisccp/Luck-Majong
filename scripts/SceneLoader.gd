extends Node

var is_transitioning: bool = false
var _transition_layer: CanvasLayer
var _fade_rect: ColorRect

func _ready() -> void:
	# Inicia o carregamento em background da cena do jogo
	ResourceLoader.load_threaded_request("res://scenes/MainGame.tscn")
	
	# Cria o CanvasLayer no layer 128 para segurar a transição
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128
	add_child(_transition_layer)
	
	# Prepara o ColorRect preto
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_layer.add_child(_fade_rect)

func transition_to_game() -> void:
	is_transitioning = true
	# Bloqueia qualquer clique passante
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade-to-Black (escurecer)
	var tween_in = create_tween()
	tween_in.tween_property(_fade_rect, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	await tween_in.finished
	
	# Carrega e converte a cena
	var status = ResourceLoader.load_threaded_get_status("res://scenes/MainGame.tscn")
	var game_scene: PackedScene
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		game_scene = ResourceLoader.load_threaded_get("res://scenes/MainGame.tscn")
	else:
		# Se já foi pego ou não estava carregando, carrega direto de forma segura
		game_scene = load("res://scenes/MainGame.tscn")
		
	# Muda a cena fisicamente
	get_tree().change_scene_to_packed(game_scene)
	
	# Micro-delay para instanciar o Mega Bake na cena preta sem travar
	await get_tree().create_timer(0.1).timeout
	
	# Clarear a tela
	var tween_out = create_tween()
	tween_out.tween_property(_fade_rect, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	await tween_out.finished
	
	# Libera cliques
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false

func transition_to_menu() -> void:
	is_transitioning = true
	# Bloqueia qualquer clique passante
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade-to-Black (escurecer)
	var tween_in = create_tween()
	tween_in.tween_property(_fade_rect, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	await tween_in.finished
	
	# Muda a cena
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	
	# Clarear a tela
	var tween_out = create_tween()
	tween_out.tween_property(_fade_rect, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	await tween_out.finished
	
	# Libera cliques
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
