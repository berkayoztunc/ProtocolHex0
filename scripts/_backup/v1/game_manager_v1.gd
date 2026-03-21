extends Node2D

@export var spawn_interval: float = 1.5
@export var min_spawn_distance: float = 400.0
@export var max_spawn_distance: float = 600.0

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var xp_gem_scene: PackedScene = preload("res://scenes/xp_gem.tscn")
var chest_scene: PackedScene = preload("res://scenes/chest.tscn")
var perk_tree_scene: PackedScene = preload("res://scenes/perk_tree.tscn")
var kill_count: int = 0
var game_over: bool = false
var autosave_elapsed: float = 0.0
var applying_start_state: bool = false
var elapsed_seconds: float = 0.0
var upgrade_stacks: Dictionary = {}
var weapon_display_timer: float = 0.0
var perk_tree_instance: Control = null
var perk_points: int = 0

var upgrade_catalog: Dictionary = {
	# --- Tier 1: Temel İstatistikler (Maliyet: 1) ---
	"attack_speed": {"id": "attack_speed", "name": "Saldırı Hızı", "description": "Atış bekleme süresi azalır.", "rarity": "common", "category": "combat", "prerequisites": []},
	"weapon_damage": {"id": "weapon_damage", "name": "Saldırı Değeri", "description": "Silah ve mermi hasarı artar.", "rarity": "common", "category": "combat", "prerequisites": []},
	"max_health": {"id": "max_health", "name": "Maksimum Can", "description": "Maksimum can +20 artar.", "rarity": "common", "category": "defense", "prerequisites": []},
	"move_speed": {"id": "move_speed", "name": "Hız", "description": "Hareket hızı artar.", "rarity": "common", "category": "mobility", "prerequisites": []},

	# --- Tier 2: Gelişmiş Yetenekler (Maliyet: 2) ---
	"crit_chance": {"id": "crit_chance", "name": "Kritik Şansı", "description": "Kritik vuruş şansı +%8 artar.", "rarity": "uncommon", "category": "combat", "prerequisites": ["attack_speed"]},
	"cooldown_mastery": {"id": "cooldown_mastery", "name": "Sistem Optimizasyonu", "description": "Silah bekleme süreleri azalır.", "rarity": "uncommon", "category": "combat", "prerequisites": ["attack_speed"]},
	"weapon_projectile": {"id": "weapon_projectile", "name": "Ammo Adedi", "description": "Her atışta çıkan mermi sayısı artar.", "rarity": "uncommon", "category": "combat", "prerequisites": ["weapon_damage"]},
	"life_regen": {"id": "life_regen", "name": "Can Yenileme", "description": "Saniyede +1.5 can yenilenir.", "rarity": "uncommon", "category": "defense", "prerequisites": ["max_health"]},
	"dash": {"id": "dash", "name": "Faz Kayması", "description": "+2 dash şarjı. Shift ile kullan.", "rarity": "uncommon", "category": "mobility", "prerequisites": ["move_speed"]},
	"xp_magnet": {"id": "xp_magnet", "name": "Toplama Alanı", "description": "XP ve sandık toplama alanı genişler.", "rarity": "uncommon", "category": "mobility", "prerequisites": ["move_speed"]},

	# --- Tier 3: İleri Seviye (Maliyet: 3) ---
	"pierce": {"id": "pierce", "name": "Delici Mermi", "description": "Mermiler +1 ekstra düşmandan geçer.", "rarity": "rare", "category": "combat", "prerequisites": ["crit_chance"]},
	"burn_dot": {"id": "burn_dot", "name": "Yakıcı Atış", "description": "Vurduğun düşmanlara yanma şansı.", "rarity": "rare", "category": "combat", "prerequisites": ["crit_chance"]},
	"rear_targeting": {"id": "rear_targeting", "name": "Arka Nişan", "description": "İleri ve geri aynı anda ateş eder.", "rarity": "rare", "category": "targeting", "prerequisites": ["weapon_projectile"]},
	"side_sweep": {"id": "side_sweep", "name": "Yan Tarama", "description": "Sol ve sağ yönde ateş eder.", "rarity": "rare", "category": "targeting", "prerequisites": ["weapon_projectile"]},
	"armor": {"id": "armor", "name": "Savunma Değeri", "description": "Alınan hasar +3 azalır.", "rarity": "rare", "category": "defense", "prerequisites": ["life_regen"]},
	"xp_multiplier": {"id": "xp_multiplier", "name": "XP Verimi", "description": "Kazanılan XP +%20 artar.", "rarity": "rare", "category": "utility", "prerequisites": ["xp_magnet"]},
	"unlock_nano": {"id": "unlock_nano", "name": "Nano Swarm", "description": "Hızlı atışlı nano mermiler. Pasif silah.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["cooldown_mastery"]},
	"unlock_tesla": {"id": "unlock_tesla", "name": "Tesla Emitter", "description": "Zincirleme elektrik şimşeği. Pasif silah.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["crit_chance"]},
	"unlock_scatter": {"id": "unlock_scatter", "name": "Scatter Cannon", "description": "Geniş açılı 7 pellet. Pasif silah.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["weapon_projectile"]},
	"unlock_bouncing_projectile": {"id": "unlock_bouncing_projectile", "name": "Sekebilen Mermi", "description": "Hedefler arasında seken mermi tipini açar.", "rarity": "rare", "category": "projectile", "prerequisites": ["weapon_projectile"]},

	# --- Tier 4: Uzmanlık (Maliyet: 4) ---
	"unlock_aoe_projectile": {"id": "unlock_aoe_projectile", "name": "Patlayıcı Mermi", "description": "AOE vuran mermi tipini açar.", "rarity": "epic", "category": "projectile", "prerequisites": ["pierce"]},
	"unlock_beam_projectile": {"id": "unlock_beam_projectile", "name": "Işın Mermi", "description": "Işın şeklinde mermi tipini açar.", "rarity": "epic", "category": "projectile", "prerequisites": ["burn_dot"]},
	"full_spread": {"id": "full_spread", "name": "Tam Yelpaze", "description": "İleri ve ±45° yelpaze ateşi.", "rarity": "epic", "category": "targeting", "prerequisites": ["rear_targeting"]},
	"orbital_fire": {"id": "orbital_fire", "name": "Orbital Ateş", "description": "Spiral pattern ile dairesel ateş.", "rarity": "epic", "category": "targeting", "prerequisites": ["side_sweep"]},
	"shield": {"id": "shield", "name": "Enerji Kalkanı", "description": "30 saniyede bir ölümcül darbeyi engeller.", "rarity": "epic", "category": "defense", "prerequisites": ["armor"]},
	"luck": {"id": "luck", "name": "Şans", "description": "Sandık ve yüksek kalite XP düşme ihtimali artar.", "rarity": "epic", "category": "utility", "prerequisites": ["xp_multiplier"]},
	"unlock_orbital_sentinel": {"id": "unlock_orbital_sentinel", "name": "Orbital Sentinel", "description": "Etrafında dönen enerji küreleri. Pasif silah.", "rarity": "epic", "category": "passive_weapon", "prerequisites": ["cooldown_mastery"]},

	# --- Tier 5: Pasif Güçlendirme & Aktif Silahlar (Maliyet: 5) ---
	"upgrade_nano": {"id": "upgrade_nano", "name": "Nano Güçlendirme", "description": "Nano Swarm hasarını artır.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["unlock_nano"]},
	"upgrade_tesla": {"id": "upgrade_tesla", "name": "Tesla Güçlendirme", "description": "Tesla Emitter hasarını artır.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["unlock_tesla"]},
	"upgrade_scatter": {"id": "upgrade_scatter", "name": "Scatter Güçlendirme", "description": "Scatter Cannon hasarını artır.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["unlock_scatter"]},
	"upgrade_orbital": {"id": "upgrade_orbital", "name": "Orbital Güçlendirme", "description": "Orbital Sentinel hasarını artır.", "rarity": "rare", "category": "passive_weapon", "prerequisites": ["unlock_orbital_sentinel"]},
	"unlock_railgun": {"id": "unlock_railgun", "name": "Railgun", "description": "Railgun silah slotunu aç. [1] ile aktive et.", "rarity": "epic", "category": "active_weapon", "prerequisites": ["pierce"]},
	"unlock_void": {"id": "unlock_void", "name": "Void Launcher", "description": "Void Launcher silah slotunu aç. [2] ile aktive et.", "rarity": "epic", "category": "active_weapon", "prerequisites": ["burn_dot"]},
	"unlock_arc": {"id": "unlock_arc", "name": "Arc Blaster", "description": "Arc Blaster silah slotunu aç. [3] ile aktive et.", "rarity": "epic", "category": "active_weapon", "prerequisites": ["unlock_tesla"]},
	"unlock_phase": {"id": "unlock_phase", "name": "Phase Disruptor", "description": "Phase Disruptor silah slotunu aç. [4] ile aktive et.", "rarity": "epic", "category": "active_weapon", "prerequisites": ["shield"]},
	"unlock_gravity": {"id": "unlock_gravity", "name": "Gravity Pulse", "description": "Gravity Pulse silah slotunu aç. [5] ile aktive et.", "rarity": "legendary", "category": "active_weapon", "prerequisites": ["unlock_orbital_sentinel"]},

	# --- Tier 6: Aktif Silah Güçlendirme (Maliyet: 6) ---
	"upgrade_railgun": {"id": "upgrade_railgun", "name": "Railgun Güçlendirme", "description": "Railgun hasarını artır.", "rarity": "rare", "category": "active_weapon", "prerequisites": ["unlock_railgun"]},
	"upgrade_void": {"id": "upgrade_void", "name": "Void Güçlendirme", "description": "Void Launcher hasarını artır.", "rarity": "rare", "category": "active_weapon", "prerequisites": ["unlock_void"]},
	"upgrade_arc": {"id": "upgrade_arc", "name": "Arc Güçlendirme", "description": "Arc Blaster hasarını artır.", "rarity": "rare", "category": "active_weapon", "prerequisites": ["unlock_arc"]},
	"upgrade_phase": {"id": "upgrade_phase", "name": "Phase Güçlendirme", "description": "Phase Disruptor hasarını artır.", "rarity": "rare", "category": "active_weapon", "prerequisites": ["unlock_phase"]},
	"upgrade_gravity": {"id": "upgrade_gravity", "name": "Gravity Güçlendirme", "description": "Gravity Pulse hasarını artır.", "rarity": "rare", "category": "active_weapon", "prerequisites": ["unlock_gravity"]},
}

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
@onready var game_over_label: Label = $HUD/GameOverLabel


func _ready() -> void:
	get_tree().paused = false
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
	player.perk_charges_changed.connect(hud.update_perk_charges)
	player.bomb_triggered.connect(_on_player_bomb_triggered)
	hud.menu_requested.connect(_on_menu_requested)
	hud.perk_tree_requested.connect(_on_perk_tree_requested)
	hud.projectile_switch_requested.connect(_on_projectile_switch_requested)
	player.weapons_changed.connect(_on_weapons_changed)
	player.targeting_changed.connect(_on_targeting_changed)
	player.projectile_class_changed.connect(_on_projectile_class_changed)

	hud.update_health(player.health, player.max_health)
	hud.update_xp(0, player.xp_to_next_level)
	hud.update_level(1)
	hud.update_kills(0)
	hud.update_perk_charges(player.bomb_charges, player.heal_charges)
	game_over_label.visible = false
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
	# Refresh weapon display every 0.1s (smooth countdown for temp weapons)
	weapon_display_timer -= delta
	if weapon_display_timer <= 0.0:
		weapon_display_timer = 0.1
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
	var progress_ratio: float = _compute_difficulty_progress()
	var elite_chance: float = _compute_elite_chance()
	var is_elite: bool = randf() <= elite_chance
	var health_growth: float = float(ConfigService.get_value("difficulty.enemy_health_growth", 0.09))
	var speed_growth: float = float(ConfigService.get_value("difficulty.enemy_speed_growth", 0.03))
	var damage_growth: float = float(ConfigService.get_value("difficulty.enemy_damage_growth", 0.05))
	enemy.physical_resistance = clampf(progress_ratio * float(ConfigService.get_value("difficulty.physical_resist_growth", 0.02)), 0.0, 0.65)
	enemy.explosive_resistance = clampf(progress_ratio * float(ConfigService.get_value("difficulty.explosive_resist_growth", 0.01)), 0.0, 0.5)
	if enemy.has_method("apply_scaling"):
		enemy.apply_scaling(progress_ratio, is_elite, health_growth, speed_growth, damage_growth)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)


func _on_enemy_died(pos: Vector2) -> void:
	kill_count += 1
	hud.update_kills(kill_count)
	_try_spawn_chest(pos)
	_spawn_xp_gem(pos)
	MockApiClient.queue_event("enemy_killed", {"kills": kill_count})
	_persist_run_state()
	# Gradually increase difficulty
	var step_kills: int = int(ConfigService.get_value("difficulty.step_kills", 8))
	if kill_count % max(step_kills, 1) == 0:
		var interval_step: float = float(ConfigService.get_value("difficulty.spawn_interval_step", 0.08))
		var min_interval: float = float(ConfigService.get_value("difficulty.min_spawn_interval", 0.28))
		spawn_timer.wait_time = max(min_interval, spawn_timer.wait_time - interval_step)


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
	game_over_label.visible = true
	_persist_run_state()
	Session.finalize_run()
	MockApiClient.queue_event("run_finished", {"kills": kill_count, "level": player.level})
	get_tree().paused = true


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
		get_tree().paused = false


func _on_player_level_changed(new_level: int) -> void:
	if applying_start_state:
		return
	MockApiClient.queue_event("level_up", {"level": new_level})
	perk_points += 1
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


func _on_player_bomb_triggered(damage: int) -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, "explosive")
	if player and player.has_method("camera_shake"):
		player.camera_shake(10.0)
	MockApiClient.queue_event("bomb_used", {"affected_enemies": enemies.size()})


func _compute_difficulty_progress() -> float:
	var per_kill_growth: float = float(ConfigService.get_value("difficulty.enemy_health_growth", 0.09))
	return (float(kill_count) / 30.0) * per_kill_growth + (elapsed_seconds / 300.0)


func _compute_elite_chance() -> float:
	var base: float = float(ConfigService.get_value("difficulty.elite_chance_base", 0.03))
	var per_minute: float = float(ConfigService.get_value("difficulty.elite_chance_per_minute", 0.015))
	var max_chance: float = float(ConfigService.get_value("difficulty.max_elite_chance", 0.2))
	var minutes: float = elapsed_seconds / 60.0
	return clampf(base + (minutes * per_minute), base, max_chance)


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

	var chest: Node2D = chest_scene.instantiate()
	chest.global_position = pos
	chest.opened.connect(_on_chest_opened)
	add_child(chest)


func _on_chest_opened(_pos: Vector2) -> void:
	if game_over or not player:
		return
	var reward: String = _roll_chest_reward()
	match reward:
		"heal":
			var heal_amount: int = int(float(player.max_health) * 0.3)
			player.health = mini(player.health + heal_amount, player.max_health)
			player.health_changed.emit(player.health, player.max_health)
			hud.show_notification("❤ +%d Can!" % heal_amount)
		"shield":
			player.has_shield = true
			player._shield_active = true
			hud.show_notification("🛡 Kalkan Aktif!")
		"magnet":
			player.magnet_collect_all()
			hud.show_notification("🧲 Mıknatıs!")
		"bomb":
			player.bomb_charges += 1
			player.perk_charges_changed.emit(player.bomb_charges, player.heal_charges)
			hud.show_notification("💣 +1 Bomba!")
		"perk_points":
			var amount: int = _roll_perk_point_amount()
			perk_points += amount
			hud.show_notification("⭐ +%d Perk Puanı!" % amount)
	_persist_run_state()
	MockApiClient.queue_event("chest_opened", {"reward": reward, "kills": kill_count})


func _roll_chest_reward() -> String:
	var roll: int = randi_range(1, 100)
	if roll <= 25:
		return "heal"
	elif roll <= 35:
		return "shield"
	elif roll <= 55:
		return "magnet"
	elif roll <= 75:
		return "bomb"
	else:
		return "perk_points"


func _roll_perk_point_amount() -> int:
	var roll: int = randi_range(1, 100)
	if roll <= 60:
		return 1
	elif roll <= 90:
		return 2
	else:
		return 3


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
