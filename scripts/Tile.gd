## Tile.gd — Peça do Mahjong Solitaire (Godot 4.x)
##
## Area2D com visual premium de bloco de resina 3D (formato dominó vertical).
## Mega Bake: Texto e sombra num único PNG.

class_name MahjongTile
extends Area2D

## Posição na grade: x (coluna), y (linha), z (camada).
var grid_pos := Vector3i.ZERO
## Identificador da estampa do gato (1–20).
var cat_id: int = 1
## Tamanho da peça em pixels (dominó vertical: 80×110).
var tile_size := Vector2(80, 110)
## Deslocamento em pixels para posicionamento sub-grid (half-tile offset).
var pixel_offset := Vector2.ZERO

## Estado de jogo.
var is_matched: bool = false
var is_hinted: bool = false
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_visuals()
		
## Drag & Peek
var is_dragging := false
var start_pos := Vector2.ZERO
const DRAG_THRESHOLD := 15.0

## Inventário — armazena estado original para revive.
var is_in_inventory: bool = false
var original_global_pos: Vector2 = Vector2.ZERO
var original_z_index: int = 0

## Referências internas.
var _collision_shape: CollisionShape2D
var _sprite: Sprite2D
var _select_tween: Tween
var _shake_tween: Tween
var _disintegrate_tween: Tween
var _is_shaking := false

const TOTAL_TYPES := 20

## ─── Cache Dinâmico "Mega Bake" ───────────────────────────────
static var _baked_textures_cache: Dictionary = {}

static func _init_baked_textures() -> void:
	if _baked_textures_cache.is_empty():
		for id in range(1, 21):
			_baked_textures_cache[id] = load("res://assets/tiles/cat%d.png" % id)


func _ready() -> void:
	input_pickable = true
	collision_layer = 1
	collision_mask = 1
	_init_baked_textures()
	_build_visuals()


func get_calculated_z_index() -> int:
	return grid_pos.z * 10


func calculate_target_pos(cell_w: float, cell_h: float, tile_w: float, tile_h: float, z_off_x: float, z_off_y: float) -> Vector2:
	"""Calcula a posição LOCAL correta dentro do BoardManager baseada exclusivamente
	em grid_pos e pixel_offset. Usado pelo Undo/Revive para garantir alinhamento
	preciso independente do zoom (Auto-Framing) atual do tabuleiro."""
	var sx := grid_pos.x * cell_w + grid_pos.z * z_off_x + tile_w / 2.0 + pixel_offset.x
	var sy := grid_pos.y * cell_h + grid_pos.z * z_off_y + tile_h / 2.0 + pixel_offset.y
	return Vector2(sx, sy)

func setup(pos: Vector3i, type_id: int, size: Vector2) -> void:
	if _select_tween and _select_tween.is_valid(): _select_tween.kill()
	if _shake_tween and _shake_tween.is_valid(): _shake_tween.kill()
	
	grid_pos = pos
	cat_id = type_id
	tile_size = size
	z_index = get_calculated_z_index()
	
	# A CURA DO POOLING: Força a atualização da imagem quando a peça é reciclada do BoardManager
	update_sticker()


func cells_occupied() -> Array[Vector2i]:
	return [
		Vector2i(grid_pos.x, grid_pos.y),
		Vector2i(grid_pos.x + 1, grid_pos.y),
		Vector2i(grid_pos.x, grid_pos.y + 1),
		Vector2i(grid_pos.x + 1, grid_pos.y + 1)
	]


# ─── Visuais: Bloco Dominó de Resina (Mega Bake) ───────────────────────────────

func _build_visuals() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _baked_textures_cache[cat_id]
	_sprite.name = "TileSprite"
	add_child(_sprite)
	
	# Usar escala caso o asset seja maior/menor que tilesize
	var tex_size := _sprite.texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		_sprite.scale = tile_size / tex_size
	
	# ── Hitbox de precisão ──
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	
	# Dimensões de hit restritas especificamente à área "Face" da peça (Bloking Solid)
	var face_useful_w: float = 98.0 * 0.95
	var face_useful_h: float = 116.0 * 0.95
	
	# Adiciona 10 pixels extras
	var hitbox_padding := 10.0
	shape.size = Vector2(face_useful_w + hitbox_padding, face_useful_h + hitbox_padding)
	
	_collision_shape.shape = shape
	_collision_shape.name = "CollisionShape"
	add_child(_collision_shape)


# ─── Update Visuals ─────────────────────────────────────────────────

func update_sticker() -> void:
	if _sprite:
		_sprite.texture = _baked_textures_cache[cat_id]

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if is_matched or is_in_inventory:
		return
	
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
	
	if is_selected:
		modulate = Color(1.3, 1.25, 0.85, 1.0)
		_select_tween = create_tween()
		_select_tween.set_loops()
		_select_tween.tween_property(self , "scale", Vector2(1.08, 1.08), 0.3) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_select_tween.tween_property(self , "scale", Vector2(1.0, 1.0), 0.3) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)


func set_blocked(_blocked: bool) -> void:
	if is_selected:
		return
	modulate = Color(1.0, 1.0, 1.0)
	if _sprite:
		_sprite.modulate = Color(1.0, 1.0, 1.0)


func play_error_shake() -> void:
	"""Tremor rápido no eixo X para feedback de peça bloqueada."""
	if _is_shaking or is_in_inventory or is_matched or is_dragging:
		return
	
	AudioManager.play_haptic(35)
	_is_shaking = true
	var orig_x = position.x
	_shake_tween = create_tween()
	var offset = 6.0
	var dur = 0.04
	
	# Vai e vem rápido no eixo X
	_shake_tween.tween_property(self , "position:x", orig_x + offset, dur)
	_shake_tween.tween_property(self , "position:x", orig_x - offset, dur * 2)
	_shake_tween.tween_property(self , "position:x", orig_x + (offset / 2.0), dur * 1.5)
	_shake_tween.tween_property(self , "position:x", orig_x, dur)
	
	_shake_tween.tween_callback(func():
		position.x = orig_x # Garante o alinhamento no final
		_is_shaking = false
	)


# ─── Animações ──────────────────────────────────────────────────────

func play_match_animation() -> void:
	is_matched = true
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
	
	var match_tween := create_tween()
	match_tween.set_parallel(true)
	match_tween.tween_property(self , "scale", Vector2(0.0, 0.0), 0.3) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	match_tween.tween_property(self , "modulate:a", 0.0, 0.25) \
		.set_ease(Tween.EASE_IN)
	
	await match_tween.finished
	visible = false
	_collision_shape.set_deferred("disabled", true)


func play_disintegrate_nonblocking(on_done: Callable = Callable()) -> void:
	"""Desintegração fire-and-forget — NÃO usa await, não bloqueia input.
	Fase 1 (0.05s): squash elástico sutil (scale x1.25).
	Fase 2 (0.15s): colapso para 0 + fade simultâneo.
	Chama on_done() ao terminar (opcional)."""
	is_matched = true
	input_pickable = false
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
	if _disintegrate_tween and _disintegrate_tween.is_valid():
		_disintegrate_tween.kill()
	
	var cur_scale := scale
	
	# Fase 1: squash elástico rápido (pulso de match)
	_disintegrate_tween = create_tween()
	_disintegrate_tween.tween_property(self , "scale",
		Vector2(cur_scale.x * 1.25, cur_scale.y * 1.25), 0.05) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Fase 2: colapso + fade em paralelo
	_disintegrate_tween.tween_callback(func():
		var phase2 := create_tween()
		phase2.set_parallel(true)
		phase2.tween_property(self , "scale", Vector2.ZERO, 0.23) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		phase2.tween_property(self , "modulate:a", 0.0, 0.20) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		phase2.finished.connect(func():
			visible = false
			if _collision_shape:
				_collision_shape.set_deferred("disabled", true)
			if on_done.is_valid():
				on_done.call()
			queue_free()
		)
	)


func play_hint_glow() -> void:
	"""Pulso de luz zen constante e sem alterar escala."""
	is_hinted = true
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
	
	_select_tween = create_tween()
	_select_tween.set_loops()
	_select_tween.tween_property(self , "modulate", Color(1.35, 1.25, 0.9, 1.0), 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_select_tween.tween_property(self , "modulate", Color(1.1, 1.05, 0.95, 1.0), 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func stop_hint_glow() -> void:
	is_hinted = false
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
	modulate = Color.WHITE
	# Só reseta escala se a peça estiver no tabuleiro (escala base = 1.0).
	# Se estiver no inventário, a escala já foi definida pela animação de voo.
	if not is_in_inventory:
		scale = Vector2(1.0, 1.0)


func mark_matched() -> void:
	is_matched = true
	visible = false
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)


func animate_lift() -> void:
	"""Levanta a peça para arrasto."""
	if is_in_inventory or is_matched: return
	
	if not is_hinted:
		if _select_tween and _select_tween.is_valid():
			_select_tween.kill()
		modulate = Color(1.1, 1.1, 1.1, 1.0)
		
	z_index = 4000


func animate_drop() -> void:
	"""Devolve a peça espiada ao tabuleiro."""
	if is_in_inventory or is_matched: return
	
	is_dragging = false
	
	var drop_tween := create_tween()
	drop_tween.tween_property(self , "global_position", start_pos, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	drop_tween.tween_callback(func():
		z_index = get_calculated_z_index()
		if not is_hinted:
			modulate = Color.WHITE
	)
