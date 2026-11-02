# FostercareTweaks User Guide

Configuration and controls for **FostercareTweaks**.

Open the settings with `/ft`, or from **Game Menu > AddOn Options >
FostercareTweaks**. The window has five pages: **General**, **Unit Frames**,
**Auras**, **Raid** and **Action Bars**. `/ft uf`, `/ft auras`, `/ft raid` and
`/ft bars` open a page directly; `/ft testraid` shows sample raid frames.

Every change saves at once. A feature that can only start or stop with a fresh
interface shows a **Reload UI** button; click it when ready. Hover any switch
for a short explanation; a dimmed control waits for the switch above it.

---

## General

- **Gameplay**: **Dismount to attack, fly, talk** dismounts or leaves your form
  when you attack, take a flight, talk to an NPC or use an item. **Switch stance
  for spells** changes a warrior's stance or a druid's form when a spell needs
  it. Hide the stance bar.
- **Dismount, leave form, stand up when casting** are ClassicAPI settings:
  **Game Menu > AddOn Options > ClassicAPI**. They dismount and cast on the same
  press, when the cast can go off.
- **Always on**: sell prices on item tooltips (times the stack), **Shift** to
  compare with what you wear, quality borders in bags, bank, character and
  inspect, a **Sell Junk** button at merchants (walking away cancels unsent
  sales), copyable web links in chat, and coordinates and class-colored group
  members on the world map.
- **Minimap**: a 24-hour clock, a square minimap, tidy buttons and wheel zoom.
- **Chat**: wheel scrolling and sticky channels, history restored after a
  reload, timestamps (not in the combat log), class-colored names and blue
  shamans.
  Classes come from ClassicAPI, which knows your group, nearby players, friends
  and everyone seen this session. To remember players between sessions, turn on
  the player cache in **AddOn Options > ClassicAPI**.
- **World map**: for a map window, use the minimize button on the map (the
  game's own windowed map).
  **Map window size** sets its size; so does **Ctrl + mouse wheel** on the map.

## Unit Frames

These improve Blizzard's player, target and pet frames.

- **Class colors behind names**. Exact **health numbers** are always shown
  (they hide when the target dies, under Blizzard's "Dead").
- **Ctrl+Shift moves things**: hold both keys to show handles on the frames, aura
  areas, raid frames and minimap pieces, and drag them. Action bars move with
  **Move bars** on the Action Bars page. **Reset all positions** puts them back
  after a reload; `/ft resetuf` does both at once.
- **Target castbar**: your target's casts under its frame; grey when they cannot
  be interrupted. Hold Ctrl+Shift to move it; it follows the target frame.
- **Your cast bar**: hold Ctrl+Shift to move it off the action bars.
- **No castbar borders**: removes the border art from your cast bar and the target's (needs a reload).
- **Raid marks**: their size on the target and raid frames, and on the
  portrait or beside the frame. When you are not in a group, the raid mark keys
  set marks only you can see.
- **Energy ticks**: estimated energy ticks and the five-second mana rule on your
  power bar, with an optional bright line and a flash at each tick. The line
  runs even when the bar is full; it finds the server's tick at the first gain
  and flashes from then on. With NamPower, spell gains are left out of the
  estimate.

## Auras

- **Player and target**: buffs and debuffs under the player and target frames,
  with sweeps, countdowns and dispel colors (also on the raid frames). Choose
  which rows show, and the icon sizes.
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
  (without the bag and game menu buttons), centered right-side bars and reagent
  counts (how many casts your reagents allow). Cooldowns always count down on
  the buttons, in the auras' look: tenths in red under 5 seconds.
- **Bars**: one row per bar, with its switch to show it and its size. **More**
  opens the rest under the row: **Buttons per row** (12 is a row, 1 a column),
  **Spacing**, **Show empty buttons**, **Fill bottom to top** and **Reset this
  bar** (keeps its actions). Changing a bar turns on **Custom layouts**; off
  puts every bar back in the game's layout.
- **Move bars** shows a handle on each bar; drag it, then click again or close
  the window to lock. Not in combat.
- **Extra 1** shows action page 2 (slots 13 to 24). **Extra 2 to 7** hold their
  own spells and items: drop a spell or item on an empty button out of combat
  with the game's action bar lock off. Drag between these rows to move or swap;
  **Shift + right-click** clears one. Macros stay on the normal bars. Bind keys
  under **FostercareTweaks Action Bars** in Key Bindings.
