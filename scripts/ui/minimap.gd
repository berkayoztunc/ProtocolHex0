extends Control

const MAP_W: float = 190.0
const MAP_H: float = 130.0
const WORLD_RADIUS: float = 600.0
const PLAYER_DOT_R: float = 4.0
const ENEMY_DOT_R: float = 3.0
const EDGE_MARGIN: float = 4.0
const CORNER_LEN: float = 16.0
const CORNER_W: float = 2.5

const COLOR_BG        := Color(0.02, 0.04, 0.08, 0.72)
const COLOR_GRID      := Color(1.0, 1.0, 1.0, 0.05)
const COLOR_BORDER    := Color(0.45, 0.75, 1.0, 0.35)
const COLOR_CORNER    := Color(0.55, 0.88, 1.0, 0.95)
const COLOR_PLAYER    := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_ENEMY     := Color(1.0, 0.18, 0.18, 1.0)
const COLOR_ENEMY_EDGE := Color(1.0, 0.18, 0.18, 0.65)


func _ready() -> void:
	custom_minimum_size = Vector2(MAP_W, MAP_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cx := MAP_W * 0.5
	var cy := MAP_H * 0.5

	# Background
	draw_rect(Rect2(0.0, 0.0, MAP_W, MAP_H), COLOR_BG)

	# Center crosshair grid
	draw_line(Vector2(cx, 0.0), Vector2(cx, MAP_H), COLOR_GRID, 1.0)
	draw_line(Vector2(0.0, cy), Vector2(MAP_W, cy), COLOR_GRID, 1.0)

	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null:
		var player_pos: Vector2 = player.global_position
		var center := Vector2(cx, cy)

		# Enemies
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not enemy.visible:
				continue
			var offset: Vector2 = enemy.global_position - player_pos
			var map_pos := Vector2(
				center.x + (offset.x / WORLD_RADIUS) * cx,
				center.y + (offset.y / WORLD_RADIUS) * cy
			)
			if _inside(map_pos):
				draw_circle(map_pos, ENEMY_DOT_R, COLOR_ENEMY)
			else:
				var dir: Vector2 = offset.normalized()
				var edge_pos := Vector2(
					clampf(center.x + dir.x * (cx - EDGE_MARGIN), EDGE_MARGIN, MAP_W - EDGE_MARGIN),
					clampf(center.y + dir.y * (cy - EDGE_MARGIN), EDGE_MARGIN, MAP_H - EDGE_MARGIN)
				)
				draw_circle(edge_pos, ENEMY_DOT_R * 0.7, COLOR_ENEMY_EDGE)

		# Player dot (center)
		draw_circle(center, PLAYER_DOT_R, COLOR_PLAYER)

	_draw_frame()


func _inside(pos: Vector2) -> bool:
	return pos.x >= 0.0 and pos.x <= MAP_W and pos.y >= 0.0 and pos.y <= MAP_H


func _draw_frame() -> void:
	var w := MAP_W
	var h := MAP_H
	var cl := CORNER_LEN
	var lw := CORNER_W

	# Subtle full border
	draw_rect(Rect2(0.0, 0.0, w, h), COLOR_BORDER, false, 1.0)

	# Corner brackets (tactical HUD look)
	# Top-left
	draw_line(Vector2(0, 0), Vector2(cl, 0), COLOR_CORNER, lw)
	draw_line(Vector2(0, 0), Vector2(0, cl), COLOR_CORNER, lw)
	# Top-right
	draw_line(Vector2(w, 0), Vector2(w - cl, 0), COLOR_CORNER, lw)
	draw_line(Vector2(w, 0), Vector2(w, cl), COLOR_CORNER, lw)
	# Bottom-left
	draw_line(Vector2(0, h), Vector2(cl, h), COLOR_CORNER, lw)
	draw_line(Vector2(0, h), Vector2(0, h - cl), COLOR_CORNER, lw)
	# Bottom-right
	draw_line(Vector2(w, h), Vector2(w - cl, h), COLOR_CORNER, lw)
	draw_line(Vector2(w, h), Vector2(w, h - cl), COLOR_CORNER, lw)
