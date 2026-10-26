# FostercareTweaks User Guide

Configuration and controls for **FostercareTweaks 1.5.0**.

Open the settings with `/ft`, or from **Game Menu > AddOn Options >
FostercareTweaks**. The window has five pages: **General**, **Unit Frames**,
**Auras**, **Raid** and **Action Bars**. `/ft uf`, `/ft auras`, `/ft raid` and
`/ft bars` open a page directly.

Every change saves at once. A feature that can only start or stop with a fresh
interface shows a **Reload UI** button; click it when ready. Hover any switch
for a short explanation; a dimmed control waits for the switch above it.

---

## General

- **Gameplay**: **Switch stance for spells** changes a warrior's stance or a
  druid's form when a spell needs it. Hide the stance bar.
- **Dismount, leave form, stand up when casting** are ClassicAPI settings:
  **Game Menu > AddOn Options > ClassicAPI**. Characters that had Auto Dismount
  on get them turned on once.
- **Items**: sell prices on tooltips (times the stack), **Shift** to compare
  with what you wear, quality borders in bags, bank, character and inspect, and
  a **Sell Junk** button at merchants. Walking away cancels unsent sales.
- **Minimap**: a 24-hour clock, a square minimap, tidy buttons and wheel zoom.
- **Chat**: wheel scrolling and sticky channels, copyable web links, history
  restored after a reload, timestamps, class-colored names and blue shamans.
  Classes come from ClassicAPI, which knows your group, nearby players, friends
  and everyone seen this session. To remember players between sessions, turn on
  the player cache in **AddOn Options > ClassicAPI**.
- **World map**: a movable map window (**Ctrl + wheel** resizes, **Shift +
  wheel** fades), coordinates, and group members in class colors.

## Unit Frames

These improve Blizzard's player, target and pet frames.

- **Class colors behind names**, exact **health numbers** (they hide when the
  target dies, under Blizzard's "Dead").
- **Move with Ctrl+Shift**: hold both keys to show handles on the frames, aura
  areas and raid frames, and drag them. **Reset positions** puts them back after
  a reload; `/ft resetuf` does both at once.
- **Target castbar**: your target's casts under its frame; grey when they cannot
  be interrupted.
- **Raid marks**: bigger marks on the target frame and raid frames, on the
  portrait or beside the frame. When you are not in a group, the raid mark keys
  set marks only you can see.
- **Energy ticks**: estimated energy ticks and the five-second mana rule on your
  power bar, with an optional bright line and a flash at each tick. With
  NamPower, spell gains are left out of the estimate.

## Auras

- **Improved auras** under the player and target frames: sweeps, countdowns and
  dispel colors. Choose player/target buffs and debuffs and icon sizes.
  **Timers on Blizzard debuffs** is for when the improved auras are off.
- **Timers**: sweeps, countdowns and dispel colors also apply to the raid frames.
- **Top right of the screen**: show or hide Blizzard's buffs, debuffs and weapon
  enchants; **Ctrl+Shift** moves them.
- **Borders** for buffs, debuffs and weapon enchants (the weapon's quality color).

## Raid

One grid serves both parties and raids.

- **Use these frames** replaces the party frames and the game's raid frames.
  Turning it off gives them back.
- **Clicking**: left-click targets a member (or casts the spell you have ready on
  them); right-click opens their menu.
- **Health text**: missing health, percent or current health.
- **Indicators**: an aggro corner on the member your enemy target is attacking,
  a heal-over-time corner and debuff icons (dispellable ones first).
- **Buffs**: heals and your own buffs first; **Every buff** shows all that fit.
  `+N` counts icons that did not fit.
- **Size**: width, height, scale and gaps; icon sizes and counts.
- **Test grid** shows 40 sample members; **Reset raid settings** keeps the
  frames' position.

## Action Bars

- **Look**: hide the gryphons, remove the bar background, a short main bar
  (without the bag and game menu buttons), centered right-side bars, cooldown
  numbers and reagent counts (how many casts your reagents allow).
- **Custom layouts** lets you move and reshape bars. Off keeps the game's layout.
- **Move bars** shows a handle on each bar; drag it, then click again or close
  the window to lock. Not in combat.
- Pick a bar on the right, then set **Show this bar**, **Show empty buttons**,
  **Fill bottom to top**, **Buttons per row** (12 is a row, 1 a column), **Size**
  and **Spacing**. **Reset this bar** keeps its actions.
- **Extra 1** shows action page 2 (slots 13 to 24). **Extra 2 to 7** hold their
  own spells and items: drop a spell or item on an empty button out of combat
  with the game's action bar lock off. Drag between these rows to move or swap;
  **Shift + right-click** clears one. Macros stay on the normal bars. Bind keys
  under **FostercareTweaks Action Bars** in Key Bindings.
