extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal xp_changed(current: int, needed: int)
signal level_changed(level: int)
signal player_died
signal perk_charges_changed(bomb_charges: int, heal_charges: int)
signal bomb_triggered(damage: int)
signal weapons_changed
signal targeting_changed(mode: String)
signal projectile_class_changed(projectile_class: String)

@export var speed: float = 200.0
@export var max_health: int = 100
@export var shoot_cooldown: float = 0.5
@export var heal_amount: int = 35
@export var bomb_damage: int = 999

var health: int
var xp: int = 0
var level: int = 1
var xp_to_next_level: int = 10
var can_shoot: bool = true
var bomb_charges: int = 0
var heal_charges: int = 0
var weapon_damage: int = 10
var weapon_projectile_count: int = 1
var weapon_spread_degrees: float = 14.0
var min_shoot_cooldown: float = 0.12

# --- New stats ---
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0
var pierce_count: int = 0
var burn_chance: float = 0.0
var burn_damage: int = 3
var armor: int = 0
var life_regen: float = 0.0
var _regen_accumulator: float = 0.0
var dash_charges: int = 0
var dash_speed: float = 600.0
var dash_duration: float = 0.15
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var xp_multiplier: float = 1.0
var luck: float = 0.0
var cooldown_multiplier: float = 1.0
var has_shield: bool = false
var _shield_active: bool = false
var _shield_cooldown: float = 0.0
var shield_cooldown_max: float = 30.0

# --- Weapon system ---
var unlocked_passive_weapons: Array[String] = []
var _passive_weapon_timers: Dictionary = {}
var targeting_mode: String = "forward"

# --- Held weapon system ---
var current_held_weapon: String = "plasma_rifle"
var _weapon_slots: Dictionary = {}  # weapon_id -> {unlocked, active_time, cooldown_time}
var _held_weapon_cooldown: float = 0.0
var _spiral_angle: float = 0.0
var unlocked_targeting_modes: Array[String] = ["forward"]
var _targeting_mode_index: int = 0
var projectile_class: String = "standard"
var projectile_classes: Array[String] = ["standard", "aoe", "bouncing", "beam"]
var unlocked_projectile_classes: Array[String] = ["standard"]
var projectile_class_names: Dictionary = {
	"standard": "Standart",
	"aoe": "Patlayici",
	"bouncing": "Sekebilen",
	"beam": "Isin"
}

# Weapon upgrade levels (per weapon id)
var weapon_upgrade_levels: Dictionary = {}

# Camera shake
var _shake_intensity: float = 0.0
var _shake_decay: float = 8.0

@onready var shoot_timer: Timer = $ShootTimer
@onready var pickup_area: Area2D = $PickupArea

var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var aoe_bullet_scene: PackedScene = preload("res://scenes/aoe_bullet.tscn")
var bouncing_bullet_scene: PackedScene = preload("res://scenes/bouncing_bullet.tscn")
var beam_bullet_scene: PackedScene = preload("res://scenes/beam_bullet.tscn")


func _ready() -> void:
	add_to_group("player")
	health = max_health
	weapon_damage = int(ConfigService.get_value("weapons.base_damage", 10))
	weapon_spread_degrees = float(ConfigService.get_value("weapons.spread_degrees", 14.0))
	weapon_projectile_count = int(ConfigService.get_value("weapons.base_projectiles", 1))
	min_shoot_cooldown = float(ConfigService.get_value("weapons.min_cooldown", 0.12))
	shoot_cooldown = float(ConfigService.get_value("weapons.base_cooldown", shoot_cooldown))
	xp_to_next_level = _compute_xp_needed(level)
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_to_next_level)
	perk_charges_changed.emit(bomb_charges, heal_charges)
	projectile_class_changed.emit(projectile_class)
	# Init passive weapon timers
	for wid in unlocked_passive_weapons:
		_passive_weapon_timers[wid] = 0.0
	# Init held weapon fire cooldown
	_held_weapon_cooldown = 0.0
	_setup_hero_sprite()


func _physics_process(delta: float) -> void:
	# Camera shake
	if _shake_intensity > 0.01:
		var cam: Camera2D = get_node_or_null("Camera2D")
		if cam:
			cam.offset = Vector2(randf_range(-_shake_intensity, _shake_intensity), randf_range(-_shake_intensity, _shake_intensity))
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
	else:
		_shake_intensity = 0.0
		var cam: Camera2D = get_node_or_null("Camera2D")
		if cam and cam.offset.length() > 0.1:
			cam.offset = Vector2.ZERO

	# Dash logic
	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_direction * dash_speed
		if _dash_timer <= 0.0:
			_is_dashing = false
	else:
		var input_dir: Vector2 = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		velocity = input_dir.normalized() * speed
	move_and_slide()
	_update_hero_animation(velocity)

	# Life regen
	if life_regen > 0.0 and health > 0 and health < max_health:
		_regen_accumulator += life_regen * delta
		if _regen_accumulator >= 1.0:
			var regen_ticks: int = int(_regen_accumulator)
			_regen_accumulator -= float(regen_ticks)
			health = mini(health + regen_ticks, max_health)
			health_changed.emit(health, max_health)

	# Shield cooldown
	if has_shield and not _shield_active:
		_shield_cooldown -= delta
		if _shield_cooldown <= 0.0:
			_shield_active = true

	# Auto-fire passive weapons
	_auto_fire_passives(delta)

	# Process held weapon (main fire + duration)
	_process_held_weapon(delta)

	# Handle utility inputs (Tab, Dash, projectile switch)
	_handle_utility_inputs()
	_handle_perk_inputs()


func _auto_fire_passives(delta: float) -> void:
	for wid in unlocked_passive_weapons:
		if not _passive_weapon_timers.has(wid):
			_passive_weapon_timers[wid] = 0.0
		_passive_weapon_timers[wid] -= delta
		if _passive_weapon_timers[wid] <= 0.0:
			var wdef: Dictionary = _get_weapon_def(wid)
			if wdef.is_empty():
				continue
			var targeting_pref: String = str(wdef.get("targeting_pref", "nearest"))
			# Weapons that need a target: only fire if one exists in range
			if targeting_pref != "none" and targeting_pref != "radial":
				var eff_range: float = float(wdef.get("speed", 400.0)) * float(wdef.get("lifetime", 3.0))
				var target: Node2D = _find_best_target_for_weapon(wdef, eff_range)
				if target == null:
					_passive_weapon_timers[wid] = 0.0  # retry next frame
					continue
			var cd: float = float(wdef.get("cooldown", 0.5))
			_passive_weapon_timers[wid] = _get_effective_weapon_cooldown(cd)
			_fire_weapon(wid, wdef)


func _process_held_weapon(delta: float) -> void:
	# Tick all weapon slot cooldowns
	for wid in _weapon_slots:
		var slot: Dictionary = _weapon_slots[wid]
		if float(slot.get("cooldown_time", 0.0)) > 0.0:
			slot["cooldown_time"] = maxf(0.0, float(slot["cooldown_time"]) - delta)
		if float(slot.get("active_time", 0.0)) > 0.0:
			slot["active_time"] = maxf(0.0, float(slot["active_time"]) - delta)
			if float(slot["active_time"]) <= 0.0:
				# Duration expired — start cooldown and revert to plasma
				var wdef: Dictionary = _get_weapon_def(wid)
				slot["cooldown_time"] = float(wdef.get("active_cooldown_sec", 60.0))
				if current_held_weapon == wid:
					current_held_weapon = "plasma_rifle"
					_held_weapon_cooldown = 0.0
					_update_weapon_visual()
					weapons_changed.emit()

	# Tick fire cooldown
	if _held_weapon_cooldown > 0.0:
		_held_weapon_cooldown -= delta
		if _held_weapon_cooldown > 0.0:
			return

	# Fire held weapon
	var wdef: Dictionary = _get_weapon_def(current_held_weapon)
	if wdef.is_empty():
		return
	var targeting_pref: String = str(wdef.get("targeting_pref", "nearest"))
	if targeting_pref != "none" and targeting_pref != "radial":
		var eff_range: float = float(wdef.get("speed", 400.0)) * float(wdef.get("lifetime", 3.0))
		var target: Node2D = _find_best_target_for_weapon(wdef, eff_range)
		if target == null:
			return
	var is_held_weapon: bool = wdef.get("is_held", false)
	_held_weapon_cooldown = _get_effective_weapon_cooldown(float(wdef.get("cooldown", 0.5))) if not is_held_weapon else float(wdef.get("cooldown", 0.5))
	_fire_weapon(current_held_weapon, wdef)


func _activate_weapon_slot(weapon_id: String) -> void:
	if not _weapon_slots.has(weapon_id):
		return
	var slot: Dictionary = _weapon_slots[weapon_id]
	if not bool(slot.get("unlocked", false)):
		return
	if float(slot.get("cooldown_time", 0.0)) > 0.0:
		return
	if float(slot.get("active_time", 0.0)) > 0.0:
		return  # Already active
	# If another weapon is active, force-expire it first
	if current_held_weapon != "plasma_rifle":
		var prev_slot: Dictionary = _weapon_slots.get(current_held_weapon, {})
		if not prev_slot.is_empty():
			var prev_def: Dictionary = _get_weapon_def(current_held_weapon)
			prev_slot["active_time"] = 0.0
			prev_slot["cooldown_time"] = float(prev_def.get("active_cooldown_sec", 60.0))
	var wdef: Dictionary = _get_weapon_def(weapon_id)
	slot["active_time"] = float(wdef.get("active_duration_sec", 15.0))
	slot["cooldown_time"] = 0.0
	current_held_weapon = weapon_id
	_held_weapon_cooldown = 0.0
	_update_weapon_visual()
	weapons_changed.emit()


func _handle_utility_inputs() -> void:
	# Tab - cycle targeting mode
	if Input.is_action_just_pressed("cycle_targeting") and unlocked_targeting_modes.size() > 1:
		_targeting_mode_index = (_targeting_mode_index + 1) % unlocked_targeting_modes.size()
		targeting_mode = unlocked_targeting_modes[_targeting_mode_index]
		targeting_changed.emit(targeting_mode)

	if Input.is_action_just_pressed("cycle_projectile_class"):
		cycle_projectile_class()

	# KEY 1-5: Activate weapon slots
	if Input.is_action_just_pressed("weapon_slot_1"):
		_try_activate_slot(1)
	elif Input.is_action_just_pressed("weapon_slot_2"):
		_try_activate_slot(2)
	elif Input.is_action_just_pressed("weapon_slot_3"):
		_try_activate_slot(3)
	elif Input.is_action_just_pressed("weapon_slot_4"):
		_try_activate_slot(4)
	elif Input.is_action_just_pressed("weapon_slot_5"):
		_try_activate_slot(5)

	# Dash (Shift)
	if Input.is_action_just_pressed("dash") and dash_charges > 0 and not _is_dashing:
		var input_dir: Vector2 = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		if input_dir.length_squared() > 0.01:
			_dash_direction = input_dir.normalized()
		else:
			_dash_direction = Vector2.RIGHT
		dash_charges -= 1
		_is_dashing = true
		_dash_timer = dash_duration


func _try_activate_slot(slot_key: int) -> void:
	for wid in _weapon_slots:
		var slot: Dictionary = _weapon_slots[wid]
		if int(slot.get("slot_key", 0)) == slot_key:
			_activate_weapon_slot(wid)
			return


func _fire_weapon(weapon_id: String, wdef: Dictionary) -> void:
	var is_wave: bool = wdef.get("is_wave", false)
	var is_gravity: bool = wdef.get("is_gravity", false)
	var is_orbit: bool = wdef.get("is_orbit", false)
	var targeting_pref: String = str(wdef.get("targeting_pref", "nearest"))
	var is_held_weapon: bool = wdef.get("is_held", false)

	# Compute damage, including upgrade levels
	var base_dmg: int = int(wdef.get("base_damage", 10))
	var upgrade_lvl: int = int(weapon_upgrade_levels.get(weapon_id, 0))
	var dmg_step: int = int(wdef.get("upgrade_damage_step", 3))
	var total_damage: int = base_dmg + (upgrade_lvl * dmg_step)
	# General weapon_damage bonus only for non-held weapons (plasma + passives)
	if not is_held_weapon:
		total_damage += weapon_damage

	# Crit check (only for non-held weapons)
	var is_crit: bool = false
	if not is_held_weapon and crit_chance > 0.0:
		is_crit = randf() < crit_chance
		if is_crit:
			total_damage = int(round(float(total_damage) * crit_multiplier))

	# Phase Disruptor: wave damage to all on-screen enemies
	if is_wave:
		_do_wave_attack(total_damage, wdef)
		return

	# Gravity Pulse: push + damage all nearby enemies
	if is_gravity:
		_do_gravity_pulse(total_damage, wdef)
		return

	# Orbital Sentinel: spawn orbiting bullets around player
	if is_orbit:
		_spawn_orbit_bullets(total_damage, wdef)
		return

	# Radial weapons (arc_blaster): fire evenly in all directions, no target needed
	if targeting_pref == "radial":
		var proj_count: int = int(wdef.get("projectile_count", 5))
		if not is_held_weapon:
			proj_count = _get_effective_projectile_count(proj_count, wdef)
		for i in range(proj_count):
			var angle: float = (TAU / float(proj_count)) * float(i)
			_spawn_weapon_bullet(Vector2.from_angle(angle), total_damage, wdef, is_crit, not is_held_weapon)
		return

	# All other projectile weapons need a target
	var eff_range: float = float(wdef.get("speed", 400.0)) * float(wdef.get("lifetime", 3.0))
	var target: Node2D = _find_best_target_for_weapon(wdef, eff_range)
	if target == null:
		return

	var bullet_speed: float = float(wdef.get("speed", 400.0))
	var directions: Array[Vector2] = _compute_fire_directions(target, bullet_speed)

	var projectile_count: int = int(wdef.get("projectile_count", 1))
	if not is_held_weapon:
		projectile_count = _get_effective_projectile_count(projectile_count, wdef)
	var spread: float = deg_to_rad(float(wdef.get("spread_degrees", weapon_spread_degrees)))

	for base_dir in directions:
		if projectile_count <= 1:
			_spawn_weapon_bullet(base_dir, total_damage, wdef, is_crit, not is_held_weapon)
		else:
			var start_angle: float = -spread * 0.5
			for idx in range(projectile_count):
				var t: float = float(idx) / float(projectile_count - 1) if projectile_count > 1 else 0.0
				var offset_angle: float = lerpf(start_angle, -start_angle, t)
				_spawn_weapon_bullet(base_dir.rotated(offset_angle), total_damage, wdef, is_crit, not is_held_weapon)


func _spawn_weapon_bullet(direction: Vector2, damage_amount: int, wdef: Dictionary, bullet_is_crit: bool = false, is_default: bool = false) -> void:
	var bullet: Node2D = _get_projectile_scene().instantiate()
	bullet.global_position = global_position
	bullet.set_direction(direction)
	bullet.set_damage(damage_amount)
	bullet.set_damage_type(str(wdef.get("damage_type", "physical")))
	bullet.speed = float(wdef.get("speed", 400.0))
	bullet.lifetime = float(wdef.get("lifetime", 3.0))
	bullet.pierce_count = int(wdef.get("pierce", 0)) + (pierce_count if is_default else 0)
	bullet.chain_count = int(wdef.get("chain", 0))
	bullet.chain_range = float(wdef.get("chain_range", 150.0))
	bullet.is_aoe = bool(wdef.get("is_aoe", false))
	bullet.aoe_radius = float(wdef.get("aoe_radius", 80.0))
	bullet.aoe_damage_ratio = float(wdef.get("aoe_damage_ratio", 0.6))
	bullet.weapon_type = str(wdef.get("name", "plasma_rifle"))
	bullet.is_crit = bullet_is_crit
	bullet.burn_chance = burn_chance if is_default else 0.0
	bullet.burn_damage = burn_damage if is_default else 0
	_apply_projectile_class_modifiers(bullet, wdef)

	# Set bullet color
	var color_arr: Array = wdef.get("color", [1.0, 1.0, 0.4]) as Array
	if color_arr.size() >= 3:
		var bcol: Color = Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]))
		bullet.modulate = bcol

	get_tree().current_scene.add_child(bullet)


func _spawn_orbit_bullets(damage_amount: int, wdef: Dictionary) -> void:
	var count: int = _get_effective_projectile_count(int(wdef.get("projectile_count", 3)), wdef)
	var orbit_r: float = float(wdef.get("orbit_radius", 55.0))
	var orbit_s: float = float(wdef.get("orbit_speed", 3.0))
	var lt: float = float(wdef.get("lifetime", 4.0))
	for i in range(count):
		var bullet: Node2D = bullet_scene.instantiate()
		bullet.is_orbit = true
		bullet.orbit_center = self
		bullet.orbit_radius = orbit_r
		bullet.orbit_speed = orbit_s
		bullet.orbit_angle = (TAU / float(count)) * float(i)
		bullet.global_position = global_position + Vector2(cos(bullet.orbit_angle), sin(bullet.orbit_angle)) * orbit_r
		bullet.set_damage(damage_amount)
		bullet.set_damage_type(str(wdef.get("damage_type", "energy")))
		bullet.lifetime = lt
		bullet.weapon_type = str(wdef.get("name", "orbital_sentinel"))
		bullet.burn_chance = burn_chance
		bullet.burn_damage = burn_damage
		var color_arr: Array = wdef.get("color", [1.0, 0.9, 0.3]) as Array
		if color_arr.size() >= 3:
			bullet.modulate = Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]))
		get_tree().current_scene.add_child(bullet)


func _do_wave_attack(damage_amount: int, wdef: Dictionary) -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var dtype: String = str(wdef.get("damage_type", "void"))
	_spawn_vfx_ring("res://assets/vfx/vfx_void_explosion_ring.png", global_position, 250.0)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage_amount, dtype)


func _do_gravity_pulse(damage_amount: int, wdef: Dictionary) -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var grav_radius: float = float(wdef.get("gravity_radius", 200.0))
	var grav_force: float = float(wdef.get("gravity_force", 300.0))
	var dtype: String = str(wdef.get("damage_type", "kinetic"))
	_spawn_vfx_ring("res://assets/vfx/vfx_gravity_wave_ring.png", global_position, grav_radius)
	for enemy in enemies:
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= grav_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_amount, dtype)
			# Push enemy away
			var push_dir: Vector2 = (enemy.global_position - global_position).normalized()
			enemy.global_position += push_dir * grav_force * 0.1


func _get_targeting_directions() -> Array[Vector2]:
	# Legacy fallback — used only if something calls this directly
	var nearest: Node2D = _find_nearest_enemy()
	if nearest == null:
		return []
	return _compute_fire_directions(nearest, 400.0)


func _compute_fire_directions(target: Node2D, bullet_speed: float) -> Array[Vector2]:
	var base_dir: Vector2 = _compute_lead_direction(target, bullet_speed)

	match targeting_mode:
		"rear_guard":
			return [base_dir, -base_dir]
		"side_sweep":
			return [base_dir.rotated(deg_to_rad(90.0)), base_dir.rotated(deg_to_rad(-90.0))]
		"full_spread":
			return [base_dir, base_dir.rotated(deg_to_rad(45.0)), base_dir.rotated(deg_to_rad(-45.0))]
		"orbital_fire":
			var orbital_bullet_count: int = int(ConfigService.get_value("weapons.targeting_modes.orbital_fire.projectile_dirs", 2))
			orbital_bullet_count = clampi(orbital_bullet_count, 2, 3)
			var orbital_spin_speed: float = float(ConfigService.get_value("weapons.targeting_modes.orbital_fire.spin_speed", 0.55))
			_spiral_angle += orbital_spin_speed
			var dirs: Array[Vector2] = []
			for i in range(orbital_bullet_count):
				dirs.append(Vector2.from_angle(_spiral_angle + (TAU / float(orbital_bullet_count)) * float(i)))
			return dirs
		_: # forward
			return [base_dir]


func _compute_lead_direction(target: Node2D, bullet_speed: float) -> Vector2:
	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	if distance < 1.0 or bullet_speed <= 0.0:
		return to_target.normalized()
	var time_to_reach: float = distance / bullet_speed
	# Predict where enemy will be; 0.7 factor since enemies may change direction
	var enemy_vel: Vector2 = Vector2.ZERO
	if target is CharacterBody2D:
		enemy_vel = target.velocity
	var predicted_pos: Vector2 = target.global_position + enemy_vel * time_to_reach * 0.7
	var lead_dir: Vector2 = (predicted_pos - global_position)
	if lead_dir.length_squared() < 1.0:
		return to_target.normalized()
	return lead_dir.normalized()


func _find_best_target_for_weapon(wdef: Dictionary, eff_range: float) -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var targeting_pref: String = str(wdef.get("targeting_pref", "nearest"))

	# Filter enemies within weapon's effective range
	var in_range: Array[Node2D] = []
	for enemy in enemies:
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= eff_range:
			in_range.append(enemy)

	if in_range.is_empty():
		return null

	match targeting_pref:
		"closest":
			return _pick_closest(in_range)
		"cluster":
			return _pick_cluster_center(in_range)
		"line":
			return _pick_line_target(in_range)
		_: # "nearest"
			return _pick_closest(in_range)


func _pick_closest(enemies: Array[Node2D]) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in enemies:
		var dist: float = global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _pick_cluster_center(enemies: Array[Node2D]) -> Node2D:
	# Pick enemy with most neighbors within cluster_radius — maximizes chain/AOE value
	var cluster_radius: float = 120.0
	var best: Node2D = null
	var best_score: int = -1
	for enemy in enemies:
		var score: int = 0
		for other in enemies:
			if other == enemy:
				continue
			if enemy.global_position.distance_to(other.global_position) <= cluster_radius:
				score += 1
		if score > best_score:
			best_score = score
			best = enemy
	return best if best != null else _pick_closest(enemies)


func _pick_line_target(enemies: Array[Node2D]) -> Node2D:
	# Pick direction passing through most enemies (for pierce weapons like Railgun)
	var best: Node2D = null
	var best_count: int = 0
	for enemy in enemies:
		var dir: Vector2 = (enemy.global_position - global_position).normalized()
		var count: int = 0
		for other in enemies:
			var to_other: Vector2 = other.global_position - global_position
			var proj: float = to_other.dot(dir)
			if proj > 0.0:
				var perp_dist: float = absf(to_other.cross(dir))
				if perp_dist <= 35.0:
					count += 1
		if count > best_count:
			best_count = count
			best = enemy
	return best if best != null else _pick_closest(enemies)


func _find_nearest_enemy() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in enemies:
		var dist: float = global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func take_damage(amount: int) -> void:
	# Shield absorb
	if _shield_active:
		_shield_active = false
		_shield_cooldown = shield_cooldown_max
		return
	# Armor reduction
	var final_amount: int = maxi(1, amount - armor)
	health -= final_amount
	health = max(health, 0)
	health_changed.emit(health, max_health)
	camera_shake(3.0 + float(final_amount) * 0.15)
	if health <= 0:
		camera_shake(8.0)
		player_died.emit()


func camera_shake(intensity: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)


func add_xp(amount: int) -> void:
	var actual_amount: int = int(round(float(amount) * xp_multiplier))
	xp += actual_amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = _compute_xp_needed(level)
		level_changed.emit(level)
	xp_changed.emit(xp, xp_to_next_level)


func apply_run_state(saved_state: Dictionary) -> void:
	level = int(saved_state.get("level", 1))
	xp = int(saved_state.get("xp", 0))
	xp_to_next_level = int(saved_state.get("xp_needed", _compute_xp_needed(level)))
	max_health = int(saved_state.get("max_health", max_health))
	health = int(saved_state.get("health", max_health))
	bomb_charges = int(saved_state.get("bomb_charges", 0))
	heal_charges = int(saved_state.get("heal_charges", 0))
	weapon_damage = int(saved_state.get("weapon_damage", weapon_damage))
	weapon_projectile_count = int(saved_state.get("weapon_projectile_count", weapon_projectile_count))
	shoot_cooldown = float(saved_state.get("shoot_cooldown", shoot_cooldown))
	shoot_timer.wait_time = shoot_cooldown
	health = clamp(health, 0, max_health)
	# Restore expanded state
	crit_chance = float(saved_state.get("crit_chance", 0.0))
	pierce_count = int(saved_state.get("pierce_count", 0))
	armor = int(saved_state.get("armor", 0))
	life_regen = float(saved_state.get("life_regen", 0.0))
	dash_charges = int(saved_state.get("dash_charges", 0))
	xp_multiplier = float(saved_state.get("xp_multiplier", 1.0))
	luck = float(saved_state.get("luck", 0.0))
	cooldown_multiplier = float(saved_state.get("cooldown_multiplier", 1.0))
	has_shield = bool(saved_state.get("has_shield", false))
	targeting_mode = str(saved_state.get("targeting_mode", "forward"))
	var saved_projectiles: Variant = saved_state.get("unlocked_projectile_classes", null)
	if saved_projectiles != null and typeof(saved_projectiles) == TYPE_ARRAY:
		unlocked_projectile_classes.clear()
		for projectile_id in saved_projectiles:
			var projectile_name: String = _sanitize_projectile_class(str(projectile_id))
			if projectile_name not in unlocked_projectile_classes:
				unlocked_projectile_classes.append(projectile_name)
	if unlocked_projectile_classes.is_empty():
		unlocked_projectile_classes.append("standard")
	projectile_class = _sanitize_unlocked_projectile_class(str(saved_state.get("projectile_class", projectile_class)))
	var saved_modes: Variant = saved_state.get("unlocked_targeting_modes", null)
	if saved_modes != null and typeof(saved_modes) == TYPE_ARRAY:
		unlocked_targeting_modes.clear()
		for m in saved_modes:
			unlocked_targeting_modes.append(str(m))
	if targeting_mode in unlocked_targeting_modes:
		_targeting_mode_index = unlocked_targeting_modes.find(targeting_mode)
	else:
		_targeting_mode_index = 0
	var saved_passives: Variant = saved_state.get("unlocked_passive_weapons", null)
	if saved_passives != null and typeof(saved_passives) == TYPE_ARRAY:
		unlocked_passive_weapons.clear()
		for w in saved_passives:
			unlocked_passive_weapons.append(str(w))
	var saved_upgrades: Variant = saved_state.get("weapon_upgrade_levels", null)
	if saved_upgrades != null and typeof(saved_upgrades) == TYPE_DICTIONARY:
		weapon_upgrade_levels = (saved_upgrades as Dictionary).duplicate(true)
	# Re-init timers for any newly unlocked passives
	for wid in unlocked_passive_weapons:
		if not _passive_weapon_timers.has(wid):
			_passive_weapon_timers[wid] = 0.0
	# Reset held weapon to base (temp weapons don't survive save/load)
	current_held_weapon = "plasma_rifle"
	_held_weapon_cooldown = 0.0
	# Restore weapon slots
	var saved_slots: Variant = saved_state.get("weapon_slots", null)
	_weapon_slots.clear()
	if saved_slots != null and typeof(saved_slots) == TYPE_DICTIONARY:
		for wid in saved_slots:
			var s: Dictionary = (saved_slots[wid] as Dictionary).duplicate(true)
			s["active_time"] = 0.0  # Don't preserve active state across save/load
			s["cooldown_time"] = 0.0
			_weapon_slots[str(wid)] = s
	_update_weapon_visual()
	level_changed.emit(level)
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_to_next_level)
	perk_charges_changed.emit(bomb_charges, heal_charges)
	weapons_changed.emit()
	targeting_changed.emit(targeting_mode)
	projectile_class_changed.emit(projectile_class)


func get_run_state() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"xp_needed": xp_to_next_level,
		"health": health,
		"max_health": max_health,
		"bomb_charges": bomb_charges,
		"heal_charges": heal_charges,
		"weapon_damage": weapon_damage,
		"weapon_projectile_count": weapon_projectile_count,
		"shoot_cooldown": shoot_cooldown,
		"crit_chance": crit_chance,
		"pierce_count": pierce_count,
		"armor": armor,
		"life_regen": life_regen,
		"dash_charges": dash_charges,
		"xp_multiplier": xp_multiplier,
		"luck": luck,
		"cooldown_multiplier": cooldown_multiplier,
		"has_shield": has_shield,
		"targeting_mode": targeting_mode,
		"projectile_class": projectile_class,
		"unlocked_projectile_classes": unlocked_projectile_classes.duplicate(),
		"unlocked_targeting_modes": unlocked_targeting_modes.duplicate(),
		"unlocked_passive_weapons": unlocked_passive_weapons.duplicate(),
		"weapon_upgrade_levels": weapon_upgrade_levels.duplicate(true),
		"weapon_slots": _weapon_slots.duplicate(true)
	}


func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_gems"):
		var gem: Node = area.get_parent()
		if gem.has_method("collect"):
			gem.collect()
			add_xp(gem.xp_value)
	elif area.is_in_group("chests"):
		var chest: Node = area.get_parent()
		if chest.has_method("collect"):
			chest.collect()


func magnet_collect_all() -> void:
	for area in get_tree().get_nodes_in_group("xp_gems"):
		var gem: Node = area.get_parent()
		if gem and not gem.is_queued_for_deletion() and gem.has_method("collect"):
			gem.collect()
			if "xp_value" in gem:
				add_xp(gem.xp_value)


func _handle_perk_inputs() -> void:
	if Input.is_action_just_pressed("use_bomb") and bomb_charges > 0:
		bomb_charges -= 1
		perk_charges_changed.emit(bomb_charges, heal_charges)
		bomb_triggered.emit(bomb_damage)

	if Input.is_action_just_pressed("use_heal") and heal_charges > 0 and health > 0:
		heal_charges -= 1
		health = min(health + heal_amount, max_health)
		health_changed.emit(health, max_health)
		perk_charges_changed.emit(bomb_charges, heal_charges)


func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		# --- Combat ---
		"attack_speed":
			shoot_cooldown = maxf(min_shoot_cooldown, shoot_cooldown * 0.88)
			shoot_timer.wait_time = shoot_cooldown
			# Also slightly speed up all passive weapon cooldowns already in progress
			for wid in unlocked_passive_weapons:
				_passive_weapon_timers[wid] *= 0.9
		"weapon_damage":
			weapon_damage += int(ConfigService.get_value("weapons.damage_upgrade_step", 3))
		"weapon_projectile":
			weapon_projectile_count += int(ConfigService.get_value("weapons.projectile_upgrade_step", 1))
		"crit_chance":
			crit_chance = minf(crit_chance + 0.08, 0.6)
		"pierce":
			pierce_count += 1
		"burn_dot":
			burn_chance = minf(burn_chance + 0.15, 0.8)
			burn_damage += 2
		"unlock_aoe_projectile":
			_unlock_projectile_class("aoe")
		"unlock_bouncing_projectile":
			_unlock_projectile_class("bouncing")
		"unlock_beam_projectile":
			_unlock_projectile_class("beam")

		# --- Targeting (exclusive switch, but cycleable via Tab) ---
		"rear_targeting":
			_unlock_targeting_mode("rear_guard")
		"side_sweep":
			_unlock_targeting_mode("side_sweep")
		"full_spread":
			_unlock_targeting_mode("full_spread")
		"orbital_fire":
			_unlock_targeting_mode("orbital_fire")

		# --- Passive weapon unlocks ---
		"unlock_nano":
			_unlock_passive_weapon("nano_swarm")
		"unlock_tesla":
			_unlock_passive_weapon("tesla_emitter")
		"unlock_scatter":
			_unlock_passive_weapon("scatter_cannon")
		"unlock_orbital_sentinel":
			_unlock_passive_weapon("orbital_sentinel")

		# --- Passive weapon upgrades ---
		"upgrade_nano":
			weapon_upgrade_levels["nano_swarm"] = int(weapon_upgrade_levels.get("nano_swarm", 0)) + 1
		"upgrade_tesla":
			weapon_upgrade_levels["tesla_emitter"] = int(weapon_upgrade_levels.get("tesla_emitter", 0)) + 1
		"upgrade_scatter":
			weapon_upgrade_levels["scatter_cannon"] = int(weapon_upgrade_levels.get("scatter_cannon", 0)) + 1
		"upgrade_orbital":
			weapon_upgrade_levels["orbital_sentinel"] = int(weapon_upgrade_levels.get("orbital_sentinel", 0)) + 1

		# --- Active weapon unlocks (slot system) ---
		"unlock_railgun":
			_unlock_weapon_slot("railgun")
		"unlock_void":
			_unlock_weapon_slot("void_launcher")
		"unlock_arc":
			_unlock_weapon_slot("arc_blaster")
		"unlock_gravity":
			_unlock_weapon_slot("gravity_pulse")
		"unlock_phase":
			_unlock_weapon_slot("phase_disruptor")

		# --- Active weapon upgrades ---
		"upgrade_railgun":
			weapon_upgrade_levels["railgun"] = int(weapon_upgrade_levels.get("railgun", 0)) + 1
		"upgrade_void":
			weapon_upgrade_levels["void_launcher"] = int(weapon_upgrade_levels.get("void_launcher", 0)) + 1
		"upgrade_arc":
			weapon_upgrade_levels["arc_blaster"] = int(weapon_upgrade_levels.get("arc_blaster", 0)) + 1
		"upgrade_gravity":
			weapon_upgrade_levels["gravity_pulse"] = int(weapon_upgrade_levels.get("gravity_pulse", 0)) + 1
		"upgrade_phase":
			weapon_upgrade_levels["phase_disruptor"] = int(weapon_upgrade_levels.get("phase_disruptor", 0)) + 1

		# --- Defense ---
		"max_health":
			max_health += 20
			health = min(health + 20, max_health)
			health_changed.emit(health, max_health)
		"life_regen":
			life_regen += 1.5
		"armor":
			armor += 3
		"shield":
			has_shield = true
			_shield_active = true

		# --- Mobility ---
		"move_speed":
			speed += 20.0
		"xp_magnet":
			# Increase pickup area radius by 20
			var shape: CollisionShape2D = pickup_area.get_node("PickupShape")
			if shape and shape.shape is CircleShape2D:
				(shape.shape as CircleShape2D).radius += 20.0
		"dash":
			dash_charges += 2

		# --- Utility ---
		"xp_multiplier":
			xp_multiplier += 0.2
		"luck":
			luck = minf(luck + 0.1, 1.5)
		"cooldown_mastery":
			cooldown_multiplier = maxf(0.55, cooldown_multiplier - 0.08)


func _unlock_passive_weapon(weapon_id: String) -> void:
	if weapon_id not in unlocked_passive_weapons:
		unlocked_passive_weapons.append(weapon_id)
		_passive_weapon_timers[weapon_id] = 0.0
		weapons_changed.emit()


func _unlock_weapon_slot(weapon_id: String) -> void:
	if _weapon_slots.has(weapon_id):
		return  # Already unlocked
	var wdef: Dictionary = _get_weapon_def(weapon_id)
	_weapon_slots[weapon_id] = {
		"unlocked": true,
		"slot_key": int(wdef.get("slot_key", 0)),
		"active_time": 0.0,
		"cooldown_time": 0.0,
	}
	weapon_upgrade_levels[weapon_id] = int(weapon_upgrade_levels.get(weapon_id, 0))
	weapons_changed.emit()


func _unlock_targeting_mode(mode: String) -> void:
	if mode not in unlocked_targeting_modes:
		unlocked_targeting_modes.append(mode)
	targeting_mode = mode
	_targeting_mode_index = unlocked_targeting_modes.find(mode)
	targeting_changed.emit(targeting_mode)


func cycle_projectile_class() -> void:
	if unlocked_projectile_classes.size() <= 1:
		return
	var current_index: int = unlocked_projectile_classes.find(projectile_class)
	if current_index < 0:
		current_index = 0
	projectile_class = unlocked_projectile_classes[(current_index + 1) % unlocked_projectile_classes.size()]
	projectile_class_changed.emit(projectile_class)


func get_projectile_class_display_name() -> String:
	return str(projectile_class_names.get(projectile_class, projectile_class.capitalize()))


func can_cycle_projectile_classes() -> bool:
	return unlocked_projectile_classes.size() > 1


func has_projectile_class(projectile_id: String) -> bool:
	return projectile_id in unlocked_projectile_classes


func get_perk_charges() -> Dictionary:
	return {
		"bomb": bomb_charges,
		"heal": heal_charges
	}


func _get_weapon_def(weapon_id: String) -> Dictionary:
	var def: Variant = ConfigService.get_value("weapons.definitions.%s" % weapon_id, null)
	if def != null and typeof(def) == TYPE_DICTIONARY:
		return def as Dictionary
	return {}


func _get_projectile_scene() -> PackedScene:
	match projectile_class:
		"aoe":
			return aoe_bullet_scene
		"bouncing":
			return bouncing_bullet_scene
		"beam":
			return beam_bullet_scene
		_:
			return bullet_scene


func _apply_projectile_class_modifiers(bullet: Node2D, wdef: Dictionary) -> void:
	match projectile_class:
		"aoe":
			bullet.is_aoe = true
			bullet.aoe_radius = maxf(bullet.aoe_radius, 90.0)
			bullet.aoe_damage_ratio = maxf(bullet.aoe_damage_ratio, 0.7)
		"bouncing":
			bullet.set("bounce_count", int(wdef.get("bounce_count", 2)))
			bullet.set("bounce_range", float(wdef.get("bounce_range", 220.0)))
		"beam":
			bullet.speed = 0.0
			bullet.lifetime = minf(float(wdef.get("beam_lifetime", 0.18)), 0.3)
			bullet.set("beam_length", float(wdef.get("beam_length", 240.0)))
			bullet.set("beam_width", float(wdef.get("beam_width", 14.0)))
		_:
			pass


func _sanitize_projectile_class(value: String) -> String:
	if value in projectile_classes:
		return value
	return "standard"


func _sanitize_unlocked_projectile_class(value: String) -> String:
	var sanitized: String = _sanitize_projectile_class(value)
	if sanitized in unlocked_projectile_classes:
		return sanitized
	return "standard"


func _unlock_projectile_class(projectile_id: String) -> void:
	var sanitized: String = _sanitize_projectile_class(projectile_id)
	if sanitized in unlocked_projectile_classes:
		return
	unlocked_projectile_classes.append(sanitized)
	projectile_class = sanitized
	projectile_class_changed.emit(projectile_class)


func get_active_weapons_display() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# Current held weapon (always first)
	var held_def: Dictionary = _get_weapon_def(current_held_weapon)
	var active_time: float = 0.0
	if current_held_weapon != "plasma_rifle" and _weapon_slots.has(current_held_weapon):
		active_time = float(_weapon_slots[current_held_weapon].get("active_time", 0.0))
	result.append({
		"name": str(held_def.get("name", current_held_weapon)),
		"id": current_held_weapon,
		"key": "",
		"ready": true,
		"is_held": true,
		"active_time": active_time,
	})
	# Weapon slots (1-5)
	for wid in _weapon_slots:
		if wid == current_held_weapon:
			continue  # Already shown above
		var slot: Dictionary = _weapon_slots[wid]
		var wdef: Dictionary = _get_weapon_def(wid)
		var cd: float = float(slot.get("cooldown_time", 0.0))
		var max_cd: float = float(wdef.get("active_cooldown_sec", 60.0))
		result.append({
			"name": str(wdef.get("name", wid)),
			"id": wid,
			"key": "[%d]" % int(slot.get("slot_key", 0)),
			"ready": cd <= 0.0,
			"cooldown_time": cd,
			"cooldown_pct": cd / maxf(max_cd, 0.001),
		})
	# Passive support weapons
	for wid in unlocked_passive_weapons:
		var wdef: Dictionary = _get_weapon_def(wid)
		result.append({"name": str(wdef.get("name", wid)), "id": wid, "key": "", "ready": true})
	return result


func _spawn_bullet(direction: Vector2) -> void:
	# Legacy: kept for backward compatibility with bomb system etc
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.set_direction(direction)
	if bullet.has_method("set_damage"):
		bullet.set_damage(weapon_damage)
	if bullet.has_method("set_damage_type"):
		bullet.set_damage_type("physical")
	get_tree().current_scene.add_child(bullet)


func _compute_xp_needed(current_level: int) -> int:
	var base: int = int(ConfigService.get_value("xp.base_xp", 10))
	var linear_step: int = int(ConfigService.get_value("xp.linear_step", 4))
	var quadratic_step: int = int(ConfigService.get_value("xp.quadratic_step", 1))
	var level_index: int = maxi(current_level - 1, 0)
	return base + (level_index * linear_step) + int(pow(level_index, 2) * quadratic_step)


func _get_effective_weapon_cooldown(base_cooldown: float) -> float:
	var configured_base: float = float(ConfigService.get_value("weapons.base_cooldown", 0.5))
	var attack_speed_ratio: float = shoot_cooldown / maxf(configured_base, 0.001)
	return maxf(min_shoot_cooldown, base_cooldown * attack_speed_ratio * cooldown_multiplier)


func _get_effective_projectile_count(base_projectile_count: int, wdef: Dictionary = {}) -> int:
	var base_config: int = int(ConfigService.get_value("weapons.base_projectiles", 1))
	var bonus_projectiles: int = maxi(0, weapon_projectile_count - base_config)
	var scaled_bonus: int = bonus_projectiles
	var is_orbit_weapon: bool = bool(wdef.get("is_orbit", false))

	if is_orbit_weapon:
		scaled_bonus = mini(scaled_bonus, 1)
	elif base_projectile_count >= 6:
		scaled_bonus = int(floor(float(scaled_bonus) * 0.35))
	elif base_projectile_count >= 3:
		scaled_bonus = int(floor(float(scaled_bonus) * 0.5))

	var default_cap: int = base_projectile_count + 3
	if is_orbit_weapon:
		default_cap = base_projectile_count + 1
	var max_projectile_count: int = int(wdef.get("projectile_cap", default_cap))
	max_projectile_count = maxi(1, max_projectile_count)

	return clampi(base_projectile_count + scaled_bonus, 1, max_projectile_count)


func _spawn_vfx_ring(vfx_path: String, pos: Vector2, radius: float) -> void:
	if not ResourceLoader.exists(vfx_path):
		return
	var tex: Texture2D = load(vfx_path) as Texture2D
	if tex == null:
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = pos
	var ring_start: float = ConfigService.get_value("visual.sprite_scale.vfx_ring_start", 0.15)
	sprite.scale = Vector2(ring_start, ring_start)
	sprite.modulate.a = 0.85
	get_tree().current_scene.add_child(sprite)
	var target_scale: float = radius / maxf(tex.get_width() * 0.5, 1.0)
	var tween: Tween = sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(target_scale, target_scale), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(sprite.queue_free)


# ---- Hero Sprite System ----
var _hero_sprite: AnimatedSprite2D = null
var _last_move_dir: Vector2 = Vector2.DOWN
var _hero_direction: String = "south"
var _hero_base_path: String = "res://assets/characters/main_hero_v2"

# ---- Weapon Visual System ----
var _weapon_sprite: Sprite2D = null
var _weapon_offsets: Dictionary = {
	"south": Vector2(14, 6),
	"north": Vector2(-14, -8),
	"east": Vector2(18, 2),
	"west": Vector2(-18, 2),
}


func _setup_hero_sprite() -> void:
	# Hide the placeholder ColorRect
	var body: Node = get_node_or_null("Body")
	if body:
		body.visible = false

	# Check if PixelLab sprite sheets exist
	var idle_south_anim: String = "%s/animations/breathing-idle/south/frame_000.png" % _hero_base_path
	var idle_south_rot: String = "%s/rotations/south.png" % _hero_base_path
	if not ResourceLoader.exists(idle_south_anim) and not ResourceLoader.exists(idle_south_rot):
		return  # Assets not imported yet; keep ColorRect visible

	if body:
		body.visible = false

	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = "HeroSprite"
	sprite.position = Vector2.ZERO
	var hero_scale: float = ConfigService.get_value("visual.sprite_scale.hero", 1.8)
	var hero_target_px: float = ConfigService.get_value("visual.target_px.hero", 96.0)
	var idle_source: String = idle_south_anim if ResourceLoader.exists(idle_south_anim) else idle_south_rot
	var idle_tex: Texture2D = load(idle_source) as Texture2D
	if idle_tex != null:
		var hero_side: float = maxf(float(idle_tex.get_width()), float(idle_tex.get_height()))
		if hero_side > 1.0:
			hero_scale = hero_target_px / hero_side
	sprite.scale = Vector2(hero_scale, hero_scale)

	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")

	for direction in ["south", "north", "east", "west"]:
		_add_directional_animation_frames(frames, "breathing-idle", "idle_%s" % direction, direction, 8.0)
		if frames.get_frame_count("idle_%s" % direction) == 0:
			_add_idle_rotation_frame(frames, direction)
		_add_directional_animation_frames(frames, "walk", "walk_%s" % direction, direction, 10.0)

	sprite.sprite_frames = frames
	sprite.play("idle_south")
	add_child(sprite)
	_hero_sprite = sprite
	_hero_direction = "south"
	_setup_weapon_sprite()


func _setup_weapon_sprite() -> void:
	if _weapon_sprite != null:
		return
	var ws: Sprite2D = Sprite2D.new()
	ws.name = "WeaponSprite"
	ws.z_index = 1
	ws.position = _weapon_offsets.get("south", Vector2(14, 6))
	add_child(ws)
	_weapon_sprite = ws
	_update_weapon_visual()


func _update_weapon_visual() -> void:
	if _weapon_sprite == null:
		return
	var wdef: Dictionary = _get_weapon_def(current_held_weapon)
	# Try loading a held weapon texture
	var held_tex_path: String = "res://assets/weapons/held_%s.png" % current_held_weapon
	if ResourceLoader.exists(held_tex_path):
		_weapon_sprite.texture = load(held_tex_path) as Texture2D
		var target_size: float = 28.0
		if _weapon_sprite.texture != null:
			var side: float = maxf(float(_weapon_sprite.texture.get_width()), 1.0)
			_weapon_sprite.scale = Vector2(target_size / side, target_size / side)
		_weapon_sprite.modulate = Color.WHITE
	else:
		# Placeholder: colored rectangle via a white pixel stretched
		_weapon_sprite.texture = null
		# Use weapon color as modulate for glow hint on body
		var color_arr: Array = wdef.get("color", [0.3, 0.8, 1.0]) as Array
		if color_arr.size() >= 3:
			_weapon_sprite.modulate = Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]), 0.85)
	# Update position offset based on direction
	_weapon_sprite.position = _weapon_offsets.get(_hero_direction, Vector2(14, 6))


func _add_directional_animation_frames(frames: SpriteFrames, source_anim: String, target_anim: String, direction: String, speed: float) -> void:
	frames.add_animation(target_anim)
	frames.set_animation_speed(target_anim, speed)
	frames.set_animation_loop(target_anim, true)
	for i in range(6):
		var path: String = "%s/animations/%s/%s/frame_%03d.png" % [_hero_base_path, source_anim, direction, i]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				frames.add_frame(target_anim, tex)
	if frames.get_frame_count(target_anim) == 0 and direction != "south":
		for i in range(6):
			var fallback_path: String = "%s/animations/%s/south/frame_%03d.png" % [_hero_base_path, source_anim, i]
			if ResourceLoader.exists(fallback_path):
				var fallback_tex: Texture2D = load(fallback_path) as Texture2D
				if fallback_tex:
					frames.add_frame(target_anim, fallback_tex)


func _add_idle_rotation_frame(frames: SpriteFrames, direction: String) -> void:
	var anim_name: String = "idle_%s" % direction
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 8.0)
	frames.set_animation_loop(anim_name, true)
	var path: String = "%s/rotations/%s.png" % [_hero_base_path, direction]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			frames.add_frame(anim_name, tex)


func _get_cardinal_direction(move_dir: Vector2) -> String:
	if absf(move_dir.x) > absf(move_dir.y):
		return "east" if move_dir.x > 0.0 else "west"
	return "south" if move_dir.y > 0.0 else "north"


func _update_hero_animation(move_dir: Vector2) -> void:
	if _hero_sprite == null:
		return
	if move_dir.length_squared() > 0.01:
		_hero_direction = _get_cardinal_direction(move_dir)
		var walk_anim: String = "walk_%s" % _hero_direction
		if _hero_sprite.animation != walk_anim:
			_hero_sprite.play(walk_anim)
		_last_move_dir = move_dir
		_hero_sprite.flip_h = false
	else:
		var idle_anim: String = "idle_%s" % _hero_direction
		if _hero_sprite.animation != idle_anim:
			_hero_sprite.play(idle_anim)
	# Update weapon sprite position for current direction
	if _weapon_sprite != null:
		_weapon_sprite.position = _weapon_offsets.get(_hero_direction, Vector2(14, 6))
		_weapon_sprite.flip_h = _hero_direction == "west"
		# Z-index: behind hero when facing north, in front otherwise
		_weapon_sprite.z_index = -1 if _hero_direction == "north" else 1
