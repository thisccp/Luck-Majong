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

## Estado de jogo.
var is_matched: bool = false
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_visuals()

## Inventário — armazena estado original para revive.
var is_in_inventory: bool = false
var original_global_pos: Vector2 = Vector2.ZERO
var original_z_index: int = 0

## Referências internas.
var _collision_shape: CollisionShape2D
var _sprite: Sprite2D
var _select_tween: Tween

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
## Hitbox reduzida para precisão (20% menor que o visual)
const HITBOX_SHRINK := 0.20

## Textura compartilhada
static var _cat_atlas: Texture2D = null

static func _load_atlas() -> void:
	if _cat_atlas == null:
		_cat_atlas = load("res://assets/tiles/cats.png")


func _ready() -> void:
	input_pickable = true
	collision_layer = 1
	collision_mask = 1
	_load_atlas()
	_build_visuals()


func setup(pos: Vector3i, type_id: int, size: Vector2) -> void:
	grid_pos = pos
	cat_id = type_id
	tile_size = size
	z_index = grid_pos.z * 10


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
	base_sprite.texture = load("res://assets/tiles/tile_base.png")
	base_sprite.name = "Base"
	
	var base_w: float = base_sprite.texture.get_width()
	var base_h: float = base_sprite.texture.get_height()
	var scale_x := tile_size.x / base_w
	var scale_y := tile_size.y / base_h
	base_sprite.scale = Vector2(scale_x, scale_y)
	add_child(base_sprite)
	
	# ── Definição da Face Útil ──
	# tile_base.png tem chanfros 3D no TOPO e na DIREITA.
	# Centro da face útil em relação ao centro da imagem total:
	var face_center_x := -(base_w * 0.04) * scale_x  # Empurra para ESQUERDA
	var face_center_y :=  (base_h * 0.025) * scale_y  # Empurra para BAIXO
	var center_offset := Vector2(face_center_x, face_center_y)
	
	# Dimensões da face útil (descontando chanfros)
	var face_useful_w: float = tile_size.x * 0.82
	var face_useful_h: float = tile_size.y * 0.85
	
	# ── Sticker do Gato ──
	var tex_atlas := _create_cat_atlas_texture(cat_id)
	
	# Scale: ajustar o frame inteiro para caber na face útil.
	# O espaçamento branco do atlas serve como padding natural.
	var scale_fit: float = minf(face_useful_w / FRAME_W, face_useful_h / FRAME_H)
	
	# Sombra do sticker (efeito "adesivo colado")
	var sticker_shadow := Sprite2D.new()
	sticker_shadow.texture = tex_atlas
	sticker_shadow.modulate = Color(0, 0, 0, 0.15)
	sticker_shadow.scale = Vector2(scale_fit, scale_fit)
	sticker_shadow.position = center_offset + Vector2(1.0, 1.5)
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
	shape.size = tile_size * (1.0 - HITBOX_SHRINK)
	_collision_shape.shape = shape
	_collision_shape.name = "CollisionShape"
	_collision_shape.position = center_offset
	add_child(_collision_shape)



# ─── Update Visuals ─────────────────────────────────────────────────

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if is_matched:
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
	if blocked:
		modulate = Color(0.6, 0.6, 0.6)
	else:
		modulate = Color(1.0, 1.0, 1.0)


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
	"""Pulso de luz zen."""
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
	
	_select_tween = create_tween()
	_select_tween.set_loops()
	_select_tween.tween_property(self, "modulate", Color(1.35, 1.25, 0.9, 1.0), 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_select_tween.parallel().tween_property(self, "scale", Vector2(1.06, 1.06), 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_select_tween.tween_property(self, "modulate", Color(1.1, 1.05, 0.95, 1.0), 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_select_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func stop_hint_glow() -> void:
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
		_select_tween = null
	modulate = Color.WHITE
	scale = Vector2(1.0, 1.0)


func mark_matched() -> void:
	is_matched = true
	visible = false
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
