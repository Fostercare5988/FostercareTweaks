# Tweaks

Small interface improvements for World of Warcraft 1.12.1: item tooltips, the
merchant, chat, the minimap, the world map and stances.

## Features

- **Item tooltips:** the sell price of an item, times its stack (bags, bank,
  loot, mail, quests, trade, merchant, auction, links); hold Shift to compare it
  with what you wear.
- **Quality borders** on character and inspect slots.
- **Sell Junk** button at merchants.
- **Chat:** arrow keys without Alt, web addresses you can copy, Shift-click a
  name into the chat box, the last 30 lines back after a reload or login,
  timestamps, and names in class colour (shamans blue everywhere).
- **Minimap:** size, square shape, a 24-hour clock, the clutter buttons hidden,
  mouse-wheel zoom; Ctrl+Shift moves the map, the zone name, the clock and the
  mail, battleground and tracking icons.
- **World map:** the window's size (also Ctrl+mouse wheel), your and the
  cursor's coordinates, group members in class colours.
- **Auto Stance** (warriors and druids): a spell that needs another stance or
  form switches to it.

Every feature has a switch on its page in AddOn Options; `/ft` opens it.

## Requirements

WoW 1.12.1 (build 5875) with **[ClassicAPI](https://github.com/brues-code/ClassicAPI)** loaded.

## Installation

Download `Tweaks.zip` from the
[latest release](https://github.com/Fostercare5988/Tweaks/releases/latest),
extract it into `Interface/AddOns` and enable it in the game's AddOns list. The
folder must contain `Interface/AddOns/Tweaks/Tweaks.toc`.

## Related addons

Version 1.0.0 is a rebuild. The unit frames, auras and watched auras of the old
Tweaks are now
[UnitFrames](https://github.com/Fostercare5988/UnitFrames), the party
and raid grid is [RaidFrames](https://github.com/Fostercare5988/RaidFrames),
and the action bars belong to ActionBars.
