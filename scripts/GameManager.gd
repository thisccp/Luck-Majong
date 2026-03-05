## GameManager.gd — Controller principal do Mahjong Solitaire (Godot 4.x)
##
## Sistema de Inventário Zen: clique na peça → voa para slot → match automático.
## Game Over quando 4 slots cheios sem par. Reviver até 3×.

class_name GameManager
extends Control

# ─── UI existente ────────────────────────────────────────────────────

@onready var _board: BoardManager = $BoardContainer/BoardManager
@onready var _btn_hint: TextureButton = $UILayer/VBox/BottomMargin/HintBtn
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
## Reserva imediata de slot: Tile → índice do slot reservado
var _slot_assignments: Dictionary = {}

# ─── Reviver ─────────────────────────────────────────────────────────

var revive_limit: int = 3

# ─── Game Over Popup (criado via código) ─────────────────────────────

var _game_over_popup: PanelContainer
var _revive_btn: Button
var _restart_go_btn: Button
var _go_tiles_hbox: HBoxContainer

# ─── Estado ──────────────────────────────────────────────────────────

var _pairs_matched: int = 0
var _game_paused: bool = false


# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_btn_hint.pressed.connect(_on_hint)
	_btn_menu.pressed.connect(_show_pause_popup)
	_board.tile_pressed.connect(_on_tile_pressed)

	_build_inventory_bar()
	_build_game_over_popup()

	# ── Popups existentes ──
	$UILayer/WinPopup/PlayAgainBtn.pressed.connect(func():
		_hide_popups()
		print("Indo para Nível 2 (WIP)")
	)
	$UILayer/WinPopup/HomeBtn.pressed.connect(func():
		_hide_popups()
		get_tree().reload_current_scene()
	)
	$UILayer/PausePopup/SoundToggle.toggled.connect(func(bp: bool):
		print("Sound toggled: ", bp)
	)
	$UILayer/PausePopup/RestartBtn.pressed.connect(func():
		_hide_popups()
		get_tree().reload_current_scene()
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
	bar_img.custom_minimum_size = Vector2(360, 180)  # Forçar tamanho garantindo que a proporção caiba
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
		get_tree().reload_current_scene()
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
	_pending_animations = 0
	_board.new_game()


func _on_tile_pressed(tile: MahjongTile) -> void:
	"""Clique na peça → adicionar ao inventário (sem bloqueio)."""
	if _game_paused:
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

	# Atualizar tabuleiro (peças que ficaram livres)
	_board.update_tile_states()

	# Fire-and-forget: animação não bloqueia cliques
	_pending_animations += 1
	_animate_tile_to_slot(tile, slot_index)

	# EAGER: detectar par IMEDIATAMENTE no mesmo frame do clique
	# Isso libera slots logicamente antes de qualquer animação terminar
	_try_instant_pair_resolution()


func _animate_tile_to_slot(tile: MahjongTile, slot_index: int) -> void:
	"""Anima a peça. Pares já foram detectados no clique (eager)."""
	await _fly_tile_to_slot(tile, slot_index)

	if not is_instance_valid(tile):
		_pending_animations -= 1
		return

	# Finalizar no UI (se tile ainda está no inventário — pode ter sido matched)
	if tile.is_in_inventory:
		_reparent_tile_to_ui(tile)
	_pending_animations -= 1

	# Quando todas as animações terminaram, checar apenas game over
	if _pending_animations <= 0:
		_check_game_over()


func _check_game_over() -> void:
	"""Checa game over (pares já foram resolvidos no clique)."""
	if _inventory.size() >= MAX_INVENTORY:
		_show_game_over_popup()


func _fly_tile_to_slot(tile: MahjongTile, slot_index: int) -> void:
	"""Anima a peça voando do tabuleiro ao bolso, POR CIMA da moldura."""
	# Converter posição atual do board para coordenadas de tela
	var start_screen_pos: Vector2 = tile.global_position

	# Reparentar ao UILayer ANTES do voo (para ficar acima do slots.png)
	if tile.get_parent() == _board:
		_board.remove_child(tile)
		$UILayer.add_child(tile)

	tile.z_index = 1000
	tile.position = start_screen_pos

	# Posição-alvo: centro do bolso FINAL TEÓRICO (slot reservado)
	var target_pos: Vector2 = _get_slot_center(slot_index)

	# Escala-alvo: peça deve caber visualmente no bolso
	var pocket: Vector2 = _get_slot_pocket_size(slot_index)
	var scale_to_fit: float = minf(
		pocket.x / tile.tile_size.x,
		pocket.y / tile.tile_size.y
	)
	var target_scale := Vector2(scale_to_fit, scale_to_fit)

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

	# Tile já está no UILayer (reparentado em _fly_tile_to_slot)
	# Apenas finalizar z_index e garantir cor
	tile.z_index = 50
	tile.modulate = Color.WHITE

	# Reorganizar TODAS as peças para garantir consistência
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
	Libera slots imediatamente, permitindo cliques seguintes sem delay."""
	var pair = _find_inventory_pair()
	while pair != null:
		var t1: MahjongTile = _inventory[pair[0]]
		var t2: MahjongTile = _inventory[pair[1]]

		# Liberar logicamente AGORA (mesmo frame)
		t1.is_in_inventory = false
		t2.is_in_inventory = false
		_board.record_match(t1, t2)
		_pairs_matched += 1

		var indices: Array = [pair[0], pair[1]]
		indices.sort()
		_inventory.remove_at(indices[1])
		_inventory.remove_at(indices[0])

		_slot_assignments.erase(t1)
		_slot_assignments.erase(t2)
		_recalculate_slot_assignments()

		# Reorganizar peças restantes (deslizar)
		_reorganize_slots()

		# Animação cosmética fire-and-forget (não bloqueia NADA)
		_animate_pair_removal(t1, t2)

		# Atualizar board
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


func _animate_pair_removal(tile1: MahjongTile, tile2: MahjongTile) -> void:
	"""Animação cosmética de match — fire-and-forget, não bloqueia nada."""
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(tile1, "modulate", Color(1.5, 1.3, 0.8, 0.0), 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(tile1, "scale", tile1.scale * 1.3, 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(tile2, "modulate", Color(1.5, 1.3, 0.8, 0.0), 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(tile2, "scale", tile2.scale * 1.3, 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Callback ao terminar — limpar sem bloquear
	fade_tween.finished.connect(func():
		if is_instance_valid(tile1):
			tile1.mark_matched()
		if is_instance_valid(tile2):
			tile2.mark_matched()
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

		# Fundo: base da peça
		var base_rect := TextureRect.new()
		base_rect.texture = tile_base_tex
		base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		base_rect.stretch_mode = TextureRect.STRETCH_SCALE
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
		tile.modulate = Color.WHITE
		tile.z_index = 1000  # Acima de tudo durante o voo

		# Converter posição da tela para coordenadas locais do board
		var start_local: Vector2 = (current_screen_pos - _board.global_position) / _board.scale
		tile.position = start_local
		tile.scale = current_scale

		# Destino: posição original no board
		var target_pos: Vector2 = tile.get_meta("original_position") if tile.has_meta("original_position") else start_local
		var target_z: int = tile.original_z_index

		# Animar voo de volta
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(tile, "position", target_pos, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(tile, "scale", Vector2.ONE, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): tile.z_index = target_z).set_delay(0.35)

	# Atualizar tabuleiro após um breve delay para as animações
	await get_tree().create_timer(0.4).timeout
	_board.update_tile_states()


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

func _on_hint() -> void:
	if _game_paused:
		return
	var hint = _board.find_hint()
	if hint != null:
		var t1: MahjongTile = hint[0]
		var t2: MahjongTile = hint[1]
		_board.highlight_hint(t1, t2)
		await get_tree().create_timer(2.0).timeout
		_board.clear_selection()
	elif _board.active_tiles().is_empty() and _inventory.is_empty():
		# Sem peças livres no board e sem inventário — win?
		_show_win_popup()


func _on_shuffle() -> void:
	_board.shuffle_remaining()


# ═══════════════════════════════════════════════════════════════════════
# POPUPS
# ═══════════════════════════════════════════════════════════════════════

func _show_win_popup() -> void:
	_game_paused = true
	_dim_overlay.visible = true
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_popup.visible = true
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
	if is_instance_valid(_btn_hint):
		_btn_hint.disabled = disabled


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
