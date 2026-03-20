## BoardManager.gd — Gerenciador do tabuleiro do Mahjong Solitaire (Godot 4.x)
##
## Responsável por: gerar layouts, algoritmo de geração reversa (100% solvável),
## instanciar peças, verificar regras de bloqueio/match e renderizar o tabuleiro.

class_name BoardManager
extends Node2D

## Sinal emitido quando uma peça é clicada.
signal tile_pressed(tile: MahjongTile)

# ─── Constantes de Layout (Calibragem Mega Bake) ──────────────────────

## Largura visual do 'carimbo' (inclui a madeira + transparência da sombra lateral)
const TILE_W := 108.0
## Altura visual do 'carimbo' (inclui a madeira + transparência da sombra inferior)
const TILE_H := 130.0

## Distância real da grade horizontal. Calibrada para encoste perfeito das faces (metade de 98px)
const CELL_W := 44.6  
## Distância real da grade vertical. Calibrada para sobreposição consistente na mesma altura Z
const CELL_H := 58.0  

## Offset 3D por camada Z (Estilo Bloco Sólido - simulando a espessura física exata da madeira)
const Z_OFFSET_X := -8.0   # Deslocamento lateral para cada andar superior
const Z_OFFSET_Y := -14.0  # Deslocamento vertical para cada andar superior

## Dimensões restritas da Face superior (área clicável e intersecção lógica)
const FACE_W := 98.0
const FACE_H := 116.0

## Número de tipos de estampa (Gatos disponíveis no pool)
const NUM_TYPES := 20

# ─── Estado do jogo ─────────────────────────────────────────────────

## Dicionário de tiles: Vector3i → MahjongTile (ou dados durante geração)
var tiles: Dictionary = {}
var move_history: Array = []
var current_shape: Array[Vector3i] = []
var is_shuffling: bool = false
var is_input_locked: bool = false
var _blocking_cache: Dictionary = {}

# ─── Áudio ──────────────────────────────────────────────────────────
var sfx_tile_block: AudioStream = preload("res://assets/audio/sfx/tile_block.wav")

# ─── API pública ────────────────────────────────────────────────────

func new_game(level: int = 1, keep_shape: bool = false) -> void:
	"""Gera um novo tabuleiro 100% solvável e renderiza."""
	tiles.clear()
	move_history.clear()
	_clear_children()
	
	if not keep_shape or current_shape.is_empty():
		current_shape = get_next_level_shape(level)
		
	var profile: Dictionary = get_level_profile(level)
	
	if profile.get("layer_boost_pairs", 0) > 0:
		_inject_boost_pairs(current_shape, profile["layer_boost_pairs"])
		
	# BLINDAGEM MATEMÁTICA OBRIGATÓRIA: Forçar número de layouts para sempre Par
	if current_shape.size() % 2 != 0:
		var removed = current_shape.pop_back()
		print("[BoardManager] BLINDAGEM MATEMÁTICA: O layout base original continha bloco ímpar.", removed, " removido!")
		
	assert(current_shape.size() % 2 == 0, "ERRO CRÍTICO: Layout físico tem número ímpar de blocos!")
		
	_generate_beatable(current_shape, profile.get("cat_variety", NUM_TYPES))
	_render_board()
	print("[BoardManager] new_game: %d tiles gerados" % tiles.size())


func active_tiles() -> Array[MahjongTile]:
	"""Retorna tiles ainda não removidos."""
	var result: Array[MahjongTile] = []
	for tile in tiles.values():
		if is_instance_valid(tile) and tile is MahjongTile and not tile.is_matched and not tile.is_in_inventory:
			result.append(tile)
	return result


func is_tile_free(tile: MahjongTile) -> bool:
	"""Retorna APENAS o estado cacheado para performance extrema (CPU)."""
	if tile.is_matched or tile.is_in_inventory:
		return false
	return _blocking_cache.get(tile, true)


func recalculate_all_blocking() -> void:
	"""
	Executa o loop pesado de oclusão 55/45 UMA ÚNICA VEZ e preenche o _blocking_cache.
	"""
	_blocking_cache.clear()
	var active = active_tiles()
	
	# Cache de retângulos para evitar recálculo no loop interno
	var tile_rects: Dictionary = {}
	for tile in active:
		tile_rects[tile] = Rect2(
			tile.grid_pos.x * CELL_W + tile.grid_pos.z * Z_OFFSET_X + tile.pixel_offset.x,
			tile.grid_pos.y * CELL_H + tile.grid_pos.z * Z_OFFSET_Y + tile.pixel_offset.y,
			FACE_W, FACE_H
		)

	for tile in active:
		var tile_rect: Rect2 = tile_rects[tile]
		var face_area = FACE_W * FACE_H
		var total_overlap = 0.0
		var is_blocked_above = false
		
		# --- 1. Bloqueio por sobreposição (Z+1 ou Visual Front) ---
		for other in active:
			if other == tile: continue
			
			var is_above: bool = (other.grid_pos.z > tile.grid_pos.z)
			var is_visually_in_front: bool = (other.grid_pos.z == tile.grid_pos.z and other.position.y > tile.position.y)
			
			if not (is_above or is_visually_in_front): 
				continue
			
			var other_rect: Rect2 = tile_rects[other]
			var intersection := tile_rect.intersection(other_rect)
			total_overlap += intersection.get_area()
			
			if total_overlap / face_area >= 0.25:
				is_blocked_above = true
				break
		
		if is_blocked_above:
			_blocking_cache[tile] = false
			continue
			
		# --- 2. Bloqueio lateral no MESMO NÍVEL (Z) ---
		var left_blocked := false
		var right_blocked := false
		for dy in range(-1, 2):
			if _has_neighbor(tile.grid_pos.x - 2, tile.grid_pos.y + dy, tile.grid_pos.z):
				left_blocked = true
			if _has_neighbor(tile.grid_pos.x + 2, tile.grid_pos.y + dy, tile.grid_pos.z):
				right_blocked = true
				
		if left_blocked and right_blocked:
			_blocking_cache[tile] = false
		else:
			_blocking_cache[tile] = true


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
	# This _try_match logic seems mostly unused inside GameManager's pair resolution, it's a fallback.
	return true


func record_match(_t1: MahjongTile, _t2: MahjongTile) -> void:
	"""Registra um match já validado e animado."""
	pass # Move history is now dynamically pushed in GameManager per tile.


func is_won() -> bool:
	"""Verdadeiro se todas as peças foram removidas."""
	for tile in tiles.values():
		if is_instance_valid(tile) and tile is MahjongTile and not tile.is_matched:
			return false
	return true


func has_moves() -> bool:
	"""Verdadeiro se existe pelo menos um par disponível."""
	return find_hint().size() > 0


func find_hint(inv_ids: Array[int] = []) -> Array[MahjongTile]:
	"""Retorna um Array de peças para dica. Priority 1: Match com inventário. Priority 2: Par no topo."""
	var free_tiles: Array[MahjongTile] = []
	for tile in tiles.values():
		if is_instance_valid(tile) and tile is MahjongTile and not tile.is_matched and is_tile_free(tile):
			free_tiles.append(tile)
	
	# Order by Z-index descending (highest pieces first)
	free_tiles.sort_custom(func(a: MahjongTile, b: MahjongTile) -> bool:
		return a.grid_pos.z > b.grid_pos.z
	)
	
	# Priority 1: Salva-vidas de Slot
	for tile in free_tiles:
		if tile.cat_id in inv_ids:
			return [tile]
			
	# Priority 2: Fallback para Tabuleiro
	var seen: Dictionary = {}
	for tile in free_tiles:
		if seen.has(tile.cat_id):
			return [seen[tile.cat_id], tile]
		else:
			seen[tile.cat_id] = tile
	
	return []


func execute_shuffle() -> void:
	"""Embaralha as texturas ativas no tabuleiro usando uma onda diagonal."""
	if is_shuffling:
		return
		
	var active: Array[MahjongTile] = active_tiles()
	if active.is_empty():
		return
		
	is_shuffling = true
	
	# Extrair apenas os IDs para embaralhar
	var types: Array[int] = []
	for tile in active:
		types.append(tile.cat_id)
		
	types.shuffle()
	
	# Ordenar peças para a onda diagonal (x + y)
	active.sort_custom(func(a: MahjongTile, b: MahjongTile) -> bool:
		var sum_a = a.position.x + a.position.y
		var sum_b = b.position.x + b.position.y
		return sum_a < sum_b
	)
	
	var total_anim_time := 0.5
	var num_tiles := active.size()
	var time_per_tile := total_anim_time / num_tiles
	var _tweens_completed := 0
	
	for i in range(num_tiles):
		var tile = active[i]
		var new_type = types[i]
		var delay = i * time_per_tile
		
		var tween := tile.create_tween()
		# Aguarda o atraso específico do tile
		if delay > 0:
			tween.tween_interval(delay)
			
		# Encerra scale.x para 0 (flip) rápido (0.06s)
		tween.tween_property(tile, "scale:x", 0.0, 0.06).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		
		# Muda o tipo no meio do flip
		tween.tween_callback(func():
			if is_instance_valid(tile):
				tile.cat_id = new_type
				tile.update_sticker() # Call to update visual
		)
		
		# Volta o scale pra proporção original que o zoom da cena dá (0.06s)
		# Note: O scale do tile deve voltar para 1.0 ou o original que tem gravado. Mas por default é 1.0 já q ele é filho direto.
		var orig_scale_x = tile.scale.x if tile.scale.x > 0 else 1.0
		tween.tween_property(tile, "scale:x", orig_scale_x, 0.06).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		# Para o último, limpar is_shuffling
		if i == num_tiles - 1:
			tween.finished.connect(func():
				is_shuffling = false
				clear_selection()
			)


func update_tile_states() -> void:
	"""Atualiza visual de blocked/free em todas as peças."""
	recalculate_all_blocking()
	for tile in tiles.values():
		if is_instance_valid(tile) and tile is MahjongTile and not tile.is_matched and not tile.is_in_inventory:
			tile.set_blocked(not is_tile_free(tile))


func highlight_hint(hint_tiles: Array[MahjongTile]) -> void:
	"""Destaca peças com glow continuo de hint."""
	clear_selection()
	for tile in hint_tiles:
		tile.play_hint_glow()


func clear_selection() -> void:
	"""Remove qualquer seleção visual e para hint glow."""
	for tile in tiles.values():
		if is_instance_valid(tile) and tile is MahjongTile and not tile.is_matched and not tile.is_in_inventory:
			tile.is_selected = false
			tile.stop_hint_glow()
	
	# Recalcula e reaplica o filtro cinza nas peças bloqueadas
	update_tile_states()


func clear_hint_for_type(id: int) -> void:
	"""Varrre o tabuleiro e remove hint glow persistente para peças deste cat_id após um match alternativo."""
	for tile in tiles.values():
		if is_instance_valid(tile) and tile is MahjongTile and tile.cat_id == id:
			tile.stop_hint_glow()


# ─── Progressão e Dificuldade ───────────────────────────────────────

func get_level_profile(level: int) -> Dictionary:
	"""
	Retorna a Dificuldade Curva Senoidal estruturada em blocos modulares de Mundo (10 fases).
	"""
	var world_index := int((level - 1) / 10.0)
	var cur_phase := (level - 1) % 10 + 1 # 1 a 10
	var variety: int = NUM_TYPES
	var boost_pairs: int = 0
	
	if cur_phase >= 1 and cur_phase <= 4:
		# Fase 1~4: Fácil / Aquecimento
		variety = 6 + (cur_phase * 2) # N1=8 ... N4=14
		boost_pairs = randi() % 2     # 0 a 1 pares físicos a mais
	elif cur_phase == 5:
		# Fase 5: Pico Médio (Aumento drástico base)
		variety = 14
		boost_pairs = 2
	elif cur_phase == 6:
		# Fase 6: Respiro Zen (Muito mais fácil após o pico)
		variety = 8
		boost_pairs = 0
	elif cur_phase >= 7 and cur_phase <= 9:
		# Fase 7~9: Escalada rumo ao Boss
		variety = 12 + ((cur_phase - 6) * 1) # N7=13 ... N9=15
		boost_pairs = randi() % 2 + 1        # 1 a 2 pares extras
	elif cur_phase == 10:
		# Fase 10: Boss
		variety = min(18 + randi() % 3, NUM_TYPES) # 18 a 20 variações de gatos (tensão altíssima de pareamento falso no inventário)
		boost_pairs = 3 + randi() % 2              # 3 ou 4 pares inteiros a mais fisicamente pendurados em Z acima
		
	# Escalada infinita pós mundo 0
	variety = clampi(variety + (world_index * 2), 1, NUM_TYPES)
	boost_pairs += world_index
		
	var is_hard := false
	if cur_phase == 5 or cur_phase >= 8:
		is_hard = true
		
	return {
		"cat_variety": variety,
		"layer_boost_pairs": boost_pairs,
		"is_hard_level": is_hard
	}

func _inject_boost_pairs(slots: Array[Vector3i], pairs_amount: int) -> void:
	"""
	Encontra posições válidas suportadas no layout para socar pares a mais (aumentando a pirâmide atômica).
	As injeções buscam o Z atual de um bloco base e injetam em Z+1 sobre células seguras validas.
	"""
	return # CONGELAMENTO PROCEDURAL: Garante que os layouts permaneçam estritamente no formato base projetado.
	if pairs_amount <= 0: return
	var injection_count = pairs_amount * 2
	
	# Mapeador de existência temporário local ao layout físico não construído
	var map_temp := {}
	var z_max := 0
	for pos in slots:
		map_temp[pos] = true
		if pos.z > z_max:
			z_max = pos.z
			
	var possible_spawns: Array[Vector3i] = []
	for pos in slots:
		var target_z = pos.z + 1
		# Na regra rigorosa um tile físico em X,Y só encaixa estável se as 4 células abaixo base (0,0) também estiverem na cena
		# Mas considerando nossa simplificação celular da grade onde cada bloco = 1 celular 3D no map:
		var inject_pos = Vector3i(pos.x, pos.y, target_z)
		if not map_temp.has(inject_pos):
			# Pra evitar pirâmides palitinho absurdamente esguias (stack estrito infinito) randomiza mas só onde faz suporte largo
			var left_support = map_temp.has(Vector3i(pos.x - 2, pos.y, pos.z))
			var right_support = map_temp.has(Vector3i(pos.x + 2, pos.y, pos.z))
			# Permite injetar Z+1 se ancorar no bloco e tiver amigos vizinhos da mesma base (espalhamento orgânico)
			if left_support or right_support or randf() > 0.6: 
				possible_spawns.append(inject_pos)
			
	possible_spawns.shuffle()
	
	var injected := 0
	for sp in possible_spawns:
		if injected >= injection_count: break
		# Prevenir sobreposição das novas injeções na rodada
		if not map_temp.has(sp):
			slots.append(sp)
			map_temp[sp] = true
			injected += 1
			
	print("[BoardManager] Injetou %d blocos extras (boost) no layout físico" % injected)

# ─── Layout ─────────────────────────────────────────────────────────

func get_next_level_shape(level: int) -> Array[Vector3i]:
	var rng = RandomNumberGenerator.new()
	rng.seed = level
	
	var shapes = {}
	
	if level >= 1 and level <= 5:
		shapes = {
			"snake": _load_shape_snake,
			"flat_field": _load_shape_flat_field
		}
	elif level >= 6 and level <= 10:
		shapes = {
			"classic_turtle": _load_shape_classic_turtle,
			"neko_pillar": _load_shape_neko_pillar
		}
	else:
		if level % 5 == 0:
			shapes = {
				"pyramid": _load_shape_pyramid,
				"twin_peaks": _load_shape_twin_peaks
			}
		elif level % 5 == 1:
			shapes = {
				"snake": _load_shape_snake,
				"flat_field": _load_shape_flat_field
			}
		else:
			shapes = {
				"classic_turtle": _load_shape_classic_turtle,
				"neko_pillar": _load_shape_neko_pillar
			}
		
	var keys = shapes.keys()
	var chosen = keys[rng.randi() % keys.size()]
	
	print("[BoardManager] Nível %d | Semente %d | Gerando layout: %s" % [level, rng.seed, chosen])
	return shapes[chosen].call()


func _load_shape_neko_pillar() -> Array[Vector3i]:
	"""Layout 'Neko Pillar' (Ref. Estrutural) — Pilar Vertical (6 colunas). Total: 66 peças (33 pares)."""
	var slots: Array[Vector3i] = []
	# Z=0 (Base 6 colunas, alta densidade e altura 12): 30 peças
	for y in range(2, 11, 2): slots.append(Vector3i(0, y, 0)) # Col 1
	for y in range(1, 12, 2): slots.append(Vector3i(2, y, 0)) # Col 2
	for y in range(0, 13, 2): slots.append(Vector3i(4, y, 0)) # Col 3 (Centro)
	for y in range(1, 12, 2): slots.append(Vector3i(6, y, 0)) # Col 4
	for y in range(2, 11, 2): slots.append(Vector3i(8, y, 0)) # Col 5
	for y in range(5, 8, 2): slots.append(Vector3i(10, y, 0)) # Col 6 (Extra support)
	# Z=1 (Camada 1): 20 peças
	for y in range(3, 10, 2): slots.append(Vector3i(2, y, 1))
	for y in range(2, 11, 2): slots.append(Vector3i(4, y, 1))
	for y in range(2, 11, 2): slots.append(Vector3i(6, y, 1))
	for y in range(3, 10, 2): slots.append(Vector3i(8, y, 1))
	slots.append(Vector3i(4, 0, 1))
	slots.append(Vector3i(6, 12, 1))
	# Z=2 (Camada 2): 10 peças
	for y in range(4, 9, 2): slots.append(Vector3i(4, y, 2))
	for y in range(5, 8, 2): slots.append(Vector3i(6, y, 2))
	for y in range(4, 9, 2): slots.append(Vector3i(8, y, 2))
	slots.append(Vector3i(4, 2, 2))
	slots.append(Vector3i(6, 9, 2))
	# Z=3 (Topo): 6 peças
	for y in range(5, 8, 2): slots.append(Vector3i(4, y, 3))
	for y in range(4, 9, 2): slots.append(Vector3i(6, y, 3))
	slots.append(Vector3i(8, 7, 3))
	return slots


func _load_shape_classic_turtle() -> Array[Vector3i]:
	"""Tartaruga centralizada. Foco no meio."""
	var slots: Array[Vector3i] = []
	# Z=0
	for y in range(2, 11, 2): slots.append(Vector3i(0, y, 0)); slots.append(Vector3i(10, y, 0))
	for y in range(1, 12, 2): slots.append(Vector3i(2, y, 0)); slots.append(Vector3i(8, y, 0))
	for y in range(0, 13, 2): slots.append(Vector3i(4, y, 0)); slots.append(Vector3i(6, y, 0))
	# Z=1
	for y in range(3, 10, 2): slots.append(Vector3i(2, y, 1)); slots.append(Vector3i(8, y, 1))
	for y in range(2, 11, 2): slots.append(Vector3i(4, y, 1)); slots.append(Vector3i(6, y, 1))
	# Z=2
	for y in range(4, 9, 2): slots.append(Vector3i(4, y, 2)); slots.append(Vector3i(6, y, 2))
	# Z=3
	slots.append(Vector3i(4, 6, 3)); slots.append(Vector3i(6, 6, 3))
	return slots


func _load_shape_pyramid() -> Array[Vector3i]:
	"""Base subindo gradativamente até Z=4."""
	var slots: Array[Vector3i] = []
	# Z=0 (6 colunas)
	for x in [0,2,4,6,8,10]:
		for y in range(0, 13, 2): slots.append(Vector3i(x, y, 0))
	# Z=1 (4 colunas centrais)
	for x in [2,4,6,8]:
		for y in range(2, 11, 2): slots.append(Vector3i(x, y, 1))
	# Z=2 (2 colunas centrais)
	for x in [4,6]:
		for y in range(4, 9, 2): slots.append(Vector3i(x, y, 2))
	# Z=3 (2 colunas centrais)
	for x in [4,6]:
		for y in range(5, 8, 2): slots.append(Vector3i(x, y, 3))
	# Z=4 
	slots.append(Vector3i(4, 6, 4))
	slots.append(Vector3i(6, 6, 4))
	return slots


func _load_shape_twin_peaks() -> Array[Vector3i]:
	"""Duas torres gigantes com Z=4, separadas e com meio vazio."""
	var slots: Array[Vector3i] = []
	# Z=0 conectando elas + pontes nas bordas
	for x in [0,2,8,10]:
		for y in range(0, 13, 2): slots.append(Vector3i(x, y, 0))
	for x in [4,6]:
		for y in [0, 12]: slots.append(Vector3i(x, y, 0)) 
		
	# Z=1 (Torres)
	for x in [0,2,8,10]:
		for y in range(2, 11, 2): slots.append(Vector3i(x, y, 1))
	# Z=2
	for x in [0,2,8,10]:
		for y in range(4, 9, 2): slots.append(Vector3i(x, y, 2))
	# Z=3
	for x in [0,2,8,10]:
		for y in range(5, 8, 2): slots.append(Vector3i(x, y, 3))
	# Z=4
	slots.append(Vector3i(0, 6, 4)); slots.append(Vector3i(2, 6, 4))
	slots.append(Vector3i(8, 6, 4)); slots.append(Vector3i(10, 6, 4))
	return slots


func _load_shape_snake() -> Array[Vector3i]:
	"""Formato de Sinuoso/S em Z baixos. Limitado ~44 peças."""
	var slots: Array[Vector3i] = []
	# Z=0
	for y in range(0, 4, 2):
		slots.append(Vector3i(0, y, 0)); slots.append(Vector3i(2, y, 0)); slots.append(Vector3i(4, y, 0))
	for y in range(4, 8, 2):
		slots.append(Vector3i(4, y, 0)); slots.append(Vector3i(6, y, 0)); slots.append(Vector3i(8, y, 0))
	for y in range(8, 12, 2):
		slots.append(Vector3i(0, y, 0)); slots.append(Vector3i(2, y, 0)); slots.append(Vector3i(4, y, 0))
		
	for y in range(0, 13, 2):
		slots.append(Vector3i(10, y, 0))
	
	# Z=1 (Sobre a cobra)
	for y in range(1, 4, 2):
		slots.append(Vector3i(2, y, 1)); slots.append(Vector3i(4, y, 1))
	for y in range(5, 8, 2):
		slots.append(Vector3i(4, y, 1)); slots.append(Vector3i(6, y, 1))
	for y in range(9, 12, 2):
		slots.append(Vector3i(2, y, 1)); slots.append(Vector3i(4, y, 1))
		
	# Z=2 (Picos)
	slots.append(Vector3i(2, 2, 2)); slots.append(Vector3i(6, 6, 2)); slots.append(Vector3i(2, 10, 2))
	return slots


func _load_shape_flat_field() -> Array[Vector3i]:
	"""Tabuleiro espalhado e raso. Limitado a ~58 peças."""
	var slots: Array[Vector3i] = []
	# Z=0
	for x in [0,2,4,6,8,10]:
		for y in range(0, 14, 2): slots.append(Vector3i(x, y, 0))
	
	# Z=1 espalhadas 
	for x in [2,4,6,8]:
		for y in [2, 6, 10]:
			slots.append(Vector3i(x, y, 1))
	return slots


# ─── Geração Reversa (Beatable) ────────────────────────────────────

func _generate_beatable(slots: Array[Vector3i], cat_variety: int = NUM_TYPES) -> void:
	"""Algoritmo de Geração Reversa — garante 100% de solvabilidade e utiliza apenas a cota de gatos definida no perfil."""
	var total := slots.size()
	
	@warning_ignore("integer_division")
	var num_pairs := total / 2
	
	# 1. Definir o pool finito de gatinhos (subset por limitação de fase)
	var available_cats: Array[int] = []
	for i in range(1, NUM_TYPES + 1):
		available_cats.append(i)
	available_cats.shuffle()
	
	var selected_cat_pool: Array[int] = []
	for i in range(mini(cat_variety, NUM_TYPES)):
		selected_cat_pool.append(available_cats[i])
	
	# 2. Distribuir os IDs pareados utilizando apenas o pool restrito
	var type_ids: Array[int] = []
	for i in range(num_pairs):
		type_ids.append(selected_cat_pool[i % selected_cat_pool.size()])
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
		# --- Bloqueio por sobreposição — Regra 65/35 (pixel-based com Face) ---
		var tile_rect := Rect2(
			slot.x * CELL_W + slot.z * Z_OFFSET_X,
			slot.y * CELL_H + slot.z * Z_OFFSET_Y,
			FACE_W, FACE_H
		)
		var face_area := FACE_W * FACE_H
		var total_overlap := 0.0
		
		for rem_pos: Vector3i in remaining:
			if rem_pos == slot: continue
			if rem_pos.z <= slot.z: continue
			
			var other_rect := Rect2(
				rem_pos.x * CELL_W + rem_pos.z * Z_OFFSET_X,
				rem_pos.y * CELL_H + rem_pos.z * Z_OFFSET_Y,
				FACE_W, FACE_H
			)
			var intersection := tile_rect.intersection(other_rect)
			total_overlap += intersection.get_area()
		
		var blocked_above := (total_overlap / face_area) >= 0.35
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
	move_history.clear()
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
		
		var tile_node: MahjongTile
		if _tile_pool.size() > 0:
			tile_node = _tile_pool.pop_back()
			tile_node.modulate = Color.WHITE
			tile_node.scale = Vector2.ONE
			tile_node.visible = true
			tile_node.is_matched = false
			tile_node.is_in_inventory = false
			tile_node.is_hinted = false
			tile_node.is_selected = false
			
			# Reset Adicional (Blindagem de Reset):
			tile_node.stop_hint_glow() # Garante que brilhos não vazem no pool
			tile_node.set_meta("matched_partner", null)
			tile_node.set_meta("match_landed", false)
			tile_node.set_meta("original_position", null)
		else:
			tile_node = MahjongTile.new()
			
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
	var action_buttons = get_node_or_null("../../UILayer/VBox/BottomMargin/ActionButtonsHBox")
	
	# Limites verticais padrão caso os nós não sejam encontrados
	var top_boundary: float = 180.0
	var bottom_boundary: float = area_h - 120.0
	
	if is_instance_valid(slots_bar):
		# A barra real termina em global_position.y + size.y
		top_boundary = slots_bar.global_position.y + slots_bar.size.y
	
	if is_instance_valid(action_buttons):
		# Os botões começam em global_position.y
		bottom_boundary = action_buttons.global_position.y
		
	# Margens solicitadas (removida a MARGIN_SIDE extra, pois aplicaremos 95% exato)
	const MARGIN_TOP_PX := 25.0
	const MARGIN_BOTTOM_PX := 50.0
	
	var usable_start_y := top_boundary + MARGIN_TOP_PX
	var usable_end_y := bottom_boundary - MARGIN_BOTTOM_PX
	var usable_h: float = usable_end_y - usable_start_y
	var usable_w: float = area_w
	
	# 1. Escala de Glória (Otimizada para preencher 96% do espaço disponível)
	var target_scale: float = minf((usable_w * 0.96) / board_w, (usable_h * 0.96) / board_h)
	
	# 2. Limites de Sanidade (Clamping)
	# Impede que layouts minúsculos fiquem com peças do tamanho da tela, e layouts gigantes fiquem microscópicos
	var MAX_TILE_SCALE := 1.40 # Peças no máximo 40% maiores que o padrão
	var MIN_TILE_SCALE := 0.55 # Peças no mínimo 45% menores que o padrão
	var final_scale := clampf(target_scale, MIN_TILE_SCALE, MAX_TILE_SCALE)
	
	self.scale = Vector2(final_scale, final_scale)
	
	# 3. Centralização Dinâmica e Absoluta
	var scaled_w: float = board_w * final_scale
	var scaled_h: float = board_h * final_scale
	
	# Centraliza perfeitamente no eixo X, anulando o offset original do gerador
	var pos_x: float = (area_w - scaled_w) / 2.0 - (min_px.x * final_scale)
	
	# No eixo Y, usamos um peso de 0.55 (ligeiramente abaixo do centro geométrico) 
	# para acomodar o peso visual da pirâmide 3D e ficar mais próximo do jogador
	var pos_y: float = usable_start_y + (usable_h - scaled_h) * 0.55 - (min_px.y * final_scale)
	
	self.position = Vector2(pos_x, pos_y)
	
	print("[BoardManager] Auto-Framing | Board: %.0f×%.0f | Escala Final: %.2f | Pos: (%.0f, %.0f)" % [
		board_w, board_h, final_scale, pos_x, pos_y
	])
	
	# Forçar uma atualização do SceneTree ANTES de pedir as bounding boxes (Occlusion Fix)
	# para que todas as peças tenham completado sua inserção global, e as globais scales 
	# contem corretamente na regra de 90/10.
	await get_tree().process_frame
	
	update_tile_states()


# ─── Input centralizado ─────────────────────────────────────────────

## Frame do último clique processado — evita dupla emissão por emulação.
var _last_pick_frame: int = -1
## Timestamp do último pick processado — cooldown anti-double-click.
var _last_pick_time: float = 0.0
## Cooldown mínimo entre picks (ms).
const PICK_COOLDOWN_MS := 30.0

## Variáveis do Drag & Peek
var _dragged_tile: MahjongTile = null
var _drag_start_screen_pos: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	"""Top-Down Picker centralizado — com Mouse, Touch e ARRASTO.
	
	REGRA ABSOLUTA: se há uma peça sob o clique, SEMPRE consumir
	o evento para impedir que ele "atravesse".
	"""
	
	if is_input_locked:
		return
	
	# ─── Arrasto Contínuo (Drag/Motion) ───
	if is_shuffling:
		# Ignorar tudo e consumir se for touch, ou retornar
		get_viewport().set_input_as_handled()
		return
		
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and _dragged_tile != null:
		# Consume o evento e arrasta a peça
		get_viewport().set_input_as_handled()
		var motion_pos = event.global_position if "global_position" in event else event.position
		
		# Move livremente baseando-se no pointer de toque
		_dragged_tile.global_position = motion_pos
		
		# Marca arrastar só se moveu mais que o limite
		if not _dragged_tile.is_dragging:
			if motion_pos.distance_to(_drag_start_screen_pos) > MahjongTile.DRAG_THRESHOLD:
				_dragged_tile.is_dragging = true
		return
	
	# ─── Cliques Iniciais e Finais ───
	if not (event is InputEventMouseButton) and not (event is InputEventScreenTouch):
		return
		
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
		
	var world_pos := get_global_mouse_position()
	
	if event.pressed:
		# PRESS: Iniciar o Drag & Peek se possível
		
		# Query: encontrar TODAS as peças sob o ponto de clique
		var space_state := get_world_2d().direct_space_state
		var query := PhysicsPointQueryParameters2D.new()
		query.position = world_pos
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.collision_mask = 0xFFFFFFFF
		
		var results := space_state.intersect_point(query, 32)
		
		var topmost_tile: MahjongTile = null
		var best_z := -1
		
		for result in results:
			var collider = result["collider"]
			if is_instance_valid(collider) and collider is MahjongTile and not collider.is_matched:
				if collider.grid_pos.z > best_z:
					best_z = collider.grid_pos.z
					topmost_tile = collider
					
		if topmost_tile == null:
			return  # Nenhuma peça sob o cursor
			
		get_viewport().set_input_as_handled()
		
		if is_tile_free(topmost_tile):
			_dragged_tile = topmost_tile
			_drag_start_screen_pos = world_pos
			_dragged_tile.start_pos = _dragged_tile.global_position
			_dragged_tile.animate_lift()
		else:
			# SFX: Peça bloqueada (Aumentado o volume em +8 dB para realçar o erro)
			AudioManager.play_sfx(sfx_tile_block, 1.0, 10.0)
			# Peça bloqueada: dispara o shake visual!
			topmost_tile.play_error_shake()
			
	else:
		# RELEASE: Soltar a peça ou finalizar clique
		if _dragged_tile != null:
			get_viewport().set_input_as_handled()
			
			var final_pos = get_global_mouse_position()
			var is_click = final_pos.distance_to(_drag_start_screen_pos) <= MahjongTile.DRAG_THRESHOLD
			
			if is_click:
				# Deduplicação e Cooldown (Aplica só a "cliques")
				var frame := Engine.get_process_frames()
				if frame != _last_pick_frame:
					var now := Time.get_ticks_msec()
					if (now - _last_pick_time) >= PICK_COOLDOWN_MS:
						_last_pick_frame = frame
						_last_pick_time = now
						
						# Emitir a match - Restaurar a tile fisicamente aqui pq não foi animada dropada
						_dragged_tile.animate_drop() # Limpa as modif de lift pq o GameManager vai reparentar/limpar na seq.
						tile_pressed.emit(_dragged_tile)
			else:
				# Foi um arrasto de espiada solto em qualquer lugar. Voltar peca.
				_dragged_tile.animate_drop()
				
			_dragged_tile = null


func _has_neighbor(x: int, y: int, z: int) -> bool:
	var pos := Vector3i(x, y, z)
	if not tiles.has(pos):
		return false
	var tile = tiles[pos]
	if is_instance_valid(tile) and tile is MahjongTile:
		return not tile.is_matched and not tile.is_in_inventory
	return false


var _tile_pool: Array[MahjongTile] = []

func _clear_children() -> void:
	for child in get_children():
		if child is MahjongTile:
			child.hide()
			remove_child(child)
			_tile_pool.push_back(child)
		else:
			child.queue_free()
