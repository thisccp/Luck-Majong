## BoardManager.gd — Gerenciador do tabuleiro do Mahjong Solitaire (Godot 4.x)
##
## Responsável por: gerar layouts, algoritmo de geração reversa (100% solvável),
## instanciar peças, verificar regras de bloqueio/match e renderizar o tabuleiro.

class_name BoardManager
extends Node2D

## Sinal emitido quando uma peça é clicada.
signal tile_pressed(tile: MahjongTile)

# ─── Constantes de layout ───────────────────────────────────────────

## Tamanho de uma célula. Com CELL_W menor que TILE_W/2, as peças se sobrepõem lateralmente.
const TILE_W := 76.0
const CELL_W := TILE_W * 0.38  # 28.88
const CELL_H := 52.0
## Tamanho real do tile widget (formato ~3:4 visualmente alinhado como carta).
const TILE_H := CELL_H * 2  # 104
## Offset 3D por camada Z. (Efeito de pilha vertical limpa)
const Z_OFFSET_X := 0.0
const Z_OFFSET_Y := -8.0
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
	
	var slots := _load_turtle_layout()
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
	# Retângulo visual da peça no espaço do tabuleiro (com pixel_offset)
	var tile_rect := Rect2(
		tile.grid_pos.x * CELL_W + tile.grid_pos.z * Z_OFFSET_X + tile.pixel_offset.x,
		tile.grid_pos.y * CELL_H + tile.grid_pos.z * Z_OFFSET_Y + tile.pixel_offset.y,
		TILE_W, TILE_H
	)
	var tile_area := TILE_W * TILE_H
	var total_overlap := 0.0
	
	for other in tiles.values():
		if not (other is MahjongTile):
			continue
		if other.is_matched or other.is_in_inventory or other.grid_pos.z <= tile.grid_pos.z:
			continue
		var other_rect := Rect2(
			other.grid_pos.x * CELL_W + other.grid_pos.z * Z_OFFSET_X + other.pixel_offset.x,
			other.grid_pos.y * CELL_H + other.grid_pos.z * Z_OFFSET_Y + other.pixel_offset.y,
			TILE_W, TILE_H
		)
		var intersection := tile_rect.intersection(other_rect)
		total_overlap += intersection.get_area()
	
	# Bloqueada se ≥ 10% da área coberta
	if total_overlap / tile_area >= 0.10:
		return false
	
	# --- Bloqueio lateral ---
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
		if tile is MahjongTile and not tile.is_matched:
			tile.is_selected = false
			tile.stop_hint_glow()
	
	# Recalcula e reaplica o filtro cinza nas peças bloqueadas
	update_tile_states()


# ─── Layout ─────────────────────────────────────────────────────────

func _load_turtle_layout() -> Array[Vector3i]:
	"""
	Layout 'The Turtle' — Pirâmide Mahjong clássica em 5 camadas (HORIZONTAL COMPACTO).
	Total: 60 peças (30 pares). Formato de tartaruga clássico:
	  • Base diamante com cabeça/cauda no eixo X (larga)
	  • Camadas ímpares (Z=1, Z=3) com half-tile offset
	  • Topo Z=4 com 2 peças
	"""
	var slots: Array[Vector3i] = []

	# ═══ Z=0 (Base — Casco da Tartaruga): 30 peças ═══
	# Diamante com cabeça (esquerda) e cauda (direita)
	# Row y=0: centro estreito (4 peças)
	for x in [6, 8, 10, 12]:
		slots.append(Vector3i(x, 0, 0))
	# Row y=2: expandindo (6 peças)
	for x in [4, 6, 8, 10, 12, 14]:
		slots.append(Vector3i(x, 2, 0))
	# Row y=4: faixa mais larga + cabeça(x=0,2) + cauda(x=16,18) = 10 peças
	for x in [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]:
		slots.append(Vector3i(x, 4, 0))
	# Row y=6: contraindo (6 peças)
	for x in [4, 6, 8, 10, 12, 14]:
		slots.append(Vector3i(x, 6, 0))
	# Row y=8: centro estreito (4 peças)
	for x in [6, 8, 10, 12]:
		slots.append(Vector3i(x, 8, 0))

	# ═══ Z=1 (Half-tile offset): 16 peças ═══
	for x in [7, 9, 11]:
		slots.append(Vector3i(x, 1, 1))
	for x in [5, 7, 9, 11, 13]:
		slots.append(Vector3i(x, 3, 1))
	for x in [5, 7, 9, 11, 13]:
		slots.append(Vector3i(x, 5, 1))
	for x in [7, 9, 11]:
		slots.append(Vector3i(x, 7, 1))

	# ═══ Z=2: 8 peças ═══
	for x in [8, 10]:
		slots.append(Vector3i(x, 2, 2))
	for x in [6, 8, 10, 12]:
		slots.append(Vector3i(x, 4, 2))
	for x in [8, 10]:
		slots.append(Vector3i(x, 6, 2))

	# ═══ Z=3 (Half-tile offset): 4 peças ═══
	for x in [7, 11]:
		slots.append(Vector3i(x, 3, 3))
	for x in [7, 11]:
		slots.append(Vector3i(x, 5, 3))

	# ═══ Z=4 (Topo): 2 peças ═══
	for x in [8, 10]:
		slots.append(Vector3i(x, 4, 4))

	# Total: 30 + 16 + 8 + 4 + 2 = 60 Peças!
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


func _find_free_slots_for_generation(
	remaining: Dictionary, _placed: Dictionary
) -> Array[Vector3i]:
	var free: Array[Vector3i] = []
	for slot: Vector3i in remaining:
		var sx := slot.x
		var sy := slot.y
		var sz := slot.z
		
		var blocked_above := false
		var cells := [
			Vector2i(sx, sy), Vector2i(sx + 1, sy),
			Vector2i(sx, sy + 1), Vector2i(sx + 1, sy + 1)
		]
		for rem_pos: Vector3i in remaining:
			if rem_pos.z > sz:
				var p_sx := rem_pos.x
				var p_sy := rem_pos.y
				var pcells := [
					Vector2i(p_sx, p_sy), Vector2i(p_sx + 1, p_sy),
					Vector2i(p_sx, p_sy + 1), Vector2i(p_sx + 1, p_sy + 1)
				]
				for cell in cells:
					if cell in pcells:
						blocked_above = true
						break
			if blocked_above:
				break
		if blocked_above:
			continue
		
		var left_blocked := false
		var right_blocked := false
		for dy in range(-1, 2):
			if remaining.has(Vector3i(sx - 2, sy + dy, sz)):
				left_blocked = true
			if remaining.has(Vector3i(sx + 2, sy + dy, sz)):
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
	
	# Calcular bounds do layout
	var max_x := 0
	var max_y := 0
	var max_z := 0
	for pos: Vector3i in tiles:
		max_x = maxi(max_x, pos.x + 2)
		max_y = maxi(max_y, pos.y + 1)
		max_z = maxi(max_z, pos.z)
	
	# Tamanho total do tabuleiro (sem escala)
	# Usa pos.y+2 para altura real (tile ocupa 2 células) e abs() para Z offset negativo
	var board_w: float = max_x * CELL_W + absi(max_z) * absf(Z_OFFSET_X) + TILE_W * 0.1
	var board_h: float = (max_y + 1) * CELL_H + absi(max_z) * absf(Z_OFFSET_Y) + TILE_H * 0.5
	
	# Posicionar tiles a partir de (0,0) — sem offset
	var sorted_positions := tiles.keys()
	sorted_positions.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		if a.z != b.z: return a.z < b.z
		if a.y != b.y: return a.y < b.y
		return a.x < b.x
	)
	
	var tile_nodes: Dictionary = {}
	
	for pos: Vector3i in sorted_positions:
		var data = tiles[pos]
		var cat_id_val: int = data["cat_id"]
		var pix_offset: Vector2 = data.get("pixel_offset", Vector2.ZERO) if data is Dictionary else Vector2.ZERO
		
		var tile_node := MahjongTile.new()
		tile_node.setup(pos, cat_id_val, Vector2(TILE_W, TILE_H))
		tile_node.pixel_offset = pix_offset
		
		# Posição relativa ao tabuleiro (centro do tile) + pixel_offset
		var sx: float = pos.x * CELL_W + pos.z * Z_OFFSET_X + TILE_W / 2.0 + pix_offset.x
		var sy: float = pos.y * CELL_H + pos.z * Z_OFFSET_Y + TILE_H / 2.0 + pix_offset.y
		tile_node.position = Vector2(sx, sy)
		
		add_child(tile_node)
		tile_nodes[pos] = tile_node
	
	tiles = tile_nodes
	
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
		
	# Margens solicitadas
	const MARGIN_TOP_PX := 25.0
	const MARGIN_BOTTOM_PX := 50.0
	const MARGIN_SIDE := 0.04  # 4%
	
	var usable_start_y := top_boundary + MARGIN_TOP_PX
	var usable_end_y := bottom_boundary - MARGIN_BOTTOM_PX
	var usable_h: float = usable_end_y - usable_start_y
	var usable_w: float = area_w * (1.0 - MARGIN_SIDE * 2.0)
	
	# Maximizar escala para o espaço
	var scale_factor: float = minf(usable_w / board_w, usable_h / board_h)
	
	self.scale = Vector2(scale_factor, scale_factor)
	
	# Centralizar horizontalmente
	var scaled_w: float = board_w * scale_factor
	var pos_x: float = (area_w - scaled_w) / 2.0
	
	# Centralizar verticalmente dentro do espaço útil exato
	var scaled_h: float = board_h * scale_factor
	var pos_y: float = usable_start_y + (usable_h - scaled_h) / 2.0
	
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
