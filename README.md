# FostercareTweaks

Customizable action bars, unit frames and interface improvements for World of
Warcraft 1.12.1.

## Features

- Minimalist action bars with adjustable rows, growth direction, scale and spacing.
- Seven optional extra rows, with individual visibility and key bindings.
- Optional modern player, target, target-of-target and raid frames.
- Aura timers, enemy castbars, resource tick estimates and raid markers.
- Adjustable nameplate size, raid marks and observed enemy-player cooldown estimates.
- Item quality borders, equipment comparisons, vendor values and a sell-junk button.
- Windowed world map, square minimap, chat history, timestamps and clickable URLs.

## Requirements

WoW 1.12.1 build 5875, **ClassicAPI 1.15.15+** and **SuperWoW 2.2+**.
NamPower 4.6.2+ enables enemy nameplate cooldown estimates and improves resource-tick attribution when available.

## Installation

Download `FostercareTweaks-1.0.0.zip` from
[Releases](https://github.com/Fostercare5988/FostercareTweaks/releases/latest)
and extract `FostercareTweaks` into `Interface/AddOns`. Enable it in the game's
AddOns list and launch through your DLL loader.

The folder must contain `Interface/AddOns/FostercareTweaks/FostercareTweaks.toc`.

## Configuration

Open **`/ft`** for five pages: **General**, **Unit Frames**, **Raid Frames**,
**Action Bars** and **Nameplates**. White labels, charcoal sections and teal selection marks make
the controls easier to distinguish. `/ft uf`, `/ft raid` and `/ft bars` open
the matching page directly. **`/ft nameplates`** opens nameplate settings.

In **Nameplates**, set plate size, mark size/position and cooldown icon size,
count, minimum duration and spacing. Existing nameplate enable choices are kept;
changes to plate-size support, class colors or castbar enable switches need Reload UI.
Cooldown estimates toggle immediately. ShaguPlates retains ownership when loaded.

Under **Unit Frames**, **Clear Raid Target Marks** enables mark support after
Reload UI; mark size and placement apply live. All five pages scroll, and the
window adjusts to the available UI height.

Enemy cooldown icons appear only after an observed enemy player's cast or channel.
Their `~` timers use base cooldowns from your current client spell data. Talents,
resets, delayed cooldown starts and server changes can alter the real cooldown.
Item-only cooldowns, pets and abilities you did not observe are outside this feature.
Icons disappearing means the estimate ended; it does not prove an ability is ready.

In **Action Bars**, enable custom layouts, select a bar and adjust its buttons
per row, upward growth, size and spacing. Unlock the handles to position bars,
then lock them again. Configure layouts out of combat. Existing bindings are
kept; assign additional keys under **FostercareTweaks Action Bars** in the game's
Key Bindings window.

**Extra Row 1** displays native page 2, slots 13–24. **Extra Rows 2–7** provide
independent spell and item actions through ClassicAPI. These six rows accept
spells and items; keep macros on native bars. New rows start hidden.

Hold **Shift + Ctrl** to move supported unit frames and aura containers.
Use **`/ft testraid`** to preview the raid layout.

See the [user guide](docs/USER_GUIDE.md) for action placement, frame settings,
shortcuts and feature details.
