#!/usr/bin/env python3
"""Rewrite player.gd to use the new perk system.
Changes:
  1. Remove bomb signals and bomb_damage export
  2. Remove bomb_charges var
  3. Remove dash vars
  4. Remove elemental school vars (chill/volt/void/nano/chrono)
  5. Add new stat vars + vision_changed signal
  6. Remove void_collapse / chrono_slow calls from physics_process
  7. Remove dash block from _handle_utility_inputs
  8. Remove bomb block from _handle_perk_inputs
  9. Remove _process_void_collapse() and _process_chrono_slow() functions
 10. Remove _apply_synergy() function
 11. Rewrite apply_upgrade() match block
"""

import re

FILE = "scripts/entities/player.gd"

with open(FILE, "r", encoding="utf-8") as f:
    content = f.read()

# ──────────────────────────────────────────────────────────────────────────────
# 1. Remove bomb signals (keep others)
# ──────────────────────────────────────────────────────────────────────────────
content = content.replace(
    "signal perk_charges_changed(bomb_charges: int, heal_charges: int)\nsignal bomb_triggered(damage: int)\n",
    ""
)
print("[1] bomb signals removed:", "bomb_triggered" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 2. Remove bomb_damage export
# ──────────────────────────────────────────────────────────────────────────────
content = content.replace(
    "@export var bomb_damage: int = 999\n",
    ""
)
print("[2] bomb_damage export removed:", "bomb_damage" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 3. Remove bomb_charges var
# ──────────────────────────────────────────────────────────────────────────────
content = content.replace(
    "var bomb_charges: int = 0\n",
    ""
)
print("[3] bomb_charges var removed:", "bomb_charges" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 4. Remove dash vars block
# ──────────────────────────────────────────────────────────────────────────────
dash_vars = (
    "var dash_charges: int = 0\n"
    "var dash_speed: float = 600.0\n"
    "var dash_duration: float = 0.15\n"
    "var _is_dashing: bool = false\n"
    "var _dash_timer: float = 0.0\n"
    "var _dash_direction: Vector2 = Vector2.ZERO\n"
)
content = content.replace(dash_vars, "")
print("[4] dash vars removed:", "dash_charges" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 5. Remove elemental school vars block
# ──────────────────────────────────────────────────────────────────────────────
elemental_block_start = "# --- Elemental status effects ---"
elemental_block_end = "var _chrono_tick: float = 0.0        # timer for chrono slow ticks\n"
start_idx = content.find(elemental_block_start)
end_idx = content.find(elemental_block_end)
if start_idx != -1 and end_idx != -1:
    end_idx += len(elemental_block_end)
    content = content[:start_idx] + content[end_idx:]
    print("[5] elemental vars removed: OK")
else:
    print(f"[5] ERROR start={start_idx} end={end_idx}")

# ──────────────────────────────────────────────────────────────────────────────
# 6. Add new stat vars after 'var luck: float = 0.0'
# ──────────────────────────────────────────────────────────────────────────────
NEW_STAT_VARS = (
    "var luck: float = 0.0\n"
    "# --- New perk stats ---\n"
    "var electric_bullet_chance: float = 0.0\n"
    "var explosive_bullet_chance: float = 0.0\n"
    "var chest_luck: float = 0.0\n"
    "var vision_range_level: int = 0\n"
    "signal vision_changed(level: int)\n"
)
content = content.replace("var luck: float = 0.0\n", NEW_STAT_VARS, 1)
print("[6] new stat vars added:", "electric_bullet_chance" in content)

# ──────────────────────────────────────────────────────────────────────────────
# 7. Remove void_collapse / chrono_slow calls from physics_process
# ──────────────────────────────────────────────────────────────────────────────
elemental_calls = (
    "\n\t# Elemental field passives\n"
    "\tif void_energy > 0.0:\n"
    "\t\t_process_void_collapse(delta)\n"
    "\tif chrono_slow_pct > 0.0:\n"
    "\t\t_process_chrono_slow(delta)\n"
)
content = content.replace(elemental_calls, "\n")
print("[7] elemental calls removed:", "_process_void_collapse" not in content or "_process_void_collapse(delta)" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 8. Remove dash block from _handle_utility_inputs
# ──────────────────────────────────────────────────────────────────────────────
dash_input_block = (
    "\n\t# Dash (Shift)\n"
    "\tif Input.is_action_just_pressed(\"dash\") and dash_charges > 0 and not _is_dashing:\n"
    "\t\tvar input_dir: Vector2 = Vector2(\n"
    "\t\t\tInput.get_axis(\"move_left\", \"move_right\"),\n"
    "\t\t\tInput.get_axis(\"move_up\", \"move_down\")\n"
    "\t\t)\n"
    "\t\tif input_dir.length_squared() > 0.01:\n"
    "\t\t\t_dash_direction = input_dir.normalized()\n"
    "\t\telse:\n"
    "\t\t\t_dash_direction = Vector2.RIGHT\n"
    "\t\tdash_charges -= 1\n"
    "\t\t_is_dashing = true\n"
    "\t\t_dash_timer = dash_duration\n"
)
content = content.replace(dash_input_block, "\n")
print("[8] dash input block removed:", "dash_charges -= 1" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 9. Remove bomb block from _handle_perk_inputs
# ──────────────────────────────────────────────────────────────────────────────
bomb_input = (
    "\tif Input.is_action_just_pressed(\"use_bomb\") and bomb_charges > 0:\n"
    "\t\tbomb_charges -= 1\n"
    "\t\tperk_charges_changed.emit(bomb_charges, heal_charges)\n"
    "\t\tbomb_triggered.emit(bomb_damage)\n\n\t"
)
content = content.replace(bomb_input, "\t")
print("[9] bomb input block removed:", "use_bomb" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 10. Remove _process_void_collapse function
# ──────────────────────────────────────────────────────────────────────────────
void_fn = (
    "func _process_void_collapse(delta: float) -> void:\n"
    "\t_void_charge += void_energy * delta\n"
    "\tif _void_charge < 1.0:\n"
    "\t\treturn\n"
    "\t_void_charge = 0.0\n"
    "\tvar collapse_dmg: int = maxi(10, int(20.0 * (1.0 + void_energy)))\n"
    "\tvar enemies: Array = get_tree().get_nodes_in_group(\"enemies\")\n"
    "\tfor e in enemies:\n"
    "\t\tif e.has_method(\"take_damage\"):\n"
    "\t\t\tif global_position.distance_to(e.global_position) <= void_collapse_radius:\n"
    "\t\t\t\te.take_damage(collapse_dmg, \"void\", false)\n"
    "\t_spawn_vfx_ring(\"res://assets/vfx/vfx_void_explosion_ring.png\", global_position, void_collapse_radius)\n"
    "\n\n"
)
content = content.replace(void_fn, "")
print("[10] void collapse fn removed:", "func _process_void_collapse" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 11. Remove _process_chrono_slow function
# ──────────────────────────────────────────────────────────────────────────────
chrono_fn = (
    "func _process_chrono_slow(delta: float) -> void:\n"
    "\t_chrono_tick += delta\n"
    "\tif _chrono_tick < 0.25:\n"
    "\t\treturn\n"
    "\t_chrono_tick = 0.0\n"
    "\tvar chrono_radius: float = 220.0\n"
    "\tvar enemies: Array = get_tree().get_nodes_in_group(\"enemies\")\n"
    "\tfor e in enemies:\n"
    "\t\tif e.has_method(\"apply_chill\"):\n"
    "\t\t\tif global_position.distance_to(e.global_position) <= chrono_radius:\n"
    "\t\t\t\te.apply_chill(chrono_slow_pct, 0.4)\n"
    "\n\n"
)
content = content.replace(chrono_fn, "")
print("[11] chrono slow fn removed:", "func _process_chrono_slow" not in content)

# ──────────────────────────────────────────────────────────────────────────────
# 12. Remove _apply_synergy function (large block from 'func _apply_synergy' to next 'func ')
# ──────────────────────────────────────────────────────────────────────────────
synergy_start = "\nfunc _apply_synergy(synergy_id: String) -> void:"
synergy_end = "\nfunc _next_available_slot_key"
s_idx = content.find(synergy_start)
e_idx = content.find(synergy_end)
if s_idx != -1 and e_idx != -1:
    content = content[:s_idx] + content[e_idx:]
    print("[12] _apply_synergy removed: OK")
else:
    print(f"[12] ERROR start={s_idx} end={e_idx}")

# ──────────────────────────────────────────────────────────────────────────────
# 13. Replace apply_upgrade() match block
# ──────────────────────────────────────────────────────────────────────────────
NEW_APPLY_UPGRADE = '''func apply_upgrade(upgrade_id: String) -> void:
\tmatch upgrade_id:
\t\t# ═══ PASSiF BONUSLAR ═══
\t\t"p_max_health":
\t\t\tmax_health += 20
\t\t\thealth = min(health + 20, max_health)
\t\t\thealth_changed.emit(health, max_health)
\t\t"p_fire_rate":
\t\t\tshoot_cooldown = maxf(min_shoot_cooldown, shoot_cooldown * 0.92)
\t\t\tshoot_timer.wait_time = shoot_cooldown
\t\t"p_crit_chance":
\t\t\tcrit_chance = minf(crit_chance + 0.05, 0.80)
\t\t"p_crit_multiplier":
\t\t\tcrit_multiplier += 0.20
\t\t"p_move_speed":
\t\t\tspeed += 15.0
\t\t"p_pickup_radius":
\t\t\tvar shape: CollisionShape2D = pickup_area.get_node("PickupShape")
\t\t\tif shape and shape.shape is CircleShape2D:
\t\t\t\t(shape.shape as CircleShape2D).radius += 25.0
\t\t"p_chest_luck":
\t\t\tchest_luck = minf(chest_luck + 0.05, 1.0)
\t\t"p_fire_power":
\t\t\tweapon_damage += 5
\t\t"p_vision_range":
\t\t\tvision_range_level += 1
\t\t\tvision_changed.emit(vision_range_level)
\t\t"p_armor":
\t\t\tarmor += 5

\t\t# ═══ MERMi EFEKTLERi ═══
\t\t"pa_electric_bullet":
\t\t\telectric_bullet_chance = minf(electric_bullet_chance + 0.08, 0.80)
\t\t"pa_burning_bullet":
\t\t\tburn_chance = minf(burn_chance + 0.08, 0.80)
\t\t"pa_explosive_bullet":
\t\t\texplosive_bullet_chance = minf(explosive_bullet_chance + 0.08, 0.80)

\t\t# ═══ AKTiF SKiLLER - UNLOCK ═══
\t\t"unlock_railgun":
\t\t\t_unlock_weapon_slot("railgun")
\t\t"unlock_rocket_blaster":
\t\t\t_unlock_weapon_slot("rocket_blaster")
\t\t"unlock_octo_gun":
\t\t\t_unlock_weapon_slot("octo_gun")
\t\t"unlock_arc_blaster":
\t\t\t_unlock_weapon_slot("arc_blaster")
\t\t"unlock_sonic_jumper":
\t\t\t_unlock_weapon_slot("sonic_jumper")
\t\t"unlock_blitz_bomb":
\t\t\t_unlock_weapon_slot("blitz_bomb")
\t\t"unlock_spin_laser":
\t\t\t_unlock_weapon_slot("spin_laser")
\t\t"unlock_orbital_mayhem":
\t\t\t_unlock_weapon_slot("orbital_mayhem")
\t\t"unlock_magnetic_field":
\t\t\t_unlock_weapon_slot("magnetic_field")

\t\t# ═══ AKTiF SKiLLER - UPGRADE ═══
\t\tvar upg_id when upg_id.begins_with("upgrade_"):
\t\t\tvar weapon_key: String = upg_id.substr(len("upgrade_"))
\t\t\tif _weapon_slots.has(weapon_key):
\t\t\t\tweapon_upgrade_levels[weapon_key] = int(weapon_upgrade_levels.get(weapon_key, 0)) + 1

'''

# Find old apply_upgrade function boundaries
old_start = "func apply_upgrade(upgrade_id: String) -> void:\n"
old_end = "\nfunc _next_available_slot_key"
old_start_idx = content.find(old_start)
old_end_idx = content.find(old_end)
if old_start_idx != -1 and old_end_idx != -1:
    content = content[:old_start_idx] + NEW_APPLY_UPGRADE + content[old_end_idx:]
    print("[13] apply_upgrade rewritten: OK")
else:
    print(f"[13] ERROR start={old_start_idx} end={old_end_idx}")

# ──────────────────────────────────────────────────────────────────────────────
# Write
# ──────────────────────────────────────────────────────────────────────────────
with open(FILE, "w", encoding="utf-8") as f:
    f.write(content)
print("[done] player.gd written")
