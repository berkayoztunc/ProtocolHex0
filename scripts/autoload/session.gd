extends Node

const PROFILE_PATH := "user://player_profile.json"

var player_name: String = "Hero"
var pending_continue: bool = false
var current_run: Dictionary = {}
var last_run: Dictionary = {}


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
	last_run = current_run.duplicate(true)
	save_profile()


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


func save_profile() -> void:
	var payload: Dictionary = {
		"player_name": player_name,
		"last_run": last_run
	}
	var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))


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
