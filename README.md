# FostercareTweaks

Action bars, Blizzard unit-frame improvements, party and raid frames and many
interface tweaks for World of Warcraft 1.12.1.

## Features

- Action bars you can move and reshape, plus seven extra rows with key bindings.
- Party and raid frames with click targeting, aura icons, aggro and heal corners.
- Improved auras, class colors, health numbers, target castbar, raid marks and
  energy ticks on Blizzard's player and target frames.
- Item quality borders, equipment comparison, sell prices and a Sell Junk button.
- Windowed world map, square minimap, chat history, timestamps and copyable links.

## Requirements

WoW 1.12.1 build 5875 with **ClassicAPI 1.17.9+**, **SuperWoW 2.2+**, **NamPower 4.6.2+**
and **UnitXP SP3 v89+** loaded.

FostercareTweaks leaves to ClassicAPI what ClassicAPI does: dismounting when you
cast (its AddOn Options; FostercareTweaks covers attacks, flights, NPCs and
items), remembering players' classes (its player cache) and the raid frames'
click actions.

## Installation

Download the current code using **Code > Download ZIP** on
[GitHub](https://github.com/Fostercare5988/FostercareTweaks). Extract it, rename
the folder to `FostercareTweaks` inside `Interface/AddOns` and enable it in the
game's AddOns list. The folder must contain
`Interface/AddOns/FostercareTweaks/FostercareTweaks.toc`.

## Settings

Type **`/ft`**, or open **Game Menu > AddOn Options > FostercareTweaks**. Five
pages: **General**, **Unit Frames**, **Auras**, **Raid** and **Action Bars**.
Changes save at once; a **Reload UI** button appears when one needs it.
Hold **Ctrl+Shift** to move frames, and use **`/ft testraid`** to preview the raid
frames.

Nameplates are a separate addon,
[FostercareNameplates](https://github.com/Fostercare5988/FostercareNameplates).

The **ActionBarProfiles** addon saves and restores the actions in all seven extra
rows (`/abp save <name>`, `/abp load <name>`).

See the [user guide](docs/USER_GUIDE.md) for every setting.
