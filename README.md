# FostercareTweaks

Customizable action bars, unit frames and interface improvements for World of
Warcraft 1.12.1.

## Features

- Minimalist action bars with adjustable rows, growth direction, scale and spacing.
- Seven optional extra rows, with individual visibility and key bindings.
- Optional modern player, target, target-of-target and raid frames.
- Aura timers, enemy castbars, resource tick estimates and raid markers.
- Blizzard-style nameplates with adjustable size, native raid marks, target emphasis,
  health text, your debuffs, crowd control, combo points and enemy cooldown estimates.
- Item quality borders, equipment comparisons, vendor values and a sell-junk button.
- Windowed world map, square minimap, chat history, timestamps and clickable URLs.

## Requirements

WoW 1.12.1 build 5875, **ClassicAPI 1.15.15+** and **SuperWoW 2.2+**.
NamPower 4.6.2+ enables enemy nameplate cooldown estimates and improves resource-tick attribution when available.

## Installation

Download the current code using **Code → Download ZIP** on
[GitHub](https://github.com/Fostercare5988/FostercareTweaks), or choose a packaged build from
[Releases](https://github.com/Fostercare5988/FostercareTweaks/releases/latest).
Extract and rename the addon folder to `FostercareTweaks` inside `Interface/AddOns`. Enable it in the game's
AddOns list and launch through your DLL loader.

The folder must contain `Interface/AddOns/FostercareTweaks/FostercareTweaks.toc`.

## Configuration

Open **`/ft`** for five pages: **General**, **Unit Frames**, **Raid Frames**,
**Action Bars** and **Nameplates**. White labels, charcoal sections and teal selection marks make
the controls easier to distinguish. `/ft uf`, `/ft raid` and `/ft bars` open
the matching page directly. **`/ft nameplates`** opens nameplate settings.
General has fixed section headings. Unit Frames and Raid Frames have focused
section buttons. General changes use **Apply**; the other pages save each change
immediately. Changes requiring a reload show an explicit **Reload UI** button.

In **Nameplates**, use the live preview to adjust plate size independently of global
UI scale, target enlargement, opacity and castbar proportions. Names and levels keep
their original font size and native parent. Move native
raid marks left, right or above the name. Enable health text, your debuffs, one crowd-control
effect, optional enemy buffs, combo points and an optional **Targeting you** label.
**Use FostercareTweaks nameplate features** switches all of this addon's nameplate
features on or off after restarting the game. Off leaves ordinary Blizzard plates
and the independent target-frame castbar available, without this addon's plate
hooks, cast queries or nameplate feature events. Your individual choices are kept;
the nameplate reset button does not change this switch.
Other controls and module toggles apply immediately while enabled. Existing size settings migrate
once to preserve their base appearance; other enable choices are kept.
BlizzNameplatesPlus and ShaguPlates retain ownership when loaded.

The target-frame castbar and nameplate castbars are separate views within this
addon. Keep either or both enabled; their controls identify the view they affect.

Health and aura changes use batched unit events. Aura countdowns run at 5 Hz only
while timed rows are visible; resolved classes are cached and idle casts reconcile
at 5 Hz. Cast animation and native color/mark/opacity repair remain smooth at render
rate. Native clicks and mouseover stay intact.

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
