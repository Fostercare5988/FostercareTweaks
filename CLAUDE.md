# FostercareTweaks

Action bars, unit and raid frames and many interface tweaks. Player guide:
`docs/USER_GUIDE.md`. Regression tests: `regressions/FostercareTweaks` in
VanillaForge (32 tests).

| Area | Files |
| --- | --- |
| Core | `Core.lua` (module registry `FT:register`, `/ft`), `Helpers.lua` |
| Settings | `Settings.lua` (one ForgeUI window, five tabs, AddOn Options entry), `ForgeUI.lua` and `Media/` (VanillaForge kit, copied unchanged) |
| Action bars | `ActionBars.lua`, `ExtraActions.lua` (extra rows 2-7), `mods/actionbar-*.lua`, `mods/cooldown-numbers.lua`, `mods/reduced-actionbar.lua` |
| Unit frames | `mods/unitframes/` (core: shared settings, colors, bars; auras: improved auras on Blizzard frames and raid icons; raid; native-group), `mods/unitframe*.lua`, `mods/health-numbers.lua`, `mods/target-*.lua`, `mods/raid-target-marks.lua` |
| World and minimap | `mods/worldmap-window.lua`, `mods/minimap-tweaks.lua` |
| Bags and items | `mods/vendor-values.lua`, `mods/sell-junk.lua`, `mods/item-colors.lua`, `mods/equip-compare.lua` |
| Chat | `mods/chat-tweaks.lua`, `mods/chat-class-colors.lua` |
| Gameplay | `mods/gameplay.lua`, `mods/blue-shaman.lua`, `mods/custom.lua` |

Things to know:

- The player, target and pet frames are Blizzard's; FostercareTweaks only
  improves them. The Modern replacement frames were removed on 2026-10-25
  (no character used them); `FT.MigrateFrameSettings` clears their settings.
- Bars (`UF:CreateBar`) are native StatusBars; ClassicAPI supplies reverse
  fill and fill styles.
- Each `mods/` file registers one module with `FT:register({ title, category,
  enabled })` and an `enable` function. The load order is the TOC.
- Settings: each control saves at once and calls the module's live update;
  a module without one marks the window as needing a reload. Controls refresh
  through the `syncs` list; never write settings from a refresh.
- Raid buttons click through ClassicAPI unit attributes (`SetUnit` in
  raid.lua: `unit`, `type1` target, `type2` menu). Aura badges on them keep
  their own click handler so their tooltips stay.
- Solo, `SetRaidTargetIcon` sets NamPower local marks (raid-target-marks.lua).
- Lua 5.0 collects garbage in one full pass (about 100 ms at 60 MB). Code that
  runs on a timer must not build strings or tables each tick.
- On 2026-10-21 the stutter profiler showed no FostercareTweaks handler over
  5 ms during dungeon and battleground play, and under 1 ms per second overall.
