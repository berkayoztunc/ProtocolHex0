extends Node
## Perk Catalog — Single Tree, 3 Categories
## Passive Bonuses | Bullet Effects | Active Skills

enum Tab {
	TEMEL = 0,
}

const TAB_NAMES: Dictionary = {
	Tab.TEMEL: "Perk Tree",
}

const TAB_COLORS: Dictionary = {
	Tab.TEMEL: Color(0.7, 0.8, 1.0),
}

var _all_catalogs: Dictionary = {}
var _tab_catalogs: Dictionary = {}
var _tab_layouts: Dictionary = {}
var _tab_categories: Dictionary = {}


func _ready() -> void:
	_build_all()


func _build_all() -> void:
	_tab_catalogs.clear()
	_tab_layouts.clear()
	_tab_categories.clear()
	_all_catalogs.clear()

	_tab_catalogs[Tab.TEMEL] = _build_catalog()
	_tab_layouts[Tab.TEMEL]  = _build_layout()
	_tab_categories[Tab.TEMEL] = _build_categories()

	for tab_id in _tab_catalogs:
		var cat: Dictionary = _tab_catalogs[tab_id]
		for perk_id in cat:
			_all_catalogs[perk_id] = cat[perk_id]


func get_all_catalogs() -> Dictionary:
	return _all_catalogs


func get_tab_catalog(tab_id: int) -> Dictionary:
	return _tab_catalogs.get(tab_id, {})


func get_tab_layout(tab_id: int) -> Dictionary:
	return _tab_layouts.get(tab_id, {})


func get_tab_categories(tab_id: int) -> Dictionary:
	return _tab_categories.get(tab_id, {})


func get_tab_ids() -> Array:
	return _tab_catalogs.keys()


func get_perk_tab(_perk_id: String) -> int:
	return Tab.TEMEL


# ══════════════════════════════════════════════════════════════
# MAIN CATALOG
# ══════════════════════════════════════════════════════════════

func _build_catalog() -> Dictionary:
	return {
		# ─── PASSIVE BONUSES ────────────────────────────────────
		"p_max_health": {
			"id": "p_max_health", "name": "Maximum Health",
			"description": "+20 maximum health.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_fire_rate": {
			"id": "p_fire_rate", "name": "Fire Rate",
			"description": "Normal weapon fire rate increases by 8%.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_crit_chance": {
			"id": "p_crit_chance", "name": "Critical Chance",
			"description": "+5% critical hit chance.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_crit_multiplier": {
			"id": "p_crit_multiplier", "name": "Critical Damage",
			"description": "Critical damage multiplier +0.20.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_move_speed": {
			"id": "p_move_speed", "name": "Move Speed",
			"description": "+15 movement speed.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_pickup_radius": {
			"id": "p_pickup_radius", "name": "Collection Area",
			"description": "XP and chest pickup radius +25.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_chest_luck": {
			"id": "p_chest_luck", "name": "Chest Luck",
			"description": "+5% chest drop chance.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_fire_power": {
			"id": "p_fire_power", "name": "Fire Power",
			"description": "+5 normal weapon damage.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_vision_range": {
			"id": "p_vision_range", "name": "Vision Range",
			"description": "Screen vignette reduced, vision range +2%.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_armor": {
			"id": "p_armor", "name": "Defense",
			"description": "+5 armor, incoming damage reduced.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_weapon_range": {
			"id": "p_weapon_range", "name": "Weapon Range",
			"description": "Main weapon range +200. Bullets travel farther.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"p_life_steal": {
			"id": "p_life_steal", "name": "Nano Vampire",
			"description": "+3% life steal. 3% of damage dealt returns as health.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},

		# ─── BULLET EFFECTS ─────────────────────────────────────
		"pa_electric_bullet": {
			"id": "pa_electric_bullet", "name": "Electric Bullet",
			"description": "+8% chance: on hit, chain lightning in area.",
			"rarity": "rare", "category": "passive_active", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"pa_burning_bullet": {
			"id": "pa_burning_bullet", "name": "Burning Bullet",
			"description": "+8% chance: applies burn to enemy (damage over time).",
			"rarity": "rare", "category": "passive_active", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},
		"pa_explosive_bullet": {
			"id": "pa_explosive_bullet", "name": "Explosive Bullet",
			"description": "+8% chance: small area explosion on hit.",
			"rarity": "rare", "category": "passive_active", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": true
		},

		# ─── ACTIVE SKILLS — Unlock ─────────────────────────────
		"unlock_railgun": {
			"id": "unlock_railgun", "name": "Rail Gun",
			"description": "100 red piercing beam bullets, ~5s burst. Press key to activate.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_rocket_blaster": {
			"id": "unlock_rocket_blaster", "name": "Rocket Blaster",
			"description": "Homing rockets to closest 5 targets with 100% hit. Press key to activate.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_octo_gun": {
			"id": "unlock_octo_gun", "name": "Octo Gun",
			"description": "Fires at 6 targets simultaneously for 20 sec. Press key to activate.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_arc_blaster": {
			"id": "unlock_arc_blaster", "name": "Arc Blaster",
			"description": "8 bullets × 3 rounds to nearest target, pushing back. Press key to activate.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_sonic_jumper": {
			"id": "unlock_sonic_jumper", "name": "Sonic Jumper",
			"description": "Leap in movement direction, blue shield damages nearby enemies. Press key to activate.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_blitz_bomb": {
			"id": "unlock_blitz_bomb", "name": "Blitz Bomb",
			"description": "Slow ice bomb to nearest enemy, AoE freeze on arrival. Press key to activate.",
			"rarity": "rare", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_spin_laser": {
			"id": "unlock_spin_laser", "name": "Helix Laser",
			"description": "360° rotating green laser, 2 rounds of high damage. Press key to activate.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_orbital_mayhem": {
			"id": "unlock_orbital_mayhem", "name": "Orbital Mayhem",
			"description": "Brief pause → rocket rain on screen → chest spawn. Press key to activate.",
			"rarity": "legendary", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},
		"unlock_magnetic_field": {
			"id": "unlock_magnetic_field", "name": "Magnetic Field",
			"description": "Instantly collects all XP gems on the map. Press key to activate.",
			"rarity": "rare", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL,
			"is_base": false
		},

		# ─── ACTIVE SKILLS — Upgrade ────────────────────────────
		"upgrade_railgun": {
			"id": "upgrade_railgun", "name": "Rail Gun+",
			"description": "Rail Gun damage and pierce power increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_railgun"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_rocket_blaster": {
			"id": "upgrade_rocket_blaster", "name": "Rocket Blaster+",
			"description": "Rocket damage and blast radius increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_rocket_blaster"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_octo_gun": {
			"id": "upgrade_octo_gun", "name": "Octo Gun+",
			"description": "Octo Gun damage and duration increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_octo_gun"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_arc_blaster": {
			"id": "upgrade_arc_blaster", "name": "Arc Blaster+",
			"description": "Arc Blaster burst damage and knockback increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_arc_blaster"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_sonic_jumper": {
			"id": "upgrade_sonic_jumper", "name": "Sonic Jumper+",
			"description": "Sonic Jumper damage and range increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_sonic_jumper"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_blitz_bomb": {
			"id": "upgrade_blitz_bomb", "name": "Blitz Bomb+",
			"description": "Blitz Bomb AoE area and freeze duration increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_blitz_bomb"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_spin_laser": {
			"id": "upgrade_spin_laser", "name": "Helix Laser+",
			"description": "Helix Laser rotation count and damage increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_spin_laser"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_orbital_mayhem": {
			"id": "upgrade_orbital_mayhem", "name": "Orbital Mayhem+",
			"description": "Orbital Mayhem rocket count and chest chance increase.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_orbital_mayhem"], "tab": Tab.TEMEL,
			"is_base": false
		},
		"upgrade_magnetic_field": {
			"id": "upgrade_magnetic_field", "name": "Magnetic Field+",
			"description": "Magnetic Field cooldown decreases.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_magnetic_field"], "tab": Tab.TEMEL,
			"is_base": false
		},
	}


# ══════════════════════════════════════════════════════════════
# GRID LAYOUT
# ══════════════════════════════════════════════════════════════

func _build_layout() -> Dictionary:
	return {
		# Row 0 — Passives (group 1)
		"p_max_health":      {"row": 0, "col": 0},
		"p_fire_rate":       {"row": 0, "col": 1},
		"p_crit_chance":     {"row": 0, "col": 2},
		"p_crit_multiplier": {"row": 0, "col": 3},
		"p_move_speed":      {"row": 0, "col": 4},
		# Row 1 — Passives (group 2)
		"p_pickup_radius":   {"row": 1, "col": 0},
		"p_chest_luck":      {"row": 1, "col": 1},
		"p_fire_power":      {"row": 1, "col": 2},
		"p_vision_range":    {"row": 1, "col": 3},
		"p_armor":           {"row": 1, "col": 4},
		"p_weapon_range":    {"row": 1, "col": 5},
		"p_life_steal":      {"row": 1, "col": 6},
		# Row 2 — Bullet Effects
		"pa_electric_bullet":  {"row": 2, "col": 0},
		"pa_burning_bullet":   {"row": 2, "col": 2},
		"pa_explosive_bullet": {"row": 2, "col": 4},
		# Row 3 — Active Skill Unlock
		"unlock_railgun":        {"row": 3, "col": 0},
		"unlock_rocket_blaster": {"row": 3, "col": 1},
		"unlock_octo_gun":       {"row": 3, "col": 2},
		"unlock_arc_blaster":    {"row": 3, "col": 3},
		"unlock_sonic_jumper":   {"row": 3, "col": 4},
		"unlock_blitz_bomb":     {"row": 3, "col": 5},
		"unlock_spin_laser":     {"row": 3, "col": 6},
		"unlock_orbital_mayhem": {"row": 3, "col": 7},
		"unlock_magnetic_field": {"row": 3, "col": 8},
		# Row 4 — Active Skill Upgrade
		"upgrade_railgun":        {"row": 4, "col": 0},
		"upgrade_rocket_blaster": {"row": 4, "col": 1},
		"upgrade_octo_gun":       {"row": 4, "col": 2},
		"upgrade_arc_blaster":    {"row": 4, "col": 3},
		"upgrade_sonic_jumper":   {"row": 4, "col": 4},
		"upgrade_blitz_bomb":     {"row": 4, "col": 5},
		"upgrade_spin_laser":     {"row": 4, "col": 6},
		"upgrade_orbital_mayhem": {"row": 4, "col": 7},
		"upgrade_magnetic_field": {"row": 4, "col": 8},
	}


# ══════════════════════════════════════════════════════════════
# CATEGORY HEADERS
# ══════════════════════════════════════════════════════════════

func _build_categories() -> Dictionary:
	return {
		0: "PASSIVE BONUSES",
		2: "BULLET EFFECTS",
		3: "ACTIVE SKILLS",
	}
