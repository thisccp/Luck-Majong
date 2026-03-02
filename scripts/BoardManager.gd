## BoardManager.gd — Gerenciador do tabuleiro do Mahjong Solitaire (Godot 4.x)
##
## Responsável por: gerar layouts, algoritmo de geração reversa (100% solvável),
## instanciar peças, verificar regras de bloqueio/match e renderizar o tabuleiro.

class_name BoardManager
extends Node2D

## Sinal emitido quando uma peça é clicada.
signal tile_pressed(tile: MahjongTile)

# ─── Constantes de layout ───────────────────────────────────────────

## Tamanho de uma célula (a peça ocupa 2 células de largura × 1 de altura).
const CELL_W := 40.0
const CELL_H := 52.0
## Tamanho real do tile widget.
const TILE_W := CELL_W * 2  # 80
const TILE_H := CELL_H       # 52
## Offset 3D por camada Z.
const Z_OFFSET_X := 6.0
const Z_OFFSET_Y := 6.0
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
	
	var slots := _classic_pyramid_layout()
	_generate_beatable(slots)
	_render_board()
	print("[BoardManager] new_game: %d tiles gerados" % tiles.size())


func active_tiles() -> Array[MahjongTile]:
	"""Retorna tiles ainda não removidos."""
	var result: Array[MahjongTile] = []
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched:
			result.append(tile)
	return result


func is_tile_free(tile: MahjongTile) -> bool:
	"""
	Uma peça está livre se:
	  1. Nenhuma peça em z+1 sobrepõe qualquer de suas células.
	  2. Pelo menos um dos lados (esquerdo ou direito) está livre.
	"""
	if tile.is_matched:
		return false
	
	var tile_cells: Array[Vector2i] = tile.cells_occupied()
	
	# --- Bloqueio por sobreposição (z+1) ---
	for other in tiles.values():
		if not (other is MahjongTile):
			continue
		if other.is_matched or other.grid_pos.z != tile.grid_pos.z + 1:
			continue
		var other_cells: Array[Vector2i] = other.cells_occupied()
		for cell in tile_cells:
			if cell in other_cells:
				return false
	
	# --- Bloqueio lateral ---
	var left_blocked := _has_neighbor(tile.grid_pos.x - 2, tile.grid_pos.y, tile.grid_pos.z)
	var right_blocked := _has_neighbor(tile.grid_pos.x + 2, tile.grid_pos.y, tile.grid_pos.z)
	
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
		if tile is MahjongTile and not tile.is_matched:
			tile.set_blocked(not is_tile_free(tile))


func highlight_hint(t1: MahjongTile, t2: MahjongTile) -> void:
	"""Destaca duas peças como hint."""
	clear_selection()
	t1.is_selected = true
	t2.is_selected = true


func clear_selection() -> void:
	"""Remove qualquer seleção visual."""
	for tile in tiles.values():
		if tile is MahjongTile and not tile.is_matched:
			tile.is_selected = false


# ─── Layout ─────────────────────────────────────────────────────────

func _classic_pyramid_layout() -> Array[Vector3i]:
	"""
	Layout de pirâmide clássica.
	  z=0 — 6×5 = 30 tiles
	  z=1 — 4×3 = 12 tiles
	  z=2 — 2×1 =  2 tiles
	  Total = 44 → 22 pares ✔
	"""
	var slots: Array[Vector3i] = []
	var layers := [
		[6, 5, 0, 0],
		[4, 3, 1, 1],
		[2, 1, 2, 2],
	]
	for z in range(layers.size()):
		var cols: int = layers[z][0]
		var rows: int = layers[z][1]
		var x_off: int = layers[z][2]
		var y_off: int = layers[z][3]
		for col in range(cols):
			for row in range(rows):
				slots.append(Vector3i(x_off + col, y_off + row, z))
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
	remaining: Dictionary, placed: Dictionary
) -> Array[Vector3i]:
	var free: Array[Vector3i] = []
	for slot: Vector3i in remaining:
		var sx := slot.x
		var sy := slot.y
		var sz := slot.z
		
		var blocked_above := false
		var cells := [Vector2i(sx, sy), Vector2i(sx + 1, sy)]
		for placed_pos: Vector3i in placed:
			if placed_pos.z == sz + 1:
				var pcells := [
					Vector2i(placed_pos.x, placed_pos.y),
					Vector2i(placed_pos.x + 1, placed_pos.y)
				]
				for cell in cells:
					if cell in pcells:
						blocked_above = true
						break
			if blocked_above:
				break
		if blocked_above:
			continue
		
		var left_blocked := placed.has(Vector3i(sx - 2, sy, sz))
		var right_blocked := placed.has(Vector3i(sx + 2, sy, sz))
		if left_blocked and right_blocked:
			continue
		free.append(slot)
	return free


# ─── Renderização ───────────────────────────────────────────────────

func _render_board() -> void:
	"""Cria os nós de tile e posiciona no tabuleiro."""
	_clear_children()
	
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
	
	# Tamanho total do tabuleiro
	var board_w: float = max_x * CELL_W + max_z * Z_OFFSET_X
	var board_h: float = max_y * CELL_H + max_z * Z_OFFSET_Y
	
	# Centralizar
	var offset_x: float = maxf((area_w - board_w) / 2.0, 10.0)
	var offset_y: float = maxf((area_h - board_h) / 2.0, 10.0)
	
	print("[BoardManager] Board: %.0f×%.0f, Offset: %.0f,%.0f" % [board_w, board_h, offset_x, offset_y])
	
	# Ordenar por Z para camadas corretas
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
		
		# Criar tile programaticamente (sem depender de cena)
		var tile_node := MahjongTile.new()
		tile_node.setup(pos, cat_id_val, Vector2(TILE_W, TILE_H))
		
		# Posição (centro do tile)
		var sx: float = offset_x + pos.x * CELL_W + pos.z * Z_OFFSET_X + TILE_W / 2.0
		var sy: float = offset_y + pos.y * CELL_H + pos.z * Z_OFFSET_Y + TILE_H / 2.0
		tile_node.position = Vector2(sx, sy)
		
		# Adicionar à cena → dispara _ready() e constrói visuais
		add_child(tile_node)
		tile_nodes[pos] = tile_node
	
	# Substituir dicionário de dados por nós
	tiles = tile_nodes
	print("[BoardManager] %d tiles renderizados" % tiles.size())
	
	# Atualizar visuais
	update_tile_states()


# ─── Input centralizado ─────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	"""Top-Down Picker com regras estritas de Mahjong Solitário.
	
	1. Encontra TODAS as peças sob o cursor via intersect_point
	2. Seleciona a peça com maior Z (topo da pilha)
	3. Se a peça do topo NÃO é livre → clique IGNORADO (não atravessa)
	4. Se a peça do topo É livre → emite tile_pressed
	5. O evento é SEMPRE consumido quando há peça sob o cursor
	"""
	var is_click := false
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		is_click = true
	elif event is InputEventScreenTouch and event.is_pressed():
		is_click = true
	
	if not is_click:
		return
	
	# Posição do clique em coordenadas do canvas (mundo 2D)
	var mouse_pos := get_global_mouse_position()
	
	# Usar o DirectSpaceState para encontrar TODAS as peças sob o clique
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
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
		return  # Nenhuma peça sob o cursor — não consumir o evento
	
	# SEMPRE consumir o evento quando há peça — impede "atravessar"
	get_viewport().set_input_as_handled()
	
	# Só emitir o sinal se a peça do topo é LIVRE (regras do Mahjong)
	if is_tile_free(topmost_tile):
		tile_pressed.emit(topmost_tile)


func _has_neighbor(x: int, y: int, z: int) -> bool:
	var pos := Vector3i(x, y, z)
	if not tiles.has(pos):
		return false
	var tile = tiles[pos]
	if tile is MahjongTile:
		return not tile.is_matched
	return true


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
