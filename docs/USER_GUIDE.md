# FostercareTweaks User Guide

Configuration and controls for **FostercareTweaks**.

Open the settings with `/ft`, or in **Game Menu > AddOn Options**: expand
**FostercareTweaks** for its six pages, **General**, **Frames**, **Auras**,
**Watched**, **Raid** and **Bars** (the same pages as the `/ft` window). `/ft frames`,
`/ft auras`, `/ft watched`, `/ft raid` and `/ft bars` open a page directly;
`/ft testraid` shows sample raid frames.

| Page | What is on it |
| --- | --- |
| General | Gameplay, minimap, chat, world map |
| Frames | The player and target frames, cast bars, raid marks, energy ticks |
| Auras | Every list of buffs and debuffs, one heading per place on screen |
| Watched | The auras you pick by name, each with its own icon |
| Raid | The party and raid frames: size, health text, corner marks |
| Bars | The action bars |

Every change saves at once. Most apply at once too; a feature that can only start
or stop with a fresh interface shows a **Reload UI** button; click it when ready.
Hover any switch for a short explanation; a dimmed control waits for the switch
above it.

---

## General

- **Gameplay**: **Switch stance for spells** changes a warrior's stance or a
  druid's form when a spell needs it. Hide the stance bar.
- **Always on**: sell prices on item tooltips (times the stack), **Shift** to
  compare with what you wear, quality borders in bags, bank, character and
  inspect, a **Sell Junk** button at merchants (walking away cancels unsent
  sales), copyable web links in chat, and coordinates and class-colored group
  members on the world map. A quest link clicked in chat shows the quest's
  title and objectives.
- **Minimap**: a 24-hour clock, a square minimap, tidy buttons and wheel zoom.
- **Chat**: wheel scrolling (Shift: to the top or bottom) and arrow-key message
  history, history restored after a
  reload, timestamps (not in the combat log), class-colored names and blue
  shamans.
  Classes come from ClassicAPI, which knows your group, nearby players, friends
  and everyone seen this session. To remember players between sessions, turn on
  the player cache in **AddOn Options > ClassicAPI**.
- **World map**: for a map window, use the minimize button on the map (the
  game's own windowed map).
  **Map window size** sets its size; so does **Ctrl + mouse wheel** on the map.

## Frames

These improve Blizzard's player, target and pet frames. Their buffs and debuffs
are on the Auras page.

- **Class colors behind names**. Exact **health numbers** are always shown
  (they hide when the target dies, under Blizzard's "Dead").
- **Ctrl+Shift moves things**: hold both keys to show handles on the frames, aura
  areas, raid frames and minimap pieces, and drag them. Action bars move with
  **Move bars** on the Bars page. **Reset all positions** puts them back
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

Every list of buffs and debuffs is here, under a heading for the place it
shows on screen.

- **Under the player frame** and **Under the target frame**: buffs and debuffs
  with sweeps, countdowns and dispel colors. **Icon size under the frames**
  sets their size.
- **Top right of the screen**: show or hide Blizzard's buffs, debuffs and weapon
  enchants; **Ctrl+Shift** moves them. Each weapon shows the icon of its poison,
  oil or imbue (the poison from your bags, else its spell), main hand on the
  left and off hand on the right; hover it for the weapon.
- **Borders, everywhere**: borders for buffs, debuffs and weapon enchants (the
  weapon's quality color), in every list.
- **On raid members**: buff and debuff icons inside each member of the raid
  frames, how many, their size and the gap between them. Heals and your own
  buffs come first; **Every buff** shows all that fit, and `+N` counts icons
  that did not fit. Dispellable debuffs come first. **Test grid** shows sample
  members to judge the sizes. These are dimmed while the raid frames are off.

## Watched

- Type a spell's name (or ID) and click **Add your buff** or
  **Add target debuff**. Each gets its own icon with the time left, shown while
  the aura is up, in front of unit frames and bars. A new icon starts in a row
  above your character; hold **Ctrl+Shift** to move it.
- A watched aura leaves the lists on the Auras page, so it shows once. The list
  is a grid; click an aura for its card. **Own icon**, **Top right**
  (Blizzard's buffs, for your buffs) and **Player row** / **Target row** choose
  where it shows: at first only its own icon. Turn the icon off too to hide an
  aura everywhere.
- Target debuffs count only yours unless you turn **Only mine** off. With
  **Only mine**, another player's debuff of the same name stays in the target row.
- **Cooldown** (your buffs, on at first): when the buff ends,
  its icon stays greyed with the spell's cooldown until it is ready, such as
  Stealth after you leave it. **Remove** takes it off the list.

## Raid

One grid serves both parties and raids.

- **Use these frames** replaces the party frames and the game's raid frames.
  Turning it off gives them back.
- **Clicking**: left-click targets a member (or casts the spell you have ready on
  them); right-click opens their menu.
- **Health text**: missing health, percent or current health.
- **Corner marks**: an aggro corner on the member your enemy target is
  attacking, and a heal-over-time corner.
- **Size**: width, height, scale and gaps.
- The buff and debuff icons on members are on the Auras page.
- **Test grid** shows 40 sample members; **Reset raid settings** puts the frames
  and their icons back to the defaults and keeps the frames' position.

## Bars

- **Look**: hide the gryphons, remove the bar background, a short main bar
  (without the bag and game menu buttons) and reagent
  counts (how many casts your reagents allow). Cooldowns count down on the
  buttons in the auras' look (tenths in red under 5 seconds) while the game's
  cooldown numbers are on (ClassicAPI's `countdownForCooldowns`).
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
