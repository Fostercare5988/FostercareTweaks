# FostercareTweaks

A modular interface and quality-of-life add-on suite for World of Warcraft 1.12.1.

## Features

- **Unit Frames & Raid Grid**: Choose between enhanced standard Blizzard frames or clean modern unit frames (Player, Target, Target-of-Target). Includes a compact 40-player raid grid with class coloring, health deficits, dispel highlights, and configurable buff indicators.
- **Action Bars & Cooldowns**: Optional floating action bar layout, available-cast counters for spells consuming reagents, clean numeric cooldown text, and centered right action bars.
- **Nameplates**: Direct class-colored health bars and responsive nameplate castbars tied to enemy casting states.
- **World Map & Minimap**: Resizable, windowed world map with mousewheel zoom and opacity controls, live player/cursor coordinates, square minimap, and hovering 24-hour clock.
- **Items & Tooltips**: One-click merchant junk seller, bag/bank item quality borders, side-by-side equipment comparison, and native vendor sell values on tooltips.
- **Chat & Social**: Clickable URL links with a modal copy dialog, non-combat chat history retention across reloads, class-colored Who/Friends/Guild rosters, and configurable timestamps.
- **Automation Tweaks**: Automatic dismount and stance switching, optional suppression of default cast or stance bars, and error message filtering.

## Requirements

- **World of Warcraft 1.12.1** (Build 5875)
- [ClassicAPI v1.15.15+](https://github.com/brues-code/ClassicAPI) (`ClassicAPI.dll`)
- [SuperWoW v2.2+](https://github.com/balakethelock/SuperWoW) (`SuperWoWhook.dll` / `SuperWoWlauncher.exe`)
- *Optional:* [UnitXP SP3](https://codeberg.org/konaka/UnitXP_SP3) (`UnitXP_SP3.dll`) for authoritative health readings.

> Note: Completely restart the game client after installing or updating DLLs. `/reload` cannot reload DLLs.

## Installation

1. Copy or clone this repository into your WoW add-on directory:
   ```text
   World of Warcraft/Interface/AddOns/FostercareTweaks/
   ```
2. Verify that `FostercareTweaks.toc` is located directly at `Interface/AddOns/FostercareTweaks/FostercareTweaks.toc`.
3. Launch WoW using the SuperWoW launcher.
4. Ensure FostercareTweaks is checked on the character selection AddOn screen.
5. Type `/ft` in game to access the configuration panel.

## Commands & Shortcuts

| Command | Description |
| :--- | :--- |
| `/ft` / `/ftweaks` | Open main configuration panel |
| `/ft testraid` | Toggle 40-player mock raid frame preview |
| `/ft resetuf` | Reset unit frame positions to defaults |

| Shortcut | Context | Action |
| :--- | :--- | :--- |
| `Shift` + `Ctrl` + Drag | Unit Frames & Auras | Unlock drag handles and reposition frames |
| `Shift` + `Ctrl` + Drag | Bag Bar / Micro Menu | Reposition reduced action bar panels |
| `Shift` + Hover Item | Bags / Bank / Inventory | Open side-by-side equipment comparison |
| `Ctrl` + Mousewheel | World Map Window | Adjust map scale |
| `Shift` + Mousewheel | World Map Window | Adjust map opacity |
| Mousewheel | Chat Frames | Scroll chat history (`Shift` jumps to top/bottom) |
| Mousewheel | MiniMap | Zoom minimap in / out |

## Limitations & Notes

- **Standard Frame Class Colors**: When using standard Blizzard frames, player and target name backgrounds use permanent class coloring. This design choice is always enabled.
- **Sell Junk Queue**: Selling grey items operates via native merchant queue commands without capturing your cursor. Closing or walking away from the merchant cancels any remaining pending sales.
- **Aura Durations**: Debuff and buff cooldown sweeps only appear when duration telemetry is available to the client.
- **Reagent Counters**: Counts show how many casts your carried reagents support. Macro buttons need a spell identified by the client; re-save older macros if their spell is not identified.

---

For detailed configuration, customization options, and layout controls, see the [User Guide](docs/USER_GUIDE.md).

Maintained by [Fostercare5988](https://github.com/Fostercare5988).
