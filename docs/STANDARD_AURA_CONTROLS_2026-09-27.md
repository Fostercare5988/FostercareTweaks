# Blizzard player aura controls — 2026-09-27

## Bounded implementation

- Objective: independently hide/show and move the original top-right buffs,
  debuffs and weapon enchants while preserving enhanced player-frame auras.
- Baseline: d7bf9c91f37663b135814279d81dd3c1679ddd6c. The pending raid-buff
  wrapping/Show All work remains intact; see RAID_BUFF_LAYOUT_2026-09-27.md.
- Routing: VanillaForge AGENTS.md, system contract, workflow, task/review and
  retrospective templates. No framework lesson promotion or addon-wide redesign.
- Initial implementation stayed local. The maintainer subsequently authorized
  committing and pushing the native aura controls and pending raid-buff work
  to main on 2026-09-27. Runtime verification remains pending.

## Source and ownership

[SOURCE-VERIFIED] The archived Blizzard 1.12.1 tag resolves to
5a98d3fd8172c95966426c62cb4e8a72165a4fd5; its FrameXML.toc declares 11200.
[BuffFrame.lua](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/BuffFrame.lua)
and [BuffFrame.xml](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/BuffFrame.xml)
establish the native button filters, right-click cancellation, duration regions,
enchant updater and BuffButton8/16 position resets.

The new module creates three passive parent areas and reparents original buttons,
retaining their scripts and event registrations. BuffFrame and
TemporaryEnchantFrame remain active update controllers. Their separate duration
font strings follow the icon anchors and receive independent visibility alpha;
native Show calls and flashing cannot reveal a disabled area. Re-enabling runs
native updates immediately, preserving the prior `this` script context.
A native position post-hook restores icon anchors, never saved mover positions.
No replacement aura renderer, new timer, per-frame layout hook, dependency or
SavedVariables declaration is added.

Persistence: optional numeric keys Show Standard Buffs, Show Standard Debuffs and
Show Weapon Enchants (nil/1 visible, 0 hidden), plus standard_global_buffs,
standard_global_debuffs and standard_weapon_enchants in the existing
unitframe_positions table. Runtime frames/lists stay transient. Existing position
reset clears these entries; Unit Frame defaults restore visibility.
TOC loads the module after movement helpers. Controls are in a dedicated section,
separate from Standard/Modern presentation and enhanced player aura controls.

## Validation and integration review

- 34 Lua 5.1 regressions pass, including all prior raid layout tests and six new
  native-area tests: independent visibility, refresh, cancellation script
  ownership, anchors, drag/save behavior, live settings/defaults and idempotence.
- Actual archived Blizzard BuffFrame.lua was also executed with mocked engine/UI
  data: native aura/enchant updates, hidden duration regions, right-click
  cancellation and position refresh passed. This is source integration testing,
  not [EMPIRICALLY VERIFIED] game rendering.
- Lua compilation and TOC path/order checks pass. Strict VanillaForge linter:
  0 errors, 0 advisories. git diff --check passes.
- Correctness/ownership/API/TOC/persistence/docs reviewed against cumulative
  changes. Existing raid improvements and Blizzard frame colors are preserved.
  Local code is ready for runtime testing; no performance claims are made.

## Runtime checklist — [UNVERIFIED - TEST FIRST]

1. `/reload`, open `/ft` > Unit Frames > Top-right Blizzard Auras. Hide each
   area independently, then re-enable it. Player-frame auras must remain visible.
2. Gain/lose buffs and debuffs while the corresponding original area is hidden.
   Test both weapon enchants, no enchant and expiring enchant: no orphan timers.
3. Right-click an original buff and inspect original buff/debuff/enchant tooltips.
4. Ctrl+Shift-drag each visible area, release a modifier during dragging, reload,
   change buff duration display and change enchants. Positions must persist and
   no automatic native anchor should snap a moved area back.
5. Test your UI scale, screen edges, standard/modern player styles and position
   reset. Verify prior raid Show All/wrapping still works in a real raid.

## Retrospective

Exact 1.12 source was necessary: player debuffs are native BuffButton entries,
and durations belong to controller frames, not the buttons. Keeping native
controllers active avoids replacing their update/cancellation logic. An actual
archived-source integration check supplemented geometry mocks. Static validation
caught a legacy math.mod call, corrected to the enhanced Lua `%` syntax.
These project details stay in the addon; existing framework ownership/evidence
rules cover the general lesson.

## Plain aura styling — 2026-09-27

Scoped visual adjustment from 3dfbc2f, requested by the maintainer. Remove FT's
dark decorative aura overlay and the weapon-enchant item-rarity frame. Shared
player/target/raid buffs have no decorative border; dispel overlays remain
available under their existing settings. Resetting or reusing an aura button
hides its overlay, and active debuffs explicitly show the colored cue. Raid
preview and live debuff badges use the same overlay visibility policy.

Native top-right icon textures receive a 7% crop to remove embedded dark edges.
The stock weapon-enchant border is transparent, matching the plain icons.
The original BuffFrame.xml defines these Icon/Border regions; BuffFrame.lua
updates textures/colors rather than resetting the crop/alpha. No replacement
handlers, hooks, timers, new setting or API dependency is introduced. Native
debuff type cues are retained. Item Rarity Borders still applies to inventory,
bank, character and inspect slots; its enchant update hook is removed entirely.
Positions, dimensions, duration text/sweeps, stack counts and tooltips are intact.

Validation: full 42-test Lua 5.1 frame suite, strict linter and diff review.
[UNVERIFIED - TEST FIRST] Sync and reload; inspect player/target/raid buffs and
top-right auras with main/offhand enchants. Expect plain icon edges, retained
timer/stack text and colored debuff cues where enabled. Add/remove a buff,
change target, and check the borders stay absent after refresh and resizing.

Retrospective: the enchant frame came from Item Rarity Borders, not ClassicAPI.
Remove it at that owner rather than adding a timer that repeatedly hides it.
This is a project style preference; no framework lesson promotion is required.

## Separate aura border choices (supersedes the unconditional plain style above)

Maintainer clarification: weapon borders remain useful for identifying item
quality. `/ft` > Unit Frames > Aura Borders now has three independent live
settings: Show Buff Borders (default 0), Show Debuff Borders (default 0), and
Show Weapon Enchant Borders (default 1). Missing SavedVariables use these
same defaults. Values save in the existing per-character config; no migration
or new SavedVariables declaration is needed. Reset to Defaults restores them.
Visibility, positions and aura timing are independent of styling.

[SOURCE-VERIFIED] Shared player/target/raid aura buttons and previews reuse one
border policy. Enabled buff borders are decorative; enabled enhanced debuff
borders retain the existing optional dispel colors. Native harmful icons use
their Blizzard dispel border. Original top-right buff icons receive a reusable
overlay only if requested. Cropping and native click/tooltips remain intact.

[SOURCE-VERIFIED] The native enchant controller assigns inventory slot IDs
16/17 to the displayed buttons. Weapon border ownership is in Blizzard Aura
Controls, independent of Item Rarity Borders. It reuses AddBorder and colors
from GetInventoryItemQuality/GetItemQualityColor. A native updater posthook
handles hand reassignment; UNIT_INVENTORY_CHANGED refreshes player equipment.
Quality is read on hand changes, equipment events and explicit settings
refreshes, rather than on every native update. Missing quality uses neutral
gray. Cached border frames are reused and do not intercept mouse input.

Validation: all 46 Lua 5.1 frame regressions, including four saved/live-border
lifecycle regressions, pass. These cover reopening/recreating settings,
independent visibility, reset defaults, shared/raid previews, tooltip identity,
weapon hand reassignment, quality changes and no per-frame quality polling.
Strict linter and diff checks are recorded with the published checkpoint.

[UNVERIFIED - TEST FIRST] Sync this checkpoint and reload in WoW. Toggle all
three choices separately; inspect player/target, raid and top-right icons.
Check timers, cancellation, tooltips and Ctrl+Shift movement. Equip main/offhand
weapons of different rarity, enchant only the offhand, then both hands; confirm
correct colors and hand reassignment. Verify choices survive relogging.

Retrospective: style preferences need independent controls when a border also
carries information. Keep quality ownership scoped to aura controls rather
than coupling it to inventory decoration. This project-specific preference
requires no VanillaForge Known Pattern promotion.
