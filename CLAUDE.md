# FostercareTweaks

Action bars, unit and raid frames and many interface tweaks. Player guide:
`docs/USER_GUIDE.md`. Regression tests: `regressions/FostercareTweaks` in
VanillaForge (21 tests).

| Area | Files |
| --- | --- |
| Core | `Core.lua` (module registry `FT:register`), `Helpers.lua`, `SettingsWidgets.lua`, `Options.lua` |
| Action bars | `ActionBars.lua`, `ExtraActions.lua` (extra rows 2-7), `ActionBarOptions.lua`, `mods/actionbar-*.lua`, `mods/cooldown-numbers.lua`, `mods/reduced-actionbar.lua` |
| Unit frames | `mods/unitframes/` (core, auras, player, target, tot, raid, native-group), `mods/unitframe*.lua`, `mods/health-numbers.lua`, `mods/target-*.lua`, `mods/raid-target-marks.lua`, `UnitFrameOptions.lua`, `RaidFrameOptions.lua` |
| World and minimap | `mods/worldmap-window.lua`, `mods/minimap-tweaks.lua` |
| Bags and items | `mods/vendor-values.lua`, `mods/sell-junk.lua`, `mods/item-colors.lua`, `mods/equip-compare.lua` |
| Chat | `mods/chat-tweaks.lua`, `mods/chat-class-colors.lua` |
| Gameplay | `mods/gameplay.lua`, `mods/blue-shaman.lua`, `mods/custom.lua` |

Things to know:

- Each `mods/` file registers one module with `FT:register({ title, category,
  enabled })` and an `enable` function. The load order is the TOC.
- On 2026-10-21 the stutter profiler showed no FostercareTweaks handler over
  5 ms during dungeon and battleground play, and under 1 ms per second overall.
