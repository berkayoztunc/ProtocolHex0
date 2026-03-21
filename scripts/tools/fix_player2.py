#!/usr/bin/env python3
"""Fix remaining player.gd references after the main fix_player.py run."""

FILE = "scripts/entities/player.gd"

with open(FILE, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Remove perk_charges_changed emit in _ready()
content = content.replace(
    "\tperk_charges_changed.emit(bomb_charges, heal_charges)\n\tprojectile_class_changed.emit(projectile_class)",
    "\tprojectile_class_changed.emit(projectile_class)"
)
print("[1] _ready() perk_charges emit fixed:", "perk_charges_changed" not in content[:600])

# 2. Remove dash logic block in _physics_process
OLD_DASH_BLOCK = (
    "\t# Dash logic\n"
    "\tif _is_dashing:\n"
    "\t\t_dash_timer -= delta\n"
    "\t\tvelocity = _dash_direction * dash_speed\n"
    "\t\tif _dash_timer <= 0.0:\n"
    "\t\t\t_is_dashing = false\n"
    "\telse:\n"
    "\t\tvar input_dir: Vector2 = Vector2(\n"
    "\t\t\tInput.get_axis(\"move_left\", \"move_right\"),\n"
    "\t\t\tInput.get_axis(\"move_up\", \"move_down\")\n"
    "\t\t)\n"
    "\t\tvelocity = input_dir.normalized() * speed\n"
)
NEW_MOVEMENT = (
    "\tvar input_dir: Vector2 = Vector2(\n"
    "\t\tInput.get_axis(\"move_left\", \"move_right\"),\n"
    "\t\tInput.get_axis(\"move_up\", \"move_down\")\n"
    "\t)\n"
    "\tvelocity = input_dir.normalized() * speed\n"
)
content = content.replace(OLD_DASH_BLOCK, NEW_MOVEMENT)
print("[2] dash physics block fixed:", "_is_dashing" not in content)

# 3. Remove bomb/dash from apply_run_state
content = content.replace(
    "\tbomb_charges = int(saved_state.get(\"bomb_charges\", 0))\n",
    ""
)
content = content.replace(
    "\tdash_charges = int(saved_state.get(\"dash_charges\", 0))\n",
    ""
)
# Remove elemental saves in apply_run_state
content = content.replace(
    "\t# Restore elemental stats\n"
    "\tburn_chance = float(saved_state.get(\"burn_chance\", 0.0))\n"
    "\tburn_damage = int(saved_state.get(\"burn_damage\", 3))\n"
    "\tchill_chance = float(saved_state.get(\"chill_chance\", 0.0))\n"
    "\tchill_slow_pct = float(saved_state.get(\"chill_slow_pct\", 0.0))\n"
    "\tvolt_chain_count = int(saved_state.get(\"volt_chain_count\", 0))\n"
    "\tvolt_chain_damage_pct = float(saved_state.get(\"volt_chain_damage_pct\", 0.6))\n"
    "\tvoid_energy = float(saved_state.get(\"void_energy\", 0.0))\n"
    "\tvoid_collapse_radius = float(saved_state.get(\"void_collapse_radius\", 120.0))\n"
    "\tnano_heal_pct = float(saved_state.get(\"nano_heal_pct\", 0.0))\n"
    "\tchrono_slow_pct = float(saved_state.get(\"chrono_slow_pct\", 0.0))\n",
    "\t# Restore bullet effect stats\n"
    "\tburn_chance = float(saved_state.get(\"burn_chance\", 0.0))\n"
    "\tburn_damage = int(saved_state.get(\"burn_damage\", 3))\n"
    "\telectric_bullet_chance = float(saved_state.get(\"electric_bullet_chance\", 0.0))\n"
    "\texplosive_bullet_chance = float(saved_state.get(\"explosive_bullet_chance\", 0.0))\n"
    "\tchest_luck = float(saved_state.get(\"chest_luck\", 0.0))\n"
    "\tvision_range_level = int(saved_state.get(\"vision_range_level\", 0))\n"
)
# Remove perk_charges_changed in apply_run_state
content = content.replace(
    "\tperk_charges_changed.emit(bomb_charges, heal_charges)\n\tweapons_changed.emit()",
    "\tweapons_changed.emit()"
)
print("[3] apply_run_state elemental/bomb refs fixed")

# 4. Rewrite get_run_state() to remove old entries
OLD_RUN_STATE = (
    "func get_run_state() -> Dictionary:\n"
    "\treturn {\n"
    "\t\t\"level\": level,\n"
    "\t\t\"xp\": xp,\n"
    "\t\t\"xp_needed\": xp_to_next_level,\n"
    "\t\t\"health\": health,\n"
    "\t\t\"max_health\": max_health,\n"
    "\t\t\"bomb_charges\": bomb_charges,\n"
    "\t\t\"heal_charges\": heal_charges,\n"
    "\t\t\"weapon_damage\": weapon_damage,\n"
    "\t\t\"weapon_projectile_count\": weapon_projectile_count,\n"
    "\t\t\"shoot_cooldown\": shoot_cooldown,\n"
    "\t\t\"crit_chance\": crit_chance,\n"
    "\t\t\"pierce_count\": pierce_count,\n"
    "\t\t\"armor\": armor,\n"
    "\t\t\"life_regen\": life_regen,\n"
    "\t\t\"dash_charges\": dash_charges,\n"
    "\t\t\"xp_multiplier\": xp_multiplier,\n"
    "\t\t\"luck\": luck,\n"
    "\t\t\"cooldown_multiplier\": cooldown_multiplier,\n"
    "\t\t\"has_shield\": has_shield,\n"
    "\t\t\"targeting_mode\": targeting_mode,\n"
    "\t\t\"projectile_class\": projectile_class,\n"
    "\t\t\"unlocked_projectile_classes\": unlocked_projectile_classes.duplicate(),\n"
    "\t\t\"unlocked_targeting_modes\": unlocked_targeting_modes.duplicate(),\n"
    "\t\t\"unlocked_passive_weapons\": unlocked_passive_weapons.duplicate(),\n"
    "\t\t\"weapon_upgrade_levels\": weapon_upgrade_levels.duplicate(true),\n"
    "\t\t\"weapon_slots\": _weapon_slots.duplicate(true),\n"
    "\t\t# Elemental\n"
    "\t\t\"burn_chance\": burn_chance,\n"
    "\t\t\"burn_damage\": burn_damage,\n"
    "\t\t\"chill_chance\": chill_chance,\n"
    "\t\t\"chill_slow_pct\": chill_slow_pct,\n"
    "\t\t\"volt_chain_count\": volt_chain_count,\n"
    "\t\t\"volt_chain_damage_pct\": volt_chain_damage_pct,\n"
    "\t\t\"void_energy\": void_energy,\n"
    "\t\t\"void_collapse_radius\": void_collapse_radius,\n"
    "\t\t\"nano_heal_pct\": nano_heal_pct,\n"
    "\t\t\"chrono_slow_pct\": chrono_slow_pct,\n"
    "\t}\n"
)
NEW_RUN_STATE = (
    "func get_run_state() -> Dictionary:\n"
    "\treturn {\n"
    "\t\t\"level\": level,\n"
    "\t\t\"xp\": xp,\n"
    "\t\t\"xp_needed\": xp_to_next_level,\n"
    "\t\t\"health\": health,\n"
    "\t\t\"max_health\": max_health,\n"
    "\t\t\"heal_charges\": heal_charges,\n"
    "\t\t\"weapon_damage\": weapon_damage,\n"
    "\t\t\"weapon_projectile_count\": weapon_projectile_count,\n"
    "\t\t\"shoot_cooldown\": shoot_cooldown,\n"
    "\t\t\"crit_chance\": crit_chance,\n"
    "\t\t\"pierce_count\": pierce_count,\n"
    "\t\t\"armor\": armor,\n"
    "\t\t\"life_regen\": life_regen,\n"
    "\t\t\"xp_multiplier\": xp_multiplier,\n"
    "\t\t\"luck\": luck,\n"
    "\t\t\"cooldown_multiplier\": cooldown_multiplier,\n"
    "\t\t\"has_shield\": has_shield,\n"
    "\t\t\"targeting_mode\": targeting_mode,\n"
    "\t\t\"projectile_class\": projectile_class,\n"
    "\t\t\"unlocked_projectile_classes\": unlocked_projectile_classes.duplicate(),\n"
    "\t\t\"unlocked_targeting_modes\": unlocked_targeting_modes.duplicate(),\n"
    "\t\t\"unlocked_passive_weapons\": unlocked_passive_weapons.duplicate(),\n"
    "\t\t\"weapon_upgrade_levels\": weapon_upgrade_levels.duplicate(true),\n"
    "\t\t\"weapon_slots\": _weapon_slots.duplicate(true),\n"
    "\t\t# Bullet effects\n"
    "\t\t\"burn_chance\": burn_chance,\n"
    "\t\t\"burn_damage\": burn_damage,\n"
    "\t\t\"electric_bullet_chance\": electric_bullet_chance,\n"
    "\t\t\"explosive_bullet_chance\": explosive_bullet_chance,\n"
    "\t\t\"chest_luck\": chest_luck,\n"
    "\t\t\"vision_range_level\": vision_range_level,\n"
    "\t}\n"
)
content = content.replace(OLD_RUN_STATE, NEW_RUN_STATE)
print("[4] get_run_state rewritten:", "chill_chance" not in content or "get_run_state" in content)

# 5. Remove perk_charges_changed in _handle_perk_inputs (heal only)
content = content.replace(
    "\t\thealth = min(health + heal_amount, max_health)\n"
    "\t\thealth_changed.emit(health, max_health)\n"
    "\t\tperk_charges_changed.emit(bomb_charges, heal_charges)\n",
    "\t\thealth = min(health + heal_amount, max_health)\n"
    "\t\thealth_changed.emit(health, max_health)\n"
)
print("[5] _handle_perk_inputs bomb emit removed")

# 6. Fix get_perk_charges() - remove bomb ref
content = content.replace(
    "func get_perk_charges() -> Dictionary:\n"
    "\treturn {\n"
    "\t\t\"bomb\": bomb_charges,\n"
    "\t\t\"heal\": heal_charges\n"
    "\t}\n",
    "func get_perk_charges() -> Dictionary:\n"
    "\treturn {\n"
    "\t\t\"heal\": heal_charges\n"
    "\t}\n"
)
print("[6] get_perk_charges bomb ref removed")

with open(FILE, "w", encoding="utf-8") as f:
    f.write(content)
print("[done] player.gd cleanup written")
