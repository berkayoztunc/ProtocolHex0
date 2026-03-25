# LEVEL SELECT PAGE

## 1. Overview

The Level Select screen (`level_select.tscn` / `level_select.gd`) is the gateway between
the Start Menu and an active run. Players choose a sector (zone) before entering combat.
The screen is **built entirely in GDScript** — no child nodes exist in the .tscn file.

Flow:
```
Start Menu → [Play] → Level Select → [Giriş] → Main (game)
Start Menu → [Play] → Level Select → [← Geri] → Start Menu
```

---

## 2. Current Zones (4)

| ID       | Display Name   | LVL | unlock_requires_zone | Required Items                              | Description                                         |
|----------|----------------|-----|----------------------|---------------------------------------------|-----------------------------------------------------|
| zone_1   | Sector Alpha   | 1   | *(none — always unlocked)*  | nano_cores:5, energy_cells:3         | İlk sektör. Temel kaynaklar toplanabilir.          |
| zone_2   | Sector Beta    | 2   | zone_1               | nano_cores:8, energy_cells:6, power_shards:4 | Tehlike artıyor. Gelişmiş düşmanlar aktif.        |
| zone_3   | Sector Gamma   | 3   | zone_2               | nano_cores:12, energy_cells:10, power_shards:8 | Yüksek taktik gerektirir. Elite spawner aktif.  |
| zone_4   | Sector Delta   | 4   | zone_3               | nano_cores:18, energy_cells:15, power_shards:14, data_cores:6 | Son bilinen sektör. Tüm düşman tipleri aktif. |

All zones are currently **visually accessible** regardless of lock state (lock badge shown
but `Giriş` is never disabled). Hard unlock gating will be added later.

---

## 3. Future Roadmap — 250 Levels

GeniHero targets 250 playable levels organized into themed sectors. Planned structure:

| Zone range | Theme                | Difficulty tier |
|-----------|----------------------|-----------------|
| zone_1–4  | Sector Alpha–Delta   | Beginner        |
| zone_5–20 | Industrial Ruins     | Intermediate    |
| zone_21–50| Corrupted Network    | Advanced        |
| zone_51+  | Deep Core / Unknown  | Expert          |

Each zone will be a named entry in `config_service.gd`'s `"zones"` dictionary.
The Level Select UI is designed to grow automatically — adding a `zone_id` to `ZONE_IDS`
in `level_select.gd` and a matching dict entry in config is all that's needed.

---

## 4. Level Card Format Specification

Each card is a **300 × 400 px PanelContainer**:

```
┌─────────────────────────────┐  ← StyleBoxFlat, 3px border (zone color), 8px radius
│ 🔒 LOCKED  (if locked)      │
│                             │
│         LVL 2               │  ← 52px, zone color
│       Sector Beta           │  ← 18px, white
│ ──────────────────────────  │  ← HSeparator, zone color
│ Tehlike artıyor. Gelişmiş   │  ← 13px, light gray, word-wrapped
│ düşmanlar aktif.            │
│                             │
│  Required item types: 3     │  ← 12px, muted gray
│                             │
│   ┌─────────────────────┐   │
│   │      Giriş →        │   │  ← 16px, zone-tinted button
│   └─────────────────────┘   │
└─────────────────────────────┘
```

Card gap: **20 px** between cards.
Card stride: **320 px** (300 + 20).

---

## 5. Unlock Criteria

### Current (simplified)
- All zones unlocked for entry — lock badge is cosmetic only.

### Planned (future implementation)
A zone is unlocked when its `unlock_requires_zone` chain is satisfied:
- `zone_1` — always unlocked (`unlock_requires_zone: ""`).
- `zone_N` — unlocked if the previous zone has a recorded completion
  (e.g., `Session.base_perk_levels` has any entry, or a dedicated
  `Session.completed_zones: Array[String]` is added).

To implement hard gating, change `_build_card` to set
`enter_btn.disabled = is_locked` and show an unlock tooltip.

---

## 6. Visual Design Spec

| Zone   | Border & accent color | Hex (approx) |
|--------|-----------------------|--------------|
| zone_1 | Teal                  | `#33CCBB`    |
| zone_2 | Yellow                | `#E6CC1A`    |
| zone_3 | Orange                | `#E6801A`    |
| zone_4 | Red                   | `#CC1A1A`    |

- Background: `Color(0.07, 0.07, 0.10)` — near-black blue-grey
- Card body: `Color(0.10, 0.10, 0.14)` — dark slightly-blue panel
- Title text: `Color.WHITE`
- Description text: `Color(0.85, 0.85, 0.85)`
- Muted info text: `Color(0.60, 0.60, 0.60)`

Arrow nav buttons (< >) are anchored to the vertical center of the left/right edges.
Back button anchored bottom-left.

---

## 7. Difficulty Progression

| Zone         | Enemy variety       | Special spawns                         | Resource weight |
|--------------|---------------------|----------------------------------------|-----------------|
| Sector Alpha | Basic, Runner       | None                                   | 1.0×            |
| Sector Beta  | + Brute, Charger    | None                                   | 1.3×            |
| Sector Gamma | + Elite, Skirmisher | Elite spawner active                   | 1.6×            |
| Sector Delta | All enemy types     | Full mix; Juggernaut, Sniper, Mortar   | 2.0×            |

Difficulty multipliers (`meta_resource_spawn_weight`) are defined in
`config_service.gd` under `zones.<zone_id>.meta_resource_spawn_weight`.

---

## 8. How to Add New Zones

### Step 1 — Add zone data to `config_service.gd`

In the `"zones"` block, append:

```gdscript
"zone_5": {
    "display_name": "Sector Epsilon",
    "level": 5,
    "unlock_requires_zone": "zone_4",
    "required_items": {"nano_cores": 25, "energy_cells": 20, "power_shards": 18, "data_cores": 10},
    "meta_resource_spawn_weight": 2.5,
    "description": "Industrial ruins overrun by corrupted units."
},
```

### Step 2 — Register in `level_select.gd`

```gdscript
const ZONE_IDS: Array[String] = ["zone_1", "zone_2", "zone_3", "zone_4", "zone_5"]
const ZONE_COLORS: Array[Color] = [
    Color(0.2, 0.8, 0.7),
    Color(0.9, 0.8, 0.1),
    Color(0.9, 0.5, 0.1),
    Color(0.8, 0.1, 0.1),
    Color(0.5, 0.2, 0.9),  # zone_5 purple
]
```

That's it — the card is auto-built and the scroll layout adjusts automatically.

### Step 3 — (Optional) Enemy / spawn config

Update wave spawn tables and difficulty parameters for the new zone in the relevant
game manager config entries.

---

## 9. Technical Implementation Notes

- **Programmatic UI**: No child nodes live in `level_select.tscn`. The entire scene is
  constructed in `_build_ui()` called from `_ready()`. This avoids .tscn merge conflicts
  and keeps the layout logic co-located with behavior.

- **Horizontal scroll via Tween**: `_snap_to_index(index, animated)` moves `_cards_container`
  along the X axis using `Tween.TRANS_CUBIC / EASE_OUT` with a 0.25 s duration.

- **Drag handling**: `_gui_input` on the root Control captures `InputEventMouseButton` and
  `InputEventMouseMotion`. A drag is committed only when movement exceeds `DRAG_THRESHOLD`
  (10 px) to prevent accidental swipes blocking button clicks.

- **Card centering**: Target X for the container is computed as:
  `(viewport_width * 0.5) − (index * CARD_STRIDE) − (CARD_WIDTH * 0.5)`

- **Session integration**: On `Giriş`, the script calls:
  1. `Session.set_current_zone(zone_id)` — stores zone, persists to disk.
  2. `Session.start_new_run(Session.player_name)` — resets run state.
  3. `get_tree().change_scene_to_file("res://scenes/main.tscn")` — enters the game.

- **Files**:
  - Script: `res://scripts/ui/level_select.gd`
  - Scene: `res://scenes/level_select.tscn`
  - Zone data source: `res://scripts/autoload/config_service.gd` → `"zones"` block
  - Session methods: `res://scripts/autoload/session.gd`
