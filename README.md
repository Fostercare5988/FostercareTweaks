# FostercareTweaks

[![Interface](https://img.shields.io/badge/Interface-1.12.1%20%28Build%205875%29-blue.svg)](https://github.com/Fostercare5988/FostercareTweaks)
[![Version](https://img.shields.io/badge/Version-3.0.0-brightgreen.svg)](https://github.com/Fostercare5988/FostercareTweaks)
[![Engine](https://img.shields.io/badge/Engine-ClassicAPI%20%7C%20SuperWoW%20%7C%20UnitXP%20SP3-orange.svg)](https://github.com/Fostercare5988/FostercareTweaks)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A high-performance, modular UI modernization and quality-of-life suite engineered natively for the **World of Warcraft 1.12.1 Enhanced Client Stack** (`ClassicAPI v1.15.8+`, `SuperWoW v2.2+`, and optional `UnitXP SP3`).

FostercareTweaks consolidates, streamlines, and modernizes features formerly split across separate tweak packs into a cohesive, standalone package. All legacy 2006 workarounds—such as active target-swapping loops, 330 KB static price tables, hidden tooltip text scraping, and destructive global API overwrites—have been replaced with native engine capabilities, structured APIs, and non-intrusive event pipelines.

---

## What's New in v3.0

- **Zero Static Price Tables**: Removed ~4,000 lines (330 KB) of hardcoded vendor pricing data. Replaced with native `C_Item.GetItemSellPrice` and `GetItemSellPriceByID`, backed by a lazy-caching metatable for full backwards compatibility.
- **Anti-Pattern Elimination**: Eradicated the legacy `TargetByName` / `ClearTarget` active unit-scanning loop. Unit class and level resolution is now 100% passive and event-driven.
- **Event-Driven Castbars**: Detached target castbars from continuous per-frame `OnUpdate` polling. Castbars are now driven by `UNIT_SPELLCAST_*`, `UNIT_CASTEVENT`, and `PLAYER_TARGET_CHANGED`, with rendering throttled strictly to active in-flight casts.
- **Modern Nameplate Lifecycle**: Bound nameplate management directly to `NAME_PLATE_CREATED`, `NAME_PLATE_UNIT_ADDED`, and `NAME_PLATE_UNIT_REMOVED` events. Correlates nameplates to unit tokens (`nameplate1`, etc.) for zero-guesswork class coloring and cast tracking.
- **Structured Reagent Tracking**: Eliminated hidden `GameTooltip` text scraping in favor of `GetActionInfo` and `C_Spell.GetSpellReagents(spellID)` with direct `C_Item.GetItemCount` item ID queries.
- **Non-Destructive Hooking Pipeline**: 100% converted from global function reassignment to engine-native `hooksecurefunc` across all status bar, unit frame, layout, and inspect modules.
- **In-Place Palette Preservation**: Mutates `RAID_CLASS_COLORS["SHAMAN"]` in place to preserve global table identity and prevent breaking third-party addon references.
- **Native Dismount & Form Cancellation**: Integrated `Dismount()` and `CancelShapeshiftForm()` primitives, short-circuiting 0..31 buff texture scanning.

---

## Feature Overview

### 1. Action Bars
- **Floating Action Bar**: Removes stone background textures and lets action bars float cleanly above the game world.
- **Reagent Counters**: Live badge counters for class reagents (Flash Powder, Blinding Powder, Ankhs, Soul Shards, Runes, Candles, Feathers, Symbol of Kings) using structured spell metadata and item ID counts.
- **Cooldown Numbers**: Clean numeric countdown text on action bar cooldowns with mouse passthrough (`:EnableMouse(false)`) and 100ms update throttling.
- **Reduced Action Bar**: Compact action bar layout with toggleable floating bag bar and micromenu panels (movable via Shift+Ctrl).
- **Keybind Centering**: Horizontally centered right-side vertical action bars for streamlined ergonomics.

### 2. Unit Frames
- **True Health Numbers**: Displays authoritative current/max health numbers and percentages powered directly by `UnitXP("health", unit)` or native SuperWoW APIs without heuristic guessing.
- **Class Colors & Portraits**: Dynamic class-colored status bars, name backgrounds, and optional circular class badge portraits.
- **Dynamic Movable Frames**: Hold Shift+Ctrl to unlock and drag player and target frames with an alignment grid.
- **Event-Driven Target Castbars**: Responsive casting and channeling bars with uninterruptible shield indicators.
- **Debuff Durations**: Displays remaining debuff duration spirals and text overlays on target debuff icons via `C_UnitAuras`.
- **Resource Ticks**: 2-second energy and 5-second mana regeneration tick spark indicators.

### 3. Nameplates
- **Event-Driven Binding**: Uses native `NAME_PLATE_*` events and `C_NamePlate` engine bindings with zero per-frame child scanning overhead.
- **Authoritative Class Colors**: Instant PvP player identification via direct unit token queries (`plate.unit`).
- **GUID-Linked Nameplate Castbars**: Live casting and channeling bars attached directly to enemy nameplates.
- **UI-Scale Awareness**: Automatic nameplate scaling matching custom UI scale preferences.

### 4. World & MiniMap
- **Windowed World Map**: Converts the world map into a movable, scalable window with Ctrl+Mousewheel zoom, Shift+Mousewheel opacity control, and ESC-to-close (`UISpecialFrames`).
- **Live Coordinates**: Throttled player and cursor coordinates on the world map with diff caching.
- **Map Class Indicators**: Displays party and raid members as class-colored circular blips on both world and battlefield maps.
- **Square MiniMap**: Bordered square minimap replacement with mouse wheel zoom.
- **MiniMap Clock**: 24-hour clock displaying local and server time on hover, driven by hardware tickers.

### 5. Items & Tooltips
- **One-Click Junk Seller**: Merchant button to automatically sell all grey items with instant summary confirmation.
- **Item Quality Borders**: Color-coded rarity borders across inventory bags, bank, character sheet, inspect window, and temporary weapon enchants.
- **Equipment Comparison**: Side-by-side gear comparison tooltips when holding Shift.
- **Native Vendor Values**: Displays item sell prices directly on tooltips via `C_Item.GetItemSellPrice` without external databases.

### 6. Chat & Social
- **Hyperlink Handling & URL Copy**: Clickable web URLs with a modal copy dialog, CLINK resolution, and shift-clickable player names.
- **Chat History Retention**: Non-combat chat buffer persistence across UI reloads and character relogs.
- **Social List Colors**: Class-colored player names and last-seen dates across Who, Friends, and Guild rosters.
- **Timestamps & Mousewheel Scrolling**: Configurable chat timestamps and smooth mousewheel message history navigation.

### 7. General Tweaks
- **Auto Dismount**: Instantly dismounts or cancels shapeshift forms when attempting to cast spells or interact with flight masters.
- **Auto Stance**: Automatically switches to the required warrior or druid stance on ability activation.
- **Error Suppression**: Optional silent Lua error suppression for clean gameplay sessions.

---

## Slash Commands & Shortcuts

Access settings at any time:
- `/ft`
- `/ftweaks`
- `/fostercaretweaks`

| Key Combination | Context | Action |
| :--- | :--- | :--- |
| `Shift` + `Ctrl` + Drag | Player / Target Frames | Unlock and drag unit frames (shows alignment grid). |
| `Shift` + `Ctrl` + Drag | Bag Bar / Micro Menu | Reposition reduced action bar panels. |
| `Shift` + Hover Item | Bag / Inventory | Open side-by-side equipment comparison tooltip. |
| `Ctrl` + Mousewheel | World Map Window | Adjust world map scale. |
| `Shift` + Mousewheel | World Map Window | Adjust world map opacity. |
| Mousewheel | Chat Frames | Scroll chat history up/down (`Shift` to jump to top/bottom). |
| Mousewheel | MiniMap | Zoom in / zoom out. |

---

## Requirements & Compatibility

| Component | Status | Purpose |
| :--- | :--- | :--- |
| **ClassicAPI** | `v1.15.8+` (Mandatory) | Modern C++ namespaces (`C_Item`, `C_Spell`, `C_UnitAuras`, `C_NamePlate`, `C_Timer`), `hooksecurefunc`, and hardware timers. |
| **SuperWoW** | `v2.2+` (Mandatory) | Extended combat events (`UNIT_CASTEVENT`), GUID queries, and combat inspection. |
| **UnitXP SP3** | `v90+` (Optional) | Authoritative unit health values via `UnitXP("health", unit)`. |

---

## Installation

1. Download or clone this repository.
2. Place the `FostercareTweaks` folder into your World of Warcraft directory under `Interface\AddOns\`:
   ```text
   World of Warcraft\Interface\AddOns\FostercareTweaks\
   ```
3. Ensure both `ClassicAPI.dll` and `SuperWoW.dll` are enabled in your client loader.
4. Launch the game and type `/ft` to configure your preferred modules.
