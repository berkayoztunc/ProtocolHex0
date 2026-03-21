extends Node
## Perk Kataloğu — Tek Ağaç, 3 Kategori
## Pasif Bonuslar | Mermi Efektleri | Aktif Skiller

enum Tab {
	TEMEL = 0,
}

const TAB_NAMES: Dictionary = {
	Tab.TEMEL: "Perk Ağacı",
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
# ANA KATALOG
# ══════════════════════════════════════════════════════════════

func _build_catalog() -> Dictionary:
	return {
		# ─── PASSİF BONUSLAR ───────────────────────────────────
		"p_max_health": {
			"id": "p_max_health", "name": "Maksimum Can",
			"description": "+20 maksimum can.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_fire_rate": {
			"id": "p_fire_rate", "name": "Ateş Hızı",
			"description": "Normal silah atış hızı %8 artar.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_crit_chance": {
			"id": "p_crit_chance", "name": "Kritik Şansı",
			"description": "+%5 kritik vuruş şansı.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_crit_multiplier": {
			"id": "p_crit_multiplier", "name": "Kritik Hasar",
			"description": "Kritik hasar çarpanı +0.20.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_move_speed": {
			"id": "p_move_speed", "name": "Hareket Hızı",
			"description": "+15 hareket hızı.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_pickup_radius": {
			"id": "p_pickup_radius", "name": "Toplama Alanı",
			"description": "XP ve sandık toplama alanı +25 genişler.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_chest_luck": {
			"id": "p_chest_luck", "name": "Sandık Şansı",
			"description": "+%5 sandık düşme şansı.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_fire_power": {
			"id": "p_fire_power", "name": "Ateş Gücü",
			"description": "+5 normal silah hasarı.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_vision_range": {
			"id": "p_vision_range", "name": "Görüş Alanı",
			"description": "Ekran gölgeleme azalır, görüş alanı %2 artar.",
			"rarity": "uncommon", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},
		"p_armor": {
			"id": "p_armor", "name": "Savunma",
			"description": "+5 zırh değeri, alınan hasar azalır.",
			"rarity": "common", "category": "passive", "prerequisites": [], "tab": Tab.TEMEL
		},

		# ─── MERMİ EFEKTLERİ ──────────────────────────────────
		"pa_electric_bullet": {
			"id": "pa_electric_bullet", "name": "Elektrikli Mermi",
			"description": "+%8 şans: isabet'te alan içinde elektrik sektirir.",
			"rarity": "rare", "category": "passive_active", "prerequisites": [], "tab": Tab.TEMEL
		},
		"pa_burning_bullet": {
			"id": "pa_burning_bullet", "name": "Yakıcı Mermi",
			"description": "+%8 şans: düşmana yanma uygular (sürekli hasar).",
			"rarity": "rare", "category": "passive_active", "prerequisites": [], "tab": Tab.TEMEL
		},
		"pa_explosive_bullet": {
			"id": "pa_explosive_bullet", "name": "Patlayan Mermi",
			"description": "+%8 şans: isabette küçük alan patlaması.",
			"rarity": "rare", "category": "passive_active", "prerequisites": [], "tab": Tab.TEMEL
		},

		# ─── AKTİF SKİLLER — Unlock ───────────────────────────
		"unlock_railgun": {
			"id": "unlock_railgun", "name": "Rail Gun",
			"description": "100 kırmızı delici ışın mermisi, ~5 sn burst. Tuş ile aktive et.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_rocket_blaster": {
			"id": "unlock_rocket_blaster", "name": "Roket Blaster",
			"description": "En yakın 5 hedefe %100 isabet homing roket, patlayıp biter. Tuş ile aktive et.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_octo_gun": {
			"id": "unlock_octo_gun", "name": "Octo Gun",
			"description": "6 hedefe aynı anda 20 sn boyunca ateş eder. Tuş ile aktive et.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_arc_blaster": {
			"id": "unlock_arc_blaster", "name": "Arc Blaster",
			"description": "En yakın hedefe 8 mermi × 3 tur, geri iterek. Tuş ile aktive et.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_sonic_jumper": {
			"id": "unlock_sonic_jumper", "name": "Sonic Jumper",
			"description": "Koşu yönüne sıçrama, mavi kalkan ile yoldakilere hasar verir. Tuş ile aktive et.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_blitz_bomb": {
			"id": "unlock_blitz_bomb", "name": "Blitz Bom",
			"description": "En yakın düşmana yavaş buz bombası, varınca AoE dondurur. Tuş ile aktive et.",
			"rarity": "rare", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_spin_laser": {
			"id": "unlock_spin_laser", "name": "Helix Lazer",
			"description": "360° dönen yeşil lazer, 2 tur yüksek hasar. Tuş ile aktive et.",
			"rarity": "epic", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_orbital_mayhem": {
			"id": "unlock_orbital_mayhem", "name": "Orbital Mayhem",
			"description": "Kısa duraklama → ekrana roket yağmuru → sandık spawn. Tuş ile aktive et.",
			"rarity": "legendary", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},
		"unlock_magnetic_field": {
			"id": "unlock_magnetic_field", "name": "Manyetik Alan",
			"description": "Haritadaki tüm exp gemlerini anında toplar. Tuş ile aktive et.",
			"rarity": "rare", "category": "active_unlock", "prerequisites": [], "tab": Tab.TEMEL
		},

		# ─── AKTİF SKİLLER — Upgrade ──────────────────────────
		"upgrade_railgun": {
			"id": "upgrade_railgun", "name": "Rail Gun+",
			"description": "Rail Gun hasarı ve delme gücü artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_railgun"], "tab": Tab.TEMEL
		},
		"upgrade_rocket_blaster": {
			"id": "upgrade_rocket_blaster", "name": "Roket Blaster+",
			"description": "Roket hasarı ve patlama alanı artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_rocket_blaster"], "tab": Tab.TEMEL
		},
		"upgrade_octo_gun": {
			"id": "upgrade_octo_gun", "name": "Octo Gun+",
			"description": "Octo Gun hasarı ve süresi artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_octo_gun"], "tab": Tab.TEMEL
		},
		"upgrade_arc_blaster": {
			"id": "upgrade_arc_blaster", "name": "Arc Blaster+",
			"description": "Arc Blaster burst hasarı ve geri itme gücü artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_arc_blaster"], "tab": Tab.TEMEL
		},
		"upgrade_sonic_jumper": {
			"id": "upgrade_sonic_jumper", "name": "Sonic Jumper+",
			"description": "Sonic Jumper hasarı ve menzili artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_sonic_jumper"], "tab": Tab.TEMEL
		},
		"upgrade_blitz_bomb": {
			"id": "upgrade_blitz_bomb", "name": "Blitz Bom+",
			"description": "Blitz Bom AoE alanı ve donma süresi artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_blitz_bomb"], "tab": Tab.TEMEL
		},
		"upgrade_spin_laser": {
			"id": "upgrade_spin_laser", "name": "Helix Lazer+",
			"description": "Helix Lazer tur sayısı ve hasarı artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_spin_laser"], "tab": Tab.TEMEL
		},
		"upgrade_orbital_mayhem": {
			"id": "upgrade_orbital_mayhem", "name": "Orbital Mayhem+",
			"description": "Orbital Mayhem roket sayısı ve sandık şansı artar.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_orbital_mayhem"], "tab": Tab.TEMEL
		},
		"upgrade_magnetic_field": {
			"id": "upgrade_magnetic_field", "name": "Manyetik Alan+",
			"description": "Manyetik Alan cooldownu azalır.",
			"rarity": "rare", "category": "active_upgrade", "prerequisites": ["unlock_magnetic_field"], "tab": Tab.TEMEL
		},
	}


# ══════════════════════════════════════════════════════════════
# GRID LAYOUT
# ══════════════════════════════════════════════════════════════

func _build_layout() -> Dictionary:
	return {
		# Satır 0 — Pasifler (1. grup)
		"p_max_health":      {"row": 0, "col": 0},
		"p_fire_rate":       {"row": 0, "col": 1},
		"p_crit_chance":     {"row": 0, "col": 2},
		"p_crit_multiplier": {"row": 0, "col": 3},
		"p_move_speed":      {"row": 0, "col": 4},
		# Satır 1 — Pasifler (2. grup)
		"p_pickup_radius":   {"row": 1, "col": 0},
		"p_chest_luck":      {"row": 1, "col": 1},
		"p_fire_power":      {"row": 1, "col": 2},
		"p_vision_range":    {"row": 1, "col": 3},
		"p_armor":           {"row": 1, "col": 4},
		# Satır 2 — Mermi Efektleri
		"pa_electric_bullet":  {"row": 2, "col": 0},
		"pa_burning_bullet":   {"row": 2, "col": 2},
		"pa_explosive_bullet": {"row": 2, "col": 4},
		# Satır 3 — Aktif Skill Unlock
		"unlock_railgun":        {"row": 3, "col": 0},
		"unlock_rocket_blaster": {"row": 3, "col": 1},
		"unlock_octo_gun":       {"row": 3, "col": 2},
		"unlock_arc_blaster":    {"row": 3, "col": 3},
		"unlock_sonic_jumper":   {"row": 3, "col": 4},
		"unlock_blitz_bomb":     {"row": 3, "col": 5},
		"unlock_spin_laser":     {"row": 3, "col": 6},
		"unlock_orbital_mayhem": {"row": 3, "col": 7},
		"unlock_magnetic_field": {"row": 3, "col": 8},
		# Satır 4 — Aktif Skill Upgrade
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
# KATEGORİ BAŞLIKLARI
# ══════════════════════════════════════════════════════════════

func _build_categories() -> Dictionary:
	return {
		0: "PASSİF BONUSLAR",
		2: "MERMİ EFEKTLERİ",
		3: "AKTİF SKİLLER",
	}
