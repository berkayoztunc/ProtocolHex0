extends Node2D

@export var spawn_interval: float = 1.5
@export var min_spawn_distance: float = 800.0
@export var max_spawn_distance: float = 1150.0

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var xp_gem_scene: PackedScene = preload("res://scenes/xp_gem.tscn")
var chest_scene: PackedScene = preload("res://scenes/chest.tscn")
var loot_box_scene: PackedScene = preload("res://scenes/loot_box.tscn")
var perk_tree_scene: PackedScene = preload("res://scenes/perk_tree.tscn")
var world_bomb_scene: PackedScene = preload("res://scenes/world_bomb.tscn")
var meta_resource_scene: PackedScene = preload("res://scenes/meta_resource.tscn")
var recall_zone_scene: PackedScene = preload("res://scenes/recall_zone.tscn")
var zone_item_pickup_scene: PackedScene = preload("res://scenes/zone_item_pickup.tscn")
var hero_capsule_scene: PackedScene = preload("res://scenes/hero_capsule.tscn")
var kill_count: int = 0
var game_over: bool = false
var autosave_elapsed: float = 0.0
var applying_start_state: bool = false
var elapsed_seconds: float = 0.0
var upgrade_stacks: Dictionary = {}
var weapon_display_timer: float = 0.0
var perk_tree_instance: Control = null
var perk_points: int = 200

# --- Meta-resource & recall ---
var _task_list: Array[Dictionary] = []
var _zone_items: Dictionary = {}
var _tasks_all_done: bool = false
var _map_item_ids: Array[String] = []
var _wave_loot_dropped: bool = false  # max 1 enemy loot drop per wave
# --------------------------------

# --- Wave scheduler ---
var _enemy_pool: EnemyPool = null
var _wave_number: int = 0
var _wave_schedule: Array = []  # Array of {gap: float, count: int}
var _wave_head: int = 0
var _wave_event_timer: float = 0.0
var _in_wave: bool = false
# ----------------------

var upgrade_catalog: Dictionary = {}

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
# Game over panel is managed by hud.gd (show_game_over / hide_game_over)


func _ready() -> void:
	get_tree().paused = false
	upgrade_catalog = UpgradeCatalogs.get_all_catalogs()
	min_spawn_distance = float(ConfigService.get_value("difficulty.spawn_distance_min", min_spawn_distance))
	max_spawn_distance = float(ConfigService.get_value("difficulty.spawn_distance_max", max_spawn_distance))
	# Build enemy pool (pre-warms all archetype variants)
	_enemy_pool = EnemyPool.new()
	_enemy_pool.name = "EnemyPool"
	add_child(_enemy_pool)
	_enemy_pool.initialize(enemy_scene)
	# Repurpose SpawnTimer as the inter-wave gap timer (one-shot between waves)
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_start_next_wave)
	spawn_timer.wait_time = float(ConfigService.get_value("waves.initial_delay", 1.2))
	spawn_timer.start()

	player.health_changed.connect(hud.update_health)
	player.xp_changed.connect(hud.update_xp)
	player.level_changed.connect(hud.update_level)
	player.level_changed.connect(_on_player_level_changed)
	player.player_died.connect(_on_player_died)
	player.vision_changed.connect(_on_player_vision_changed)
	hud.menu_requested.connect(_on_menu_requested)
	hud.perk_tree_requested.connect(_on_perk_tree_requested)
	hud.projectile_switch_requested.connect(_on_projectile_switch_requested)
	hud.game_over_restart_requested.connect(_on_game_over_restart)
	hud.game_over_menu_requested.connect(_on_game_over_menu)
	player.weapons_changed.connect(_on_weapons_changed)
	player.targeting_changed.connect(_on_targeting_changed)
	player.projectile_class_changed.connect(_on_projectile_class_changed)

	hud.update_health(player.health, player.max_health)
	hud.update_xp(0, player.xp_to_next_level)
	hud.update_level(1)
	hud.update_kills(0)
	hud.update_perk_points(perk_points)
	_apply_start_state()
	_persist_run_state()
	# Init zone task list & inventory display
	_init_task_list()
	hud.show_task_list(_task_list)
	_update_inventory_hud()
	# Spawn map-source pickups + initial meta resources + hero capsule
	_spawn_map_pickups()
	_spawn_hero_capsule()
	# Init weapon and targeting display
	hud.update_active_weapons(player.get_active_weapons_display())
	hud.update_weapon_display("Plasma Rifle")
	hud.update_projectile_display(player.get_projectile_class_display_name())
	hud.set_projectile_switch_enabled(player.can_cycle_projectile_classes())
	hud.update_targeting_display("Forward")


func _process(delta: float) -> void:
	if game_over:
		return
	elapsed_seconds += delta
	autosave_elapsed += delta
	if autosave_elapsed >= 2.0:
		autosave_elapsed = 0.0
		_persist_run_state()
	# Wave scheduler tick
	if _in_wave:
		_wave_event_timer -= delta
		if _wave_event_timer <= 0.0:
			_dispatch_wave_event()
	# Refresh weapon display every 0.025s for responsive cooldown overlay
	weapon_display_timer -= delta
	if weapon_display_timer <= 0.0:
		weapon_display_timer = 0.025
		if player:
			hud.update_active_weapons(player.get_active_weapons_display())
	# Recall zone spawn (R key) — only one zone at a time
	if Input.is_action_just_pressed("recall"):
		_try_spawn_recall_zone()


func _start_next_wave() -> void:
	if game_over:
		return
	_wave_number += 1
	_wave_loot_dropped = false  # reset drop quota each wave
	var wave_size: int = _compute_wave_size()
	_wave_schedule = _generate_wave_schedule(wave_size)
	_wave_head = 0
	_in_wave = true
	if _wave_schedule.size() > 0:
		_wave_event_timer = (_wave_schedule[0] as Dictionary).get("gap", 0.1)


func _dispatch_wave_event() -> void:
	if _wave_head >= _wave_schedule.size():
		_in_wave = false
		return
	var event: Dictionary = _wave_schedule[_wave_head] as Dictionary
	var burst: int = int(event.get("count", 1))
	for _i in burst:
		_spawn_enemy()
	_wave_head += 1
	if _wave_head < _wave_schedule.size():
		_wave_event_timer = (_wave_schedule[_wave_head] as Dictionary).get("gap", 0.4)
	else:
		_in_wave = false
		spawn_timer.wait_time = _get_inter_wave_gap()
		spawn_timer.start()


func _compute_wave_size() -> int:
	var base: int = int(ConfigService.get_value("waves.wave_base_count", 3))
	var scale: float = float(ConfigService.get_value("waves.wave_count_scaling", 1.1))
	var time_interval: float = float(ConfigService.get_value("waves.wave_time_bonus_interval", 50.0))
	var max_count: int = int(ConfigService.get_value("waves.wave_max_count", 22))
	var wave_bonus: int = int(float(_wave_number) * scale)
	var time_bonus: int = int(elapsed_seconds / maxf(time_interval, 1.0))
	return clampi(base + wave_bonus + time_bonus, base, max_count)


# Returns a schedule: an Array of {gap: float, count: int} dicts.
# Each gap is the delay (in seconds) BEFORE spawning that burst, relative to the previous event.
func _generate_wave_schedule(total: int) -> Array:
	var schedule: Array = []
	var remaining: int = total
	var is_first: bool = true
	while remaining > 0:
		var burst: int = mini(remaining, _pick_burst_size())
		var gap: float = _pick_burst_gap(is_first)
		schedule.append({"gap": gap, "count": burst})
		remaining -= burst
		is_first = false
	return schedule


func _pick_burst_size() -> int:
	var r: float = randf()
	if r < 0.55:
		return 1   # 55% — single
	if r < 0.85:
		return 2   # 30% — double
	return 3       # 15% — triple


func _pick_burst_gap(is_first: bool) -> float:
	if is_first:
		# Brief lead-in so players see the wave start
		return randf_range(0.05, 0.20)
	var r: float = randf()
	if r < 0.25:
		return randf_range(0.25, 0.40)   # 25% — quick follow-up
	if r < 0.70:
		return randf_range(0.40, 0.70)   # 45% — medium gap
	return randf_range(0.70, 1.10)       # 30% — longer pause


func _get_inter_wave_gap() -> float:
	var base: float = float(ConfigService.get_value("waves.inter_wave_gap_base", 3.2))
	var min_gap: float = float(ConfigService.get_value("waves.inter_wave_gap_min", 1.5))
	var reduction: float = float(ConfigService.get_value("waves.inter_wave_gap_reduction_per_wave", 0.05))
	return maxf(min_gap, base - float(_wave_number) * reduction)


func _spawn_enemy() -> void:
	if _enemy_pool == null:
		return
	var archetype_id: String = _pick_enemy_archetype_id()
	var archetype_data: Dictionary = _get_enemy_archetype_data(archetype_id)
	var enemy: CharacterBody2D = _enemy_pool.acquire(archetype_id)
	var angle: float = randf() * TAU
	var dist: float = randf_range(min_spawn_distance, max_spawn_distance)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	# Hazard alanında spawn etme — farklı açı dene (maks 10 deneme)
	var _haz_bg: Node = get_tree().get_first_node_in_group("background_tiler")
	if _haz_bg != null and _haz_bg.has_method("is_hazard_at_world"):
		var _retry: int = 0
		while _haz_bg.is_hazard_at_world(enemy.global_position) and _retry < 10:
			angle = randf() * TAU
			enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
			_retry += 1
	enemy.target = player
	if enemy.has_method("setup_from_archetype"):
		enemy.setup_from_archetype(archetype_id, archetype_data)
	var progress_ratio: float = _compute_difficulty_progress()
	var elite_chance: float = _compute_elite_chance()
	var is_elite: bool = randf() <= elite_chance
	var health_growth: float = float(ConfigService.get_value("difficulty.enemy_health_growth", 0.09))
	var speed_growth: float = float(ConfigService.get_value("difficulty.enemy_speed_growth", 0.03))
	var damage_growth: float = float(ConfigService.get_value("difficulty.enemy_damage_growth", 0.05))
	var base_physical_resist: float = float(archetype_data.get("physical_resistance", 0.0))
	var base_explosive_resist: float = float(archetype_data.get("explosive_resistance", 0.0))
	enemy.physical_resistance = clampf(base_physical_resist + (progress_ratio * float(ConfigService.get_value("difficulty.physical_resist_growth", 0.02))), 0.0, 0.65)
	enemy.explosive_resistance = clampf(base_explosive_resist + (progress_ratio * float(ConfigService.get_value("difficulty.explosive_resist_growth", 0.01))), 0.0, 0.5)
	if enemy.has_method("apply_scaling"):
		enemy.apply_scaling(progress_ratio, is_elite, health_growth, speed_growth, damage_growth)
	# Prevent duplicate signal connections across pool reuse cycles
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)
	_enemy_pool.activate(enemy)
	# E1: Fade-in flash effect on spawn
	enemy.modulate.a = 0.0
	var _spawn_tween: Tween = create_tween()
	_spawn_tween.tween_property(enemy, "modulate:a", 1.0, 0.3)
	_spawn_enemy_flash(enemy.global_position)


func _spawn_enemy_flash(pos: Vector2) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	# Outer slow ring
	var ring: Line2D = Line2D.new()
	ring.z_index = 6
	for p in 28:
		var ang: float = (TAU / 28.0) * float(p)
		ring.add_point(Vector2(cos(ang), sin(ang)) * 1.0)
	ring.closed = true
	ring.width = 2.5
	ring.default_color = Color(0.70, 1.0, 1.0, 0.90)
	scene_root.add_child(ring)
	ring.global_position = pos
	var tw: Tween = ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(20.0, 20.0), 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(ring, "modulate:a", 0.0, 0.30).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ring.queue_free)
	# Inner faster ring
	var ring2: Line2D = Line2D.new()
	ring2.z_index = 6
	for p in 20:
		var ang2: float = (TAU / 20.0) * float(p)
		ring2.add_point(Vector2(cos(ang2), sin(ang2)) * 1.0)
	ring2.closed = true
	ring2.width = 1.5
	ring2.default_color = Color(1.0, 0.88, 0.45, 0.75)
	scene_root.add_child(ring2)
	ring2.global_position = pos
	var tw2: Tween = ring2.create_tween().set_parallel(true)
	tw2.tween_property(ring2, "scale", Vector2(9.0, 9.0), 0.18).set_ease(Tween.EASE_OUT)
	tw2.tween_property(ring2, "modulate:a", 0.0, 0.18)
	tw2.chain().tween_callback(ring2.queue_free)
	# Spark particles outward
	for i in 7:
		var dot: ColorRect = ColorRect.new()
		dot.z_index = 7
		dot.color = Color(0.55, 0.95, 1.0, 0.95)
		var r: float = randf_range(1.5, 3.5)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var spark_angle: float = (TAU / 7.0) * float(i) + randf_range(-0.25, 0.25)
		var spd: float = randf_range(60.0, 130.0)
		var vel: Vector2 = Vector2(cos(spark_angle), sin(spark_angle)) * spd
		dot.position = pos + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.15, 0.28)
		var tw3: Tween = dot.create_tween().set_parallel(true)
		tw3.tween_property(dot, "position", dot.position + vel * dur, dur).set_ease(Tween.EASE_OUT)
		tw3.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw3.chain().tween_callback(dot.queue_free)


func _spawn_enemy_death_burst(pos: Vector2) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	# Center flash
	var flash: ColorRect = ColorRect.new()
	flash.z_index = 8
	flash.color = Color(1.0, 0.55, 0.1, 0.80)
	flash.size = Vector2(18.0, 18.0)
	flash.position = pos - Vector2(9.0, 9.0)
	scene_root.add_child(flash)
	var tfw: Tween = flash.create_tween()
	tfw.tween_property(flash, "modulate:a", 0.0, 0.22)
	tfw.tween_callback(flash.queue_free)
	# Radial blood/gib particles
	for i in 14:
		var dot: ColorRect = ColorRect.new()
		dot.z_index = 5
		dot.color = Color(randf_range(0.55, 0.85), randf_range(0.05, 0.18), 0.05, 0.9)
		var r: float = randf_range(2.5, 6.0)
		dot.size = Vector2(r * 2.0, r * 2.0)
		var db_angle: float = randf_range(0.0, TAU)
		var spd: float = randf_range(80.0, 200.0)
		var vel: Vector2 = Vector2(cos(db_angle), sin(db_angle)) * spd
		dot.position = pos + Vector2(-r, -r)
		scene_root.add_child(dot)
		var dur: float = randf_range(0.25, 0.55)
		var tw: Tween = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + vel * dur, dur) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)


func _on_enemy_died(pos: Vector2) -> void:
	kill_count += 1
	hud.update_kills(kill_count)
	_spawn_enemy_death_burst(pos)
	_try_spawn_drop(pos)
	_spawn_xp_gem(pos)
	_try_spawn_world_bomb()
	_try_spawn_meta_resource(pos)
	MockApiClient.queue_event("enemy_killed", {"kills": kill_count})
	_persist_run_state()
	# Wave count/size scaling replaces the old per-kill spawn interval reduction.


func _try_spawn_world_bomb() -> void:
	var bomb_every: int = int(ConfigService.get_value("difficulty.bomb_spawn_kills", 100))
	if bomb_every <= 0 or kill_count % bomb_every != 0:
		return
	if get_tree().get_nodes_in_group("world_bombs").size() >= 4:
		return
	var angle: float = randf() * TAU
	var dist: float = randf_range(200.0, 350.0)
	var ground_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	call_deferred("_spawn_world_bomb_deferred", ground_pos)


func _spawn_world_bomb_deferred(ground_pos: Vector2) -> void:
	var bomb: Node2D = world_bomb_scene.instantiate()
	# Spawn 600 px above the intended landing position (slight horizontal jitter)
	var drop_height: float = 600.0
	bomb.global_position = ground_pos + Vector2(randf_range(-30.0, 30.0), -drop_height)
	add_child(bomb)
	if bomb.has_method("start_falling"):
		bomb.start_falling(ground_pos)


func _spawn_xp_gem(pos: Vector2) -> void:
	var tier: String = _roll_xp_tier()
	call_deferred("_spawn_xp_gem_deferred", pos, tier)


func _spawn_xp_gem_deferred(pos: Vector2, tier: String) -> void:
	var gem: Node2D = xp_gem_scene.instantiate()
	gem.global_position = pos
	if gem.has_method("set_tier"):
		gem.set_tier(tier)
	add_child(gem)


func _on_player_died() -> void:
	game_over = true
	_in_wave = false
	spawn_timer.stop()
	var held_def: Variant = ConfigService.get_value("weapons.definitions.%s" % player.current_held_weapon, null)
	var weapon_name: String = "Plasma Rifle"
	if held_def != null and typeof(held_def) == TYPE_DICTIONARY:
		weapon_name = str((held_def as Dictionary).get("name", weapon_name))
	hud.show_game_over({"kills": kill_count, "level": player.level, "weapon": weapon_name, "time": int(elapsed_seconds)})
	_persist_run_state()
	Session.finalize_run()
	MockApiClient.queue_event("run_finished", {"kills": kill_count, "level": player.level})
	get_tree().paused = true


func _on_game_over_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_game_over_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_menu_requested() -> void:
	_persist_run_state()
	Session.finalize_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_perk_tree_requested() -> void:
	if game_over:
		return
	_toggle_perk_tree()


func _on_weapons_changed() -> void:
	if player:
		hud.update_active_weapons(player.get_active_weapons_display())
		var held_def: Variant = ConfigService.get_value("weapons.definitions.%s" % player.current_held_weapon, null)
		var held_name: String = "Plasma Rifle"
		if held_def != null and typeof(held_def) == TYPE_DICTIONARY:
			held_name = str((held_def as Dictionary).get("name", held_name))
		hud.update_weapon_display(held_name)


func _on_targeting_changed(mode: String) -> void:
	var mode_def: Variant = ConfigService.get_value("weapons.targeting_modes.%s" % mode, null)
	var mode_name: String = mode.capitalize()
	if mode_def != null and typeof(mode_def) == TYPE_DICTIONARY:
		mode_name = str((mode_def as Dictionary).get("name", mode.capitalize()))
	hud.update_targeting_display(mode_name)


func _on_projectile_class_changed(_projectile_class: String) -> void:
	if player:
		hud.update_projectile_display(player.get_projectile_class_display_name())
		hud.set_projectile_switch_enabled(player.can_cycle_projectile_classes())


func _on_projectile_switch_requested() -> void:
	if game_over or not player:
		return
	player.cycle_projectile_class()


func _toggle_perk_tree() -> void:
	if perk_tree_instance and is_instance_valid(perk_tree_instance):
		perk_tree_instance.queue_free()
		perk_tree_instance = null
		get_tree().paused = false
		return
	perk_tree_instance = perk_tree_scene.instantiate() as Control
	hud.add_child(perk_tree_instance)
	if perk_tree_instance.has_method("refresh"):
		perk_tree_instance.refresh(upgrade_stacks, upgrade_catalog, perk_points, _get_selectable_upgrade_ids())
	if perk_tree_instance.has_signal("perk_selected"):
		perk_tree_instance.perk_selected.connect(_on_perk_tree_upgrade_selected)
	perk_tree_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	perk_tree_instance.tree_exited.connect(_on_perk_tree_closed)
	get_tree().paused = true


func _on_perk_tree_closed() -> void:
	perk_tree_instance = null
	if not game_over:
		var tree := get_tree()
		if tree:
			tree.paused = false


func _on_player_level_changed(new_level: int) -> void:
	if applying_start_state:
		return
	MockApiClient.queue_event("level_up", {"level": new_level})
	perk_points += 1
	hud.update_perk_points(perk_points)
	_persist_run_state()


func _apply_start_state() -> void:
	if Session.pending_continue and Session.has_last_run():
		applying_start_state = true
		player.apply_run_state(Session.last_run)
		applying_start_state = false
		kill_count = int(Session.last_run.get("kills", 0))
		upgrade_stacks = Session.last_run.get("upgrade_stacks", {}).duplicate(true)
		perk_points = int(Session.last_run.get("perk_points", 0))
		hud.update_kills(kill_count)
		hud.update_perk_points(perk_points)
	Session.pending_continue = false


func _persist_run_state() -> void:
	var run_state: Dictionary = player.get_run_state()
	run_state["upgrade_stacks"] = upgrade_stacks.duplicate(true)
	run_state["perk_points"] = perk_points
	Session.record_run_state(run_state, kill_count)


func _on_perk_tree_upgrade_selected(upgrade_id: String) -> void:
	if game_over:
		return
	var cost: int = _get_perk_cost(upgrade_id)
	if perk_points < cost or not _can_offer_upgrade(upgrade_id):
		_refresh_perk_tree()
		return
	player.apply_upgrade(upgrade_id)
	_upgrade_stack_increment(upgrade_id)
	perk_points -= cost
	hud.update_perk_points(perk_points)
	MockApiClient.queue_event("perk_tree_selected", {"id": upgrade_id, "cost": cost, "remaining_points": perk_points})
	_persist_run_state()
	if perk_points <= 0 and perk_tree_instance and is_instance_valid(perk_tree_instance):
		perk_tree_instance.queue_free()
		return
	_refresh_perk_tree()


func _get_perk_cost(perk_id: String) -> int:
	var base_cost: int = int(ConfigService.get_value("upgrades.perk_costs.%s" % perk_id, 1))
	var current_stacks: int = int(upgrade_stacks.get(perk_id, 0))
	return base_cost * (current_stacks + 1)


func _on_player_vision_changed(level: int) -> void:
	var vignette: ColorRect = get_node_or_null("VignetteLayer/Vignette")
	if vignette and vignette.material:
		var base_intensity: float = 0.65
		var new_intensity: float = maxf(0.05, base_intensity - float(level) * 0.02)
		(vignette.material as ShaderMaterial).set_shader_parameter("vignette_intensity", new_intensity)


func _compute_difficulty_progress() -> float:
	var per_kill_growth: float = float(ConfigService.get_value("difficulty.enemy_health_growth", 0.09))
	return (float(kill_count) / 30.0) * per_kill_growth + (elapsed_seconds / 300.0)


func _compute_elite_chance() -> float:
	var base: float = float(ConfigService.get_value("difficulty.elite_chance_base", 0.03))
	var per_minute: float = float(ConfigService.get_value("difficulty.elite_chance_per_minute", 0.015))
	var max_chance: float = float(ConfigService.get_value("difficulty.max_elite_chance", 0.2))
	var minutes: float = elapsed_seconds / 60.0
	return clampf(base + (minutes * per_minute), base, max_chance)


func _pick_enemy_archetype_id() -> String:
	var available_ids: Array[String] = _get_available_enemy_archetype_ids()
	if available_ids.is_empty():
		return "runner"
	var total_weight: float = 0.0
	for archetype_id in available_ids:
		var data: Dictionary = _get_enemy_archetype_data(archetype_id)
		total_weight += _get_effective_archetype_weight(data)
	var roll: float = randf() * maxf(total_weight, 0.01)
	var cursor: float = 0.0
	for archetype_id in available_ids:
		var data: Dictionary = _get_enemy_archetype_data(archetype_id)
		cursor += _get_effective_archetype_weight(data)
		if roll <= cursor:
			return archetype_id
	return available_ids.back()


func _get_available_enemy_archetype_ids() -> Array[String]:
	var result: Array[String] = []
	var archetypes: Dictionary = ConfigService.get_value("enemies.archetypes", {}) as Dictionary
	if archetypes.is_empty():
		result.append("runner")
		return result
	var unlock_mode: String = str(ConfigService.get_value("enemies.spawn_unlock_mode", "hybrid_or"))
	for key in archetypes.keys():
		var archetype_id: String = str(key)
		var data: Dictionary = archetypes[archetype_id] as Dictionary
		if _is_enemy_archetype_unlocked(data, unlock_mode):
			result.append(archetype_id)
	if result.is_empty():
		result.append("runner")
	return result


func _is_enemy_archetype_unlocked(archetype_data: Dictionary, unlock_mode: String) -> bool:
	var req_kills: int = int(archetype_data.get("unlock_kills", 0))
	var req_seconds: float = float(archetype_data.get("unlock_seconds", 0.0))
	if unlock_mode == "hybrid_and":
		return kill_count >= req_kills and elapsed_seconds >= req_seconds
	return kill_count >= req_kills or elapsed_seconds >= req_seconds


func _get_enemy_archetype_data(archetype_id: String) -> Dictionary:
	var data: Variant = ConfigService.get_value("enemies.archetypes.%s" % archetype_id, null)
	if data != null and typeof(data) == TYPE_DICTIONARY:
		return data as Dictionary
	var fallback: Variant = ConfigService.get_value("enemies.archetypes.runner", null)
	if fallback != null and typeof(fallback) == TYPE_DICTIONARY:
		return fallback as Dictionary
	return {}


func _get_effective_archetype_weight(archetype_data: Dictionary) -> float:
	var base_weight: float = maxf(0.01, float(archetype_data.get("spawn_weight", 1.0)))
	var req_kills: int = int(archetype_data.get("unlock_kills", 0))
	var req_seconds: float = float(archetype_data.get("unlock_seconds", 0.0))
	var kill_progress: float = 1.0
	if req_kills > 0:
		kill_progress = clampf(float(kill_count) / float(req_kills), 0.0, 1.6)
	var time_progress: float = 1.0
	if req_seconds > 0.0:
		time_progress = clampf(elapsed_seconds / req_seconds, 0.0, 1.6)
	var hybrid_progress: float = _compute_enemy_unlock_progress(kill_progress, time_progress)
	var ramp: float = clampf((hybrid_progress - 0.95) / 0.45, 0.25, 1.0)
	return base_weight * ramp


func _compute_enemy_unlock_progress(kill_progress: float, time_progress: float) -> float:
	var unlock_mode: String = str(ConfigService.get_value("enemies.spawn_unlock_mode", "hybrid_or"))
	if unlock_mode == "hybrid_and":
		return minf(kill_progress, time_progress)
	return maxf(kill_progress, time_progress)


func _roll_xp_tier() -> String:
	var small_weight: int = int(ConfigService.get_value("xp.small_weight", 65))
	var medium_weight: int = int(ConfigService.get_value("xp.medium_weight", 25))
	var large_weight: int = int(ConfigService.get_value("xp.large_weight", 10))
	var medium_unlock: int = int(ConfigService.get_value("xp.medium_unlock_kills", 20))
	var large_unlock: int = int(ConfigService.get_value("xp.large_unlock_kills", 45))
	if player:
		medium_weight += int(round(player.luck * 12.0))
		large_weight += int(round(player.luck * 6.0))

	if kill_count < medium_unlock:
		return "small"

	if kill_count < large_unlock:
		large_weight = 0

	var total: int = small_weight + medium_weight + large_weight
	var roll: int = randi_range(1, maxi(total, 1))
	if roll <= small_weight:
		return "small"
	if roll <= small_weight + medium_weight:
		return "medium"
	return "large"


## Single exclusive drop roll per enemy death.
## Chest (1%), LootBox with zone-item chance (3%), otherwise nothing.
## Uses kill_count milestones for guaranteed chest drops.
func _try_spawn_drop(pos: Vector2) -> void:
	var drop_every: int = int(ConfigService.get_value("chest.drop_every_kills", 50))
	var max_chests_alive: int = int(ConfigService.get_value("chest.max_chests_alive", 2))

	# Milestone chest drop (every N kills)
	var milestone_chest: bool = (kill_count % maxi(drop_every, 1) == 0)
	if milestone_chest and get_tree().get_nodes_in_group("chests").size() < max_chests_alive:
		call_deferred("_spawn_chest_deferred", pos)
		return

	# Random exclusive roll: 1% chest, 3% loot_box, else nothing
	var luck_bonus: float = player.luck * 0.005 if player else 0.0
	var r: float = randf()
	if r < 0.01 + luck_bonus:
		if get_tree().get_nodes_in_group("chests").size() < max_chests_alive:
			call_deferred("_spawn_chest_deferred", pos)
	elif r < 0.04 + luck_bonus:
		if not _task_list.is_empty():
			if get_tree().get_nodes_in_group("loot_boxes").size() < 8:
				call_deferred("_spawn_loot_box_deferred", pos)


func _spawn_loot_box_deferred(pos: Vector2) -> void:
	var lb: Node2D = loot_box_scene.instantiate()
	var jitter: Vector2 = Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
	lb.global_position = pos + jitter
	lb.opened.connect(_on_loot_box_opened)
	add_child(lb)
	_spawn_dot_burst(lb.global_position, Color(0.2, 1.0, 0.9, 0.9), 6, 40.0, 90.0, 0.25)


func _on_loot_box_opened(open_pos: Vector2) -> void:
	if game_over:
		return
	_spawn_dot_burst(open_pos, Color(1.0, 0.85, 0.2, 0.9), 8, 55.0, 130.0, 0.30)
	# 45% chance to spawn a zone task item; otherwise a meta resource
	if randf() < 0.45 and not _task_list.is_empty():
		var incomplete: Array[String] = []
		for task_entry in _task_list:
			var t: Dictionary = task_entry as Dictionary
			if not bool(t.get("done", false)) and str(t.get("source", "enemy")) == "enemy":
				incomplete.append(str(t.get("id", "")))
		if not incomplete.is_empty():
			var chosen: String = incomplete[randi() % incomplete.size()]
			call_deferred("_spawn_enemy_loot_deferred", chosen, open_pos)
			return
	# Fallback: spawn a random meta resource
	var types: Variant = ConfigService.get_value("meta_resources.types", null)
	if types != null and typeof(types) == TYPE_DICTIONARY and not (types as Dictionary).is_empty():
		var keys: Array = (types as Dictionary).keys()
		var chosen_type: String = str(keys[randi() % keys.size()])
		call_deferred("_spawn_meta_resource_deferred", open_pos, chosen_type)


## Spawns `count` colored dot particles radiating outward from `pos`.
func _spawn_dot_burst(pos: Vector2, color: Color, count: int,
		min_spd: float, max_spd: float, dur: float) -> void:
	for _i in count:
		var dot := ColorRect.new()
		dot.z_index = 8
		var r: float = randf_range(2.5, 5.0)
		dot.size = Vector2(r * 2.0, r * 2.0)
		dot.color = color
		var angle: float = randf_range(0.0, TAU)
		var spd: float = randf_range(min_spd, max_spd)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * spd
		dot.position = pos + Vector2(-r, -r)
		add_child(dot)
		var tw: Tween = dot.create_tween().set_parallel(true)
		tw.tween_property(dot, "position", dot.position + vel * dur, dur) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(dot.queue_free)


func _try_spawn_chest(pos: Vector2) -> void:
	var drop_every: int = int(ConfigService.get_value("chest.drop_every_kills", 15))
	var random_drop_chance: float = float(ConfigService.get_value("chest.random_drop_chance", 0.08))
	var max_chests_alive: int = int(ConfigService.get_value("chest.max_chests_alive", 2))
	if player:
		random_drop_chance += player.luck * 0.03
	var alive_chests: int = get_tree().get_nodes_in_group("chests").size()
	if alive_chests >= max_chests_alive:
		return

	var should_drop: bool = (kill_count % maxi(drop_every, 1) == 0) or (randf() <= random_drop_chance)
	if not should_drop:
		return
	call_deferred("_spawn_chest_deferred", pos)


func _spawn_chest_deferred(pos: Vector2) -> void:
	var chest: Node2D = chest_scene.instantiate()
	chest.global_position = pos
	chest.opened.connect(_on_chest_opened)
	add_child(chest)


func _on_chest_opened(_pos: Vector2) -> void:
	if game_over or not player:
		return
	# Always: heal 30% max health
	var heal_amount: int = maxi(1, int(float(player.max_health) * 0.30))
	player.health = mini(player.health + heal_amount, player.max_health)
	player.health_changed.emit(player.health, player.max_health)
	hud.show_notification("❤ +%d Can! Perk puanı kazandın (P ile aç)" % heal_amount)
	# Also award a perk point so player can pick
	perk_points += 1
	hud.update_perk_points(perk_points)
	_persist_run_state()
	MockApiClient.queue_event("chest_opened", {"reward": "heal_perk", "kills": kill_count})


func _can_offer_upgrade(upgrade_id: String) -> bool:
	var max_stack: int = int(ConfigService.get_value("upgrades.max_stacks.%s" % upgrade_id, -1))
	if max_stack >= 0:
		var current_stack: int = int(upgrade_stacks.get(upgrade_id, 0))
		if current_stack >= max_stack:
			return false
	# Prerequisite check
	if upgrade_catalog.has(upgrade_id):
		var prereqs: Array = upgrade_catalog[upgrade_id].get("prerequisites", []) as Array
		for prereq_id in prereqs:
			var prereq_stacks: int = int(upgrade_stacks.get(str(prereq_id), 0))
			if prereq_stacks <= 0:
				return false
	# Cost check
	var cost: int = _get_perk_cost(upgrade_id)
	if perk_points < cost:
		return false
	# Targeting: don't offer modes already unlocked
	var targeting_ids: Array[String] = ["rear_targeting", "side_sweep", "full_spread", "orbital_fire"]
	if upgrade_id in targeting_ids:
		var mode: String = _targeting_id_to_mode(upgrade_id)
		if player and mode in player.unlocked_targeting_modes:
			return false
	var projectile_upgrade_ids: Array[String] = ["unlock_aoe_projectile", "unlock_bouncing_projectile", "unlock_beam_projectile"]
	if upgrade_id in projectile_upgrade_ids:
		var projectile_id: String = _projectile_upgrade_id_to_class(upgrade_id)
		if player and player.has_projectile_class(projectile_id):
			return false
	return true


func _targeting_id_to_mode(upgrade_id: String) -> String:
	match upgrade_id:
		"rear_targeting": return "rear_guard"
		"side_sweep": return "side_sweep"
		"full_spread": return "full_spread"
		"orbital_fire": return "orbital_fire"
	return "forward"


func _projectile_upgrade_id_to_class(upgrade_id: String) -> String:
	match upgrade_id:
		"unlock_aoe_projectile": return "aoe"
		"unlock_bouncing_projectile": return "bouncing"
		"unlock_beam_projectile": return "beam"
	return "standard"


func _upgrade_stack_increment(upgrade_id: String) -> void:
	upgrade_stacks[upgrade_id] = int(upgrade_stacks.get(upgrade_id, 0)) + 1


func _get_selectable_upgrade_ids() -> Array[String]:
	var selectable_ids: Array[String] = []
	for upgrade_id in upgrade_catalog.keys():
		var perk_id: String = str(upgrade_id)
		if _can_offer_upgrade(perk_id):
			selectable_ids.append(perk_id)
	return selectable_ids


func _refresh_perk_tree() -> void:
	if perk_tree_instance and is_instance_valid(perk_tree_instance) and perk_tree_instance.has_method("refresh"):
		perk_tree_instance.refresh(upgrade_stacks, upgrade_catalog, perk_points, _get_selectable_upgrade_ids())


# =====================================================================
#  META-RESOURCE & ZONE TASK SYSTEM
# =====================================================================

func _init_task_list() -> void:
	_task_list.clear()
	_zone_items.clear()
	_map_item_ids.clear()
	_tasks_all_done = false
	var zone_data: Variant = ConfigService.get_value("zones.%s" % Session.current_zone_id, null)
	if zone_data == null or typeof(zone_data) != TYPE_DICTIONARY:
		return
	var required: Variant = (zone_data as Dictionary).get("required_items", null)
	if required == null or typeof(required) != TYPE_DICTIONARY:
		return
	for raw_key in (required as Dictionary).keys():
		var item_id: String = str(raw_key)
		var item_def: Variant = (required as Dictionary)[item_id]
		var req_count: int = 1
		var item_source: String = "enemy"
		if typeof(item_def) == TYPE_DICTIONARY:
			req_count = int((item_def as Dictionary).get("count", 1))
			item_source = str((item_def as Dictionary).get("source", "enemy"))
		else:
			req_count = int(item_def)
		_zone_items[item_id] = 0
		_task_list.append({
			"id": item_id,
			"display_name": _zone_item_display_name(item_id),
			"current": 0,
			"required": req_count,
			"source": item_source,
			"done": false
		})
		if item_source == "map":
			_map_item_ids.append(item_id)


func _zone_item_display_name(item_id: String) -> String:
	match item_id:
		"nano_cores":    return "Nano Çekirdek"
		"energy_cells":  return "Enerji Hücresi"
		"scrap_metal":   return "Hurda Metal"
		"data_shards":   return "Veri Kırıkları"
		"power_shards":  return "Güç Kırıkları"
		"data_cores":    return "Veri Çekirdekleri"
		_: return item_id.replace("_", " ").capitalize()


func _try_collect_zone_item(pos: Vector2) -> void:
	if _task_list.is_empty():
		return
	# Max 1 loot drop per enemy wave
	if _wave_loot_dropped:
		return
	# Check bag capacity
	var total_collected: int = 0
	for key in _zone_items.keys():
		total_collected += int(_zone_items[key])
	if total_collected >= Session.bag_capacity:
		return
	# 30% drop chance for the one allowed drop this wave
	if randf() > 0.30:
		return
	# Pick a random incomplete enemy-source task item to drop
	var incomplete: Array[String] = []
	for task_entry in _task_list:
		var t: Dictionary = task_entry as Dictionary
		if not bool(t.get("done", false)) and str(t.get("source", "enemy")) == "enemy":
			incomplete.append(str(t.get("id", "")))
	if incomplete.is_empty():
		return
	var chosen: String = incomplete[randi() % incomplete.size()]
	_wave_loot_dropped = true  # only one drop per wave
	# Spawn a physical loot pickup node at the enemy's death position
	call_deferred("_spawn_enemy_loot_deferred", chosen, pos)


func _spawn_enemy_loot_deferred(item_id: String, spawn_pos: Vector2) -> void:
	var pickup: Node2D = zone_item_pickup_scene.instantiate() as Node2D
	var jitter: Vector2 = Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
	pickup.global_position = spawn_pos + jitter
	pickup.set("item_type", item_id)
	pickup.set("required_count", 1)
	add_child(pickup)
	if pickup.has_signal("picked_up"):
		(pickup as Area2D).picked_up.connect(func(t: String) -> void:
			_zone_items[t] = int(_zone_items.get(t, 0)) + 1
			_check_zone_tasks()
			for task_entry in _task_list:
				hud.update_task(task_entry as Dictionary)
			hud.show_notification("Görev eşyası toplandı!", 1.5)
			_spawn_dot_burst(pickup.global_position, Color(0.25, 1.0, 0.4, 0.9), 5, 35.0, 80.0, 0.22)
		)


func _check_zone_tasks() -> void:
	var all_done: bool = true
	for i in _task_list.size():
		var t: Dictionary = _task_list[i] as Dictionary
		var item_id: String = str(t.get("id", ""))
		var current: int = int(_zone_items.get(item_id, 0))
		var required: int = int(t.get("required", 1))
		(_task_list[i] as Dictionary)["current"] = current
		(_task_list[i] as Dictionary)["done"] = current >= required
		if current < required:
			all_done = false
	if all_done and not _task_list.is_empty() and not _tasks_all_done:
		_tasks_all_done = true
		hud.show_notification("Tüm görevler tamamlandı! Geri dönmek için R bas.", 5.0)


# ===  MAP PICKUPS & INITIAL SPAWNS  ===

func _spawn_map_pickups() -> void:
	if _map_item_ids.is_empty():
		return
	var count: int = _map_item_ids.size()
	for i in count:
		var item_id: String = _map_item_ids[i]
		var req: int = 1
		for task_entry in _task_list:
			var t: Dictionary = task_entry as Dictionary
			if str(t.get("id", "")) == item_id:
				req = int(t.get("required", 1))
				break
		var angle: float = (TAU / float(count)) * float(i) + randf_range(-0.25, 0.25)
		var dist: float = randf_range(700.0, 1100.0)
		var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		call_deferred("_spawn_zone_item_pickup_deferred", item_id, req, pos)
	_spawn_initial_meta_resources()


func _spawn_zone_item_pickup_deferred(item_id: String, req_count: int, pos: Vector2) -> void:
	var pickup: Node2D = zone_item_pickup_scene.instantiate() as Node2D
	pickup.global_position = pos
	pickup.set("item_type", item_id)
	pickup.set("required_count", req_count)
	add_child(pickup)
	if pickup.has_signal("picked_up"):
		(pickup as Area2D).picked_up.connect(_on_zone_item_picked_up)


func _spawn_initial_meta_resources() -> void:
	var types: Variant = ConfigService.get_value("meta_resources.types", null)
	if types == null or typeof(types) != TYPE_DICTIONARY:
		return
	var keys: Array = (types as Dictionary).keys()
	if keys.is_empty():
		return
	var spawn_count: int = randi_range(4, 6)
	for i in spawn_count:
		var angle: float = (TAU / float(spawn_count)) * float(i) + randf_range(-0.3, 0.3)
		var dist: float = randf_range(600.0, 1000.0)
		var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		var chosen_type: String = str(keys[randi() % keys.size()])
		call_deferred("_spawn_meta_resource_deferred", pos, chosen_type)


func _on_zone_item_picked_up(item_type: String) -> void:
	var req: int = 1
	for task_entry in _task_list:
		var t: Dictionary = task_entry as Dictionary
		if str(t.get("id", "")) == item_type:
			req = int(t.get("required", 1))
			break
	_zone_items[item_type] = req
	_check_zone_tasks()
	for task_entry in _task_list:
		hud.update_task(task_entry as Dictionary)
	hud.show_notification("Harita eşyası toplandı!", 2.5)
	if player:
		_spawn_dot_burst(player.global_position, Color(0.25, 1.0, 0.4, 0.9), 5, 35.0, 80.0, 0.22)


func _spawn_hero_capsule() -> void:
	var land_pos: Vector2 = player.global_position
	var capsule: Node2D = hero_capsule_scene.instantiate() as Node2D
	player.modulate.a = 0.0
	player.capsule_landing = true
	add_child(capsule)
	capsule.global_position = land_pos + Vector2(0.0, -400.0)
	if capsule.has_signal("capsule_landed"):
		capsule.capsule_landed.connect(func() -> void:
			player.modulate.a = 1.0
			player.capsule_landing = false
		)
	if capsule.has_method("start_falling"):
		capsule.start_falling(land_pos)


func _try_spawn_meta_resource(pos: Vector2) -> void:
	var chance: float = float(ConfigService.get_value("meta_resources.spawn_chance", 0.001))
	if randf() > chance:
		return
	var types: Variant = ConfigService.get_value("meta_resources.types", null)
	if types == null or typeof(types) != TYPE_DICTIONARY:
		return
	var keys: Array = (types as Dictionary).keys()
	if keys.is_empty():
		return
	var chosen_type: String = str(keys[randi() % keys.size()])
	call_deferred("_spawn_meta_resource_deferred", pos, chosen_type)


func _spawn_meta_resource_deferred(pos: Vector2, resource_type: String) -> void:
	var res: Node2D = meta_resource_scene.instantiate() as Node2D
	res.global_position = pos
	res.set("resource_type", resource_type)
	add_child(res)
	res.resource_collected.connect(_update_inventory_hud)


func _update_inventory_hud() -> void:
	hud.update_inventory(
		Session.get_inventory_count("scrap"),
		Session.get_inventory_count("battery"),
		Session.get_inventory_count("nanochips")
	)


# =====================================================================
#  RECALL ZONE
# =====================================================================

func _try_spawn_recall_zone() -> void:
	if game_over:
		return
	# Görevler tamamlanmadan recall açılamaz
	if not _tasks_all_done and not _task_list.is_empty():
		hud.show_notification("Görevler tamamlanmadan geri dönemezsin!", 3.0)
		return
	# Only one recall zone at a time
	if not get_tree().get_nodes_in_group("recall_zone").is_empty():
		return
	var zone: Node2D = recall_zone_scene.instantiate() as Node2D
	zone.global_position = player.global_position
	zone.recall_completed.connect(_on_recall_completed)
	zone.recall_interrupted.connect(_on_recall_interrupted)
	zone.recall_cooldown_expired.connect(_on_recall_cooldown_expired)
	add_child(zone)


func _on_recall_completed() -> void:
	game_over = true
	_in_wave = false
	spawn_timer.stop()
	_persist_run_state()
	Session.complete_zone(Session.current_zone_id)
	# Transfer zone items collected this run to the permanent vault
	var vault_added: Dictionary = {}
	for item_id in _zone_items.keys():
		var count: int = int(_zone_items.get(item_id, 0))
		if count > 0:
			Session.add_to_vault(str(item_id), count)
			vault_added[item_id] = count
	Session.finalize_run()
	hud.show_level_complete({
		"kills": kill_count,
		"level": player.level,
		"time": int(elapsed_seconds),
		"zone": Session.current_zone_id,
		"items": _zone_items.duplicate(),
		"vault_added": vault_added
	})
	get_tree().paused = true


func _on_recall_interrupted(cooldown: float) -> void:
	hud.show_notification("Recall kesildi! Bekleme: %.0fs" % cooldown, 3.0)
	hud.show_recall_cooldown(cooldown)


func _on_recall_cooldown_expired() -> void:
	hud.show_recall_ready()
