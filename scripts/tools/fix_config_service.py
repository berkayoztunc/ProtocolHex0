#!/usr/bin/env python3
"""Fix config_service.gd:
  1. Undo botched nano_swarm replacement
  2. Replace entire old weapons definitions block with new 9 weapons
  3. Replace perk_costs block
  4. Replace max_stacks block
"""

import re

FILE = "scripts/autoload/config_service.gd"

with open(FILE, "r", encoding="utf-8") as f:
    content = f.read()

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 – Remove placeholder lines so the block is parseable
# ─────────────────────────────────────────────────────────────────────────────
content = content.replace(
    '"_placeholder_start_new_weapons": {},\n\t\t\t"__remove_nano_swarm": {',
    '"nano_swarm": {'
)
print("[step 1] placeholder reverted:", '"nano_swarm": {' in content)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 – Replace nano_swarm … gravity_pulse with 9 new weapon entries
# ─────────────────────────────────────────────────────────────────────────────
NEW_WEAPONS = '''\t\t\t"railgun": {
\t\t\t\t"name": "Rail Gun",
\t\t\t\t"description": "100 kirmizi delici isin mermisi burst atar, ~5 sn. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 5.0,
\t\t\t\t"active_cooldown_sec": 25.0,
\t\t\t\t"base_damage": 25,
\t\t\t\t"speed": 1200.0,
\t\t\t\t"cooldown": 0.05,
\t\t\t\t"lifetime": 1.5,
\t\t\t\t"damage_type": "kinetic",
\t\t\t\t"projectile_count": 1,
\t\t\t\t"color": [1.0, 0.2, 0.1],
\t\t\t\t"pierce": 99,
\t\t\t\t"chain": 0,
\t\t\t\t"is_aoe": false,
\t\t\t\t"is_orbit": false,
\t\t\t\t"targeting_pref": "nearest",
\t\t\t\t"upgrade_damage_step": 8,
\t\t\t\t"upgrade_speed_step": 0.1
\t\t\t},
\t\t\t"rocket_blaster": {
\t\t\t\t"name": "Roket Blaster",
\t\t\t\t"description": "En yakin 5 hedefe homing roket, patlar. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"is_burst_then_done": true,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 3.0,
\t\t\t\t"active_cooldown_sec": 35.0,
\t\t\t\t"base_damage": 80,
\t\t\t\t"speed": 300.0,
\t\t\t\t"cooldown": 0.3,
\t\t\t\t"lifetime": 5.0,
\t\t\t\t"damage_type": "explosive",
\t\t\t\t"projectile_count": 5,
\t\t\t\t"color": [1.0, 0.5, 0.1],
\t\t\t\t"pierce": 0,
\t\t\t\t"chain": 0,
\t\t\t\t"is_aoe": true,
\t\t\t\t"aoe_radius": 120.0,
\t\t\t\t"aoe_damage_ratio": 0.6,
\t\t\t\t"is_orbit": false,
\t\t\t\t"targeting_pref": "multi_nearest",
\t\t\t\t"upgrade_damage_step": 20,
\t\t\t\t"upgrade_speed_step": 0.0
\t\t\t},
\t\t\t"octo_gun": {
\t\t\t\t"name": "Octo Gun",
\t\t\t\t"description": "En yakin 6 hedefe ayni anda 20 sn boyunca ates eder. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 20.0,
\t\t\t\t"active_cooldown_sec": 45.0,
\t\t\t\t"base_damage": 18,
\t\t\t\t"speed": 500.0,
\t\t\t\t"cooldown": 0.4,
\t\t\t\t"lifetime": 1.5,
\t\t\t\t"damage_type": "physical",
\t\t\t\t"projectile_count": 6,
\t\t\t\t"color": [0.8, 1.0, 0.3],
\t\t\t\t"pierce": 0,
\t\t\t\t"chain": 0,
\t\t\t\t"is_aoe": false,
\t\t\t\t"is_orbit": false,
\t\t\t\t"targeting_pref": "multi_nearest",
\t\t\t\t"upgrade_damage_step": 5,
\t\t\t\t"upgrade_speed_step": 0.05
\t\t\t},
\t\t\t"arc_blaster": {
\t\t\t\t"name": "Arc Blaster",
\t\t\t\t"description": "En yakin hedefe 8 mermi x 3 tur geri iter. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 6.0,
\t\t\t\t"active_cooldown_sec": 30.0,
\t\t\t\t"base_damage": 20,
\t\t\t\t"speed": 450.0,
\t\t\t\t"cooldown": 0.1,
\t\t\t\t"lifetime": 1.5,
\t\t\t\t"damage_type": "electric",
\t\t\t\t"projectile_count": 8,
\t\t\t\t"burst_count": 3,
\t\t\t\t"burst_interval": 1.5,
\t\t\t\t"knockback_force": 300.0,
\t\t\t\t"color": [0.4, 0.7, 1.0],
\t\t\t\t"pierce": 0,
\t\t\t\t"chain": 0,
\t\t\t\t"is_aoe": false,
\t\t\t\t"is_orbit": false,
\t\t\t\t"targeting_pref": "nearest",
\t\t\t\t"upgrade_damage_step": 8,
\t\t\t\t"upgrade_speed_step": 0.05
\t\t\t},
\t\t\t"sonic_jumper": {
\t\t\t\t"name": "Sonic Jumper",
\t\t\t\t"description": "Hareket yonune sicrama, mavi kalkan ile hasara girer. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"is_dash_skill": true,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 0.4,
\t\t\t\t"active_cooldown_sec": 12.0,
\t\t\t\t"base_damage": 60,
\t\t\t\t"dash_distance": 350.0,
\t\t\t\t"shield_radius": 80.0,
\t\t\t\t"color": [0.3, 0.6, 1.0],
\t\t\t\t"upgrade_damage_step": 15,
\t\t\t\t"upgrade_speed_step": 0.0
\t\t\t},
\t\t\t"blitz_bomb": {
\t\t\t\t"name": "Blitz Bom",
\t\t\t\t"description": "En yakin dusmana buz bombasi, varinca AoE dondurur. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 0.2,
\t\t\t\t"active_cooldown_sec": 25.0,
\t\t\t\t"base_damage": 50,
\t\t\t\t"speed": 90.0,
\t\t\t\t"cooldown": 0.5,
\t\t\t\t"lifetime": 8.0,
\t\t\t\t"damage_type": "cryo",
\t\t\t\t"projectile_count": 1,
\t\t\t\t"color": [0.0, 0.8, 1.0],
\t\t\t\t"pierce": 0,
\t\t\t\t"chain": 0,
\t\t\t\t"is_aoe": true,
\t\t\t\t"aoe_radius": 150.0,
\t\t\t\t"aoe_damage_ratio": 0.5,
\t\t\t\t"is_homing": true,
\t\t\t\t"freeze_duration": 3.0,
\t\t\t\t"is_orbit": false,
\t\t\t\t"targeting_pref": "nearest",
\t\t\t\t"upgrade_damage_step": 15,
\t\t\t\t"upgrade_speed_step": 0.0
\t\t\t},
\t\t\t"spin_laser": {
\t\t\t\t"name": "Helix Lazer",
\t\t\t\t"description": "360 donen yesil lazer, 2 tur yuksek hasar verir. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"is_spin_laser": true,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 0.2,
\t\t\t\t"active_cooldown_sec": 28.0,
\t\t\t\t"base_damage": 80,
\t\t\t\t"spin_radius": 200.0,
\t\t\t\t"spin_rotations": 2,
\t\t\t\t"color": [0.2, 1.0, 0.3],
\t\t\t\t"upgrade_damage_step": 25,
\t\t\t\t"upgrade_speed_step": 0.0
\t\t\t},
\t\t\t"orbital_mayhem": {
\t\t\t\t"name": "Orbital Mayhem",
\t\t\t\t"description": "Kisa duraklama, ekrana roket yagmuru, sandik spawn. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"is_orbital_mayhem": true,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 0.2,
\t\t\t\t"active_cooldown_sec": 60.0,
\t\t\t\t"base_damage": 60,
\t\t\t\t"rocket_count": 12,
\t\t\t\t"color": [0.8, 0.4, 1.0],
\t\t\t\t"upgrade_damage_step": 15,
\t\t\t\t"upgrade_speed_step": 0.0
\t\t\t},
\t\t\t"magnetic_field": {
\t\t\t\t"name": "Manyetik Alan",
\t\t\t\t"description": "Haritadaki tum exp gemleri aninda toplar. [Aktif Skill]",
\t\t\t\t"is_passive": false,
\t\t\t\t"is_magnet_skill": true,
\t\t\t\t"slot_key": 0,
\t\t\t\t"active_duration_sec": 0.2,
\t\t\t\t"active_cooldown_sec": 45.0,
\t\t\t\t"base_damage": 0,
\t\t\t\t"color": [1.0, 0.9, 0.2],
\t\t\t\t"upgrade_damage_step": 0,
\t\t\t\t"upgrade_speed_step": 0.0
\t\t\t},
\t\t'''

# Find start of old weapons from nano_swarm, end = just before targeting_modes
start_marker = '"nano_swarm": {'
end_marker = '\n\t\t},\n\t\t"targeting_modes":'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

print(f"[step 2] start_idx={start_idx}, end_idx={end_idx}")
if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + NEW_WEAPONS + content[end_idx:]
    print("[step 2] weapons block replaced OK")
else:
    print("[step 2] ERROR – could not find boundaries")
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 – Replace perk_costs block
# ─────────────────────────────────────────────────────────────────────────────
NEW_PERK_COSTS = '''\t\t"perk_costs": {
\t\t\t"p_max_health": 2,
\t\t\t"p_fire_rate": 3,
\t\t\t"p_crit_chance": 3,
\t\t\t"p_crit_multiplier": 3,
\t\t\t"p_move_speed": 2,
\t\t\t"p_pickup_radius": 2,
\t\t\t"p_chest_luck": 3,
\t\t\t"p_fire_power": 2,
\t\t\t"p_vision_range": 2,
\t\t\t"p_armor": 3,
\t\t\t"pa_electric_bullet": 4,
\t\t\t"pa_burning_bullet": 4,
\t\t\t"pa_explosive_bullet": 4,
\t\t\t"unlock_railgun": 0,
\t\t\t"upgrade_railgun": 6,
\t\t\t"unlock_rocket_blaster": 5,
\t\t\t"upgrade_rocket_blaster": 6,
\t\t\t"unlock_octo_gun": 5,
\t\t\t"upgrade_octo_gun": 6,
\t\t\t"unlock_arc_blaster": 5,
\t\t\t"upgrade_arc_blaster": 6,
\t\t\t"unlock_sonic_jumper": 4,
\t\t\t"upgrade_sonic_jumper": 5,
\t\t\t"unlock_blitz_bomb": 5,
\t\t\t"upgrade_blitz_bomb": 6,
\t\t\t"unlock_spin_laser": 5,
\t\t\t"upgrade_spin_laser": 6,
\t\t\t"unlock_orbital_mayhem": 8,
\t\t\t"upgrade_orbital_mayhem": 8,
\t\t\t"unlock_magnetic_field": 4,
\t\t\t"upgrade_magnetic_field": 5
\t\t},'''

perk_costs_pattern = r'\t\t"perk_costs":\s*\{.*?\},\n'
m = re.search(perk_costs_pattern, content, re.DOTALL)
if m:
    content = content[:m.start()] + NEW_PERK_COSTS + '\n' + content[m.end():]
    print("[step 3] perk_costs replaced OK")
else:
    print("[step 3] ERROR – perk_costs block not found")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 – Replace max_stacks block
# ─────────────────────────────────────────────────────────────────────────────
NEW_MAX_STACKS = '''\t\t"max_stacks": {
\t\t\t"p_max_health": 10,
\t\t\t"p_fire_rate": 10,
\t\t\t"p_crit_chance": 10,
\t\t\t"p_crit_multiplier": 10,
\t\t\t"p_move_speed": 10,
\t\t\t"p_pickup_radius": 10,
\t\t\t"p_chest_luck": 10,
\t\t\t"p_fire_power": 10,
\t\t\t"p_vision_range": 10,
\t\t\t"p_armor": 10,
\t\t\t"pa_electric_bullet": 10,
\t\t\t"pa_burning_bullet": 10,
\t\t\t"pa_explosive_bullet": 10,
\t\t\t"unlock_railgun": 1,
\t\t\t"upgrade_railgun": 3,
\t\t\t"unlock_rocket_blaster": 1,
\t\t\t"upgrade_rocket_blaster": 3,
\t\t\t"unlock_octo_gun": 1,
\t\t\t"upgrade_octo_gun": 3,
\t\t\t"unlock_arc_blaster": 1,
\t\t\t"upgrade_arc_blaster": 3,
\t\t\t"unlock_sonic_jumper": 1,
\t\t\t"upgrade_sonic_jumper": 3,
\t\t\t"unlock_blitz_bomb": 1,
\t\t\t"upgrade_blitz_bomb": 3,
\t\t\t"unlock_spin_laser": 1,
\t\t\t"upgrade_spin_laser": 3,
\t\t\t"unlock_orbital_mayhem": 1,
\t\t\t"upgrade_orbital_mayhem": 3,
\t\t\t"unlock_magnetic_field": 1,
\t\t\t"upgrade_magnetic_field": 3
\t\t}'''

max_stacks_pattern = r'\t\t"max_stacks":\s*\{.*?\}'
m2 = re.search(max_stacks_pattern, content, re.DOTALL)
if m2:
    content = content[:m2.start()] + NEW_MAX_STACKS + content[m2.end():]
    print("[step 4] max_stacks replaced OK")
else:
    print("[step 4] ERROR – max_stacks block not found")

# ─────────────────────────────────────────────────────────────────────────────
# Write
# ─────────────────────────────────────────────────────────────────────────────
with open(FILE, "w", encoding="utf-8") as f:
    f.write(content)
print("[done] config_service.gd written")
