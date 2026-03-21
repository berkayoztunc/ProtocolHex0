extends Node2D

@export var spawn_interval: float = 1.5
@export var min_spawn_distance: float = 400.0
@export var max_spawn_distance: float = 600.0

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var xp_gem_scene: PackedScene = preload("res://scenes/xp_gem.tscn")
var chest_scene: PackedScene = preload("res://scenes/chest.tscn")
var perk_tree_scene: PackedScene = preload("res://scenes/perk_tree.tscn")
var world_bomb_scene: PackedScene = preload("res://scenes/world_bomb.tscn")
var kill_count: int = 0
var game_over: bool = false
var autosave_elapsed: float = 0.0
var applying_start_state: bool = false
var elapsed_seconds: float = 0.0
var upgrade_stacks: Dictionary = {}
var weapon_display_timer: float = 0.0
var perk_tree_instance: Control = null
var perk_points: int = 200

var upgrade_catalog: Dictionary = {}

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
# Game over panel is managed by hud.gd (show_game_over / hide_game_over)


func _ready() -> void:
	get_tree().paused = false
	upgrade_catalog = UpgradeCatalogs.get_all_catalogs()
	spawn_interval = float(ConfigService.get_value("difficulty.base_spawn_interval", spawn_interval))
	min_spawn_distance = float(ConfigService.get_value("difficulty.spawn_distance_min", min_spawn_distance))
	max_spawn_distance = float(ConfigService.get_value("difficulty.spawn_distance_max", max_spawn_distance))
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
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
	# Refresh weapon display every 0.025s for responsive cooldown overlay
	weapon_display_timer -= delta
	if weapon_display_timer <= 0.0:
		weapon_display_timer = 0.025
		if player:
			hud.update_active_weapons(player.get_active_weapons_display())


func _on_spawn_timer_timeout() -> void:
	if game_over:
		return
	_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	var angle: float = randf() * TAU
	var dist: float = randf_range(min_spawn_distance, max_spawn_distance)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	enemy.target = player
	var archetype_id: String = _pick_enemy_archetype_id()
	var archetype_data: Dictionary = _get_enemy_archetype_data(archetype_id)
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
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)


func _on_enemy_died(pos: Vector2) -> void:
	kill_count += 1
	hud.update_kills(kill_count)
	_try_spawn_chest(pos)
	_spawn_xp_gem(pos)
	_try_spawn_world_bomb()
	MockApiClient.queue_event("enemy_killed", {"kills": kill_count})
	_persist_run_state()
	# Gradually increase difficulty
	var step_kills: int = int(ConfigService.get_value("difficulty.step_kills", 8))
	if kill_count % max(step_kills, 1) == 0:
		var interval_step: float = float(ConfigService.get_value("difficulty.spawn_interval_step", 0.08))
		var min_interval: float = float(ConfigService.get_value("difficulty.min_spawn_interval", 0.28))
		spawn_timer.wait_time = max(min_interval, spawn_timer.wait_time - interval_step)


func _try_spawn_world_bomb() -> void:
	var bomb_every: int = int(ConfigService.get_value("difficulty.bomb_spawn_kills", 30))
	if bomb_every <= 0 or kill_count % bomb_every != 0:
		return
	var angle: float = randf() * TAU
	var dist: float = randf_range(200.0, 350.0)
	var spawn_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var bomb: Node2D = world_bomb_scene.instantiate()
	bomb.global_position = spawn_pos
	add_child(bomb)


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
	spawn_timer.stop()
	var held_def: Variant = ConfigService.get_value("weapons.definitions.%s" % player.current_held_weapon, null)
	var weapon_name: String = "Plasma Rifle"
	if held_def != null and typeof(held_def) == TYPE_DICTIONARY:
		weapon_name = str((held_def as Dictionary).get("name", weapon_name))
	hud.show_game_over({"kills": kill_count, "level": player.level, "weapon": weapon_name})
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
	if game_over:
		return
	_open_perk_tree_for_level_up()


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
	hud.show_notification("❤ +%d Can! Perk seç!" % heal_amount)
	# Also award a perk point so player can pick
	perk_points += 1
	hud.update_perk_points(perk_points)
	_persist_run_state()
	call_deferred("_toggle_perk_tree")
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


func _open_perk_tree_for_level_up() -> void:
	if perk_tree_instance and is_instance_valid(perk_tree_instance):
		_refresh_perk_tree()
		get_tree().paused = true
		return
	_toggle_perk_tree()
