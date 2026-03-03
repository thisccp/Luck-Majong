## GameManager.gd — Controller principal do Mahjong Solitaire (Godot 4.x)
##
## Orquestra seleção, matching, botões (Reset/Hint/Shuffle), popups e status.
## Tradução direta do main.py/MahjongApp.

class_name GameManager
extends Control

## Referências aos nós da UI.
@onready var _board: BoardManager = $BoardContainer/BoardManager
@onready var _status_label: Label = $UILayer/VBox/StatusLabel
@onready var _btn_hint: TextureButton = $UILayer/VBox/BottomMargin/HintBtn
@onready var _btn_menu: TextureButton = $UILayer/VBox/TopMargin/TopBar/MenuBtn
@onready var _dim_overlay: ColorRect = $UILayer/DimOverlay
@onready var _win_popup: TextureRect = $UILayer/WinPopup
@onready var _no_moves_popup: TextureRect = $UILayer/NoMovesPopup
@onready var _pause_popup: TextureRect = $UILayer/PausePopup

## Estado da seleção.
var _selected_tile: MahjongTile = null
var _pairs_matched: int = 0

# ─── Lifecycle ──────────────────────────────────────────────────────

func _ready() -> void:
	# Conectar botões
	_btn_hint.pressed.connect(_on_hint)
	_btn_menu.pressed.connect(_show_pause_popup)
	
	# Conectar sinal do board
	_board.tile_pressed.connect(_on_tile_pressed)
	
	# Conectar botões dos popups
	$UILayer/WinPopup/PlayAgainBtn.pressed.connect(func():
		_hide_popups()
		# _start_game() # Desativado por enquanto, esperando a lógica de Nível 2
		print("Indo para Nível 2 (WIP)")
	)
	$UILayer/WinPopup/HomeBtn.pressed.connect(func():
		_hide_popups()
		_start_game()
	)
	$UILayer/NoMovesPopup/Margin/Center/VBox/BtnBar/ShuffleBtn2.pressed.connect(func():
		_hide_popups()
		_on_shuffle()
	)
	$UILayer/NoMovesPopup/Margin/Center/VBox/BtnBar/ResetBtn2.pressed.connect(func():
		_hide_popups()
		_start_game()
	)
	$UILayer/PausePopup/SoundToggle.toggled.connect(func(button_pressed: bool):
		# TODO: Implement sound toggle logic when audio system is ready
		print("Sound toggled: ", button_pressed)
	)
	$UILayer/PausePopup/RestartBtn.pressed.connect(func():
		_hide_popups()
		_start_game()
	)
	$UILayer/PausePopup/ClosePauseBtn.pressed.connect(func():
		_hide_popups()
	)
	
	# Esconder popups
	_hide_popups()
	
	# Garantir que nós de UI não bloqueiem toques nas peças
	_set_ui_mouse_filters(self)
	
	# Iniciar primeiro jogo com delay para layout estar pronto
	await get_tree().create_timer(0.3).timeout
	_load_background()
	_start_game()


func _load_background() -> void:
	"""Carrega bg_zen.png se disponível, senão cria gradiente verde zen."""
	var bg_node = get_node_or_null("Background")
	if bg_node == null:
		print("[GameManager] ERRO: Background node não encontrado!")
		return
	if not (bg_node is TextureRect):
		print("[GameManager] ERRO: Background não é TextureRect, é: ", bg_node.get_class())
		return
	
	print("[GameManager] Background node encontrado: ", bg_node.get_class())
	
	# Tentar carregar imagem externa
	var bg_path := "res://assets/bg/bg_zen.png"
	if ResourceLoader.exists(bg_path):
		var bg_tex := load(bg_path) as Texture2D
		if bg_tex:
			bg_node.texture = bg_tex
			bg_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			print("[GameManager] Background: bg_zen.png carregado")
			return
	
	# Fallback: criar gradiente como imagem baked (100% compatível)
	var img_h := 256
	var img_w := 4
	var img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	
	# Cores ultra-suaves: #D4E6D4 (topo) → #BFD5C8 (base)
	var color_top := Color(0.831, 0.902, 0.831, 1.0)
	var color_bot := Color(0.749, 0.835, 0.784, 1.0)
	
	for y in range(img_h):
		var t: float = float(y) / float(img_h - 1)
		var col: Color = color_top.lerp(color_bot, t)
		for x in range(img_w):
			img.set_pixel(x, y, col)
	
	var tex := ImageTexture.create_from_image(img)
	bg_node.texture = tex
	print("[GameManager] Background: gradiente zen baked aplicado (%dx%d)" % [img_w, img_h])


# ─── Controle de jogo ──────────────────────────────────────────────

func _start_game() -> void:
	"""Gera um novo tabuleiro e renderiza."""
	_selected_tile = null
	_pairs_matched = 0
	_board.new_game()
	_update_status()


func _on_tile_pressed(tile: MahjongTile) -> void:
	"""Callback quando o jogador clica em uma peça."""
	# Ignorar peças bloqueadas
	if not _board.is_tile_free(tile):
		return
	
	if _selected_tile == null:
		# Primeira seleção
		_selected_tile = tile
		tile.is_selected = true
	
	elif _selected_tile == tile:
		# Clicou na mesma peça → desselecionar
		tile.is_selected = false
		_selected_tile = null
	
	else:
		# Segunda seleção — tentar match
		var prev_tile := _selected_tile
		
		if prev_tile.cat_id == tile.cat_id and _board.is_tile_free(prev_tile) and _board.is_tile_free(tile):
			# Match bem-sucedido! Desselecionar e animar
			prev_tile.is_selected = false
			_selected_tile = null
			_pairs_matched += 1
			_update_status()
			
			# Animação de match (encolhe + fade)
			prev_tile.play_match_animation()
			await tile.play_match_animation()
			
			# Registrar no board
			_board.record_match(prev_tile, tile)
			
			# Atualizar visuais
			_board.update_tile_states()
			
			# Checar vitória
			if _board.is_won():
				await get_tree().create_timer(0.3).timeout
				_show_win_popup()
			elif not _board.has_moves():
				await get_tree().create_timer(0.3).timeout
				_show_no_moves_popup()
		else:
			# Não é match — trocar seleção
			prev_tile.is_selected = false
			tile.is_selected = true
			_selected_tile = tile


func _update_status() -> void:
	@warning_ignore("integer_division")
	var total_pairs := _board.tiles.size() / 2
	_status_label.text = "Pares: %d / %d" % [_pairs_matched, total_pairs]


# ─── Botões ─────────────────────────────────────────────────────────

func _on_reset() -> void:
	"""Resetar o nível (novo jogo)."""
	_start_game()


func _on_hint() -> void:
	"""Destacar uma dica por 2 segundos."""
	var hint = _board.find_hint()
	if hint != null:
		var t1: MahjongTile = hint[0]
		var t2: MahjongTile = hint[1]
		_board.highlight_hint(t1, t2)
		await get_tree().create_timer(2.0).timeout
		_board.clear_selection()
	else:
		_show_no_moves_popup()


func _on_shuffle() -> void:
	"""Embaralhar as peças restantes."""
	_selected_tile = null
	_board.shuffle_remaining()


# ─── Popups ─────────────────────────────────────────────────────────

func _show_win_popup() -> void:
	_dim_overlay.visible = true
	_win_popup.visible = true
	_set_hud_disabled(true)


func _show_no_moves_popup() -> void:
	_dim_overlay.visible = true
	_no_moves_popup.visible = true
	_set_hud_disabled(true)

func _show_pause_popup() -> void:
	_dim_overlay.visible = true
	_pause_popup.visible = true
	_set_hud_disabled(true)

func _hide_popups() -> void:
	_dim_overlay.visible = false
	_win_popup.visible = false
	_no_moves_popup.visible = false
	_pause_popup.visible = false
	_set_hud_disabled(false)

func _set_hud_disabled(disabled: bool) -> void:
	if is_instance_valid(_btn_hint):
		_btn_hint.disabled = disabled
	if is_instance_valid(_btn_menu):
		_btn_menu.disabled = disabled


# ─── Faxina de UI (mouse_filter) ───────────────────────────────────

func _set_ui_mouse_filters(node: Node) -> void:
	"""Percorre todos os Control Nodes e define mouse_filter = IGNORE
	para tudo que NÃO é botão. Impede que fundos transparentes da UI
	bloqueiem toques nas peças do tabuleiro."""
	for child in node.get_children():
		if child is BaseButton:
			continue  # Botões devem permanecer clicáveis
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_ui_mouse_filters(child)
