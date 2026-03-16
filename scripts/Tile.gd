## Tile.gd — Peça do Mahjong Solitaire (Godot 4.x)
##
## Area2D com visual premium de bloco de resina 3D (formato dominó vertical).
## Chanfro (bevel) com gradiente, sombra suave, hitbox de precisão.
## Sprite sheet de gatinhos (atlas) centralizado na face.

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
var _is_shaking := false

const TOTAL_TYPES := 20

## ─── Atlas do Sprite Sheet de Gatinhos ─────────────────────────────
## Imagem cats.png, 5 colunas × 4 linhas, 20 gatinhos (fundo branco, sem labels)
var FRAME_W: float = 0.0
var FRAME_H: float = 0.0
const ATLAS_COLS: int = 5
const ATLAS_ROWS: int = 4

## Espessura lateral 3D
const SIDE_DEPTH := 5.0
## Padding da face
const FACE_PADDING := 6.0
## Hitbox super reduzida nas laterais para ignorar as bordas grossas transparentes (35% menor)
const HITBOX_SHRINK := 0.35

## Textura compartilhada
static var _cat_atlas: Texture2D = null
static var _shadow_material: ShaderMaterial = null
static var _base_texture: Texture2D = null

static func _load_atlas() -> void:
	if _cat_atlas == null:
		_cat_atlas = load("res://assets/tiles/cats.png")
	if _shadow_material == null:
		_shadow_material = ShaderMaterial.new()
		_shadow_material.shader = load("res://assets/shaders/blur_shadow.gdshader")
		_shadow_material.set_shader_parameter("blur_amount", 8.0)
	if _base_texture == null:
		_base_texture = load("res://assets/tiles/tile_base.png")


func _ready() -> void:
	input_pickable = true
	collision_layer = 1
	collision_mask = 1
	_load_atlas()
	_build_visuals()


func get_calculated_z_index() -> int:
	return grid_pos.z * 500 + grid_pos.y * 20 + grid_pos.x

func setup(pos: Vector3i, type_id: int, size: Vector2) -> void:
	if _select_tween and _select_tween.is_valid(): _select_tween.kill()
	if _shake_tween and _shake_tween.is_valid(): _shake_tween.kill()
	
	grid_pos = pos
	cat_id = type_id
	tile_size = size
	z_index = get_calculated_z_index()


func cells_occupied() -> Array[Vector2i]:
	return [
		Vector2i(grid_pos.x, grid_pos.y), 
		Vector2i(grid_pos.x + 1, grid_pos.y),
		Vector2i(grid_pos.x, grid_pos.y + 1), 
		Vector2i(grid_pos.x + 1, grid_pos.y + 1)
	]


# ─── Atlas ──────────────────────────────────────────────────────────

func _create_cat_atlas_texture(id: int) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = _cat_atlas
	var idx: int = id - 1
	var col: int = idx % ATLAS_COLS
	@warning_ignore("integer_division")
	var row: int = idx / ATLAS_COLS
	
	# Região limpa: cada célula inteira do grid.
	# O espaçamento branco faz parte da célula e serve como margem natural.
	atlas_tex.region = Rect2(
		col * FRAME_W,
		row * FRAME_H,
		FRAME_W,
		FRAME_H
	)
	return atlas_tex


# ─── Visuais: Bloco Dominó de Resina ───────────────────────────────

func _build_visuals() -> void:
	# Calcular dimensões do frame dinamicamente na primeira peça
	if FRAME_W == 0.0 or FRAME_H == 0.0:
		FRAME_W = float(_cat_atlas.get_width()) / float(ATLAS_COLS)
		FRAME_H = float(_cat_atlas.get_height()) / float(ATLAS_ROWS)
		print("[MahjongTile] Atlas 5x4 calculado: Frame=", FRAME_W, "x", FRAME_H)
	
	# ── Base: imagem premium do azulejo 3D ──
	var base_sprite := Sprite2D.new()
	base_sprite.texture = _base_texture
	base_sprite.name = "Base"
	
	var base_w: float = base_sprite.texture.get_width()
	var base_h: float = base_sprite.texture.get_height()
	var scale_x := tile_size.x / base_w
	var scale_y := tile_size.y / base_h
	base_sprite.scale = Vector2(scale_x, scale_y)
	
	# ── Sombra de Profundidade estrutural ──
	var drop_shadow := Sprite2D.new()
	drop_shadow.texture = base_sprite.texture
	drop_shadow.scale = Vector2(scale_x, scale_y)
	drop_shadow.position = Vector2(2.5, 4.0) # Sombra sutil de relevo (mais centrada)
	drop_shadow.modulate = Color(0, 0, 0, 0.15) # Um pouco mais visível
	drop_shadow.material = _shadow_material
	drop_shadow.name = "DropShadow"
	add_child(drop_shadow)
	
	add_child(base_sprite)
	
	# ── Definição da Face Útil ──
	# tile_base.png tem chanfros 3D no TOPO e na DIREITA.
	# Centro da face útil em relação ao centro da imagem total:
	var face_center_x := -(base_w * 0.04) * scale_x  # Empurra para ESQUERDA
	var face_center_y :=  (base_h * 0.025) * scale_y  # Empurra para BAIXO
	var center_offset := Vector2(face_center_x, face_center_y)
	
	# Dimensões da face útil (descontando chanfros)
	var face_useful_w: float = tile_size.x * 0.90
	var face_useful_h: float = tile_size.y * 0.90
	
	# ── Sticker do Gato ──
	var tex_atlas := _create_cat_atlas_texture(cat_id)
	
	# Scale: ajustar o frame inteiro para caber na face útil.
	# O espaçamento branco do atlas serve como padding natural.
	var scale_fit: float = minf(face_useful_w / FRAME_W, face_useful_h / FRAME_H)
	
	# Sombra do sticker (efeito "adesivo colado")
	var sticker_shadow := Sprite2D.new()
	sticker_shadow.texture = tex_atlas
	sticker_shadow.modulate = Color(0, 0, 0, 0.12) # Levemente mais visível
	sticker_shadow.scale = Vector2(scale_fit, scale_fit)
	sticker_shadow.position = center_offset + Vector2(1.0, 1.5)
	sticker_shadow.material = _shadow_material
	sticker_shadow.name = "StickerShadow"
	add_child(sticker_shadow)
	
	# Sticker principal
	_sprite = Sprite2D.new()
	_sprite.texture = tex_atlas
	_sprite.scale = Vector2(scale_fit, scale_fit)
	_sprite.position = center_offset
	_sprite.name = "CatFace"
	add_child(_sprite)
	
	# ── Hitbox de precisão ──
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	
	# Adiciona 10 pixels extras para cobrir o chanfro 3D e facilitar o toque mobile
	var hitbox_padding := 10.0 
	shape.size = Vector2(face_useful_w + hitbox_padding, face_useful_h + hitbox_padding) 
	
	_collision_shape.shape = shape
	_collision_shape.name = "CollisionShape"
	_collision_shape.position = center_offset
	add_child(_collision_shape)



# ─── Update Visuals ─────────────────────────────────────────────────

func update_sticker() -> void:
	var new_tex = _create_cat_atlas_texture(cat_id)
	if _sprite:
		_sprite.texture = new_tex
	if has_node("StickerShadow"):
		get_node("StickerShadow").texture = new_tex

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
		_select_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.3)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_select_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)


func set_blocked(blocked: bool) -> void:
	if is_selected:
		return
	# Removido o escurecimento (modulate). A peça fica sempre colorida.
	modulate = Color(1.0, 1.0, 1.0)
	if _sprite:
		_sprite.modulate = Color(1.0, 1.0, 1.0)


func play_error_shake() -> void:
	"""Tremor rápido no eixo X para feedback de peça bloqueada."""
	if _is_shaking or is_in_inventory or is_matched or is_dragging:
		return
	
	_is_shaking = true
	var orig_x = position.x
	_shake_tween = create_tween()
	var offset = 6.0
	var dur = 0.04
	
	# Vai e vem rápido no eixo X
	_shake_tween.tween_property(self, "position:x", orig_x + offset, dur)
	_shake_tween.tween_property(self, "position:x", orig_x - offset, dur * 2)
	_shake_tween.tween_property(self, "position:x", orig_x + (offset / 2.0), dur * 1.5)
	_shake_tween.tween_property(self, "position:x", orig_x, dur)
	
	_shake_tween.tween_callback(func():
		position.x = orig_x  # Garante o alinhamento no final
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
	match_tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.3)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	match_tween.tween_property(self, "modulate:a", 0.0, 0.25)\
		.set_ease(Tween.EASE_IN)
	
	await match_tween.finished
	visible = false
	_collision_shape.set_deferred("disabled", true)


func play_hint_glow() -> void:
	"""Pulso de luz zen constante e sem alterar escala."""
	is_hinted = true
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
	
	_select_tween = create_tween()
	_select_tween.set_loops()
	_select_tween.tween_property(self, "modulate", Color(1.35, 1.25, 0.9, 1.0), 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_select_tween.tween_property(self, "modulate", Color(1.1, 1.05, 0.95, 1.0), 0.5)\
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
	
	if has_node("DropShadow"):
		var shadow = get_node("DropShadow")
		shadow.position = Vector2(4.0, 6.0)
		shadow.modulate = Color(0, 0, 0, 0.08)


func animate_drop() -> void:
	"""Devolve a peça espiada ao tabuleiro."""
	if is_in_inventory or is_matched: return
	
	is_dragging = false
	
	var drop_tween := create_tween()
	drop_tween.tween_property(self, "global_position", start_pos, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	drop_tween.tween_callback(func():
		z_index = get_calculated_z_index()
		if not is_hinted:
			modulate = Color.WHITE
		
		if has_node("DropShadow"):
			var shadow = get_node("DropShadow")
			shadow.position = Vector2(2.5, 4.0)
			shadow.modulate = Color(0, 0, 0, 0.15)
	)
