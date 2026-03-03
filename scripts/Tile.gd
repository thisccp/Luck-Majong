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

## Referências internas.
var _collision_shape: CollisionShape2D
var _sprite: Sprite2D
var _select_tween: Tween

const TOTAL_TYPES := 20

## ─── Atlas do Sprite Sheet de Gatinhos ─────────────────────────────
## Imagem cats.png (2784x1536), 5 colunas × 4 linhas, 20 gatinhos
const FRAME_W: float = 556.8  # 2784 / 5
const FRAME_H: float = 384.0  # 1536 / 4
const ATLAS_COLS: int = 5

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
	return [Vector2i(grid_pos.x, grid_pos.y), Vector2i(grid_pos.x + 1, grid_pos.y)]


# ─── Atlas ──────────────────────────────────────────────────────────

func _create_cat_atlas_texture(id: int) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = _cat_atlas
	var idx: int = id - 1
	var col: int = idx % ATLAS_COLS
	@warning_ignore("integer_division")
	var row: int = idx / ATLAS_COLS
	atlas_tex.region = Rect2(
		col * FRAME_W,
		row * FRAME_H,
		FRAME_W,
		FRAME_H
	)
	return atlas_tex


# ─── Visuais: Bloco Dominó de Resina ───────────────────────────────

func _build_visuals() -> void:
	var tw := int(tile_size.x)
	var th := int(tile_size.y)
	
	# ── 1. SOMBRA SUAVE (multi-camada) ──
	_build_soft_shadow(tw, th)
	
	# ── 2. LATERAL 3D com gradiente bevel ──
	_build_side(tw, th)
	
	# ── 3. BASE com CHANFRO (bevel lighting) ──
	var base_img := _create_beveled_base(tw, th)
	var base_tex := ImageTexture.create_from_image(base_img)
	var base_sprite := Sprite2D.new()
	base_sprite.texture = base_tex
	base_sprite.name = "Base"
	add_child(base_sprite)
	
	# ── 4. FACE (gatinho centralizado com padding elegante) ──
	# Sticker Shadow: Sombra sutil para dar efeito de "adesivo colado"
	var sticker_shadow := Sprite2D.new()
	sticker_shadow.texture = _create_cat_atlas_texture(cat_id)
	sticker_shadow.modulate = Color(0, 0, 0, 0.15) # Sombra escura e transparente
	var face_w: float = tile_size.x - FACE_PADDING * 2.0
	var face_h: float = tile_size.y - FACE_PADDING * 2.0
	var scale_fit: float = minf(face_w / FRAME_W, face_h / FRAME_H)
	sticker_shadow.scale = Vector2(scale_fit, scale_fit)
	sticker_shadow.position = Vector2(1.0, 1.5) # Deslocamento leve para baixo-direita
	sticker_shadow.name = "StickerShadow"
	add_child(sticker_shadow)
	
	_sprite = Sprite2D.new()
	_sprite.texture = sticker_shadow.texture # Reutiliza o atlas texture
	_sprite.scale = Vector2(scale_fit, scale_fit)
	_sprite.name = "CatFace"
	# Centralizado no bloco (posição 0,0 = centro do Area2D)
	add_child(_sprite)
	
	# ── 5. HITBOX DE PRECISÃO (15% menor) ──
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = tile_size * (1.0 - HITBOX_SHRINK)
	_collision_shape.shape = shape
	_collision_shape.name = "CollisionShape"
	add_child(_collision_shape)


func _build_soft_shadow(tw: int, th: int) -> void:
	var base_offset := Vector2(3.0 + grid_pos.z * 2.5, 3.0 + grid_pos.z * 2.5)
	var layers := [
		{"expand": 0, "alpha": 0.08, "offset": Vector2(0, 0)},
		{"expand": 2, "alpha": 0.06, "offset": Vector2(1, 1)},
		{"expand": 4, "alpha": 0.04, "offset": Vector2(2, 2)},
	]
	for i in range(layers.size()):
		var layer = layers[i]
		var expand: int = layer["expand"]
		var sw: int = tw + expand * 2
		var sh: int = th + expand * 2
		var simg := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
		simg.fill(Color(0, 0, 0, layer["alpha"]))
		var stex := ImageTexture.create_from_image(simg)
		var sspr := Sprite2D.new()
		sspr.texture = stex
		sspr.position = base_offset + layer["offset"]
		sspr.z_index = -3 + i
		sspr.name = "Shadow_%d" % i
		add_child(sspr)


func _build_side(tw: int, th: int) -> void:
	"""Lateral 3D com gradiente creme → cinza (simula arredondamento)."""
	var sd := int(SIDE_DEPTH)
	var side_img := Image.create(tw + sd, th + sd, false, Image.FORMAT_RGBA8)
	
	# Gradiente na lateral: creme claro no topo → cinza no fundo
	var color_top := Color(0.78, 0.74, 0.68, 1.0)   # Creme escuro
	var color_bot := Color(0.62, 0.58, 0.52, 1.0)    # Cinza quente
	
	for y in range(th + sd):
		var t: float = float(y) / float(th + sd - 1)
		var col: Color = color_top.lerp(color_bot, t)
		for x in range(tw + sd):
			side_img.set_pixel(x, y, col)
	
	var side_tex := ImageTexture.create_from_image(side_img)
	var side_sprite := Sprite2D.new()
	side_sprite.texture = side_tex
	# Deslocado para baixo-direita para criar espessura
	side_sprite.position = Vector2(SIDE_DEPTH * 0.5, SIDE_DEPTH * 0.5)
	side_sprite.z_index = -1
	side_sprite.name = "Side"
	add_child(side_sprite)


func _create_beveled_base(tw: int, th: int) -> Image:
	"""Base com chanfro: luz top-left, sombra bottom-right."""
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	
	# Corpo — cor resina/marfim
	var body_color := Color(0.97, 0.95, 0.91, 1.0)
	img.fill(body_color)
	
	# Chanfro com gradiente
	var light_edge  := Color(1.0, 0.99, 0.97, 1.0)
	var mid_light   := Color(0.98, 0.96, 0.93, 1.0)
	var dark_edge   := Color(0.80, 0.76, 0.70, 1.0)
	var darker_edge := Color(0.74, 0.70, 0.64, 1.0)
	
	var bevel := 3
	
	# Top (luz)
	for b in range(bevel):
		var col: Color = light_edge.lerp(mid_light, float(b) / float(bevel))
		for x in range(b, tw - b):
			img.set_pixel(x, b, col)
	
	# Left (luz)
	for b in range(bevel):
		var col: Color = light_edge.lerp(mid_light, float(b) / float(bevel))
		for y in range(b, th - b):
			img.set_pixel(b, y, col)
	
	# Bottom (sombra)
	for b in range(bevel):
		var col: Color = darker_edge.lerp(dark_edge, float(b) / float(bevel))
		for x in range(b, tw - b):
			img.set_pixel(x, th - 1 - b, col)
	
	# Right (sombra)
	for b in range(bevel):
		var col: Color = darker_edge.lerp(dark_edge, float(b) / float(bevel))
		for y in range(b, th - b):
			img.set_pixel(tw - 1 - b, y, col)
	
	# Cantos arredondados
	var corner_col := Color(0.88, 0.85, 0.80, 1.0)
	for cx in range(3):
		for cy in range(3):
			if cx + cy < 2:
				img.set_pixel(cx, cy, corner_col)
				img.set_pixel(tw - 1 - cx, cy, corner_col)
				img.set_pixel(cx, th - 1 - cy, corner_col)
				img.set_pixel(tw - 1 - cx, th - 1 - cy, corner_col)
	
	# Brilho Especular (Glow de plástico polido no canto superior esquerdo)
	var specular_color := Color(1.0, 1.0, 1.0, 0.6) # Branco semi-transparente
	var glow_radius := 6
	var center_x := 8
	var center_y := 8
	for y in range(center_y - glow_radius, center_y + glow_radius):
		for x in range(center_x - glow_radius, center_x + glow_radius):
			var dist := Vector2(x - center_x, y - center_y).length()
			if dist < glow_radius:
				# Suavizar o brilho baseado na distância
				var intensity := 1.0 - (dist / glow_radius)
				var final_spec := specular_color
				final_spec.a *= intensity * intensity # Decaimento não-linear (mais natural)
				
				# Blend manual com o pixel atual
				if x >= 0 and y >= 0 and x < tw and y < th:
					var current_col := img.get_pixel(x, y)
					var blended := current_col.lerp(final_spec, final_spec.a)
					blended.a = 1.0 # manter opaco
					img.set_pixel(x, y, blended)
	
	return img


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
		modulate = Color(0.6, 0.6, 0.6, 0.7)
	else:
		modulate = Color.WHITE


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
