extends "res://scripts/projectiles/bullet.gd"

@export var bounce_count: int = 2
@export var bounce_range: float = 220.0


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies") or not body.has_method("take_damage"):
		return
	if body in _hit_enemies:
		return

	body.take_damage(damage, damage_type, is_crit)
	_hit_enemies.append(body)
	_spawn_hit_vfx()

	if is_aoe:
		_do_aoe_explosion()

	if chain_count > 0:
		chain_count -= 1
		var chain_target: Node2D = _find_chain_target()
		if chain_target:
			direction = (chain_target.global_position - global_position).normalized()
			rotation = direction.angle()
			return

	if bounce_count > 0:
		var next_target: Node2D = _find_bounce_target()
		if next_target:
			bounce_count -= 1
			global_position = body.global_position
			direction = (next_target.global_position - global_position).normalized()
			rotation = direction.angle()
			return

	if pierce_count > 0:
		pierce_count -= 1
		return

	if is_orbit:
		return

	queue_free()


func _find_bounce_target() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = bounce_range
	for enemy in enemies:
		if enemy in _hit_enemies:
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest