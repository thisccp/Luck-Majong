## Tile.gd — Peça do Mahjong Solitaire (Godot 4.x)
##
## Area2D com CollisionShape2D sincronizado com o Sprite2D.
## Input é gerenciado pelo BoardManager via intersect_point (Top-Down Picker).
## Debug visual mostra o contorno da collision shape.

class_name MahjongTile
extends Area2D

## Sinal emitido quando o jogador clica nesta peça.
signal tile_clicked(tile: MahjongTile)

## Posição na grade: x (coluna), y (linha), z (camada).
var grid_pos := Vector3i.ZERO
## Identificador da estampa do gato (1–20).
var cat_id: int = 1
## Tamanho da peça em pixels.
var tile_size := Vector2(80, 52)

## Estado de jogo.
var is_matched: bool = false
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_visuals()

## Referências internas.
var _collision_shape: CollisionShape2D

const TOTAL_TYPES := 20


static func color_for_type(type_id: int) -> Color:
	var hue := fmod(float(type_id) / TOTAL_TYPES, 1.0)
	return Color.from_hsv(hue, 0.60, 0.85)


func _ready() -> void:
	# Peça é 'pickable' para o sistema de physics queries (intersect_point)
	input_pickable = true
	# Mas NÃO usamos _input_event — o BoardManager faz a query manual
	
	_build_visuals()


func setup(pos: Vector3i, type_id: int, size: Vector2) -> void:
	"""Define os parâmetros da peça. Chamado ANTES de add_child."""
	grid_pos = pos
	cat_id = type_id
	tile_size = size
	# Z-index alto para camadas superiores — determina a ordem visual
	z_index = grid_pos.z * 10
	# Collision layer baseada na camada Z (layers 1-5)
	collision_layer = 1 << grid_pos.z
	# Mask: detecta sua própria layer
	collision_mask = 1 << grid_pos.z


func cells_occupied() -> Array[Vector2i]:
	return [Vector2i(grid_pos.x, grid_pos.y), Vector2i(grid_pos.x + 1, grid_pos.y)]


# ─── Visuais ────────────────────────────────────────────────────────

func _build_visuals() -> void:
	var half := tile_size / 2.0
	
	# --- Sprite (fundo colorido com borda) ---
	# O sprite é centralizado na posição do Area2D (centered = true por padrão)
	var img := Image.create(int(tile_size.x), int(tile_size.y), false, Image.FORMAT_RGBA8)
	var base_color := color_for_type(cat_id)
	img.fill(base_color)
	
	# Borda escura de 2px
	var border_color := base_color.darkened(0.4)
	for x in range(int(tile_size.x)):
		for y in range(2):
			img.set_pixel(x, y, border_color)
			img.set_pixel(x, int(tile_size.y) - 1 - y, border_color)
	for y in range(int(tile_size.y)):
		for x in range(2):
			img.set_pixel(x, y, border_color)
			img.set_pixel(int(tile_size.x) - 1 - x, y, border_color)
	
	var tex := ImageTexture.create_from_image(img)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.name = "Sprite"
	# Sprite centrado (0,0) — mesma origem que o Area2D
	add_child(sprite)
	
	# --- CollisionShape2D sincronizado EXATAMENTE com o Sprite ---
	# Ambos estão centrados em (0,0) do Area2D, então estão perfeitamente alinhados
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = tile_size
	_collision_shape.shape = shape
	_collision_shape.name = "CollisionShape"
	# Debug: mostrar contorno da collision no editor e em runtime
	_collision_shape.debug_color = Color(1, 0, 0, 0.3)
	add_child(_collision_shape)
	
	# --- Label com ID ---
	var label := Label.new()
	label.text = str(cat_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = tile_size
	label.position = -half
	label.add_theme_font_size_override("font_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.name = "IDLabel"
	add_child(label)


func _draw() -> void:
	"""Debug visual: desenha contorno da CollisionShape2D."""
	if not is_matched:
		var half := tile_size / 2.0
		var rect := Rect2(-half, tile_size)
		# Contorno verde para peças normais, amarelo para selecionadas
		var debug_color := Color.YELLOW if is_selected else Color(0, 1, 0, 0.4)
		draw_rect(rect, debug_color, false, 1.5)


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if is_matched:
		visible = false
		return
	if is_selected:
		modulate = Color(1.3, 1.3, 0.6, 1.0)
	else:
		modulate = Color.WHITE
	queue_redraw()  # Atualizar debug outline


func set_blocked(blocked: bool) -> void:
	if is_selected:
		return
	if blocked:
		modulate = Color(0.5, 0.5, 0.5, 0.6)
	else:
		modulate = Color.WHITE


func mark_matched() -> void:
	is_matched = true
	visible = false
	# Desabilitar collision para que intersect_point não a encontre mais
	_collision_shape.set_deferred("disabled", true)
