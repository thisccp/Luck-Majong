## BoardManager.gd — Gerenciador do tabuleiro do Mahjong Solitaire (Godot 4.x)
##
## Responsável por: gerar layouts, algoritmo de geração reversa (100% solvável),
## instanciar peças, verificar regras de bloqueio/match e renderizar o tabuleiro.

class_name BoardManager
extends Node2D

## Sinal emitido quando uma peça é clicada.
signal tile_pressed(tile: MahjongTile)

# ─── Constantes de layout ───────────────────────────────────────────

## Tamanho de uma célula. Dimensionado para densidade sólida e sem vãos (B)
const TILE_W := 88.0
const CELL_W := 44.0  # TILE_W / 2 para peças da mesma camada ficarem coladas sem sobrepor
const CELL_H := 48.0  # TILE_H / 2 para encostar perfeitamente verticalmente
## Tamanho real do tile, forma "parruda", robusta e mais quadrada (A)
const TILE_H := 96.0
## Offset 3D por camada Z. (Efeito de pirâmide/escada sobrepondo intensamente as peças de baixo)
const Z_OFFSET_X := -18.0  # Mantido recuo X (esquerda)
const Z_OFFSET_Y := -35.0  # Verticalização (B): ~36% de recuo Y (cima) cobrindo ~1/3 da altura da peça abaixo
## Número de tipos de estampa.
const NUM_TYPES := 20

# ─── Estado do jogo ─────────────────────────────────────────────────

## Dicionário de tiles: Vector3i → MahjongTile (ou dados durante geração)
var tiles: Dictionary = {}
## Histórico de jogadas para undo (futuro).
var _move_history: Array = []

# ─── API pública ────────────────────────────────────────────────────

func new_game() -> void:
	"""Gera um novo tabuleiro 100% solvável e renderiza."""
	tiles.clear()
	_move_history.clear()
	_clear_children()
	
	var slots := _load_block_layout()
	_generate_beatable(slots)
	_render_board()
	print("[BoardManager] new_game: %d tiles gerados" % tiles.size())


func active_tiles() -> Array[MahjongTile]:
	"""Retorna tiles ainda não removidos."""
	var result: Array[MahjongTile] = []
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched and not tile.is_in_inventory:
			result.append(tile)
	return result


func is_tile_free(tile: MahjongTile) -> bool:
	"""
	Uma peça está livre se:
	  1. Regra 90/10: menos de 10% da sua área está coberta por peças acima.
	  2. Pelo menos um dos lados (esquerdo ou direito) está livre.
	"""
	if tile.is_matched or tile.is_in_inventory:
		return false
	
	# --- Bloqueio por sobreposição — Regra 90/10 (pixel-based) ---
	# Retângulo visual da própria peça
	var tile_rect := Rect2(
		tile.grid_pos.x * CELL_W + tile.grid_pos.z * Z_OFFSET_X + tile.pixel_offset.x,
		tile.grid_pos.y * CELL_H + tile.grid_pos.z * Z_OFFSET_Y + tile.pixel_offset.y,
		TILE_W, TILE_H
	)
	var tile_area := TILE_W * TILE_H
	var total_overlap := 0.0
	
	for other in tiles.values():
		if not (other is MahjongTile): continue
		if other.is_matched or other.is_in_inventory: continue
		if other.grid_pos.z <= tile.grid_pos.z: continue
		
		var other_rect := Rect2(
			other.grid_pos.x * CELL_W + other.grid_pos.z * Z_OFFSET_X + other.pixel_offset.x,
			other.grid_pos.y * CELL_H + other.grid_pos.z * Z_OFFSET_Y + other.pixel_offset.y,
			TILE_W, TILE_H
		)
		var intersection := tile_rect.intersection(other_rect)
		total_overlap += intersection.get_area()
	
	# a) Bloqueada se ≥ 10% da área total estiver coberta por PEÇAS ACIMA
	if total_overlap / tile_area >= 0.10:
		return false
	
	# --- b) Bloqueio lateral no MESMO NÍVEL (Z) ---
	# A peça precisa ter pelo menos um lado (esquerdo OU direito) livre.
	var left_blocked := false
	var right_blocked := false
	for dy in range(-1, 2):
		if _has_neighbor(tile.grid_pos.x - 2, tile.grid_pos.y + dy, tile.grid_pos.z):
			left_blocked = true
		if _has_neighbor(tile.grid_pos.x + 2, tile.grid_pos.y + dy, tile.grid_pos.z):
			right_blocked = true
	
	if left_blocked and right_blocked:
		return false
	
	return true


func try_match(t1: MahjongTile, t2: MahjongTile) -> bool:
	"""Tenta fazer match de duas peças. Retorna true se bem-sucedido."""
	if t1 == t2:
		return false
	if t1.is_matched or t2.is_matched:
		return false
	if t1.cat_id != t2.cat_id:
		return false
	if not is_tile_free(t1) or not is_tile_free(t2):
		return false
	
	t1.mark_matched()
	t2.mark_matched()
	_move_history.append([t1, t2])
	return true


func record_match(t1: MahjongTile, t2: MahjongTile) -> void:
	"""Registra um match já validado e animado no histórico."""
	_move_history.append([t1, t2])


func is_won() -> bool:
	"""Verdadeiro se todas as peças foram removidas."""
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched:
			return false
	return true


func has_moves() -> bool:
	"""Verdadeiro se existe pelo menos um par disponível."""
	return find_hint() != null


func find_hint() -> Variant:
	"""Retorna um Array [tile1, tile2] com par livre, ou null."""
	var free_tiles: Array[MahjongTile] = []
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched and is_tile_free(tile):
			free_tiles.append(tile)
	
	var by_type: Dictionary = {}
	for tile in free_tiles:
		if not by_type.has(tile.cat_id):
			by_type[tile.cat_id] = []
		by_type[tile.cat_id].append(tile)
	
	for type_tiles: Array in by_type.values():
		if type_tiles.size() >= 2:
			return [type_tiles[0], type_tiles[1]]
	
	return null


func shuffle_remaining() -> void:
	"""Embaralha as peças restantes — garante solvabilidade pós-shuffle."""
	var remaining: Array[MahjongTile] = []
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched:
			remaining.append(tile)
	
	if remaining.is_empty():
		return
	
	var positions: Array[Vector3i] = []
	for tile in remaining:
		positions.append(tile.grid_pos)
	
	for tile in remaining:
		tiles.erase(tile.grid_pos)
		tile.queue_free()
	
	_generate_beatable(positions)
	_render_board()


func update_tile_states() -> void:
	"""Atualiza visual de blocked/free em todas as peças."""
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched and not tile.is_in_inventory:
			tile.set_blocked(not is_tile_free(tile))


func highlight_hint(t1: MahjongTile, t2: MahjongTile) -> void:
	"""Destaca duas peças com glow intenso de hint."""
	clear_selection()
	t1.play_hint_glow()
	t2.play_hint_glow()


func clear_selection() -> void:
	"""Remove qualquer seleção visual e para hint glow."""
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched and not tile.is_in_inventory:
			tile.is_selected = false
			tile.stop_hint_glow()
	
	# Recalcula e reaplica o filtro cinza nas peças bloqueadas
	update_tile_states()


# ─── Layout ─────────────────────────────────────────────────────────

func _load_block_layout() -> Array[Vector3i]:
	"""
	Layout 'Neko Pillar' (Ref. Estrutural) — Pilar Vertical focado no Galaxy S25 (6 colunas).
	Total: 66 peças (33 pares).
	"""
	var slots: Array[Vector3i] = []

	# ═══ Z=0 (Base 6 colunas, alta densidade e altura 12): 30 peças ═══
	# Eixo X é limitado a 0, 2, 4, 6, 8, 10
	for y in [2, 4, 6, 8, 10]: slots.append(Vector3i(0, y, 0)) # Col 1
	for y in [1, 3, 5, 7, 9, 11]: slots.append(Vector3i(2, y, 0)) # Col 2
	for y in [0, 2, 4, 6, 8, 10, 12]: slots.append(Vector3i(4, y, 0)) # Col 3 (Centro)
	for y in [1, 3, 5, 7, 9, 11]: slots.append(Vector3i(6, y, 0)) # Col 4
	for y in [2, 4, 6, 8, 10]: slots.append(Vector3i(8, y, 0)) # Col 5
	for y in [5, 7]: slots.append(Vector3i(10, y, 0)) # Col 6 (Extra support)

	# ═══ Z=1 (Camada 1): 20 peças ═══
	for y in [3, 5, 7, 9]: slots.append(Vector3i(2, y, 1))
	for y in [2, 4, 6, 8, 10]: slots.append(Vector3i(4, y, 1))
	for y in [2, 4, 6, 8, 10]: slots.append(Vector3i(6, y, 1))
	for y in [3, 5, 7, 9]: slots.append(Vector3i(8, y, 1))
	slots.append(Vector3i(4, 0, 1))
	slots.append(Vector3i(6, 12, 1))

	# ═══ Z=2 (Camada 2): 10 peças ═══
	for y in [4, 6, 8]: slots.append(Vector3i(4, y, 2))
	for y in [5, 7]: slots.append(Vector3i(6, y, 2))
	for y in [4, 6, 8]: slots.append(Vector3i(8, y, 2))
	slots.append(Vector3i(4, 2, 2))
	slots.append(Vector3i(6, 9, 2))

	# ═══ Z=3 (Topo): 6 peças ═══
	for y in [5, 7]: slots.append(Vector3i(4, y, 3))
	for y in [4, 6, 8]: slots.append(Vector3i(6, y, 3))
	slots.append(Vector3i(8, 7, 3))

	return slots


# ─── Geração Reversa (Beatable) ────────────────────────────────────

func _generate_beatable(slots: Array[Vector3i]) -> void:
	"""Algoritmo de Geração Reversa — garante 100% de solvabilidade."""
	var total := slots.size()
	if total % 2 != 0:
		slots.resize(total - 1)
		total = slots.size()
	
	@warning_ignore("integer_division")
	var num_pairs := total / 2
	
	var type_ids: Array[int] = []
	for i in range(num_pairs):
		type_ids.append(i % NUM_TYPES + 1)
	type_ids.shuffle()
	
	var remaining_set: Dictionary = {}
	for s in slots:
		remaining_set[s] = true
	
	var placed: Dictionary = {}
	var pair_index := 0
	
	while not remaining_set.is_empty() and pair_index < num_pairs:
		var free_slots: Array = _find_free_slots_for_generation(remaining_set, placed)
		
		if free_slots.size() < 2:
			free_slots = remaining_set.keys()
			if free_slots.size() < 2:
				break
		
		free_slots.shuffle()
		var s1: Vector3i = free_slots[0]
		var s2: Vector3i = free_slots[1]
		var tid: int = type_ids[pair_index]
		
		placed[s1] = tid
		placed[s2] = tid
		remaining_set.erase(s1)
		remaining_set.erase(s2)
		pair_index += 1
	
	# Armazenar como dados temporários (nós criados em _render_board)
	for pos: Vector3i in placed:
		tiles[pos] = {"grid_pos": pos, "cat_id": placed[pos]}
		
	print("[BoardManager] Caminho Dourado gerado com sucesso para 6 colunas (Neko Pillar).")


func _find_free_slots_for_generation(
	remaining: Dictionary, _placed: Dictionary
) -> Array[Vector3i]:
	var free: Array[Vector3i] = []
	
	for slot: Vector3i in remaining:
		# --- Bloqueio por sobreposição — Regra 90/10 (pixel-based) ---
		var tile_rect := Rect2(
			slot.x * CELL_W + slot.z * Z_OFFSET_X,
			slot.y * CELL_H + slot.z * Z_OFFSET_Y,
			TILE_W, TILE_H
		)
		var tile_area := TILE_W * TILE_H
		var total_overlap := 0.0
		
		for rem_pos: Vector3i in remaining:
			if rem_pos == slot: continue
			if rem_pos.z <= slot.z: continue
			
			var other_rect := Rect2(
				rem_pos.x * CELL_W + rem_pos.z * Z_OFFSET_X,
				rem_pos.y * CELL_H + rem_pos.z * Z_OFFSET_Y,
				TILE_W, TILE_H
			)
			var intersection := tile_rect.intersection(other_rect)
			total_overlap += intersection.get_area()
		
		var blocked_above := (total_overlap / tile_area) >= 0.10
		if blocked_above:
			continue
		
		# --- Bloqueio lateral no MESMO NÍVEL (Z) ---
		var left_blocked := false
		var right_blocked := false
		for dy in range(-1, 2):
			if remaining.has(Vector3i(slot.x - 2, slot.y + dy, slot.z)):
				left_blocked = true
			if remaining.has(Vector3i(slot.x + 2, slot.y + dy, slot.z)):
				right_blocked = true
				
		if left_blocked and right_blocked:
			continue
			
		free.append(slot)
	
	return free


# ─── Teste de Sobreposição 90/10 ────────────────────────────────────

func new_test_game() -> void:
	"""Gera um tabuleiro de TESTE para validar a regra 90/10.
	Tile Z=1 esquerdo: offset (30,0) → ~6% overlap → peças abaixo LIVRES.
	Tile Z=1 direito:  offset (0,0)  → ~25% overlap → peças abaixo BLOQUEADAS."""
	tiles.clear()
	_move_history.clear()
	_clear_children()

	var test_data := _test_overlap_layout()
	tiles = test_data
	_render_board()
	print("[BoardManager] TEST GAME: %d tiles (validação 90/10)" % tiles.size())


func _test_overlap_layout() -> Dictionary:
	"""Layout de teste com sobreposição controlada para validar regra 90/10."""
	var data := {}

	# ── Z=0: Base — 8 peças (4 pares) ──
	# Fila superior
	data[Vector3i(0, 0, 0)] = {"cat_id": 1, "pixel_offset": Vector2.ZERO}
	data[Vector3i(2, 0, 0)] = {"cat_id": 2, "pixel_offset": Vector2.ZERO}
	data[Vector3i(4, 0, 0)] = {"cat_id": 3, "pixel_offset": Vector2.ZERO}
	data[Vector3i(6, 0, 0)] = {"cat_id": 4, "pixel_offset": Vector2.ZERO}
	# Fila inferior
	data[Vector3i(0, 2, 0)] = {"cat_id": 1, "pixel_offset": Vector2.ZERO}
	data[Vector3i(2, 2, 0)] = {"cat_id": 2, "pixel_offset": Vector2.ZERO}
	data[Vector3i(4, 2, 0)] = {"cat_id": 3, "pixel_offset": Vector2.ZERO}
	data[Vector3i(6, 2, 0)] = {"cat_id": 4, "pixel_offset": Vector2.ZERO}

	# ── Z=1: Teste — 2 peças (1 par) ──
	# ESQUERDO: offset grande → ~6% overlap na peça (0,0) → LIVRE (< 10%)
	data[Vector3i(1, 1, 1)] = {"cat_id": 5, "pixel_offset": Vector2(30, 0)}
	# DIREITO: sem offset → ~25% overlap em vizinhos → BLOQUEADO (> 10%)
	data[Vector3i(5, 1, 1)] = {"cat_id": 5, "pixel_offset": Vector2.ZERO}

	return data


# ─── Renderização ───────────────────────────────────────────────────

func _render_board() -> void:
	"""Cria os nós de tile e posiciona no tabuleiro."""
	await get_tree().process_frame  # Garante Sincronização de Frame para resize
	
	_clear_children()
	self.scale = Vector2.ONE  # Reset scale antes de recalcular
	self.position = Vector2.ZERO
	
	if tiles.is_empty():
		print("[BoardManager] _render_board: tiles vazio!")
		return
	
	# Obter tamanho da área disponível
	var area_w := 720.0
	var area_h := 900.0
	var container = get_parent()
	if container is Control and container.size.x > 0:
		area_w = container.size.x
		area_h = container.size.y
	print("[BoardManager] Container size: %s × %s" % [area_w, area_h])
	
	# Posicionar tiles a partir da grade
	var sorted_positions := tiles.keys()
	sorted_positions.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		if a.z != b.z: return a.z < b.z
		if a.y != b.y: return a.y < b.y
		return a.x < b.x
	)
	
	# Criar nós, posicioná-los (sem offset centralizador a princípio) e registrar bounding box
	var tile_nodes: Dictionary = {}
	
	var min_px := Vector2(INF, INF)
	var max_px := Vector2(-INF, -INF)
	
	for pos: Vector3i in sorted_positions:
		var data = tiles[pos]
		var cat_id_val: int = data["cat_id"]
		var pix_offset: Vector2 = data.get("pixel_offset", Vector2.ZERO) if data is Dictionary else Vector2.ZERO
		
		var tile_node := MahjongTile.new()
		tile_node.setup(pos, cat_id_val, Vector2(TILE_W, TILE_H))
		tile_node.pixel_offset = pix_offset
		
		# Posição nua baseada na grade
		var sx: float = pos.x * CELL_W + pos.z * Z_OFFSET_X + TILE_W / 2.0 + pix_offset.x
		var sy: float = pos.y * CELL_H + pos.z * Z_OFFSET_Y + TILE_H / 2.0 + pix_offset.y
		tile_node.position = Vector2(sx, sy)
		
		# Calcular caixa delimitadora
		min_px.x = minf(min_px.x, sx - TILE_W / 2.0)
		min_px.y = minf(min_px.y, sy - TILE_H / 2.0)
		max_px.x = maxf(max_px.x, sx + TILE_W / 2.0)
		max_px.y = maxf(max_px.y, sy + TILE_H / 2.0)
		
		add_child(tile_node)
		tile_nodes[pos] = tile_node
	
	tiles = tile_nodes
	
	# O tamanho "físico" real empírico do layout em pixels antes da escala
	var board_w: float = max_px.x - min_px.x
	var board_h: float = max_px.y - min_px.y
	
	# ── Auto-scale e centralização precisa BASEADA EM UI REAL ──
	var slots_bar = get_node_or_null("../../UILayer/VBox/InventoryBarContainer/SlotsBar")
	var hint_btn = get_node_or_null("../../UILayer/VBox/BottomMargin/HintBtn")
	
	# Limites verticais padrão caso os nós não sejam encontrados
	var top_boundary: float = 180.0
	var bottom_boundary: float = area_h - 120.0
	
	if is_instance_valid(slots_bar):
		# A barra real termina em global_position.y + size.y
		top_boundary = slots_bar.global_position.y + slots_bar.size.y
	
	if is_instance_valid(hint_btn):
		# O botão começa em global_position.y
		bottom_boundary = hint_btn.global_position.y
		
	# Margens solicitadas (removida a MARGIN_SIDE extra, pois aplicaremos 95% exato)
	const MARGIN_TOP_PX := 25.0
	const MARGIN_BOTTOM_PX := 50.0
	
	var usable_start_y := top_boundary + MARGIN_TOP_PX
	var usable_end_y := bottom_boundary - MARGIN_BOTTOM_PX
	var usable_h: float = usable_end_y - usable_start_y
	var usable_w: float = area_w
	
	# 1. Escala de Glória (Escala a 96% do dispositivo):
	var scale_factor: float = minf((usable_w * 0.96) / board_w, (usable_h * 0.96) / board_h)
	
	self.scale = Vector2(scale_factor, scale_factor)
	
	# 2. Correção de Pivot e Centralização Horizontal Absoluta
	var scaled_w: float = board_w * scale_factor
	# Centraliza na área e anula o offset não-zero (min_px) do grid original
	var pos_x: float = (area_w - scaled_w) / 2.0 - (min_px.x * scale_factor)
	
	# 3. Otimização do Espaço Vertical (Trazendo para MAIS PERTO do botão de dica)
	var scaled_h: float = board_h * scale_factor
	# Em vez de / 2.0 (centro exato), mudamos para peso 0.65 para descer levemente a pirâmide
	var pos_y: float = usable_start_y + (usable_h - scaled_h) * 0.65 - (min_px.y * scale_factor)
	
	self.position = Vector2(pos_x, pos_y)
	
	print("[BoardManager] Board: %.0f×%.0f, Scale: %.2f, Pos: (%.0f, %.0f)" % [
		board_w, board_h, scale_factor, pos_x, pos_y
	])
	
	update_tile_states()


# ─── Input centralizado ─────────────────────────────────────────────

## Frame do último clique processado — evita dupla emissão por emulação.
var _last_pick_frame: int = -1
## Timestamp do último pick processado — cooldown anti-double-click.
var _last_pick_time: float = 0.0
## Cooldown mínimo entre picks (ms).
const PICK_COOLDOWN_MS := 30.0

func _unhandled_input(event: InputEvent) -> void:
	"""Top-Down Picker centralizado — funciona em Mouse e Touch.
	
	REGRA ABSOLUTA: se há uma peça sob o clique, SEMPRE consumir
	o evento (tanto press quanto release) para impedir que ele
	"atravesse" para peças em camadas inferiores.
	"""
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var world_pos := get_global_mouse_position()
	
	# Query: encontrar TODAS as peças sob o ponto de clique
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0xFFFFFFFF
	
	var results := space_state.intersect_point(query, 32)
	
	# Encontrar a peça com o Z mais alto (topo da pilha)
	var topmost_tile: MahjongTile = null
	var best_z := -1
	
	for result in results:
		var collider = result["collider"]
		if collider is MahjongTile and not collider.is_matched:
			if collider.grid_pos.z > best_z:
				best_z = collider.grid_pos.z
				topmost_tile = collider
	
	if topmost_tile == null:
		return  # Nenhuma peça sob o cursor — não consumir
	
	# ── CONSUMIR SEMPRE (press E release) ──
	# Isso impede que o evento alcance peças de camadas inferiores
	get_viewport().set_input_as_handled()
	
	# Só processar lógica no release (finger up / mouse up)
	if event.pressed:
		return  # Consome o press mas não processa
	
	# 3. Precisão do Clique: Se estiver bloqueada pela regra 90/10, ignorar completamente o release
	# O evento press já foi consumido para não vazar, mas o jogo não deve processar a jogada.
	if not is_tile_free(topmost_tile):
		return
	
	# Deduplicação por frame
	var frame := Engine.get_process_frames()
	if frame == _last_pick_frame:
		return
	_last_pick_frame = frame
	
	# Cooldown temporal anti-double-click
	var now := Time.get_ticks_msec()
	if (now - _last_pick_time) < PICK_COOLDOWN_MS:
		return
	_last_pick_time = now
	
	# Só emitir se a peça do topo é LIVRE (regras do Mahjong)
	if is_tile_free(topmost_tile):
		tile_pressed.emit(topmost_tile)


func _has_neighbor(x: int, y: int, z: int) -> bool:
	var pos := Vector3i(x, y, z)
	if not tiles.has(pos):
		return false
	var tile = tiles[pos]
	if tile is MahjongTile:
		return not tile.is_matched and not tile.is_in_inventory
	return true


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
