# FostercareTweaks

Required ClassicAPI version: **v1.15.15+**. This is the maintainer's published support baseline for this addon suite; it is not a claim that every API used here was introduced in v1.15.15. After replacing ClassicAPI.dll, fully restart WoW; `/reload` cannot reload a DLL.

[![Interface](https://img.shields.io/badge/Interface-1.12.1%20%28Build%205875%29-blue.svg)](https://github.com/Fostercare5988/FostercareTweaks)
[![Version](https://img.shields.io/badge/Version-3.1.0-brightgreen.svg)](https://github.com/Fostercare5988/FostercareTweaks)
[![Engine](https://img.shields.io/badge/Engine-ClassicAPI%20%7C%20SuperWoW%20%7C%20UnitXP%20SP3-orange.svg)](https://github.com/Fostercare5988/FostercareTweaks)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modular UI and quality-of-life addon for the **World of Warcraft 1.12.1 Enhanced Client Stack** (`ClassicAPI v1.15.15+`, `SuperWoW v2.2+`, and optional `UnitXP SP3`).

FostercareTweaks combines optional unit frames, enhancements to the original Blizzard frames, action bars, maps, tooltips and automation. It uses the enhanced client APIs where they provide the relevant state.

---

## What's New in v3.1

- **Modern Unit Frames (Player, Target & Raid)**: Native implementation inspired by Luna Unit Frames, styled with a clean 1px dark border, custom texture-clipped status bars (preventing stretching or shearing), class coloring, and UnitXP SP3 authoritative health telemetry.
- **40-Player Compact Raid Grid**: Full 8-group column layout (Groups 1–8) with compact Luna geometry (64×34px buttons), class-colored health, power bars, dead/ghost/offline indicators, health deficit formatting (`-1.2k`), dispel border coloring (Magic blue, Curse purple, Disease orange, Poison green via structured `C_UnitAuras`), range fading via native `UnitInRange`, leader/assistant/target icons, and interactive `/ft testraid` preview.
- **Floating Action Bar Polish**: Eliminated Blizzard's max-level 7px grey stone bar (`MainMenuBarMaxLevelBar`) at level 60, ensuring seamless floating action bars without interfering with reputation tracking.
- **Movable Frames with Saved Positions**: Drag-and-drop repositioning with an alignment grid for Player, Target, and Raid frames (unlocked by holding `Ctrl+Shift`), with coordinates persisted in SavedVariables across sessions.
- **Shared Aura Updates**: Unit frame aura duration text uses a shared native timer; range checks use a separate native timer. No measured performance guarantee is implied.

---

## Feature Overview

### 1. Action Bars
- **Floating Action Bar**: Removes stone background textures and max-level border art, letting action bars float cleanly above the game world. Full support for Reputation and XP tracking without background bleed.
- **Reagent Counters**: Live badge counters for class reagents (Flash Powder, Blinding Powder, Ankhs, Soul Shards, Runes, Candles, Feathers, Symbol of Kings) using structured spell metadata and item ID counts.
- **Cooldown Numbers**: Clean numeric countdown text on action bar cooldowns with mouse passthrough (`:EnableMouse(false)`) and 100ms update throttling.
- **Reduced Action Bar**: Compact action bar layout with toggleable floating bag bar and micromenu panels (movable via Shift+Ctrl).
- **Keybind Centering**: Horizontally centered right-side vertical action bars for streamlined ergonomics.

### 2. Unit Frames
- **Standard Blizzard Frames**: Separate player, target and target-of-target choices retain the original artwork. Standard frames are the default for new users; existing choices are preserved.
- **Improved Standard Auras**: Enhanced player/target buffs and debuffs with stack counts, accurate aura tooltips, optional duration text/sweeps and dispel borders. Missing remote expiration remains unknown. The global Blizzard buff strip is retained.
- **Independent Aura Movers**: Hold Ctrl+Shift to move a frame or its separate buff/debuff areas. Saved aura positions follow their owning frame and are not reset by aura updates.
- **Multiple Raid Buffs**: Four buffs by default. Under Raid Frames, choose 1–8 buffs or **Show All Buffs**, with 8–18 px icons. Narrow frames wrap the chosen buffs into extra rows below the player; each group expands only for occupied rows, without covering health/name text or the next player. All mode displays every helpful aura reported by the client and overrides the count slider.
- **Modern Player & Target Frames**: Luna-inspired unit frames with 1px dark borders, class coloring, 2D portraits, and UnitXP SP3 authoritative health numbers.
- **Optional Target Anchor API**: `FostercareTweaks.GetActiveTargetFrame()` returns the current target presentation for addons such as TWThreat.
- **Modern 40-Player Raid Grid**: 8-subgroup compact grid with class colors, power bars, health deficits, dispel highlights, range fading, and raid icons.
- **Interactive Raid Test Mode**: Toggle a full 40-player mock grid with `/ft testraid` to inspect and reposition raid frames anywhere on your screen.
- **Dynamic Movable Frames**: Hold Shift+Ctrl to unlock and drag player, target, and raid frames with an alignment grid and coordinate persistence.
- **Event-Driven Target Castbars**: Responsive casting and channeling bars with uninterruptible shield indicators.
- **Debuff Durations**: Displays remaining debuff duration spirals and text overlays on target debuff icons via `C_UnitAuras`.
- **Resource Ticks**: 2-second energy and 5-second mana regeneration tick spark indicators.

### 3. Nameplates
- **Event-Driven Binding**: Uses native `NAME_PLATE_*` events and `C_NamePlate` engine bindings with zero per-frame child scanning overhead.
- **Authoritative Class Colors**: Instant PvP player identification via direct unit token queries (`plate.unit`).
- **GUID-Linked Nameplate Castbars**: Live casting and channeling bars attached directly to enemy nameplates.
- **Live Scalability**: Proportional text and healthbar scaling synced to settings.

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
- **Tooltip Coexistence**: Vendor values are added after Blizzard item tooltip methods; Bagnon can add holdings lines in either addon load order.

### 6. Chat & Social
- **Hyperlink Handling & URL Copy**: Clickable web URLs with a modal copy dialog, CLINK resolution, and shift-clickable player names.
- **Chat History Retention**: Non-combat chat buffer persistence across UI reloads and character relogs.
- **Social List Colors**: Class-colored player names and last-seen dates across Who, Friends, and Guild rosters.
- **Timestamps & Mousewheel Scrolling**: Configurable chat timestamps and smooth mousewheel message history navigation.

### 7. General Tweaks
- **Hide Default Cast Bar**: Suppresses only Blizzard's player cast bar while keeping its cast events active; custom cast bars are unaffected.
- **Hide Stealth / Stance Bar**: Hides Blizzard's stance and shapeshift bar and restores it through the normal FrameXML update when disabled.
- **Auto Dismount**: Instantly dismounts or cancels shapeshift forms when attempting to cast spells or interact with flight masters.
- **Auto Stance**: Automatically switches to the required warrior or druid stance on ability activation.
- **Error Suppression**: Optional silent Lua error suppression for clean gameplay sessions.

Both bar options are in the **General** tab, default off, and apply without a UI reload. Former AutoBG preferences are not copied automatically because AutoBG saved one account-wide value while FostercareTweaks saves settings per character; set the desired value for each character here.

---

## Slash Commands & Shortcuts

Access settings at any time:
- `/ft`
- `/ftweaks`
- `/fostercaretweaks`
- `/ft testraid` or `/ft raidtest` — Toggle 40-player mock raid frame preview.
- `/ft ufreset` or `/ft resetuf` — Reset saved unit frame positions to defaults.

| Key Combination | Context | Action |
| :--- | :--- | :--- |
| `Shift` + `Ctrl` + Drag | Player / Target / Raid Frames and aura areas | Unlock drag handles and save positions. |
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
| **ClassicAPI** | `v1.15.15+` (Mandatory) | Modern C++ namespaces (`C_Item`, `C_Spell`, `C_UnitAuras`, `C_NamePlate`, `C_Timer`), `hooksecurefunc`, `UnitInRange`, `table.wipe`, and hardware timers. |
| **SuperWoW** | `v2.2+` (Mandatory) | Extended combat events (`UNIT_CASTEVENT`), GUID queries, `SetMouseoverUnit`, and combat inspection. |
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

ClassicAPI v1.15.15 compatibility: action type "equipmentset" is excluded from equipped-item/reagent-use tracking. The published support minimum is v1.15.15+; no native-set import or duplicate WEAR_EQUIPMENT_SET handler is added. Verify normal spell/item actions and a ClassicAPI equipment-set action in-game after updating the DLL and restarting WoW.

## Frame settings and testing

Under `/ft` > **Unit Frames** > **Top-right Blizzard Auras**, toggle **Show Standard Buffs**, **Show Standard Debuffs** and **Show Weapon Enchants** independently. They default to visible and apply immediately. These controls do not hide the enhanced auras beside the player frame.

With **Movable Unit Frames** enabled, hold **Ctrl+Shift** and drag each visible Blizzard aura area. Positions are saved independently per character. The grid and drag handles appear while either Ctrl and either Shift are held; movement can be enabled live in settings. Aura refreshes preserve an active drag, then reconcile the current layout on drop. **Reset Frame Positions** (or `/ft resetuf`) also resets these areas. To move a hidden area, enable it first. Native icons, tooltips, buff cancellation and enchant countdowns are retained. See [implementation and runtime checklist](docs/STANDARD_AURA_CONTROLS_2026-09-27.md).

Open `/ft uf`. Standard Blizzard Frames and Modern Unit Frames have separate
sections; each unit can use only one presentation. Buff/debuff controls apply to
the active player/target presentation. Presentation and aura settings save live;
Close does not undo them. The Shared Frame Features reload button applies modules
that are enabled at login, such as health numbers, class portraits and energy ticks.

Standard target aura rows align to the right and grow left, matching the target's
right-side portrait; player rows grow right. Both fit eight icons before wrapping.
Icons and timer text stay upright. Default target rows leave room beneath the
native target-of-target and FT castbar. Your moved buff/debuff areas are retained;
older target positions convert once to a stable right edge so changing aura counts
does not shift the row sideways. Use Ctrl+Shift to adjust either area.

Open `/ft raid` for raid buff count/size, row dimensions, spacing and scale.
Use `/ft testraid` to preview the full grid. The old HoT corner is a separate
indicator, not a replacement for the multiple-buff row. Modern player/target
scale does not change raid scale.

After `/reload`, test dragging, buff removal, own-debuff filtering and changing
raid dimensions at your actual UI scale. Headless tests do not verify rendering.
Run `python -B tests/test_frames.py <directory-containing-lupa>` for Lua 5.1
mock regressions. See [frame review](docs/FRAME_REVIEW_2026-09-27.md).
