## GameManager.gd — Controller principal do Mahjong Solitaire (Godot 4.x)
##
## Orquestra seleção, matching, botões (Reset/Hint/Shuffle), popups e status.
## Tradução direta do main.py/MahjongApp.

class_name GameManager
extends Control

## Referências aos nós da UI.
@onready var _board: BoardManager = $VBox/BoardContainer/BoardManager
@onready var _status_label: Label = $VBox/StatusLabel
@onready var _btn_reset: Button = $VBox/ButtonBar/ResetBtn
@onready var _btn_hint: Button = $VBox/ButtonBar/HintBtn
@onready var _btn_shuffle: Button = $VBox/ButtonBar/ShuffleBtn
@onready var _win_popup: PanelContainer = $WinPopup
@onready var _no_moves_popup: PanelContainer = $NoMovesPopup

## Estado da seleção.
var _selected_tile: MahjongTile = null
var _pairs_matched: int = 0

# ─── Lifecycle ──────────────────────────────────────────────────────

func _ready() -> void:
	# Conectar botões
	_btn_reset.pressed.connect(_on_reset)
	_btn_hint.pressed.connect(_on_hint)
	_btn_shuffle.pressed.connect(_on_shuffle)
	
	# Conectar sinal do board
	_board.tile_pressed.connect(_on_tile_pressed)
	
	# Conectar botões dos popups
	$WinPopup/VBox/PlayAgainBtn.pressed.connect(func():
		_win_popup.visible = false
		_start_game()
	)
	$NoMovesPopup/VBox/BtnBar/ShuffleBtn2.pressed.connect(func():
		_no_moves_popup.visible = false
		_on_shuffle()
	)
	$NoMovesPopup/VBox/BtnBar/ResetBtn2.pressed.connect(func():
		_no_moves_popup.visible = false
		_start_game()
	)
	
	# Esconder popups
	_win_popup.visible = false
	_no_moves_popup.visible = false
	
	# Garantir que nós de UI não bloqueiem toques nas peças
	_set_ui_mouse_filters(self)
	
	# Iniciar primeiro jogo com delay para layout estar pronto
	await get_tree().create_timer(0.3).timeout
	_start_game()


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
		
		if _board.try_match(prev_tile, tile):
			# Match bem-sucedido!
			prev_tile.is_selected = false
			_selected_tile = null
			_pairs_matched += 1
			_update_status()
			
			# Atualizar visuais
			_board.update_tile_states()
			
			# Checar vitória
			if _board.is_won():
				await get_tree().create_timer(0.4).timeout
				_show_win_popup()
			elif not _board.has_moves():
				await get_tree().create_timer(0.4).timeout
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
	_win_popup.visible = true


func _show_no_moves_popup() -> void:
	_no_moves_popup.visible = true


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
