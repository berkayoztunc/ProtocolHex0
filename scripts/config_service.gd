extends Node

const CONFIG_PATH := "user://game_config.json"

var config: Dictionary = {
	"difficulty": {
		"base_spawn_interval": 1.7,
		"min_spawn_interval": 0.42,
		"spawn_interval_step": 0.07,
		"step_kills": 10,
		"spawn_distance_min": 460.0,
		"spawn_distance_max": 700.0,
		"enemy_health_growth": 0.09,
		"enemy_speed_growth": 0.03,
		"enemy_damage_growth": 0.05,
		"elite_chance_base": 0.03,
		"elite_chance_per_minute": 0.015,
		"max_elite_chance": 0.2,
		"physical_resist_growth": 0.02,
		"explosive_resist_growth": 0.01
	},
	"xp": {
		"base_xp": 10,
		"linear_step": 4,
		"quadratic_step": 1,
		"small_weight": 65,
		"medium_weight": 25,
		"large_weight": 10,
		"medium_unlock_kills": 20,
		"large_unlock_kills": 45
	},
	"chest": {
		"drop_every_kills": 15,
		"random_drop_chance": 0.08,
		"max_chests_alive": 2
	},
	"weapons": {
		"base_damage": 10,
		"base_cooldown": 0.5,
		"base_projectiles": 1,
		"spread_degrees": 14.0,
		"damage_upgrade_step": 3,
		"projectile_upgrade_step": 1,
		"min_cooldown": 0.12,
		"definitions": {
			"plasma_rifle": {
				"name": "Plasma Rifle",
				"description": "Temel plazma silahı. Tek hedefe hassas atış.",
				"is_passive": true,
				"is_held": true,
				"base_damage": 10,
				"speed": 400.0,
				"cooldown": 0.5,
				"lifetime": 3.0,
				"damage_type": "plasma",
				"projectile_count": 1,
				"color": [0.3, 0.8, 1.0],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "nearest",
				"upgrade_damage_step": 3,
				"upgrade_speed_step": 0.04
			},
			"nano_swarm": {
				"name": "Nano Swarm",
				"description": "Hızlı atışlı küçük nano mermiler. Zayıf ama çok sayıda.",
				"is_passive": true,
				"base_damage": 4,
				"speed": 500.0,
				"cooldown": 0.18,
				"lifetime": 1.5,
				"damage_type": "physical",
				"projectile_count": 3,
				"spread_degrees": 22.0,
				"color": [0.0, 1.0, 0.5],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "nearest",
				"upgrade_damage_step": 2,
				"upgrade_speed_step": 0.02
			},
			"tesla_emitter": {
				"name": "Tesla Emitter",
				"description": "Elektrik şimşeği düşmandan düşmana atlar.",
				"is_passive": true,
				"base_damage": 8,
				"speed": 350.0,
				"cooldown": 0.7,
				"lifetime": 2.0,
				"damage_type": "electric",
				"projectile_count": 1,
				"color": [0.6, 0.8, 1.0],
				"pierce": 0,
				"chain": 3,
				"chain_range": 150.0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "cluster",
				"upgrade_damage_step": 3,
				"upgrade_speed_step": 0.05
			},
			"scatter_cannon": {
				"name": "Scatter Cannon",
				"description": "Geniş açılı 7 pellet atar. Kısa menzil, büyük hasar.",
				"is_passive": true,
				"base_damage": 6,
				"speed": 280.0,
				"cooldown": 0.9,
				"lifetime": 0.8,
				"damage_type": "physical",
				"projectile_count": 7,
				"spread_degrees": 55.0,
				"color": [1.0, 0.6, 0.2],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "closest",
				"upgrade_damage_step": 2,
				"upgrade_speed_step": 0.06
			},
			"orbital_sentinel": {
				"name": "Orbital Sentinel",
				"description": "Etrafında dönen 3 enerji küresi. Yaklaşanları yakar.",
				"is_passive": true,
				"base_damage": 12,
				"speed": 0.0,
				"cooldown": 3.0,
				"lifetime": 4.0,
				"damage_type": "energy",
				"projectile_count": 3,
				"color": [1.0, 0.9, 0.3],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": true,
				"orbit_radius": 55.0,
				"orbit_speed": 3.0,
				"targeting_pref": "none",
				"upgrade_damage_step": 4,
				"upgrade_speed_step": 0.0
			},
			"railgun": {
				"name": "Railgun",
				"description": "Güçlü piercing atış. Tüm düşmanlardan geçer.",
				"is_passive": false,
				"is_held": true,
				"slot_key": 1,
				"active_duration_sec": 15.0,
				"active_cooldown_sec": 60.0,
				"base_damage": 45,
				"speed": 800.0,
				"cooldown": 3.0,
				"lifetime": 2.0,
				"damage_type": "kinetic",
				"projectile_count": 1,
				"color": [1.0, 0.2, 0.2],
				"pierce": 99,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "line",
				"upgrade_damage_step": 12,
				"upgrade_speed_step": 0.15
			},
			"void_launcher": {
				"name": "Void Launcher",
				"description": "Karanlık enerji topu. Patlayarak alan hasarı verir.",
				"is_passive": false,
				"is_held": true,
				"slot_key": 2,
				"active_duration_sec": 12.0,
				"active_cooldown_sec": 55.0,
				"base_damage": 25,
				"speed": 250.0,
				"cooldown": 2.5,
				"lifetime": 2.5,
				"damage_type": "explosive",
				"projectile_count": 1,
				"color": [0.5, 0.0, 0.8],
				"pierce": 0,
				"chain": 0,
				"is_aoe": true,
				"aoe_radius": 90.0,
				"aoe_damage_ratio": 0.6,
				"is_orbit": false,
				"targeting_pref": "cluster",
				"upgrade_damage_step": 8,
				"upgrade_speed_step": 0.12
			},
			"arc_blaster": {
				"name": "Arc Blaster",
				"description": "5 yönde elektrik arkı atar.",
				"is_passive": false,
				"is_held": true,
				"slot_key": 3,
				"active_duration_sec": 18.0,
				"active_cooldown_sec": 65.0,
				"base_damage": 15,
				"speed": 350.0,
				"cooldown": 2.0,
				"lifetime": 1.5,
				"damage_type": "electric",
				"projectile_count": 5,
				"spread_degrees": 360.0,
				"color": [0.4, 0.7, 1.0],
				"pierce": 0,
				"chain": 1,
				"chain_range": 120.0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "radial",
				"upgrade_damage_step": 5,
				"upgrade_speed_step": 0.1
			},
			"phase_disruptor": {
				"name": "Phase Disruptor",
				"description": "Faz dalgası ile ekrandaki tüm düşmanlara hasar verir.",
				"is_passive": false,
				"is_held": true,
				"slot_key": 4,
				"active_duration_sec": 10.0,
				"active_cooldown_sec": 50.0,
				"base_damage": 20,
				"speed": 0.0,
				"cooldown": 5.0,
				"lifetime": 0.1,
				"damage_type": "void",
				"projectile_count": 0,
				"color": [0.8, 0.3, 1.0],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"is_wave": true,
				"targeting_pref": "none",
				"upgrade_damage_step": 6,
				"upgrade_speed_step": 0.25
			},
			"gravity_pulse": {
				"name": "Gravity Pulse",
				"description": "Yerçekimi dalgası ile düşmanları iter ve hasar verir.",
				"is_passive": false,
				"is_held": true,
				"slot_key": 5,
				"active_duration_sec": 12.0,
				"active_cooldown_sec": 55.0,
				"base_damage": 18,
				"speed": 0.0,
				"cooldown": 4.0,
				"lifetime": 0.1,
				"damage_type": "kinetic",
				"projectile_count": 0,
				"color": [0.2, 0.4, 0.8],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"is_gravity": true,
				"gravity_radius": 200.0,
				"gravity_force": 300.0,
				"targeting_pref": "none",
				"upgrade_damage_step": 5,
				"upgrade_speed_step": 0.2
			},

		},
		"targeting_modes": {
			"forward": {
				"name": "Forward",
				"description": "En yakın düşmana ateş eder.",
				"type": "nearest"
			},
			"rear_guard": {
				"name": "Rear Guard",
				"description": "İleri ve geri yönde aynı anda ateş eder.",
				"type": "dual",
				"angle_offsets": [0.0, 180.0]
			},
			"side_sweep": {
				"name": "Side Sweep",
				"description": "Sol ve sağ yönde ateş eder.",
				"type": "dual",
				"angle_offsets": [90.0, -90.0]
			},
			"full_spread": {
				"name": "Full Spread",
				"description": "İleri ve ±45° yelpaze ateşi.",
				"type": "fan",
				"angle_offsets": [0.0, 45.0, -45.0]
			},
			"orbital_fire": {
				"name": "Orbital Fire",
				"description": "Dairesel spiral pattern ile ateş eder.",
				"type": "spiral"
			}
		}
	},
	"visual": {
		"sprite_scale": {
			"hero": 2.0,
			"enemy": 1.82,
			"pickup": 1.65,
			"chest": 1.82,
			"projectile": 1.85,
			"projectile_orbit": 1.2,
			"vfx_hit": 1.0,
			"vfx_ring_start": 0.18,
			"menu_preview": 4.5
		},
		"target_px": {
			"hero": 112.0,
			"enemy": 56.0,
			"pickup": 32.0,
			"chest": 64.0,
			"projectile": 48.0,
			"projectile_orbit": 30.0,
			"menu_preview": 320.0
		},
		"hud": {
			"icon_size": 30,
			"label_icon_size": 22,
			"weapon_icon_size": 24,
			"health_bar_width": 448,
			"health_bar_height": 36,
			"xp_bar_width": 448,
			"xp_bar_height": 36,
			"button_min_height": 56
		}
	},
	"upgrades": {
		"perk_costs": {
			"attack_speed": 1,
			"weapon_damage": 1,
			"move_speed": 1,
			"max_health": 1,
			"crit_chance": 2,
			"cooldown_mastery": 2,
			"weapon_projectile": 2,
			"life_regen": 2,
			"dash": 2,
			"xp_magnet": 2,
			"pierce": 3,
			"burn_dot": 3,
			"rear_targeting": 3,
			"side_sweep": 3,
			"armor": 3,
			"xp_multiplier": 3,
			"unlock_nano": 3,
			"unlock_tesla": 3,
			"unlock_scatter": 3,
			"unlock_bouncing_projectile": 3,
			"unlock_aoe_projectile": 4,
			"unlock_beam_projectile": 4,
			"full_spread": 4,
			"orbital_fire": 4,
			"shield": 4,
			"luck": 4,
			"unlock_orbital_sentinel": 4,
			"upgrade_nano": 5,
			"upgrade_tesla": 5,
			"upgrade_scatter": 5,
			"upgrade_orbital": 5,
			"unlock_railgun": 5,
			"unlock_void": 5,
			"unlock_arc": 5,
			"unlock_phase": 5,
			"unlock_gravity": 5,
			"upgrade_railgun": 6,
			"upgrade_void": 6,
			"upgrade_arc": 6,
			"upgrade_phase": 6,
			"upgrade_gravity": 6,
		},
		"max_stacks": {
			"attack_speed": 8,
			"weapon_damage": 10,
			"weapon_projectile": 5,
			"move_speed": 7,
			"max_health": 8,
			"crit_chance": 5,
			"pierce": 3,
			"burn_dot": 4,
			"cooldown_mastery": 5,
			"rear_targeting": 1,
			"side_sweep": 1,
			"full_spread": 1,
			"orbital_fire": 1,
			"unlock_aoe_projectile": 1,
			"unlock_bouncing_projectile": 1,
			"unlock_beam_projectile": 1,
			"unlock_nano": 1,
			"upgrade_nano": 3,
			"unlock_tesla": 1,
			"upgrade_tesla": 3,
			"unlock_scatter": 1,
			"upgrade_scatter": 3,
			"unlock_orbital_sentinel": 1,
			"upgrade_orbital": 3,
			"unlock_railgun": 1,
			"upgrade_railgun": 3,
			"unlock_void": 1,
			"upgrade_void": 3,
			"unlock_arc": 1,
			"upgrade_arc": 3,
			"unlock_gravity": 1,
			"upgrade_gravity": 3,
			"unlock_phase": 1,
			"upgrade_phase": 3,
			"life_regen": 5,
			"armor": 5,
			"shield": 1,
			"xp_magnet": 5,
			"dash": 3,
			"xp_multiplier": 5,
			"luck": 4,
		}
	}
}


func _ready() -> void:
	_load_external_config()


func get_value(path: String, fallback: Variant = null) -> Variant:
	var keys: PackedStringArray = path.split(".")
	var current: Variant = config
	for key in keys:
		if typeof(current) != TYPE_DICTIONARY or not current.has(key):
			return fallback
		current = current[key]
	return current


func _load_external_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict: Dictionary = parsed
	_deep_merge(config, parsed_dict)


func _deep_merge(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
			_deep_merge(target[key], source[key])
		else:
			target[key] = source[key]
