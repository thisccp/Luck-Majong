extends Control

@onready var _btn_play: TextureButton = $PlayButton
@onready var _btn_options: TextureButton = $OptionsButton
@onready var _btn_quit: TextureButton = $QuitButton

@onready var _dim_background: ColorRect = $MenuPopups/DimBackground
@onready var _options_popup: PanelContainer = $MenuPopups/OptionsPopup
@onready var _quit_popup: PanelContainer = $MenuPopups/QuitPopup

@onready var _btn_close_options: Button = $MenuPopups/OptionsPopup/VBoxContainer/HBoxContainer/CloseOptionsBtn
@onready var _btn_close_quit: Button = $MenuPopups/QuitPopup/VBoxContainer/HBoxContainer/CloseQuitBtn
@onready var _btn_confirm_quit: Button = $MenuPopups/QuitPopup/VBoxContainer/ConfirmQuitBtn


var sfx_all_btn: AudioStream = preload("res://assets/audio/sfx/all_btn.wav")

func _ready() -> void:
	# Inicia o som ambiente zen e miados
	AudioManager.update_ambient(1)
	
	_setup_juicy_button(_btn_play, _on_play_pressed)
	_setup_juicy_button(_btn_options, _on_options_pressed)
	_setup_juicy_button(_btn_quit, _on_quit_pressed)
	
	_dim_background.modulate.a = 0.0
	_dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_popup.hide()
	_quit_popup.hide()
	
	_btn_close_options.pressed.connect(_close_popups)
	_btn_close_quit.pressed.connect(_close_popups)
	_btn_confirm_quit.pressed.connect(_on_confirm_quit_pressed)

func _setup_juicy_button(btn: TextureButton, pressed_callable: Callable) -> void:
	# Necessário recálculo simples para o pivô central do TextureButton
	btn.pivot_offset = btn.size / 2.0
	btn.button_down.connect(func(): _on_btn_down(btn))
	btn.button_up.connect(func(): _on_btn_up(btn))
	btn.pressed.connect(pressed_callable)

func _on_btn_down(btn: TextureButton) -> void:
	if SceneLoader.is_transitioning:
		return
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.1).set_trans(Tween.TRANS_QUAD)

func _on_btn_up(btn: TextureButton) -> void:
	if SceneLoader.is_transitioning:
		return
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _on_play_pressed() -> void:
	if SceneLoader.is_transitioning:
		return
	
	# Desabilita os botões para evitar duplo clique
	_btn_play.disabled = true
	_btn_options.disabled = true
	_btn_quit.disabled = true
	
	AudioManager.play_sfx(sfx_all_btn, 1.0, 0.0)
	
	# FORÇA o botão a voltar para a escala original (1.0), ignorando o bloqueio do sinal
	var tween := create_tween()
	tween.tween_property(_btn_play, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	# Espera o tempo exato para a animação do botão terminar de quicar e a tela escurecer
	await get_tree().create_timer(0.35).timeout
	
	get_node("/root/SceneLoader").transition_to_game()

func _on_options_pressed() -> void:
	if SceneLoader.is_transitioning:
		return
	AudioManager.play_sfx(sfx_all_btn, 1.0, 0.0)
	_show_popup(_options_popup)

func _on_quit_pressed() -> void:
	if SceneLoader.is_transitioning:
		return
	AudioManager.play_sfx(sfx_all_btn, 1.0, 0.0)
	_show_popup(_quit_popup)

func _show_popup(popup: Control) -> void:
	_dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_dim_background, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
	popup.show()

func _close_popups() -> void:
	AudioManager.play_sfx(sfx_all_btn, 1.0, 0.0)
	_options_popup.hide()
	_quit_popup.hide()
	_dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(_dim_background, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)

func _on_confirm_quit_pressed() -> void:
	AudioManager.play_sfx(sfx_all_btn, 1.0, 0.0)
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if SceneLoader.is_transitioning:
			return
		if _options_popup.visible or _quit_popup.visible:
			_close_popups()
		else:
			_on_quit_pressed()
