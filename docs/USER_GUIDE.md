# FostercareTweaks User Guide

Configuration and controls for **FostercareTweaks 1.0.0**.

Open `/ft` for one settings window with four pages: **General**, **Unit Frames**,
**Raid Frames** and **Action Bars**. Charcoal sections, white labels and teal
selection marks distinguish controls and the active page. `/ft uf`, `/ft raid`
and `/ft bars` open the corresponding page directly.

---

## 1. Frame Movement & Positioning

- **Unlocking Drag Handles**: Hold **Shift + Ctrl** to reveal movement handles and the alignment grid on supported frames (Player, Target, Target-of-Target, Raid frames, and individual aura clusters).
- **Repositioning**: While holding **Shift + Ctrl**, click and drag the frame or aura container to your desired location.
- **Saving Positions**: Positions are automatically persisted per character upon releasing the drag handle.
- **Resetting Positions**: Type `/ft resetuf` or click **Reset Frame Positions** in `/ft` to restore default screen coordinates.

---

## 2. Unit Frames & Auras

### Frame Styles
Configure your preferred style under `/ft uf`:
- **Standard Blizzard Frames**: Retains native interactions, optional class-colored name backgrounds, green Blizzard health bars, health numbers and enhanced aura timers.
- **Modern Unit Frames**: Luna-inspired clean layout featuring 1px dark borders, class coloring and 2D portraits. Health uses native SuperWoW values.
- Each **Modern Player / Target / Target's Target** checkbox selects that frame's style; unchecked uses Blizzard. Existing dimensions, scale, power-bar height and fonts apply live. Fonts shrink to their available lane; names truncate before covering health. Tall, narrow frames limit portrait width. Power numbers hide below an 8 px bar height.
- Choose name, class/creature type and level visibility independently. Health and power offer **Smart**, **Current**, **Percent** and **Hidden**. Smart omits an unnecessary maximum and uses current energy/rage; Percent remains a percentage for every resource. Level badges use native difficulty colors; unknown-level bosses use the native skull.
- **Raid Target Marks** controls unit-frame and nameplate sizes separately. Target marks fit above the level badge or sit beside the portrait. Raid marks reserve a column; native nameplate marks sit beside the health bar or above the name. ShaguPlates retains its own presentation.
- **Enemy Castbars** follows the selected target-frame style and applies live. On modern targets it sits below occupied debuff rows; cast events update state while the bar animates smoothly.

### Aura Controls & Borders
- **Aura Border Toggles**: Under `/ft` > **Unit Frames** > **Blizzard & Frame Aura Borders**, toggle borders for Buffs, Debuffs, and Weapon Enchants independently:
  - Buff & Debuff borders default to off.
  - Weapon enchant borders default to on, colored by the equipped weapon's item quality.
  - Debuff borders show dispel type colors (Magic blue, Curse purple, Disease orange, Poison green) when enabled.
- **Top-Right Blizzard Auras**: Independently toggle visibility for the standard top-right buff icons, debuff icons, and weapon enchant icons under `/ft` > **Unit Frames** > **Top-right Blizzard Auras**.
- **Target Debuff Filtering**: The option **Only Show My Debuffs on Target** filters out other players' debuffs when player attribution is known.
- **Larger Armor Debuffs** optionally enlarges Sunder Armor, Faerie Fire (including Feral) and Expose Armor by 1.25–2x, default 1.5x. Verified ranks and deployed NPC/custom variants share this behavior. Mixed-size rows wrap within the target width and preserve native aura order, stacks, tooltips, timers and your own-debuff filter. Standard frames need **Improved Standard Auras** for this layout.
- Sweeps and duration text are independent for buffs and debuffs. Missing timing stays unknown; the addon does not invent durations.

### Raid Grid
- **Layout & Sizing**: Open `/ft raid` to configure row height, width, scale, and spacing.
- **Group Labels**: Show or hide G1–G8 / Party. Hidden labels reclaim the header space, including in previews and after roster updates.
- **Aura Indicators**: Buffs and debuffs share one strip inside each member frame. Set separate sizes/counts and a shared gap. Default requests are four 10 px buffs, three 11 px debuffs and a 2 px gap. Icons shrink vertically on small frames; the minimum-height layout is a dense overview. Use larger member frames for readable stack and timer detail.
- **Priority & Overflow**: Debuffs with a dispel type come before other debuffs. Buff priority is recognized HoTs/shields, player/pet buffs, then other buffs; ties keep native aura order. Capacity gives debuffs priority while reserving a buff when both fit. The strip draws buffs, then debuffs. `+N` counts eligible icons that did not fit; nothing extends into another member frame.
- **Show All Buffs** considers every available buff and includes overflow in `+N`. Turning it off restores your saved 1–8 buff limit. Count limits intentionally exclude lower-priority candidates. Individual icons retain tooltips, stacks, available durations and the member frame's click actions.
- Small stacked indicators show stacks and the sweep; remaining seconds move into the tooltip to avoid overlapping labels. Larger indicators can show both labels.
- **Preview**: Type `/ft testraid` to display a 40-player mock raid frame to test your layout and positioning.
- **Aggro Indicator**: The red corner updates while the group frame is visible.
  An available Banzai or threat provider keeps its own semantics. Without one,
  the indicator follows the current enemy's target; it does not reveal the
  targets of every enemy.

### Resource Spark
Under `/ft uf` > **Energy Tick Visibility**, **Bright Tick Line** adds a white center and glow. **Flash on Tick** gives the bottom edge a bright white pulse at the end of each estimated tick, fading over 0.25 seconds. Both default to on. **Tick Line Width** adjusts the center from 2–6 px (default 3); the bar limits every part of the marker. Turn off the bright line to use the soft white spark, or disable the flash independently. These choices apply live and survive reloads. Mana spending starts the five-second sweep without flashing; its completion flashes.

The spark stays entirely inside the active player power bar and follows its scale. It resets on world entry, death and resource-type changes. Energy spending does not restart its two-second phase. With NamPower v4.6.2+, structured spell gains are subtracted from nearby resource updates; otherwise plausible regeneration amounts and phase are used. Full bars cannot reveal new tick timing. Server batching, capped/coalesced gains, unreported effects or custom regeneration can make this estimate imperfect.

After a large timing shift, two regularly spaced ticks resynchronize the estimate. Turning the feature off stops the animation; turning it back on uses the last observed phase.

Mana losses start an estimated five-second rule; small mana gains during that interval do not cancel it. The countdown returns to a two-second phase and pulses at its end; spending itself does not flash. Resource telemetry does not distinguish mana spending from every drain. Rage/focus have no regeneration spark.

---

## 3. Items, Tooltips & Automation

- **Sell Junk**: Adds a dedicated button to the merchant window to automatically queue and sell all grey items. The queue uses native client merchant operations without taking over your cursor. Closing or walking away from the vendor safely cancels any unsent sales.
- **Item Quality Borders**: Displays color-coded rarity borders on items in bags, the bank, character sheet, and inspect frame. Missing item data refreshes when the client cache fills; empty slots clear their previous color. Item-data and inspect-slot bursts share one deferred refresh of the current visible views.
- **Equipment Comparison**: Hold **Shift** while hovering over an equippable item in your bags or bank to view a side-by-side comparison with your currently equipped gear.
- **Vendor Values**: Shows cached sell prices on item tooltips, multiplied by the displayed stack when its count is available. A cache miss refreshes the current tooltip when item data arrives.

---

## 4. World Map & Minimap

- **Windowed World Map**: Converts the full-screen world map into an adjustable floating window.
  - **Ctrl + Mousewheel**: Adjust window scale from 30% to 150%. The scale is retained when reopening the map during the current session.
  - **Shift + Mousewheel**: Adjust map window opacity from 20% to 100%.
  - Press **ESC** or your map toggle key to close.
- **Coordinates & Roster Blips**: Live player and cursor coordinates appear at the bottom of the map, and party/raid members show as class-colored circular icons on the world map and battlefield minimap. Player coordinates refer to the displayed map and show `N/A` when no position is available there.
- **Square Minimap & Clock**: Modern square minimap with mousewheel zooming, plus a 24-hour clock displaying local and server times on mouseover.

---

## 5. Action Bars & General Tweaks

Open **`/ft bars`** or the **Action Bars** tab. Your current appearance and layout
remain the starting point; **Enable custom layouts** turns on the layout editor.
Select Main / Stealth, either bottom bar, either side bar, or Extra Rows 1–7.

- Set **Buttons per row**: 12 makes a horizontal row, 6 makes two rows, and 1
  makes a vertical column. All twelve buttons remain available.
- Buttons fill from left to right. **Bottom to top** makes successive rows grow
  upward; leave it unchecked to grow downward.
- Adjust **Size** (50–200%) and **Spacing** (0–20 px) independently for each bar.
- Select **Unlock bar handles**, drag the lavender handles, then lock them.
  Closing the menu or entering combat also locks them. Layouts save per character.
- **Show this bar** controls additional bars. The main bar follows native main /
  stealth visibility. **Show empty buttons** makes unused slots visible.
- **Extra Row 1** exposes the twelve existing actions on normal page 2 (slots
  13–24). Selecting page 2 on the main bar displays these same actions.
- **Extra Rows 2–7** each add twelve independent spell or item
  actions. Their contents save per character through ClassicAPI and do not
  alias native main, stealth or stance pages. New rows default to hidden; your
  existing choices are kept. Choose **Show this bar** for each row you want.
  Empty buttons show by default.
- Assign extra-row keys under **FostercareTweaks Action Bars** in the game's
  **Key Bindings** window. Existing bindings are kept; no keys are assigned automatically.
- **Reset this bar's layout** resets only the selected layout. Turning off custom
  layouts restores the prior native layout. Neither operation clears actions or bindings.

To arrange **Extra Rows 2–7**, finish moving the bars and lock their lavender
handles. Turn off **Lock Action Bars** in the game's options and leave combat.
Drag a player spell or item from its normal interface onto an
**empty** extra button. Passive and pet spells are not accepted. A native cursor
drop onto an occupied extra button is refused; move or clear that extra action
first.

Drag an assigned action between Extra Rows 2–7 to move it into an empty button
or swap it with another assigned action. Shift-click can also start this internal
move. Drop outside those six rows or press Escape to cancel. These internal moves
do not pick up inventory items or export actions onto native bars. **Shift +
right-click** clears an extra button without deleting the spell or item.
The game lock and combat guard apply to imports, moves, swaps and clearing.

Extra Rows 2–7 accept **spells and items only**. Macro imports are refused without
clearing your cursor: the installed ClassicAPI independent-button macro runner
cannot reliably preserve all macro control flow. Keep macros on native bars,
including Extra Row 1, where their execution remains unchanged. Unavailable
spells or items keep their saved assignment and do not silently execute a
different action.

Native bars, including Extra Row 1, retain their normal pickup/drop behavior.
Rogue stealth paging, tooltips, cooldown numbers and reagent counts remain
supported. Pet/stance bars retain their existing native controls. Layout changes
are available out of combat. The appearance toggles below continue to control the
minimalist style.

- **Floating Action Bar**: Removes the heavy stone background textures and max-level border art from the primary action bar for a lightweight floating aesthetic.
- **Reagent Counters**: Action buttons show available casts based on all reagent requirements and the reagents you carry. Bank items do not count. Spell actions and identified macros on native bars are supported; re-save older native-bar macros if their spell is not identified. Item stack counts retain their normal display.
- **Cooldown Numbers**: Clean numeric countdown text on action bar and bag cooldowns. GearRack uses its own counters when enabled; otherwise FostercareTweaks supplies the numbers. GearRack option changes apply immediately, including open flyouts. Equipment swaps and queues remain owned by GearRack.
- **Auto Dismount & Stance**: Automatically dismounts or cancels shapeshift forms after a mount/form restriction. A warrior or druid form restriction selects the first usable required stance or form.
- **Hide Bars**: Easily hide the Blizzard player cast bar or shapeshift/stance bar under `/ft` without breaking cast events.

## 6. Chat

- **Chat History**: Keeps the last 30 messages per supported chat window and restores them on login or reload, retaining their original timestamp when timestamps were enabled.
- **Chat Timestamps**: Optional timestamps apply to new messages, with configurable brackets, clock format and color.
- **Chat Hyperlinks**: Copy website addresses, including at the start of a message. Existing item, player and quest links retain their original behavior.
