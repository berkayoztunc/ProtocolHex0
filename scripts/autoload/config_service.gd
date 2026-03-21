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
	"enemies": {
		"spawn_unlock_mode": "hybrid_or",
		"archetypes": {
			"runner": {
				"display_name": "Runner",
				"unlock_kills": 0,
				"unlock_seconds": 0,
				"spawn_weight": 1.2,
				"base_health": 16,
				"base_speed": 120.0,
				"base_damage": 8,
				"physical_resistance": 0.0,
				"explosive_resistance": 0.0,
				"sprite_path": "res://assets/enemies/enemy_runner.png",
				"char_base_path": "res://assets/characters/enemy_runner",
				"behavior": "runner",
				"is_ranged": false,
				"fire_profile_id": ""
			},
			"brute": {
				"display_name": "Brute",
				"unlock_kills": 8,
				"unlock_seconds": 45,
				"spawn_weight": 0.9,
				"base_health": 34,
				"base_speed": 76.0,
				"base_damage": 14,
				"physical_resistance": 0.06,
				"explosive_resistance": 0.0,
				"sprite_path": "res://assets/enemies/enemy_brute.png",
				"char_base_path": "res://assets/characters/enemy_brute",
				"behavior": "tank",
				"is_ranged": false,
				"fire_profile_id": ""
			},
			"charger": {
				"display_name": "Charger",
				"unlock_kills": 16,
				"unlock_seconds": 90,
				"spawn_weight": 0.85,
				"base_health": 24,
				"base_speed": 102.0,
				"base_damage": 16,
				"physical_resistance": 0.02,
				"explosive_resistance": 0.0,
				"sprite_path": "res://assets/enemies/enemy_charger.png",
				"char_base_path": "res://assets/characters/enemy_charger",
				"behavior": "charger",
				"is_ranged": false,
				"fire_profile_id": ""
			},
			"zigzag": {
				"display_name": "Zigzag",
				"unlock_kills": 24,
				"unlock_seconds": 130,
				"spawn_weight": 0.8,
				"base_health": 22,
				"base_speed": 110.0,
				"base_damage": 11,
				"physical_resistance": 0.0,
				"explosive_resistance": 0.03,
				"sprite_path": "res://assets/enemies/enemy_zigzag.png",
				"char_base_path": "res://assets/characters/enemy_zigzag",
				"behavior": "zigzag",
				"is_ranged": false,
				"fire_profile_id": ""
			},
			"shielded": {
				"display_name": "Shielded",
				"unlock_kills": 34,
				"unlock_seconds": 175,
				"spawn_weight": 0.75,
				"base_health": 30,
				"base_speed": 84.0,
				"base_damage": 12,
				"physical_resistance": 0.14,
				"explosive_resistance": 0.08,
				"sprite_path": "res://assets/enemies/enemy_shielded.png",
				"char_base_path": "res://assets/characters/enemy_shielded",
				"behavior": "shielded",
				"is_ranged": false,
				"fire_profile_id": ""
			},
			"skirmisher": {
				"display_name": "Skirmisher",
				"unlock_kills": 42,
				"unlock_seconds": 215,
				"spawn_weight": 0.72,
				"base_health": 20,
				"base_speed": 98.0,
				"base_damage": 10,
				"physical_resistance": 0.01,
				"explosive_resistance": 0.03,
				"sprite_path": "res://assets/enemies/enemy_skirmisher.png",
				"char_base_path": "res://assets/characters/enemy_skirmisher",
				"behavior": "skirmisher",
				"is_ranged": true,
				"fire_profile_id": "skirmisher_shot"
			},
			"sniper": {
				"display_name": "Sniper",
				"unlock_kills": 52,
				"unlock_seconds": 260,
				"spawn_weight": 0.62,
				"base_health": 18,
				"base_speed": 88.0,
				"base_damage": 18,
				"physical_resistance": 0.0,
				"explosive_resistance": 0.0,
				"sprite_path": "res://assets/enemies/enemy_sniper.png",
				"char_base_path": "res://assets/characters/enemy_sniper",
				"behavior": "sniper",
				"is_ranged": true,
				"fire_profile_id": "sniper_shot"
			},
			"mortar": {
				"display_name": "Mortar",
				"unlock_kills": 64,
				"unlock_seconds": 315,
				"spawn_weight": 0.56,
				"base_health": 26,
				"base_speed": 74.0,
				"base_damage": 20,
				"physical_resistance": 0.04,
				"explosive_resistance": 0.1,
				"sprite_path": "res://assets/enemies/enemy_mortar.png",
				"char_base_path": "res://assets/characters/enemy_mortar",
				"behavior": "mortar",
				"is_ranged": true,
				"fire_profile_id": "mortar_orb"
			},
			"suppressor": {
				"display_name": "Suppressor",
				"unlock_kills": 76,
				"unlock_seconds": 370,
				"spawn_weight": 0.5,
				"base_health": 24,
				"base_speed": 90.0,
				"base_damage": 13,
				"physical_resistance": 0.06,
				"explosive_resistance": 0.02,
				"sprite_path": "res://assets/enemies/enemy_suppressor.png",
				"char_base_path": "res://assets/characters/enemy_suppressor",
				"behavior": "suppressor",
				"is_ranged": true,
				"fire_profile_id": "suppressor_burst"
			},
			"juggernaut": {
				"display_name": "Juggernaut",
				"unlock_kills": 90,
				"unlock_seconds": 430,
				"spawn_weight": 0.42,
				"base_health": 46,
				"base_speed": 66.0,
				"base_damage": 22,
				"physical_resistance": 0.18,
				"explosive_resistance": 0.12,
				"sprite_path": "res://assets/enemies/enemy_juggernaut.png",
				"char_base_path": "res://assets/characters/enemy_juggernaut",
				"behavior": "juggernaut",
				"is_ranged": false,
				"fire_profile_id": ""
			}
		},
		"fire_profiles": {
			"skirmisher_shot": {
				"projectile_scene": "standard",
				"cooldown": 1.4,
				"range": 280.0,
				"bullet_speed": 250.0,
				"bullet_lifetime": 1.5,
				"damage_ratio": 0.75,
				"damage_type": "physical",
				"color": [0.95, 0.85, 0.35],
				"projectile_name": "scatter_pellet"
			},
			"sniper_shot": {
				"projectile_scene": "standard",
				"cooldown": 2.2,
				"range": 420.0,
				"bullet_speed": 520.0,
				"bullet_lifetime": 1.4,
				"damage_ratio": 1.1,
				"damage_type": "kinetic",
				"color": [1.0, 0.4, 0.35],
				"projectile_name": "railgun"
			},
			"mortar_orb": {
				"projectile_scene": "aoe",
				"cooldown": 2.8,
				"range": 340.0,
				"bullet_speed": 220.0,
				"bullet_lifetime": 1.9,
				"damage_ratio": 0.95,
				"damage_type": "explosive",
				"is_aoe": true,
				"aoe_radius": 65.0,
				"aoe_damage_ratio": 0.7,
				"color": [0.95, 0.45, 0.95],
				"projectile_name": "void_launcher"
			},
			"suppressor_burst": {
				"projectile_scene": "standard",
				"cooldown": 0.95,
				"range": 300.0,
				"bullet_speed": 330.0,
				"bullet_lifetime": 1.5,
				"damage_ratio": 0.62,
				"damage_type": "physical",
				"color": [0.45, 0.8, 1.0],
				"projectile_name": "plasma_rifle"
			}
		}
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
			"railgun": {
				"name": "Rail Gun",
				"description": "100 kirmizi delici isin mermisi burst atar, ~5 sn. [Aktif Skill]",
				"is_passive": false,
				"slot_key": 0,
				"active_duration_sec": 5.0,
				"active_cooldown_sec": 25.0,
				"base_damage": 25,
				"speed": 1200.0,
				"cooldown": 0.05,
				"lifetime": 1.5,
				"damage_type": "kinetic",
				"projectile_count": 1,
				"color": [1.0, 0.2, 0.1],
				"pierce": 99,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "nearest",
				"upgrade_damage_step": 8,
				"upgrade_speed_step": 0.1
			},
			"rocket_blaster": {
				"name": "Roket Blaster",
				"description": "En yakin 5 hedefe homing roket, patlar. [Aktif Skill]",
				"is_passive": false,
				"is_burst_then_done": true,
				"slot_key": 0,
				"active_duration_sec": 3.0,
				"active_cooldown_sec": 35.0,
				"base_damage": 80,
				"speed": 300.0,
				"cooldown": 0.3,
				"lifetime": 5.0,
				"damage_type": "explosive",
				"projectile_count": 5,
				"color": [1.0, 0.5, 0.1],
				"pierce": 0,
				"chain": 0,
				"is_aoe": true,
				"aoe_radius": 120.0,
				"aoe_damage_ratio": 0.6,
				"is_orbit": false,
				"targeting_pref": "multi_nearest",
				"upgrade_damage_step": 20,
				"upgrade_speed_step": 0.0
			},
			"octo_gun": {
				"name": "Octo Gun",
				"description": "En yakin 6 hedefe ayni anda 20 sn boyunca ates eder. [Aktif Skill]",
				"is_passive": false,
				"slot_key": 0,
				"active_duration_sec": 20.0,
				"active_cooldown_sec": 45.0,
				"base_damage": 18,
				"speed": 500.0,
				"cooldown": 0.4,
				"lifetime": 1.5,
				"damage_type": "physical",
				"projectile_count": 6,
				"color": [0.8, 1.0, 0.3],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "multi_nearest",
				"upgrade_damage_step": 5,
				"upgrade_speed_step": 0.05
			},
			"arc_blaster": {
				"name": "Arc Blaster",
				"description": "En yakin hedefe 8 mermi x 3 tur geri iter. [Aktif Skill]",
				"is_passive": false,
				"slot_key": 0,
				"active_duration_sec": 6.0,
				"active_cooldown_sec": 30.0,
				"base_damage": 20,
				"speed": 450.0,
				"cooldown": 0.1,
				"lifetime": 1.5,
				"damage_type": "electric",
				"projectile_count": 8,
				"burst_count": 3,
				"burst_interval": 1.5,
				"knockback_force": 300.0,
				"color": [0.4, 0.7, 1.0],
				"pierce": 0,
				"chain": 0,
				"is_aoe": false,
				"is_orbit": false,
				"targeting_pref": "nearest",
				"upgrade_damage_step": 8,
				"upgrade_speed_step": 0.05
			},
			"sonic_jumper": {
				"name": "Sonic Jumper",
				"description": "Hareket yonune sicrama, mavi kalkan ile hasara girer. [Aktif Skill]",
				"is_passive": false,
				"is_dash_skill": true,
				"slot_key": 0,
				"active_duration_sec": 0.4,
				"active_cooldown_sec": 12.0,
				"base_damage": 60,
				"dash_distance": 350.0,
				"shield_radius": 80.0,
				"color": [0.3, 0.6, 1.0],
				"upgrade_damage_step": 15,
				"upgrade_speed_step": 0.0
			},
			"blitz_bomb": {
				"name": "Blitz Bom",
				"description": "En yakin dusmana buz bombasi, varinca AoE dondurur. [Aktif Skill]",
				"is_passive": false,
				"slot_key": 0,
				"active_duration_sec": 0.2,
				"active_cooldown_sec": 25.0,
				"base_damage": 50,
				"speed": 90.0,
				"cooldown": 0.5,
				"lifetime": 8.0,
				"damage_type": "cryo",
				"projectile_count": 1,
				"color": [0.0, 0.8, 1.0],
				"pierce": 0,
				"chain": 0,
				"is_aoe": true,
				"aoe_radius": 150.0,
				"aoe_damage_ratio": 0.5,
				"is_homing": true,
				"freeze_duration": 3.0,
				"is_orbit": false,
				"targeting_pref": "nearest",
				"upgrade_damage_step": 15,
				"upgrade_speed_step": 0.0
			},
			"spin_laser": {
				"name": "Helix Lazer",
				"description": "360 donen yesil lazer, 2 tur yuksek hasar verir. [Aktif Skill]",
				"is_passive": false,
				"is_spin_laser": true,
				"slot_key": 0,
				"active_duration_sec": 0.2,
				"active_cooldown_sec": 28.0,
				"base_damage": 80,
				"spin_radius": 200.0,
				"spin_rotations": 2,
				"color": [0.2, 1.0, 0.3],
				"upgrade_damage_step": 25,
				"upgrade_speed_step": 0.0
			},
			"orbital_mayhem": {
				"name": "Orbital Mayhem",
				"description": "Kisa duraklama, ekrana roket yagmuru, sandik spawn. [Aktif Skill]",
				"is_passive": false,
				"is_orbital_mayhem": true,
				"slot_key": 0,
				"active_duration_sec": 0.2,
				"active_cooldown_sec": 60.0,
				"base_damage": 60,
				"rocket_count": 12,
				"color": [0.8, 0.4, 1.0],
				"upgrade_damage_step": 15,
				"upgrade_speed_step": 0.0
			},
			"magnetic_field": {
				"name": "Manyetik Alan",
				"description": "Haritadaki tum exp gemleri aninda toplar. [Aktif Skill]",
				"is_passive": false,
				"is_magnet_skill": true,
				"slot_key": 0,
				"active_duration_sec": 0.2,
				"active_cooldown_sec": 45.0,
				"base_damage": 0,
				"color": [1.0, 0.9, 0.2],
				"upgrade_damage_step": 0,
				"upgrade_speed_step": 0.0
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
			"enemy": 88.0,
			"pickup": 20.0,
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
			"p_max_health": 2,
			"p_fire_rate": 3,
			"p_crit_chance": 3,
			"p_crit_multiplier": 3,
			"p_move_speed": 2,
			"p_pickup_radius": 2,
			"p_chest_luck": 3,
			"p_fire_power": 2,
			"p_vision_range": 2,
			"p_armor": 3,
			"pa_electric_bullet": 4,
			"pa_burning_bullet": 4,
			"pa_explosive_bullet": 4,
			"unlock_railgun": 0,
			"upgrade_railgun": 6,
			"unlock_rocket_blaster": 5,
			"upgrade_rocket_blaster": 6,
			"unlock_octo_gun": 5,
			"upgrade_octo_gun": 6,
			"unlock_arc_blaster": 5,
			"upgrade_arc_blaster": 6,
			"unlock_sonic_jumper": 4,
			"upgrade_sonic_jumper": 5,
			"unlock_blitz_bomb": 5,
			"upgrade_blitz_bomb": 6,
			"unlock_spin_laser": 5,
			"upgrade_spin_laser": 6,
			"unlock_orbital_mayhem": 8,
			"upgrade_orbital_mayhem": 8,
			"unlock_magnetic_field": 4,
			"upgrade_magnetic_field": 5
		},
		"max_stacks": {
			"p_max_health": 10,
			"p_fire_rate": 10,
			"p_crit_chance": 10,
			"p_crit_multiplier": 10,
			"p_move_speed": 10,
			"p_pickup_radius": 10,
			"p_chest_luck": 10,
			"p_fire_power": 10,
			"p_vision_range": 10,
			"p_armor": 10,
			"pa_electric_bullet": 10,
			"pa_burning_bullet": 10,
			"pa_explosive_bullet": 10,
			"unlock_railgun": 1,
			"upgrade_railgun": 3,
			"unlock_rocket_blaster": 1,
			"upgrade_rocket_blaster": 3,
			"unlock_octo_gun": 1,
			"upgrade_octo_gun": 3,
			"unlock_arc_blaster": 1,
			"upgrade_arc_blaster": 3,
			"unlock_sonic_jumper": 1,
			"upgrade_sonic_jumper": 3,
			"unlock_blitz_bomb": 1,
			"upgrade_blitz_bomb": 3,
			"unlock_spin_laser": 1,
			"upgrade_spin_laser": 3,
			"unlock_orbital_mayhem": 1,
			"upgrade_orbital_mayhem": 3,
			"unlock_magnetic_field": 1,
			"upgrade_magnetic_field": 3
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
