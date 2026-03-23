extends Control
class_name QuitPopup

signal quit_confirmed
signal close_requested
var panel: NinePatchRect
var title_label: Label
var message_label: Label
var action_button: TextureButton
var button_label: Label
var close_button: TextureButton

func _ready() -> void:
	# Trava a raiz para cobrir a tela toda (indispensável para o fundo escuro)
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	
	_create_panel()
	_create_title()
	_create_message()
	_create_action_button()
	_create_close_button()

func _create_panel() -> void:
	panel = NinePatchRect.new()
	panel.texture = load("res://assets/bg/popup_bg_default.png")
	
	# MÁGICA 1: Fim do "Corte" na placa!
	# Margens ajustadas apenas para proteger as bordas da madeira grossa (aprox 90px).
	# Removemos o "TILE_FIT", então o centro vai esticar suavemente sem criar emendas.
	panel.patch_margin_top = 160 # Protege a placa superior
	panel.patch_margin_bottom = 90 # Protege a moldura inferior
	panel.patch_margin_left = 90 # Protege a moldura esquerda
	panel.patch_margin_right = 90 # Protege a moldura direita
	
	add_child(panel)

	# MÁGICA 2: Centralização Absoluta (Desgruda da direita)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5

	# Tamanho do popup: 680x500 (Deixa um bom respiro nas laterais da tela)
	var p_width = 680.0
	var p_height = 500.0

	# Puxa metade do tamanho para cada lado a partir do centro da tela
	panel.offset_left = - p_width / 2.0
	panel.offset_right = p_width / 2.0
	panel.offset_top = - p_height / 2.0
	panel.offset_bottom = p_height / 2.0

func _create_title() -> void:
	title_label = Label.new()
	title_label.text = "Sair"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9)) # Creme
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(title_label)

	# MÁGICA 3: Alinhamento de Texto Perfeito
	# Forçamos a caixa de texto a ter 100% da largura do painel (0.0 até 1.0)
	title_label.anchor_left = 0.0
	title_label.anchor_right = 1.0
	title_label.anchor_top = 0.00
	title_label.anchor_bottom = 0.0
	
	# Offsets em 0 garantem que a caixa vá de ponta a ponta
	title_label.offset_left = 0
	title_label.offset_right = 0
	# Desce 35 pixels para ficar no centro da madeira
	title_label.offset_top = -45
	title_label.offset_bottom = 100

func _create_message() -> void:
	message_label = Label.new()
	message_label.text = "Tem certeza que quer sair?"
	message_label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05)) # Marrom
	message_label.add_theme_font_size_override("font_size", 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(message_label)

	# Forçamos a caixa de texto a ter 100% da largura no meio do painel
	message_label.anchor_left = 0.0
	message_label.anchor_right = 1.0
	message_label.anchor_top = 0.5
	message_label.anchor_bottom = 0.5

	# Dá 60px de margem de cada lado para o texto não bater na madeira
	message_label.offset_left = 60
	message_label.offset_right = -60
	message_label.offset_top = -60
	message_label.offset_bottom = 40

func _create_action_button() -> void:
	action_button = TextureButton.new()
	action_button.texture_normal = load("res://assets/btn/btn_popup_default.png")
	
	action_button.ignore_texture_size = true
	action_button.stretch_mode = TextureButton.STRETCH_SCALE
	panel.add_child(action_button)

	# Tamanho do botão levemente reduzido
	var btn_width = 250.0
	var btn_height = 95.0

	# NOVO: Define o centro do botão como ponto de escala
	action_button.pivot_offset = Vector2(btn_width / 2.0, btn_height / 2.0)
	
	# NOVO: Conecta os sinais de "tocar na tela" e "soltar o dedo"
	action_button.button_down.connect(_on_button_down)
	action_button.button_up.connect(_on_button_up)
	
	# Ancora no centro inferior
	action_button.anchor_left = 0.5
	action_button.anchor_right = 0.5
	action_button.anchor_top = 1.0
	action_button.anchor_bottom = 1.0
	
	# Afasta 65 pixels da borda inferior para não ficar colado
	action_button.offset_left = - btn_width / 2.0
	action_button.offset_right = btn_width / 2.0
	action_button.offset_top = -65 - btn_height
	action_button.offset_bottom = -65

	_create_button_label()
	action_button.pressed.connect(_on_quit_pressed)

func _create_button_label() -> void:
	button_label = Label.new()
	button_label.text = "SAIR"
	
	# Alterado para Vermelho forte
	button_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	button_label.add_theme_font_size_override("font_size", 55)
	button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_button.add_child(button_label)
	
	# MÁGICA 4: O texto do botão agora vai de ponta a ponta, centralizando perfeitamente!
	button_label.anchor_left = 0.0
	button_label.anchor_right = 1.0
	button_label.anchor_top = 0.0
	button_label.anchor_bottom = 1.0
	button_label.offset_left = 0
	button_label.offset_right = 0
	button_label.offset_top = 0
	button_label.offset_bottom = 0

func _on_button_down() -> void:
	# Quando o dedo toca a tela: Escurece e encolhe para 90% do tamanho
	var tween = create_tween()
	tween.tween_property(action_button, "scale", Vector2(0.9, 0.9), 0.05)
	action_button.modulate = Color(0.8, 0.8, 0.8) # Tom acinzentado

func _on_button_up() -> void:
	# Quando o dedo sai da tela: Volta a cor e o tamanho original (100%)
	var tween = create_tween()
	tween.tween_property(action_button, "scale", Vector2(1.0, 1.0), 0.1)
	action_button.modulate = Color.WHITE

func _on_quit_pressed() -> void:
	# Desativa o botão para o jogador não clicar duas vezes rápido
	action_button.disabled = true
	
	# Espera 0.1 segundos (o tempo do botão voltar ao tamanho normal)
	await get_tree().create_timer(0.1).timeout
	
	quit_confirmed.emit()
	queue_free()

func _create_close_button() -> void:
	close_button = TextureButton.new()
	close_button.texture_normal = load("res://assets/btn/btn_popup_default_close.png")
	
	# Ativamos o ignore_texture_size para controlar o tamanho via código
	close_button.ignore_texture_size = true
	close_button.stretch_mode = TextureButton.STRETCH_SCALE
	
	# Tamanho final do X (80x80)
	var x_size = 80.0
	close_button.custom_minimum_size = Vector2(x_size, x_size)
	close_button.size = Vector2(x_size, x_size)
	
	panel.add_child(close_button)
	
	# Posicionamento no Canto Superior Direito
	close_button.anchor_left = 1.0
	close_button.anchor_right = 1.0
	close_button.anchor_top = 0.0
	close_button.anchor_bottom = 0.0
	
	# AJUSTE DE SOBREPOSIÇÃO:
	# Quanto MENOR o número negativo, mais para DENTRO o botão entra.
	# Aqui, estamos deixando apenas 20 pixels para fora da borda.
	var margin_visible = 20.0
	close_button.offset_left = - (x_size - margin_visible)
	close_button.offset_right = margin_visible
	close_button.offset_top = - margin_visible
	close_button.offset_bottom = x_size - margin_visible

	# Efeito de Pivot para o Juice (opcional, igual ao outro botão)
	close_button.pivot_offset = Vector2(x_size / 2.0, x_size / 2.0)
	
	# Conexões
	close_button.button_down.connect(_on_close_btn_down)
	close_button.button_up.connect(_on_close_btn_up)
	close_button.pressed.connect(_on_close_pressed)

# Funções de animação para o X
func _on_close_btn_down() -> void:
	var tween = create_tween()
	tween.tween_property(close_button, "scale", Vector2(0.8, 0.8), 0.05)
	close_button.modulate = Color(0.8, 0.8, 0.8)

func _on_close_btn_up() -> void:
	var tween = create_tween()
	tween.tween_property(close_button, "scale", Vector2(1.0, 1.0), 0.1)
	close_button.modulate = Color.WHITE

func _on_close_pressed() -> void:
	# Somente fecha o popup sem emitir o sinal de "Sair do Jogo"
	close_requested.emit()