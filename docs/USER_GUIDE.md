# FostercareTweaks User Guide

Detailed configuration, frame controls, and module reference for **FostercareTweaks**.

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
- **Standard Blizzard Frames**: Retains the authentic Blizzard look while adding class coloring, accurate health numbers, and enhanced aura timers. Standard player and target name backgrounds use a fixed class color palette.
- **Modern Unit Frames**: Luna-inspired clean layout featuring 1px dark borders, class coloring, 2D portraits, and authoritative health numbers via UnitXP SP3.

### Aura Controls & Borders
- **Aura Border Toggles**: Under `/ft` > **Unit Frames** > **Blizzard & Frame Aura Borders**, toggle borders for Buffs, Debuffs, and Weapon Enchants independently:
  - Buff & Debuff borders default to off.
  - Weapon enchant borders default to on, colored by the equipped weapon's item quality.
  - Debuff borders show dispel type colors (Magic blue, Curse purple, Disease orange, Poison green) when enabled.
- **Top-Right Blizzard Auras**: Independently toggle visibility for the standard top-right buff icons, debuff icons, and weapon enchant icons under `/ft` > **Unit Frames** > **Top-right Blizzard Auras**.
- **Target Debuff Filtering**: The option **Only Show My Debuffs on Target** filters out other players' debuffs when player attribution is known.

### Raid Grid
- **Layout & Sizing**: Open `/ft raid` to configure row height, width, scale, and spacing.
- **Buff Displays**: Choose between 1 and 8 visible buffs per player or select **Show All Buffs**. Icons wrap neatly below the unit box without obstructing adjacent frames.
- **Preview**: Type `/ft testraid` to display a 40-player mock raid frame to test your layout and positioning.

---

## 3. Items, Tooltips & Automation

- **Sell Junk**: Adds a dedicated button to the merchant window to automatically queue and sell all grey items. The queue uses native client merchant operations without taking over your cursor. Closing or walking away from the vendor safely cancels any unsent sales.
- **Item Quality Borders**: Displays color-coded rarity borders on items in bags, the bank, character sheet, and inspect frame.
- **Equipment Comparison**: Hold **Shift** while hovering over an equippable item in your bags or bank to view a side-by-side comparison with your currently equipped gear.
- **Vendor Values**: Shows exact sell prices directly on item tooltips using native API calls.

---

## 4. World Map & Minimap

- **Windowed World Map**: Converts the full-screen world map into an adjustable floating window.
  - **Ctrl + Mousewheel**: Zoom the map in and out.
  - **Shift + Mousewheel**: Adjust map window transparency.
  - Press **ESC** or your map toggle key to close.
- **Coordinates & Roster Blips**: Live player and cursor coordinates appear at the bottom of the map, and party/raid members show as class-colored circular icons.
- **Square Minimap & Clock**: Modern square minimap with mousewheel zooming, plus a 24-hour clock displaying local and server times on mouseover.

---

## 5. Action Bars & General Tweaks

- **Floating Action Bar**: Removes the heavy stone background textures and max-level border art from the primary action bar for a lightweight floating aesthetic.
- **Reagent Counters**: Real-time badge counters on action bar buttons showing remaining counts for class reagents (Flash Powder, Ankhs, Soul Shards, Runes, etc.).
- **Cooldown Numbers**: Clean numeric countdown text on action bar cooldowns.
- **Auto Dismount & Stance**: Automatically dismounts or cancels shapeshift forms when casting or speaking to flight masters, and switches stances automatically on ability activation.
- **Hide Bars**: Easily hide the Blizzard player cast bar or shapeshift/stance bar under `/ft` without breaking cast events.
