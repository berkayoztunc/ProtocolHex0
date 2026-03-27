extends Node

const PROFILE_PATH := "user://player_profile.json"

var player_name: String = "Hero"
var pending_continue: bool = false
var current_run: Dictionary = {}
var last_run: Dictionary = {}

# ── Persistent profile data (independent of run) ──────────────
var current_zone_id: String = "zone_1"
var inventory: Dictionary = {"scrap": 0, "battery": 0, "nanochips": 0}  # Permanent — spent on base perk upgrades
var bag: Dictionary = {"scrap": 0, "battery": 0, "nanochips": 0}  # Current-run pickup bag — resets each run
var vault: Dictionary = {}  # Permanent zone-item storage (nano_cores, energy_cells, etc.)
var bag_capacity: int = 20
var base_perk_levels: Dictionary = {}
var completed_zones: Array[String] = []


func _ready() -> void:
	load_profile()


func has_saved_profile() -> bool:
	return FileAccess.file_exists(PROFILE_PATH)


func has_last_run() -> bool:
	return not last_run.is_empty()


func start_new_run(name: String) -> void:
	player_name = name.strip_edges()
	if player_name.is_empty():
		player_name = "Hero"
	pending_continue = false
	current_run = _new_run_template()
	bag = {"scrap": 0, "battery": 0, "nanochips": 0}  # Reset run bag on every new run
	save_profile()


func start_continue_run() -> void:
	pending_continue = has_last_run()
	if pending_continue:
		current_run = last_run.duplicate(true)


func record_run_state(run_state: Dictionary, kills: int) -> void:
	if current_run.is_empty():
		current_run = _new_run_template()
	for key in run_state.keys():
		current_run[key] = run_state[key]
	current_run["kills"] = kills


func finalize_run() -> void:
	if current_run.is_empty():
		return
	_flush_bag_to_inventory()
	last_run = current_run.duplicate(true)
	save_profile()

func _flush_bag_to_inventory() -> void:
	## Transfer everything in the run bag into permanent inventory, then clear the bag.
	for resource_type in bag.keys():
		if not inventory.has(resource_type):
			inventory[resource_type] = 0
		inventory[resource_type] = int(inventory[resource_type]) + int(bag[resource_type])
	bag = {"scrap": 0, "battery": 0, "nanochips": 0}


func load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict: Dictionary = parsed
	player_name = str(parsed_dict.get("player_name", "Hero"))
	var parsed_last_run: Variant = parsed_dict.get("last_run", {})
	if typeof(parsed_last_run) == TYPE_DICTIONARY:
		last_run = parsed_last_run as Dictionary
	current_zone_id = str(parsed_dict.get("current_zone_id", "zone_1"))
	var parsed_inv: Variant = parsed_dict.get("inventory", {})
	if typeof(parsed_inv) == TYPE_DICTIONARY:
		inventory = (parsed_inv as Dictionary).duplicate(true)
		for key in ["scrap", "battery", "nanochips"]:
			if not inventory.has(key):
				inventory[key] = 0
	var parsed_bpl: Variant = parsed_dict.get("base_perk_levels", {})
	if typeof(parsed_bpl) == TYPE_DICTIONARY:
		base_perk_levels = (parsed_bpl as Dictionary).duplicate(true)
	bag_capacity = int(parsed_dict.get("bag_capacity", 20))
	var parsed_cz: Variant = parsed_dict.get("completed_zones", [])
	if typeof(parsed_cz) == TYPE_ARRAY:
		completed_zones.clear()
		for zone_id in (parsed_cz as Array):
			completed_zones.append(str(zone_id))
	var parsed_vault: Variant = parsed_dict.get("vault", {})
	if typeof(parsed_vault) == TYPE_DICTIONARY:
		vault = (parsed_vault as Dictionary).duplicate(true)
	var parsed_bag: Variant = parsed_dict.get("bag", {})
	if typeof(parsed_bag) == TYPE_DICTIONARY:
		bag = (parsed_bag as Dictionary).duplicate(true)
		for key in ["scrap", "battery", "nanochips"]:
			if not bag.has(key):
				bag[key] = 0


func save_profile() -> void:
	var payload: Dictionary = {
		"player_name": player_name,
		"last_run": last_run,
		"current_zone_id": current_zone_id,
		"inventory": inventory,
		"bag": bag,
		"vault": vault,
		"base_perk_levels": base_perk_levels,
		"bag_capacity": bag_capacity,
		"completed_zones": completed_zones
	}
	var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))


# ── Zone / Meta-resource / Base Perk API ────────────────────

func set_current_zone(zone_id: String) -> void:
	current_zone_id = zone_id
	save_profile()


func complete_zone(zone_id: String) -> void:
	if zone_id not in completed_zones:
		completed_zones.append(zone_id)
		save_profile()


func is_zone_completed(zone_id: String) -> bool:
	return zone_id in completed_zones


func can_pick_up(amount: int = 1) -> bool:
	## Returns true if adding `amount` meta-resources would not exceed bag_capacity.
	var total: int = 0
	for key in bag.keys():
		total += int(bag[key])
	return total + amount <= bag_capacity


func add_to_inventory(resource_type: String, amount: int = 1) -> bool:
	## Adds to the current-run bag. Returns false if bag is full.
	if not can_pick_up(amount):
		return false
	if not bag.has(resource_type):
		bag[resource_type] = 0
	bag[resource_type] = int(bag[resource_type]) + amount
	save_profile()
	return true


func get_inventory_count(resource_type: String) -> int:
	## Returns permanent (post-flush) inventory. Used by base perk upgrade screen.
	return int(inventory.get(resource_type, 0))


func get_bag_count(resource_type: String) -> int:
	## Returns items currently in the run bag. Used by the HUD during gameplay.
	return int(bag.get(resource_type, 0))


# ── Vault API (zone-item permanent storage) ─────────────────

func add_to_vault(item_id: String, amount: int) -> void:
	## Permanently adds zone items to the vault. No capacity limit.
	if not vault.has(item_id):
		vault[item_id] = 0
	vault[item_id] = int(vault[item_id]) + amount
	save_profile()


func get_vault_count(item_id: String) -> int:
	return int(vault.get(item_id, 0))


func upgrade_base_perk(perk_id: String) -> bool:
	var current_level: int = int(base_perk_levels.get(perk_id, 0))
	var costs: Variant = ConfigService.get_value("base_perk_upgrade_costs.%s" % perk_id, null)
	if costs == null or typeof(costs) != TYPE_ARRAY:
		return false
	var costs_array: Array = costs as Array
	if current_level >= costs_array.size():
		return false
	var cost: Dictionary = costs_array[current_level] as Dictionary
	for resource in cost:
		if get_inventory_count(resource) < int(cost[resource]):
			return false
	for resource in cost:
		inventory[resource] = int(inventory.get(resource, 0)) - int(cost[resource])
	base_perk_levels[perk_id] = current_level + 1
	save_profile()
	return true


func get_base_perk_level(perk_id: String) -> int:
	return int(base_perk_levels.get(perk_id, 0))


func get_base_perk_upgrade_cost(perk_id: String) -> Dictionary:
	var current_level: int = int(base_perk_levels.get(perk_id, 0))
	var costs: Variant = ConfigService.get_value("base_perk_upgrade_costs.%s" % perk_id, null)
	if costs == null or typeof(costs) != TYPE_ARRAY:
		return {}
	var costs_array: Array = costs as Array
	if current_level >= costs_array.size():
		return {}
	return (costs_array[current_level] as Dictionary).duplicate()


func is_base_perk_max_level(perk_id: String) -> bool:
	var current_level: int = int(base_perk_levels.get(perk_id, 0))
	var costs: Variant = ConfigService.get_value("base_perk_upgrade_costs.%s" % perk_id, null)
	if costs == null or typeof(costs) != TYPE_ARRAY:
		return true
	return current_level >= (costs as Array).size()


func _new_run_template() -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"xp_needed": 10,
		"health": 100,
		"max_health": 100,
		"bomb_charges": 0,
		"heal_charges": 0,
		"weapon_damage": 10,
		"weapon_projectile_count": 1,
		"shoot_cooldown": 0.5,
		"kills": 0,
		"crit_chance": 0.0,
		"pierce_count": 0,
		"armor": 0,
		"life_regen": 0.0,
		"dash_charges": 0,
		"xp_multiplier": 1.0,
		"luck": 0.0,
		"cooldown_multiplier": 1.0,
		"has_shield": false,
		"targeting_mode": "forward",
		"unlocked_targeting_modes": ["forward"],
		"unlocked_passive_weapons": [],
		"weapon_upgrade_levels": {},
		"perk_points": 100,
		# Phase 4: Weapon mastery kill counts per weapon
		"weapon_mastery_counts": {},
		# Elemental status effect accumulators
		"burn_chance": 0.0,
		"chill_chance": 0.0,
		"volt_chain_count": 0,
		"void_energy": 0.0,
		"nano_heal_pct": 0.0,
		"chrono_slow_pct": 0.0,
		# Upgrade stacks persisted
		"upgrade_stacks": {},
	}
