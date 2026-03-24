extends Node2D

## Hazard nesneleri (lav, su, radyasyon) için dinamik StaticBody2D collision.
## BackgroundTiler hücre sistemiyle eşleşir — hücre başına tek büyük collider.
## Layer 5 (bit 4 = değer 16) → "hazard" collision layer kullanır.

@export var viewport_margin_cells: int = 2

var _colliders: Dictionary = {}   # Vector2i(hcx, hcy) → StaticBody2D
var _background: Node2D = null


func _ready() -> void:
	# Hazard collision geçici olarak devre dışı — yeniden yapılacak
	pass


func _find_background() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _sync_colliders() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return

	var bg: Node2D = _background
	var cell_world: float = float(bg.hazard_cell_tiles) * float(bg.tile_size)
	var vp_size: Vector2 = get_viewport_rect().size
	var cam_pos: Vector2 = cam.global_position

	var min_hcx: int = int(floor((cam_pos.x - vp_size.x * 0.5) / cell_world)) - viewport_margin_cells
	var max_hcx: int = int(ceil( (cam_pos.x + vp_size.x * 0.5) / cell_world)) + viewport_margin_cells
	var min_hcy: int = int(floor((cam_pos.y - vp_size.y * 0.5) / cell_world)) - viewport_margin_cells
	var max_hcy: int = int(ceil( (cam_pos.y + vp_size.y * 0.5) / cell_world)) + viewport_margin_cells

	var desired: Dictionary = {}
	for hcy in range(min_hcy, max_hcy + 1):
		for hcx in range(min_hcx, max_hcx + 1):
			if bg.is_hazard_cell(hcx, hcy):
				desired[Vector2i(hcx, hcy)] = true

	var to_remove: Array[Vector2i] = []
	for coord: Vector2i in _colliders:
		if not desired.has(coord):
			to_remove.append(coord)
	for coord: Vector2i in to_remove:
		(_colliders[coord] as StaticBody2D).queue_free()
		_colliders.erase(coord)

	for coord: Vector2i in desired:
		if not _colliders.has(coord):
			_spawn_collider(coord.x, coord.y)


func _spawn_collider(hcx: int, hcy: int) -> void:
	var bg: Node2D = _background
	var cell_world: float = float(bg.hazard_cell_tiles) * float(bg.tile_size)
	var patch_world: float = float(bg.hazard_patch_tiles) * float(bg.tile_size)

	var center: Vector2 = Vector2(
		(float(hcx) + 0.5) * cell_world,
		(float(hcy) + 0.5) * cell_world
	)

	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 16   # Layer 5 "hazard" (bit 4)
	body.collision_mask  = 0
	body.position = center
	body.set_meta("hazard_cell", Vector2i(hcx, hcy))

	var cshape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(patch_world, patch_world)
	cshape.shape = rect
	body.add_child(cshape)

	add_child(body)
	_colliders[Vector2i(hcx, hcy)] = body
