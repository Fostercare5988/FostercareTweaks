# FostercareTweaks

Customizable action bars, unit frames and interface improvements for World of
Warcraft 1.12.1.

## Features

- Minimalist action bars with adjustable rows, growth direction, scale and spacing.
- Seven optional extra rows, with individual visibility and key bindings.
- Optional modern player, target, target-of-target and raid frames.
- Aura timers, enemy castbars, resource tick estimates and raid markers.
- Item quality borders, equipment comparisons, vendor values and a sell-junk button.
- Windowed world map, square minimap, chat history, timestamps and clickable URLs.

## Requirements

WoW 1.12.1 build 5875, **ClassicAPI 1.15.15+** and **SuperWoW 2.2+**.
NamPower 4.6.2+ improves resource-tick attribution when available.

## Installation

Download the current code using **Code → Download ZIP** on
[GitHub](https://github.com/Fostercare5988/FostercareTweaks).
Extract and rename the addon folder to `FostercareTweaks` inside `Interface/AddOns`. Enable it in the game's
AddOns list and launch through your DLL loader.

The folder must contain `Interface/AddOns/FostercareTweaks/FostercareTweaks.toc`.

## Configuration

Open **`/ft`** for four pages: **General**, **Unit Frames**, **Raid Frames**,
**Action Bars**. White labels, charcoal sections and teal selection marks make
the controls easier to distinguish. `/ft uf`, `/ft raid` and `/ft bars` open
the matching page directly.
General has fixed section headings. Unit Frames and Raid Frames have focused
section buttons. General changes use **Apply**; the other pages save each change
immediately. Changes requiring a reload show an explicit **Reload UI** button.

Nameplate features are provided by the independent
[FostercareNameplates](https://github.com/Fostercare5988/FostercareNameplates)
addon. FostercareTweaks contains no nameplate hooks, cast queries, timers or settings.
Your existing nameplate preferences remain available for that addon's first import.
The target-frame castbar stays here under **Unit Frames > Combat details**.
Either addon can be enabled independently.

In **Raid Frames**, **Use FostercareTweaks party and raid frames** gives this addon
control of the group grid. The built-in compact group grid is hidden and its
native group/member updates are paused. Turning the switch off returns control
to the game's frame settings, keeping your native compact-grid preference.
The test grid temporarily takes the same ownership. On clients with the built-in
compact grid, repeated world entries reuse its frame lists instead of appending
duplicate references. This integration adds no polling timer.

**Chat Class Colors** colors player names in chat. Friends, Guild and Who keep
the game's built-in list colors; this addon no longer recolors those lists.
Your previous Social Colors switch carries over to the chat setting.

Under **Unit Frames**, **Clear Raid Target Marks** enables mark support after
Reload UI; mark size and placement apply live. All four pages scroll, and the
window adjusts to the available UI height.

In **Action Bars**, enable custom layouts, select a bar and adjust its buttons
per row, upward growth, size and spacing. Unlock the handles to position bars,
then lock them again. Configure layouts out of combat. Existing bindings are
kept; assign additional keys under **FostercareTweaks Action Bars** in the game's
Key Bindings window.

**Extra Row 1** displays native page 2, slots 13–24. **Extra Rows 2–7** provide
independent spell and item actions through ClassicAPI. These six rows accept
spells and items; keep macros on native bars. New rows start hidden.

The updated **ActionBarProfiles** addon can save and restore actions in all
seven extra rows. `/abp save <name>` includes hidden and empty rows; `/abp load
<name>` restores actions while keeping layouts, visibility and bindings. Save
older ActionBarProfiles profiles again to include Extra Rows 2–7. Both addons
need this integration. Finish extra-row drags and release extra-row keys before
loading; missing player spells or items stop the load before native bars change.

Hold **Shift + Ctrl** to move supported unit frames and aura containers.
Use **`/ft testraid`** to preview the raid layout.

See the [user guide](docs/USER_GUIDE.md) for action placement, frame settings,
shortcuts and feature details.
