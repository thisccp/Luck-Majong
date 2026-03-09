## GameManager.gd — Controller principal do Mahjong Solitaire (Godot 4.x)
##
## Sistema de Inventário Zen: clique na peça → voa para slot → match automático.
## Game Over quando 4 slots cheios sem par. Reviver até 3×.

class_name GameManager
extends Control

# ─── UI existente ────────────────────────────────────────────────────

@onready var _board: BoardManager = $BoardContainer/BoardManager
@onready var _btn_shuffle: TextureButton = $UILayer/VBox/BottomMargin/ActionButtonsHBox/ShuffleBtn
@onready var _btn_hint: TextureButton = $UILayer/VBox/BottomMargin/ActionButtonsHBox/HintBtn
@onready var _btn_undo: TextureButton = $UILayer/VBox/BottomMargin/ActionButtonsHBox/UndoBtn
@onready var _btn_menu: TextureButton = $UILayer/MenuBtn
@onready var _dim_overlay: ColorRect = $UILayer/DimOverlay
@onready var _win_popup: TextureRect = $UILayer/WinPopup
@onready var _pause_popup: TextureRect = $UILayer/PausePopup

# ─── Inventário (4 Slots) ───────────────────────────────────────────

const MAX_INVENTORY := 4
var _inventory: Array[MahjongTile] = []
var _inventory_slots: Array[Control] = []
var _inventory_bar: HBoxContainer
var _pending_animations: int = 0
var _fading_animations: int = 0
## Reserva imediata de slot: Tile → índice do slot reservado
var _slot_assignments: Dictionary = {}
## Tiles em voo (mid-flight): Tile → true
var _tiles_in_flight: Dictionary = {}

# ─── Reviver ─────────────────────────────────────────────────────────

var revive_limit: int = 3

# ─── Game Over Popup (criado via código) ─────────────────────────────

var _game_over_popup: PanelContainer
var _revive_btn: Button
var _restart_go_btn: Button
var _go_tiles_hbox: HBoxContainer

# ─── Undo ────────────────────────────────────────────────────────────

var undo_charges: int = 3

# ─── Hint & Shuffle ───────────────────────────────────────────────────

var hint_charges: int = 4
var is_hint_active: bool = false
var active_hint_cat_id: int = -1

var shuffle_charges: int = 2

# ─── Estado ──────────────────────────────────────────────────────────

var _pairs_matched: int = 0
var _game_paused: bool = false

# ─── Ads System ──────────────────────────────────────────────────────
var ad_requester: String = ""
@onready var _ad_popup: ColorRect = $UILayer/AdPopup
var _hint_label: Label
var _undo_label: Label
var _shuffle_label: Label

# ─── Progressão ──────────────────────────────────────────────────────
var current_level: int = 1

# ─── Level Intro ─────────────────────────────────────────────────────
var is_input_locked: bool = false
var _level_intro_overlay: ColorRect
var _level_label: Label
var _warning_label: Label


# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_btn_shuffle.pressed.connect(_on_shuffle_pressed)
	_btn_hint.pressed.connect(_on_hint_pressed)
	_btn_undo.pressed.connect(_on_undo_pressed)
	_btn_menu.pressed.connect(_show_pause_popup)
	_board.tile_pressed.connect(_on_tile_pressed)
	
	_build_power_labels()
	
	_update_undo_button()
	_update_hint_button()
	_update_shuffle_button()

	_build_inventory_bar()
	_build_game_over_popup()
	_build_level_intro()

	_ad_popup.refill_requested.connect(_on_ad_reward_claimed)
	_ad_popup.popup_closed.connect(func():
		_ad_popup.hide()
		_game_paused = false
	)

	# ── Popups existentes ──
	$UILayer/WinPopup/PlayAgainBtn.pressed.connect(func():
		$UILayer/WinPopup/PlayAgainBtn.disabled = true
		$UILayer/WinPopup/HomeBtn.disabled = true
		if _win_popup:
			var tween = create_tween()
			tween.tween_property(_win_popup, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.finished.connect(func():
				_hide_popups()
				_start_game()
			)
		else:
			_hide_popups()
			_start_game()
	)
	$UILayer/WinPopup/HomeBtn.pressed.connect(func():
		_hide_popups()
		get_tree().quit()
	)
	$UILayer/PausePopup/SoundToggle.toggled.connect(func(bp: bool):
		print("Sound toggled: ", bp)
	)
	$UILayer/PausePopup/RestartBtn.pressed.connect(func():
		_hide_popups()
		_restart_level()
	)
	$UILayer/PausePopup/ClosePauseBtn.pressed.connect(func():
		_hide_popups()
	)

	_hide_popups()
	_set_ui_mouse_filters(self)

	await get_tree().create_timer(0.3).timeout
	_load_background()
	_start_game()


func _load_background() -> void:
	var bg_node = get_node_or_null("Background")
	if bg_node == null or not (bg_node is TextureRect):
		return

	var bg_path := "res://assets/bg/bg_zen.png"
	if ResourceLoader.exists(bg_path):
		var bg_tex := load(bg_path) as Texture2D
		if bg_tex:
			bg_node.texture = bg_tex
			bg_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			return

	# Fallback: gradiente zen
	var img_h := 256
	var img_w := 4
	var img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	var color_top := Color(0.831, 0.902, 0.831, 1.0)
	var color_bot := Color(0.749, 0.835, 0.784, 1.0)
	for y in range(img_h):
		var t: float = float(y) / float(img_h - 1)
		var col: Color = color_top.lerp(color_bot, t)
		for x in range(img_w):
			img.set_pixel(x, y, col)
	bg_node.texture = ImageTexture.create_from_image(img)


# ═══════════════════════════════════════════════════════════════════════
# LEVEL INTRO UI
# ═══════════════════════════════════════════════════════════════════════

func _build_level_intro() -> void:
	_level_intro_overlay = ColorRect.new()
	_level_intro_overlay.name = "LevelIntroOverlay"
	_level_intro_overlay.color = Color(0, 0, 0, 0.6)
	_level_intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_level_intro_overlay.visible = false
	_level_intro_overlay.z_index = 4096 

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_intro_overlay.add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_container.add_child(vbox)

	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 64)
	_level_label.add_theme_color_override("font_color", Color.WHITE)
	_level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_level_label.add_theme_constant_override("outline_size", 8)
	vbox.add_child(_level_label)

	_warning_label = Label.new()
	_warning_label.text = "NÍVEL DIFÍCIL!"
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.add_theme_font_size_override("font_size", 42)
	_warning_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) 
	_warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_warning_label.add_theme_constant_override("outline_size", 6)
	_warning_label.visible = false
	vbox.add_child(_warning_label)

	$UILayer.add_child(_level_intro_overlay)


func play_level_intro(level: int, is_hard_level: bool) -> void:
	is_input_locked = true
	_level_intro_overlay.modulate.a = 0.0
	_level_intro_overlay.visible = true
	
	_level_label.text = "Nível %d" % level
	if is_hard_level:
		_level_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		_warning_label.visible = true
	else:
		_level_label.add_theme_color_override("font_color", Color.WHITE)
		_warning_label.visible = false
		
	var tween = create_tween()
	tween.tween_property(_level_intro_overlay, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(_level_intro_overlay, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		_level_intro_overlay.visible = false
		is_input_locked = false
	)


# ═══════════════════════════════════════════════════════════════════════
# INVENTORY BAR UI
# ═══════════════════════════════════════════════════════════════════════

func _build_inventory_bar() -> void:
	# Container principal centralizado
	var bar_container := CenterContainer.new()
	bar_container.name = "InventoryBarContainer"
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox = $UILayer/VBox
	vbox.add_child(bar_container)
	vbox.move_child(bar_container, 1)   # Após TopMargin(0), antes do Spacer

	# Imagem da barra de madeira
	var slots_tex: Texture2D = load("res://assets/tiles/slots.png")
	_inventory_bar = HBoxContainer.new()  # Reutilizar var para referência
	_inventory_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar_img := TextureRect.new()
	bar_img.name = "SlotsBar"
	bar_img.texture = slots_tex
	bar_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bar_img.custom_minimum_size = Vector2(460, 180)  # Forçado maior (460x180) para acomodar melhor a proporção parruda
	bar_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(bar_img)

	# ── Calcular posições dos bolsos dentro da imagem ──
	# slots.png: moldura de madeira com 4 bolsos uniformemente espaçados
	# Proporções dos centros dos bolsos (medidas da imagem):
	#   Bolso 1 centro X ≈ 15.8%   Bolso 2 ≈ 37.2%   Bolso 3 ≈ 58.7%   Bolso 4 ≈ 80.2%
	#   Centro Y de todos ≈ 50%
	# Tamanho de cada bolso: ~19% W × 63% H
	const POCKET_X_RATIOS: Array = [0.180, 0.394, 0.609, 0.824]
	const POCKET_Y_RATIO: float = 0.50
	const POCKET_W_RATIO: float = 0.19
	const POCKET_H_RATIO: float = 0.63

	# Criar marcadores invisíveis de posição dos bolsos
	# As posições finais serão recalculadas em _get_slot_center()
	for i in range(MAX_INVENTORY):
		var slot_marker := Control.new()
		slot_marker.name = "SlotMarker%d" % i
		slot_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_marker.custom_minimum_size = Vector2.ZERO
		# Guardar proporções como metadata
		slot_marker.set_meta("pocket_x_ratio", POCKET_X_RATIOS[i])
		slot_marker.set_meta("pocket_y_ratio", POCKET_Y_RATIO)
		slot_marker.set_meta("pocket_w_ratio", POCKET_W_RATIO)
		slot_marker.set_meta("pocket_h_ratio", POCKET_H_RATIO)
		bar_img.add_child(slot_marker)
		_inventory_slots.append(slot_marker)

	# Guardar referência ao bar_img para cálculos de posição
	set_meta("slots_bar_img", bar_img)

			
func _get_slot_center(slot_index: int) -> Vector2:
	"""Calcula o centro do bolso na tela baseado no tamanho atual do TextureRect."""
	var bar_img: TextureRect = get_meta("slots_bar_img")
	if bar_img == null:
		return Vector2.ZERO

	var slot_marker: Control = _inventory_slots[slot_index]
	var px: float = slot_marker.get_meta("pocket_x_ratio")
	var py: float = slot_marker.get_meta("pocket_y_ratio")

	# Tamanho real renderizado da imagem (pode ter padding por aspect ratio)
	var bar_size: Vector2 = bar_img.size
	var tex_size: Vector2 = Vector2(bar_img.texture.get_width(), bar_img.texture.get_height())
	var aspect: float = tex_size.x / tex_size.y
	var rendered_w: float = minf(bar_size.x, bar_size.y * aspect)
	var rendered_h: float = rendered_w / aspect
	var offset_x: float = (bar_size.x - rendered_w) / 2.0
	var offset_y: float = (bar_size.y - rendered_h) / 2.0

	var local_x: float = offset_x + rendered_w * px
	var local_y: float = offset_y + rendered_h * py

	return bar_img.global_position + Vector2(local_x, local_y)


func _get_slot_pocket_size(slot_index: int) -> Vector2:
	"""Retorna o tamanho do bolso em pixels na tela."""
	var bar_img: TextureRect = get_meta("slots_bar_img")
	if bar_img == null:
		return Vector2(58, 78)

	var slot_marker: Control = _inventory_slots[slot_index]
	var pw: float = slot_marker.get_meta("pocket_w_ratio")
	var ph: float = slot_marker.get_meta("pocket_h_ratio")

	var bar_size: Vector2 = bar_img.size
	var tex_size: Vector2 = Vector2(bar_img.texture.get_width(), bar_img.texture.get_height())
	var aspect: float = tex_size.x / tex_size.y
	var rendered_w: float = minf(bar_size.x, bar_size.y * aspect)
	var rendered_h: float = rendered_w / aspect

	return Vector2(rendered_w * pw, rendered_h * ph)


# ═══════════════════════════════════════════════════════════════════════
# GAME OVER POPUP (programático)
# ═══════════════════════════════════════════════════════════════════════

func _build_game_over_popup() -> void:
	_game_over_popup = PanelContainer.new()
	_game_over_popup.name = "GameOverPopup"
	_game_over_popup.visible = false
	_game_over_popup.custom_minimum_size = Vector2(340, 400)

	# Centralizar na tela
	_game_over_popup.anchor_left = 0.5
	_game_over_popup.anchor_top = 0.5
	_game_over_popup.anchor_right = 0.5
	_game_over_popup.anchor_bottom = 0.5
	_game_over_popup.offset_left = -170
	_game_over_popup.offset_top = -200
	_game_over_popup.offset_right = 170
	_game_over_popup.offset_bottom = 200
	_game_over_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_game_over_popup.grow_vertical = Control.GROW_DIRECTION_BOTH

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.10, 0.08, 0.95)
	panel_style.set_corner_radius_all(20)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.8, 0.6, 0.3, 0.6)
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 28
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 28
	_game_over_popup.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	_game_over_popup.add_child(vbox)

	# Título
	var title = Label.new()
	title.text = "😿 Game Over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.6))
	vbox.add_child(title)

	# Container para as 4 estampas bloqueadoras
	_go_tiles_hbox = HBoxContainer.new()
	_go_tiles_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_go_tiles_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(_go_tiles_hbox)

	# Botão estilos
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.44, 0.35, 0.26, 1)
	btn_style.set_corner_radius_all(12)
	var btn_pressed: StyleBoxFlat = StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.33, 0.25, 0.18, 1)
	btn_pressed.set_corner_radius_all(12)
	var btn_hover: StyleBoxFlat = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.52, 0.43, 0.33, 1)
	btn_hover.set_corner_radius_all(12)
	var btn_disabled: StyleBoxFlat = StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.3, 0.25, 0.2, 0.5)
	btn_disabled.set_corner_radius_all(12)

	# Reviver
	_revive_btn = Button.new()
	_revive_btn.text = "🔄 Reviver (%d)" % revive_limit
	_revive_btn.custom_minimum_size = Vector2(230, 54)
	_revive_btn.add_theme_font_size_override("font_size", 22)
	_revive_btn.add_theme_stylebox_override("normal", btn_style)
	_revive_btn.add_theme_stylebox_override("pressed", btn_pressed)
	_revive_btn.add_theme_stylebox_override("hover", btn_hover)
	_revive_btn.add_theme_stylebox_override("disabled", btn_disabled)
	_revive_btn.pressed.connect(_on_revive)
	vbox.add_child(_revive_btn)

	# Reiniciar
	_restart_go_btn = Button.new()
	_restart_go_btn.text = "🔁 Reiniciar"
	_restart_go_btn.custom_minimum_size = Vector2(230, 54)
	_restart_go_btn.add_theme_font_size_override("font_size", 22)
	_restart_go_btn.add_theme_stylebox_override("normal", btn_style)
	_restart_go_btn.add_theme_stylebox_override("pressed", btn_pressed)
	_restart_go_btn.add_theme_stylebox_override("hover", btn_hover)
	_restart_go_btn.pressed.connect(func():
		_hide_popups()
		_restart_level()
	)
	vbox.add_child(_restart_go_btn)

	$UILayer.add_child(_game_over_popup)


# ═══════════════════════════════════════════════════════════════════════
# CONTROLE DE JOGO
# ═══════════════════════════════════════════════════════════════════════

func _start_game() -> void:
	# Limpar peças que foram reparentadas ao UILayer
	for tile in _inventory:
		if is_instance_valid(tile):
			tile.queue_free()
	_pairs_matched = 0
	_inventory.clear()
	_slot_assignments.clear()
	_tiles_in_flight.clear()
	_pending_animations = 0
	_fading_animations = 0
	is_hint_active = false
	active_hint_cat_id = -1
	_update_undo_button()
	_update_hint_button()
	_board.new_game(current_level, false)
	
	var profile = _board.get_level_profile(current_level)
	play_level_intro(current_level, profile.get("is_hard_level", false))


func _restart_level() -> void:
	"""Reinicia exatamente o meso level sem resetar power-ups."""
	for tile in _inventory:
		if is_instance_valid(tile):
			tile.queue_free()
	_pairs_matched = 0
	_inventory.clear()
	_slot_assignments.clear()
	_tiles_in_flight.clear()
	_pending_animations = 0
	_fading_animations = 0
	is_hint_active = false
	active_hint_cat_id = -1
	_board.new_game(current_level, true)
	
	var profile = _board.get_level_profile(current_level)
	play_level_intro(current_level, profile.get("is_hard_level", false))


func _on_tile_pressed(tile: MahjongTile) -> void:
	"""Clique na peça → adicionar ao inventário (sem bloqueio)."""
	if _game_paused or is_input_locked:
		return
	if tile.is_in_inventory or tile.is_matched:
		return
	# Usar contagem EFETIVA: slots que realmente estão ocupados logicamente
	if _effective_slot_count() >= MAX_INVENTORY:
		return
	_add_to_inventory(tile)


# ═════════════════════════════════════════════════════════════════════
# INVENTÁRIO — LÓGICA PRINCIPAL
# ═════════════════════════════════════════════════════════════════════

func _add_to_inventory(tile: MahjongTile) -> void:
	# Reservar slot IMEDIATAMENTE (antes de qualquer animação)
	var slot_index := _next_free_slot()

	# Guardar dados originais para revive
	tile.original_global_pos = tile.global_position
	tile.original_z_index = tile.z_index
	tile.set_meta("original_position", tile.position)
	tile.set_meta("original_scale", tile.scale)
	tile.is_in_inventory = true
	tile.is_selected = false

	_inventory.append(tile)
	_slot_assignments[tile] = slot_index
	
	# Gravar histórico local de posição na grade EXATAMENTE quando foi adicionado ao slot
	_board.move_history.append({
		"tile": tile,
		"pos_x": tile.grid_pos.x,
		"pos_y": tile.grid_pos.y,
		"pos_z": tile.grid_pos.z
	})

	# Atualizar tabuleiro (peças que ficaram livres)
	_board.update_tile_states()

	# Registrar tile em voo ANTES de iniciar animação
	_tiles_in_flight[tile] = true

	# Fire-and-forget: animação não bloqueia cliques
	_pending_animations += 1
	_animate_tile_to_slot(tile, slot_index)

	# EAGER: detectar par IMEDIATAMENTE no mesmo frame do clique
	# Isso libera slots logicamente antes de qualquer animação terminar
	_try_instant_pair_resolution()


func _animate_tile_to_slot(tile: MahjongTile, slot_index: int) -> void:
	"""Anima a peça voando ao slot. Ao pousar, dispara match visual se aplicável."""
	await _fly_tile_to_slot(tile, slot_index)

	if not is_instance_valid(tile):
		_tiles_in_flight.erase(tile)
		_pending_animations -= 1
		return

	# Tile pousou — remover do registro de voo
	_tiles_in_flight.erase(tile)

	# Checar se este tile faz parte de um par pendente de animação visual
	if tile.has_meta("matched_partner"):
		tile.set_meta("match_landed", true)
		var partner: MahjongTile = tile.get_meta("matched_partner")
		if is_instance_valid(partner) and partner.has_meta("match_landed") and partner.get_meta("match_landed"):
			# Ambos pousaram → disparar animação de match por IMPACTO
			_executar_animacao_fantasma(tile, partner)
	elif tile.is_in_inventory:
		# Tile normal (não matched) — finalizar no UI
		_reparent_tile_to_ui(tile)

	_pending_animations -= 1

	# Quando todas as animações de voo terminaram, checar game over
	if _pending_animations <= 0:
		_check_game_over()


func _check_game_over() -> void:
	"""Checa game over (pares já foram resolvidos no clique)."""
	if _inventory.size() >= MAX_INVENTORY:
		_show_game_over_popup()


func _fly_tile_to_slot(tile: MahjongTile, slot_index: int) -> void:
	"""Anima a peça voando do tabuleiro ao bolso, POR CIMA da moldura."""
	# Converter posição atual do board para coordenadas de tela, LENDO a escala antes do reparent
	var start_screen_pos: Vector2 = tile.global_position
	var start_scale: Vector2 = tile.global_scale

	# Reparentar ao UILayer ANTES do voo (para ficar acima do slots.png)
	if tile.get_parent() == _board:
		_board.remove_child(tile)
		$UILayer.add_child(tile)

	# Remover a sombra estrutural assim que a peça "levantar voo" para a UI limpa
	if tile.has_node("DropShadow"):
		tile.get_node("DropShadow").visible = false

	tile.z_index = 4000
	tile.position = start_screen_pos
	tile.scale = start_scale # Preservar proporção do tabuleiro imediatamente após reparentar!

	# Posição-alvo: centro do bolso FINAL TEÓRICO (slot reservado)
	var target_pos: Vector2 = _get_slot_center(slot_index)

	# Escala-alvo: Reduzido a 80% da escala perfeita do tabuleiro para manter consistência sem deformar lateralmente.
	var target_scale := _board.scale * 0.80

	# Tween vinculado ao TILE — independente de qualquer outro tween
	var tween := tile.create_tween()
	tween.set_parallel(true)
	tween.tween_property(tile, "position", target_pos, 0.35)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "scale", target_scale, 0.35)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	await tween.finished


func _reparent_tile_to_ui(tile: MahjongTile) -> void:
	"""Finaliza a peça no UILayer após o voo (z_index + reorganização)."""
	var current_idx := _inventory.find(tile)
	if current_idx < 0 or current_idx >= MAX_INVENTORY:
		return

	# Apenas finalizar color (z_index é gerenciado dinamicamente em _reorganize_slots)
	if tile.is_hinted:
		tile.play_hint_glow()
	else:
		tile.modulate = Color.WHITE

	# Reorganizar TODAS as peças para garantir consistência
	if _fading_animations == 0:
		_reorganize_slots()


func _find_inventory_pair() -> Variant:
	"""Retorna [idx1, idx2] se houver par no inventário, ou null."""
	for i in range(_inventory.size()):
		for j in range(i + 1, _inventory.size()):
			if _inventory[i].cat_id == _inventory[j].cat_id:
				return [i, j]
	return null


func _next_free_slot() -> int:
	"""Retorna o menor índice de slot ainda não reservado."""
	var used: Array = _slot_assignments.values()
	for i in range(MAX_INVENTORY):
		if i not in used:
			return i
	return _inventory.size()


func _effective_slot_count() -> int:
	"""Conta slots REALMENTE ocupados (não conta pares já resolvidos)."""
	return _slot_assignments.size()


func _recalculate_slot_assignments() -> void:
	"""Remapeia slots sequencialmente após remoção de par."""
	_slot_assignments.clear()
	for i in range(_inventory.size()):
		_slot_assignments[_inventory[i]] = i


func _try_instant_pair_resolution() -> void:
	"""Detecta e resolve pares SINCRONAMENTE no frame do clique.
	Libera slots imediatamente, permitindo cliques seguintes sem delay.
	A animação visual de match é ADIADA até ambos os tiles pousarem."""
	var pair = _find_inventory_pair()
	while pair != null:
		var t1: MahjongTile = _inventory[pair[0]]
		var t2: MahjongTile = _inventory[pair[1]]

		# ── Liberação lógica IMEDIATA (mesmo frame) ──
		t1.is_in_inventory = false
		t2.is_in_inventory = false
		t1.is_matched = true
		t2.is_matched = true
		_board.record_match(t1, t2)
		_pairs_matched += 1

		# Desabilitar colisão imediatamente (não bloqueiam novos tiles)
		t1.input_pickable = false
		t2.input_pickable = false

		var indices: Array = [pair[0], pair[1]]
		indices.sort()
		_inventory.remove_at(indices[1])
		_inventory.remove_at(indices[0])

		_slot_assignments.erase(t1)
		_slot_assignments.erase(t2)
		_recalculate_slot_assignments()
		
		# Limpeza visual de Hint Órfão:
		# Se o jogador usou uma peça não-sugerida mas do mesmo tipo da hint, varre e limpa
		_board.clear_hint_for_type(t1.cat_id)
		
		# Limpa o estado global do Hint para permitir novos cliques
		if is_hint_active and active_hint_cat_id == t1.cat_id:
			is_hint_active = false
			active_hint_cat_id = -1
		
		# ── Limpeza do Histórico (Bug de múltiplos cliques no Undo) ──
		for i in range(_board.move_history.size() - 1, -1, -1):
			var record = _board.move_history[i]
			if record["tile"] == t1 or record["tile"] == t2:
				_board.move_history.remove_at(i)

		# A reorganização visual (_reorganize_slots) foi removida daqui para não deslizar
		# os tiles enquanto a animação do match atual não desaparecer!

		# ── Gatilho visual por IMPACTO (adiado até ambos pousarem) ──
		var t1_landed := not _tiles_in_flight.has(t1)
		var t2_landed := not _tiles_in_flight.has(t2)

		t1.set_meta("matched_partner", t2)
		t2.set_meta("matched_partner", t1)
		t1.set_meta("match_landed", t1_landed)
		t2.set_meta("match_landed", t2_landed)

		if t1_landed and t2_landed:
			# Ambos já pousaram → animação imediata
			_executar_animacao_fantasma(t1, t2)

		# Atualizar board (peças que ficaram livres)
		_board.update_tile_states()

		# Checar se há outro par (ex: AABB clicados em sequência)
		pair = _find_inventory_pair()

	# Checar vitória após resolver todos os pares
	if _board.is_won():
		await get_tree().create_timer(0.3).timeout
		_show_win_popup()
	elif _board.active_tiles().is_empty() and _inventory.is_empty():
		await get_tree().create_timer(0.3).timeout
		_show_win_popup()


func _executar_animacao_fantasma(peca_a: MahjongTile, peca_b: MahjongTile) -> void:
	"""Coreografia Visual Independente (A Peça Fantasma)
	Animação de match: desliza suavemente para cima (Y-=50) e fading,
	renderizando por cima de tudo para que a reorganização do slot ocorra limpa por baixo."""
	
	# Garantir que colisão está desabilitada e parar hint glow durante a animação
	for t in [peca_a, peca_b]:
		t.input_pickable = false
		t.stop_hint_glow()
		if t.has_node("CollisionShape"):
			t.get_node("CollisionShape").set_deferred("disabled", true)
			
	# Passo A: Elevar z_index para o céu
	peca_a.z_index = 4000
	peca_b.z_index = 4000

	_fading_animations += 1
	
	# Chamar a reorganização dos slots IMEDIATAMENTE (antes da animação de saída)
	# Assim as peças já começam a deslizar debaixo do match ativo
	if _fading_animations == 1:
		_reorganize_slots()

	# Passo C: Iniciar um Tween que faz ambas as peças subirem e desaparecerem
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)

	# Peca A
	fade_tween.tween_property(peca_a, "position:y", peca_a.position.y - 50.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(peca_a, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Peca B
	fade_tween.tween_property(peca_b, "position:y", peca_b.position.y - 50.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(peca_b, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Passo D: Chame queue_free() apenas ao final desta animação
	fade_tween.finished.connect(func():
		if is_instance_valid(peca_a):
			peca_a.queue_free()
		if is_instance_valid(peca_b):
			peca_b.queue_free()
		
		_fading_animations -= 1
		
		# A reorganização baseada em _fading_animations == 0 final foi movida pro início,
		# mas caso haja múltiplas intercaladas, garantimos aqui também.
		if _fading_animations == 0:
			await get_tree().create_timer(0.05).timeout
			if _fading_animations == 0:
				_reorganize_slots()
	)


# _remove_inventory_pair substituído por _try_instant_pair_resolution()


func _reorganize_slots() -> void:
	"""Desliza peças restantes para os bolsos corretos (efeito pilha)."""
	for i in range(_inventory.size()):
		var tile: MahjongTile = _inventory[i]

		# Só reposicionar peças já no UILayer (não as que ainda estão voando)
		if tile.get_parent() == _board:
			continue

		var pocket_center: Vector2 = _get_slot_center(i)
		
		# Define o z_index dinâmico baseado na posição do slot (efeito cascata)
		# Peças mais à esquerda (índice menor) recebem z_index menor (ex: 50, 51, 52...)
		# Garantindo que a peça que chega da direita e desliza para a esquerda passe POR BAIXO da peça que já estava na direita.
		# Espera, a regra visual desejada: quem está no slot 1 (esq) fica por baixo de quem tá no slot 2 (dir)? 
		# "que a peça que esta chegando em um slot que estava ocupada [ao deslizar da direita pra esq.], vá por baixo da peça que ja estava lá"
		# Se as peças deslizam em bando para a esquerda, elas devem ir sucessivamente descendo de camada.
		# Quem está mais BEM POSICIONADO à esquerda ganha MENOR z_index.
		tile.z_index = 50 + i

		# Só animar se a peça não está já na posição correta
		if tile.position.distance_to(pocket_center) > 2.0:
			# Tween vinculado ao TILE — independente dos outros tiles
			var slide := tile.create_tween()
			slide.tween_property(tile, "position", pocket_center, 0.2)\
				.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		else:
			tile.position = pocket_center


# ═══════════════════════════════════════════════════════════════════════
# GAME OVER & REVIVE
# ═══════════════════════════════════════════════════════════════════════

func _show_game_over_popup() -> void:
	_game_paused = true
	_dim_overlay.visible = true
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_over_popup.visible = true
	_set_hud_disabled(true)

	# Desligar dicas pendentes para que não brilhem no Game Over
	is_hint_active = false
	active_hint_cat_id = -1
	_board.clear_selection()
	for tile in _inventory:
		if is_instance_valid(tile):
			tile.stop_hint_glow()

	# Deixar peças do inventário cinzas
	for tile in _inventory:
		if is_instance_valid(tile):
			tile.modulate = Color(0.5, 0.5, 0.5, 1.0)

	# Mostrar as 4 peças bloqueadoras (base + gato)
	for child in _go_tiles_hbox.get_children():
		child.queue_free()

	var tile_base_tex: Texture2D = load("res://assets/tiles/tile_base.png")
	for tile in _inventory:
		var container := Control.new()
		container.custom_minimum_size = Vector2(50, 68)
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var base_rect := TextureRect.new()
		base_rect.texture = tile_base_tex
		base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		base_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Em vez de SCALE para não amassar as peças!
		base_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		base_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(base_rect)

		# Sticker do gato por cima
		var cat_rect := TextureRect.new()
		cat_rect.texture = tile._create_cat_atlas_texture(tile.cat_id)
		cat_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cat_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cat_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		cat_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(cat_rect)

		_go_tiles_hbox.add_child(container)

	# Atualizar botão reviver
	_update_revive_button()


func _on_revive() -> void:
	if revive_limit <= 0:
		return

	revive_limit -= 1
	_hide_popups()

	# Devolver todas as peças voando de volta ao tabuleiro
	var tiles_to_revive: Array[MahjongTile] = _inventory.duplicate()
	_inventory.clear()
	_slot_assignments.clear()
	
	# Quando ressuscitamos, limpar o histórico já que voltaram pro board.
	# Retira os N últimos items equivalentes ao tamanho do inventário do move_history.
	for i in range(tiles_to_revive.size()):
		if _board.move_history.size() > 0:
			_board.move_history.pop_back()

	for tile in tiles_to_revive:
		# Posição atual na tela (UILayer coords)
		var current_screen_pos: Vector2 = tile.position
		var current_scale: Vector2 = tile.scale

		# Reparentar de volta ao BoardManager
		if tile.get_parent() != _board:
			tile.get_parent().remove_child(tile)
			_board.add_child(tile)

		tile.is_in_inventory = false
		tile.is_matched = false
		tile.visible = true
		
		if tile.is_hinted:
			tile.play_hint_glow()
		else:
			tile.modulate = Color.WHITE
			
		tile.z_index = 4000  # Acima de tudo durante o voo

		# Converter posição da tela para coordenadas locais do board
		var start_local: Vector2 = (current_screen_pos - _board.global_position) / _board.scale
		tile.position = start_local
		tile.scale = current_scale

		# Destino: posição original no board
		var target_pos: Vector2 = tile.get_meta("original_position") if tile.has_meta("original_position") else start_local
		var target_z: int = tile.get_calculated_z_index()

		# Garantir que a peça não seja tocada durante o voo
		if tile.has_node("CollisionShape"):
			tile.get_node("CollisionShape").set_deferred("disabled", true)

		# Animar voo de volta
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(tile, "position", target_pos, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(tile, "scale", Vector2.ONE, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		
		# Chain para o que acontece quando aterra
		tween.chain().tween_callback(func():
			if is_instance_valid(tile):
				tile.z_index = target_z
				if tile.has_node("CollisionShape"):
					tile.get_node("CollisionShape").set_deferred("disabled", false)
				# Recalcular bloqueios para garantir que ela fica livre ou bloqueada corretamente
				_board.update_tile_states()
		)


func _update_revive_button() -> void:
	_revive_btn.text = "🔄 Reviver (%d)" % revive_limit
	if revive_limit <= 0:
		_revive_btn.disabled = true
		_revive_btn.modulate = Color(1, 1, 1, 0.4)
	else:
		_revive_btn.disabled = false
		_revive_btn.modulate = Color.WHITE


# ═══════════════════════════════════════════════════════════════════════
# BOTÕES EXISTENTES
# ═══════════════════════════════════════════════════════════════════════

func _on_undo_pressed() -> void:
	if _game_paused or _tiles_in_flight.size() > 0 or _fading_animations > 0 or _pending_animations > 0:
		return
		
	if undo_charges <= 0:
		ad_requester = "undo"
		_show_ad_popup()
		return
		
	if _board.move_history.size() == 0:
		return
		
	var valid_move = null
	while _board.move_history.size() > 0:
		var move = _board.move_history.pop_back()
		if move["tile"] != null and is_instance_valid(move["tile"]) and not move["tile"].is_queued_for_deletion():
			var t: MahjongTile = move["tile"]
			if t.is_in_inventory and not t.is_matched:
				valid_move = move
				break
				
	if valid_move == null:
		return
		
	var tile: MahjongTile = valid_move["tile"]

	# Reduzir card e UI
	undo_charges -= 1
	_update_undo_button()
	
	# Limpar a peça do inventário logicamente
	_inventory.erase(tile)
	_slot_assignments.erase(tile)
	_recalculate_slot_assignments()
	_reorganize_slots()
	
	# Usar posição global para não relocar abruptamente na mudança de parent
	var g_pos = tile.global_position
	var g_scale = tile.global_scale
	
	# Manter o tile no UILayer DURANTE O VOO para garantir que ele sobreponha a barra de slots
	# que está em CanvasLayer separado.
	if tile.get_parent() != get_node("UILayer"):
		if tile.get_parent():
			tile.get_parent().remove_child(tile)
		get_node("UILayer").add_child(tile)
	
	tile.global_position = g_pos
	tile.global_scale = g_scale
		
	tile.is_in_inventory = false
	tile.is_matched = false
	tile.visible = true
	
	if tile.is_hinted:
		tile.play_hint_glow()
	else:
		tile.modulate = Color.WHITE
	
	# Z Index local absurdamente alto no CanvasLayer
	tile.z_index = 4000
	if tile.has_node("CollisionShape"):
		tile.get_node("CollisionShape").set_deferred("disabled", true)
	
	var target_local_board: Vector2 = tile.get_meta("original_position") if tile.has_meta("original_position") else Vector2.ZERO
	# Precisar converter a posição local do tabuleiro para a tela (UILayer) para saber a reta do voo
	var target_global = _board.to_global(target_local_board)
	var target_z: int = tile.get_calculated_z_index()
	
	_pending_animations += 1
	var tween := create_tween()
	tween.set_parallel(true)
	# Animar a posição GLOBAL dele até o destino (como ele tá na default CanvasLayer/Viewport,
	# global_position == canvas screen position)
	tween.tween_property(tile, "global_position", target_global, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Escalar de volta baseando-se na escala do próprio Board (já que ele tá no UILayer)
	var target_global_scale = _board.global_scale
	tween.tween_property(tile, "scale", target_global_scale, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	tween.chain().tween_callback(func():
		_pending_animations -= 1
		if is_instance_valid(tile):
			# Agora sim reparentá-lo no verdadeiro Node (BoardManager)
			if tile.get_parent() != _board:
				tile.get_parent().remove_child(tile)
				_board.add_child(tile)
				
			# Como mudou de parent, sua escala final e position_local têm que ser validadas
			tile.position = target_local_board
			tile.scale = Vector2.ONE
			tile.z_index = target_z
			
			if tile.has_node("CollisionShape"):
				tile.get_node("CollisionShape").set_deferred("disabled", false)
			if tile.has_node("DropShadow"):
				tile.get_node("DropShadow").visible = true
				
			# Resync de animação de Hint: reinicia o Tween das duas metades do par ao mesmo tempo
			if tile.is_hinted:
				# Procura todos os tiles ativos no board procurando o parceiro também piscando
				for other_tile in _board.active_tiles():
					if is_instance_valid(other_tile) and other_tile != tile and other_tile.is_hinted:
						# Dá restart síncrono nas duas!
						other_tile.play_hint_glow()
						tile.play_hint_glow()
						break
			
			# Recalcular as regras de bloqueio APÓS a peça aterrar
			_board.update_tile_states()
	)

func _update_hint_button() -> void:
	if _hint_label:
		_hint_label.text = str(hint_charges) if hint_charges > 0 else "+"


func _on_hint_pressed() -> void:
	if _game_paused:
		return
		
	if hint_charges <= 0:
		ad_requester = "hint"
		_show_ad_popup()
		return
		
	if is_hint_active:
		return
		
	var inv_ids: Array[int] = []
	for tile in _inventory:
		if is_instance_valid(tile):
			inv_ids.append(tile.cat_id)
			
	var hint_tiles = _board.find_hint(inv_ids)
	if hint_tiles.size() > 0:
		hint_charges -= 1
		_update_hint_button()
		
		_board.highlight_hint(hint_tiles)
		
		is_hint_active = true
		active_hint_cat_id = hint_tiles[0].cat_id
		
		# Sincronizar brilho com a peça correspondente no inventário
		for hint_tile in hint_tiles:
			for inv_tile in _inventory:
				if is_instance_valid(inv_tile) and inv_tile.cat_id == hint_tile.cat_id:
					inv_tile.play_hint_glow()
	elif _board.active_tiles().is_empty() and _inventory.is_empty():
		# Sem peças livres no board e sem inventário — win?
		_show_win_popup()
	else:
		_show_floating_message("Tente utilizar outro tipo de ajuda para superar o desafio")


func _show_floating_message(msg_text: String) -> void:
	if $UILayer.has_node("ToastMessage"):
		return
		
	var container := MarginContainer.new()
	container.name = "ToastMessage"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.modulate.a = 0.0
	container.z_index = 5000 # Supera popups normais
	
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label := Label.new()
	label.text = msg_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	
	container.add_child(panel)
	$UILayer.add_child(container)
	
	# Aguardar o próximo frame para o Godot aplicar as âncoras e calcular o tamanho com base no texto
	await get_tree().process_frame
	if not is_instance_valid(container):
		return
		
	# Garantir centralização absoluta da própria Box na tela
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.pivot_offset = container.size / 2.0
	
	# Animação premium: Fade In -> Aguarda -> Sobe e Desvanece
	var tween := create_tween()
	var base_y = container.position.y
	
	tween.tween_property(container, "modulate:a", 1.0, 0.25)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_interval(1.8)
	
	var fade_out = create_tween()
	fade_out.set_parallel(true)
	# Espera o tween principal liberar o fading (no delay)
	fade_out.tween_property(container, "position:y", base_y - 80.0, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(2.05)
	fade_out.tween_property(container, "modulate:a", 0.0, 0.6)\
		.set_ease(Tween.EASE_IN).set_delay(2.05)
		
	fade_out.chain().tween_callback(func(): container.queue_free())


func _update_shuffle_button() -> void:
	if _shuffle_label:
		_shuffle_label.text = str(shuffle_charges) if shuffle_charges > 0 else "+"


func _on_shuffle_pressed() -> void:
	if _game_paused or _tiles_in_flight.size() > 0 or _fading_animations > 0 or _pending_animations > 0 or _board.is_shuffling:
		return
		
	if shuffle_charges <= 0:
		ad_requester = "shuffle"
		_show_ad_popup()
		return
		
	shuffle_charges -= 1
	_update_shuffle_button()
	
	_board.execute_shuffle()


# ═══════════════════════════════════════════════════════════════════════
# POPUPS
# ═══════════════════════════════════════════════════════════════════════

func _show_win_popup() -> void:
	current_level += 1
	var btn = $UILayer/WinPopup/PlayAgainBtn
	var home_btn = $UILayer/WinPopup/HomeBtn
	
	if btn:
		btn.text = "Nível " + str(current_level)
		btn.disabled = true
	if home_btn:
		home_btn.disabled = true
		
	_game_paused = true
	_dim_overlay.visible = true
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _win_popup:
		_win_popup.modulate.a = 0.0
		_win_popup.show()
		var tween = create_tween()
		tween.tween_property(_win_popup, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func():
			if btn: btn.disabled = false
			if home_btn: home_btn.disabled = false
		)
	_set_hud_disabled(true)


func _show_pause_popup() -> void:
	_game_paused = true
	_dim_overlay.visible = true
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_popup.visible = true
	_set_hud_disabled(true)


func _hide_popups() -> void:
	_game_paused = false
	_dim_overlay.visible = false
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_popup.visible = false
	_pause_popup.visible = false
	_game_over_popup.visible = false
	_set_hud_disabled(false)


func _set_hud_disabled(disabled: bool) -> void:
	if is_instance_valid(_btn_shuffle):
		_btn_shuffle.disabled = disabled
	if is_instance_valid(_btn_hint):
		_btn_hint.disabled = disabled
	if is_instance_valid(_btn_undo):
		_btn_undo.disabled = disabled

func _update_undo_button() -> void:
	if not is_instance_valid(_btn_undo): return
	
	if _undo_label:
		_undo_label.text = str(undo_charges) if undo_charges > 0 else "+"


func _build_power_labels() -> void:
	var label_settings = LabelSettings.new()
	label_settings.font_size = 28
	label_settings.outline_size = 8
	label_settings.outline_color = Color.BLACK
	label_settings.font_color = Color.WHITE
	
	_hint_label = Label.new()
	_hint_label.label_settings = label_settings
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.position = Vector2(-8, -8)  # Margin tuning
	_btn_hint.add_child(_hint_label)
	
	_undo_label = Label.new()
	_undo_label.label_settings = label_settings
	_undo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_undo_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_undo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_undo_label.position = Vector2(-8, -8)
	_btn_undo.add_child(_undo_label)

	_shuffle_label = Label.new()
	_shuffle_label.label_settings = label_settings
	_shuffle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shuffle_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_shuffle_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_shuffle_label.position = Vector2(-8, -8)
	_btn_shuffle.add_child(_shuffle_label)



func _show_ad_popup() -> void:
	_game_paused = true
	if _ad_popup:
		_ad_popup.show()


func _on_ad_reward_claimed() -> void:
	if ad_requester == "hint":
		hint_charges += 2
		_update_hint_button()
	elif ad_requester == "undo":
		undo_charges += 2
		_update_undo_button()
	elif ad_requester == "shuffle":
		shuffle_charges += 2
		_update_shuffle_button()
		
	ad_requester = ""
	_ad_popup.hide()
	_game_paused = false


# ═══════════════════════════════════════════════════════════════════════
# UI FAXINA
# ═══════════════════════════════════════════════════════════════════════

func _set_ui_mouse_filters(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			continue
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_ui_mouse_filters(child)
