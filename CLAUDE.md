# FostercareTweaks

Action bars, unit and raid frames and many interface tweaks. Player guide:
`docs/USER_GUIDE.md`. Regression tests: `regressions/FostercareTweaks` in
VanillaForge (187 tests).

| Area | Files |
| --- | --- |
| Core | `Core.lua` (module registry `FT:register`, `/ft`), `Helpers.lua` |
| Settings | `Settings.lua` (one ForgeUI window, five tabs, AddOn Options entry), `ForgeUI.lua` and `Media/` (VanillaForge kit, copied unchanged) |
| Action bars | `ActionBars.lua`, `ExtraActions.lua` (extra rows 2-7), `mods/actionbar-*.lua`, `mods/cooldown-numbers.lua`, `mods/reduced-actionbar.lua` |
| Unit frames | `mods/unitframes/` (core: shared settings, colors, bars; auras: improved auras on Blizzard frames and raid icons; raid; native-group), `mods/unitframe*.lua`, `mods/health-numbers.lua`, `mods/target-*.lua`, `mods/raid-target-marks.lua` |
| World and minimap | `mods/worldmap-window.lua`, `mods/minimap-tweaks.lua` |
| Bags and items | `mods/vendor-values.lua`, `mods/sell-junk.lua`, `mods/item-colors.lua`, `mods/equip-compare.lua` |
| Chat | `mods/chat-tweaks.lua` |
| Gameplay | `mods/gameplay.lua` (Auto Dismount, Auto Stance, stance bar), `mods/blue-shaman.lua` |

Things to know:

- The player, target and pet frames are Blizzard's; FostercareTweaks only
  improves them. The Modern replacement frames were removed on 2026-10-25
  (no character used them); `FT.MigrateFrameSettings` clears their settings.
- Bars (`UF:CreateBar`) are native StatusBars; ClassicAPI supplies reverse
  fill and fill styles.
- Each `mods/` file registers its modules with `FT:register({ title, enabled })`
  (or `always = true`: no switch, no saved key) and an `enable` function. The
  load order is the TOC. Settings.lua holds the labels and tooltips.
- Always on since 2026-11-02 (all ten characters had them on): Sell Junk,
  Vendor Values, Item Rarity Borders, Equip Compare, Chat Hyperlinks, WorldMap
  Coordinates and Class Colors, Real Health Numbers, Clear Raid Target Marks.
  Core clears their saved switches. `/ft` opens the window or a page;
  `testraid` and `resetuf` are the only other commands.
- Layouts by zone (Profiles.lua): the live settings hold the active layout
  (`profile`: world, bg, instance); `profiles` stores the others. A switch
  captures the layout keys, loads the next record and re-applies bars, frame
  positions (`FT.RestoreFramePositions`: saved spot or `fctHome`, then each
  mover's `onRestore`), raid frames, aura sizes, minimap and marks. A new layout
  key belongs in Profiles.lua's lists; the extra rows' actions stay shared.
- Settings: each control saves at once and calls the module's live update;
  a module without one marks the window as needing a reload. Controls refresh
  through the `syncs` list; never write settings from a refresh.
- Raid buttons click through ClassicAPI unit attributes (`SetUnit` in
  raid.lua: `unit`, `type1` target, `type2` menu). Aura badges on them keep
  their aura tooltip and pass clicks to the button with
  `owner:Click(GetMouseButtonClicked())`.
- `mods/unitframes/raid.lua` mixes CRLF and LF lines. Editors may rewrite all
  of them; restore unchanged lines' endings before committing.
- A character with no saved settings starts from `Defaults.lua`, the author's own
  settings (Core.lua copies it once and leaves out pixel positions this screen
  cannot hold). Generated, never edited by hand: after changing settings in game and
  `/reload`, run `python -B tools/export_defaults.py --tweaks "<SavedVariables>/FostercareTweaks.lua"`
  in VanillaForge. Chat history and the extra bars' spell lists are not included.
- No code for addons that are not installed (Cartographer, Gatherer, Prat,
  quest addons and the like); `tools/find_holes.py` reports any that return.
- Cooldown Numbers is for the stock buttons' cooldowns, which are 1.12 Models
  with no native numbers. On a native `Cooldown` it stands aside while the
  player's `countdownForCooldowns` CVar is 1 (read, never set). Frames with
  their own timer text call `SetHideCountdownNumbers(true)`. One numeric-rule
  formatter, `FT.Countdown` (Helpers.lua: red tenths under 5 s, yellow under
  10 s, then s/m/h/d), is the countdown look everywhere: aura buttons, raid
  badges and Extra Rows 2-7 set it on their Cooldowns, and the stock buttons'
  numbers call its `FormatNumber`. There is no aura-time ticker.
- Auras follow ClassicAPI's `UNIT_AURA_DELTA` (1.17.10), not `UNIT_AURA`: a
  refresh or stack change rewrites only its own button or raid badge, matched
  by spell and caster; a new or lost aura, a full update or an unmatched change
  reads the row again. `RegisterUnitEvent` filters every event whose first
  argument is a unit (ClassicAPI docs), so it carries only `player`/`target`
  and the raid members.
- Solo, `SetRaidTargetIcon` sets NamPower local marks (raid-target-marks.lua).
- Unit events: ClassicAPI fires each one once per token, including every
  `nameplateN`, `markN` and `focus`. Register `UNIT_*` events with
  `frame:RegisterUnitEvent(event, units...)` for the units the frame shows.
- Script wrappers (`FT.SetEventHandler`, `FT.HookScript`) take fixed
  parameters: in Lua 5.0 every call of a `...` function builds a table.
- Client functions are called by their own names (`hooksecurefunc`,
  `AbbreviateNumbers`); stock FrameXML frames and NamPower functions are used
  without existence checks. Load-on-demand UIs (Inspect, BattlefieldMinimap,
  AtlasLoot) and the client's GroupFrame keep theirs.
- Raid buttons: name and class colour are written by the roster pass and
  `UNIT_NAME_UPDATE`; `UNIT_HEALTH` writes the bar and, only when the number it
  shows changes (`fctHealthShown`), the text. A roster rebuild clears it.
- Chat: one `AddMessage` wrapper per non-combat window (`FT.AddChatFilter` in
  chat-tweaks.lua) runs the filters of links, timestamps and class colours.
- Auto Dismount covers what ClassicAPI's `autoDismount`/`autoUnshift`/
  `autoStand` miss (they act before spell casts only): melee attack, flight
  masters, NPCs and items in a form. Spell errors stay with ClassicAPI.
- A module's `enable` runs under `xpcall` with the error handler, so an
  error reaches !ErrorLog with its stack and the other modules still start.
- Watched auras (mods/watched-auras.lua) replace the retired FostercareAuras.
  Icon positions use mover keys `watch_*`.
- Other addons use one interface: ActionBarProfiles calls
  `FostercareTweaks.ExtraActions` (`GetProfile`, `ValidateProfile`,
  `ApplyProfile`, `ProfileVersion` 1). AutoLazy's minimap tray skips
  `FCTweaksMinimapClock` by name. Nothing else reads Tweaks' globals.
- Equip Compare follows `OnTooltipSetItem` (it fires for every item set on
  a tooltip) and `MODIFIER_STATE_CHANGED`; it never polls the tooltip. The
  compare is deferred a frame: ClassicAPI's docs warn that a tooltip rebuilt
  inside `OnTooltipSet*` can crash the client. Vendor Values keeps its `Set*`
  hooks for that reason (money lines and `Show()`) and for stack counts.
- Unchanged writes are skipped through remembered values (`fct*` fields):
  raid bars (`SetBarRange`/`SetBarColor`), aura icons, counts and borders
  (`Auras.SetIcon`/`SetCount`/`StyleBorder`). Write those widgets through
  these helpers, or clear the field, or the next update skips a real change.
- Chat History keeps no wrapper: at `PLAYER_LOGOUT` (also on reload) it reads
  the frames' last 30 lines with `GetMessageInfo`; at login it puts them
  back with `BackFillMessage`, marked so they are not dimmed again.
- The client has its own windowed world map (`WORLDMAP_WINDOWED`, the map's
  minimize button); our map window was retired on 2026-11-01. Its size is
  ours (`worldmap_scale`, slider and Ctrl+wheel), set on `WorldMapFrame`
  after the native Minimize/Maximize; full screen stays at 1.
- Lua 5.0 collects garbage in one full pass (about 100 ms at 60 MB). Code that
  runs on a timer must not build strings or tables each tick.
- On 2026-10-21 the stutter profiler showed no FostercareTweaks handler over
  5 ms during dungeon and battleground play, and under 1 ms per second overall.
