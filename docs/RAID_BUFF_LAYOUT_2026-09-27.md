# Raid buff wrapping and all-buff mode — 2026-09-27

## Scoped task

- Type: bug fix and bounded implementation. Starting revision: d7bf9c9.
- Objective: a narrow raid frame must not silently reduce the selected buff
  count; provide an explicit choice to display every client-reported buff.
- Scope: raid buff renderer/grid bounds, raid settings, behavior docs and tests.
- Invariants: existing class palette, health/resource bars, debuffs, standard
  and modern unit frames, saved frame positions and dependencies are unchanged.
- Initial implementation stayed local. The maintainer subsequently authorized
  committing and pushing these raid-buff improvements together with the native
  aura controls to main on 2026-09-27. Runtime verification remains pending.

## Behavior

[SOURCE-VERIFIED] The prior renderer clamped the selected count to one row's
capacity and only constructed eight buff badges. It reserved one row for every
member regardless of whether buffs were present.

Chosen 1–8 buffs now wrap below the health button. Each icon's border is included
in the column width. Each group packs its members below their occupied buff rows,
and the container includes the tallest group. Rows grow/shrink on UNIT_AURA,
roster changes, settings and preview updates; the next player does not overlap.
Showing many buffs on narrow frames necessarily increases group height. Smaller
icons or wider frames reduce the number of rows; buffs are never dropped to fit.

Show All Buffs uses the complete HELPFUL slot list returned by ClassicAPI. It
does not impose the old eight-badge limit, and additional badges are created
only when needed. The limited count is retained while All overrides its slider;
reset returns to four buffs and 10 px icons. Preview uses 32 sample buffs in All
mode; live mode uses the reported slot count, not that preview number.

[SOURCE-VERIFIED] The [audited ClassicAPI API contract](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/docs/API.md)
defines GetAuraSlots' reusable table form, zero maxSlots for all matching auras,
and UnitAuraBySlot's positional data. Slots are refreshed and consumed within
the same update; no old slot IDs are used later. Slot order matches plain
HELPFUL tooltip indices. Existing stacks, interactions, and real-expiry-only
cooldowns remain. Buff presence is limited to what the client reports.

## Integration and validation

- 28 Lua 5.1 mock tests passed, including ten new regressions for minimum width
  with maximum icon size, icon borders/row bounds, resize/reflow, 32 buffs,
  slot identity, tooltip/click/stack data beyond eight, dynamic aura removal,
  mixed subgroup/party geometry, disabled rows, missing icons, All/count/reset
  preferences, and preview resizing.
- All addon Lua files compile; the existing TOC path/order checks pass.
- VanillaForge strict linter: 0 errors, 0 advisories. Complete cumulative diff
  inspected; git diff --check passed.
- One new optional per-character config key: Show All Raid Buffs (default off).
  Existing raid_buff_count/raid_buff_size and position keys are retained. Badge
  caches, occupied-row heights and scratch slot lists are transient frame data.
- No new TOC entries, dependencies, API support-floor change or other addon
  implementation changes. No VanillaForge canonical knowledge changes needed.

## Runtime checks — [UNVERIFIED - TEST FIRST]

Reload, open `/ft` > Raid Frames and enable Show Raid Buffs. At width 40 and
icon size 18, choose eight and inspect all eight when present. Enable Show All
Buffs with a heavily buffed party/raid member. Inspect wrapping, tooltips, health
text and click targeting; add/remove buffs and resize. Verify subgroup spacing,
Ctrl+Shift movement and saved settings after reload. All mode can make the
group taller; the test grid shows its full preview capacity. Mock geometry does
not certify on-screen rendering, screen-edge clamping or real server aura data.

## Retrospective

The previous tests demonstrated eight buffs only after widening the frame;
they missed the user's narrow-frame setting. Boundary tests must exercise the
selected count at minimum width and maximum icon size. Integration review also
caught sparse badge caches when an intervening icon was unavailable and stale
count labels during All/reset. These are project-specific regressions; existing
canonical API/identity guidance is sufficient, with no Known Pattern promotion.

## Settings slider correction — 2026-09-27

The maintainer's live-client screenshot reported Options.lua:1074 calling a
missing Slider:Enable method when opening the raid settings. The previous mock
incorrectly supplied Button-only Enable/Disable methods to every frame type.
Both All-mode states and the reset path used those invalid calls.

[SOURCE-VERIFIED] The archived 1.12.1
[OptionsFrame.lua](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/OptionsFrame.lua#L450)
manages slider appearance separately from Button Enable/Disable. The correction
uses native Frame:EnableMouse and SetAlpha: All mode fades and blocks mouse
input on the count slider; limited mode and reset restore it. The selected
count, aura enumeration and wrapping behavior remain unchanged.

The corrected mock reproduces the exact Enable failure on the published source
and the corresponding Disable failure with All enabled. All 36 frame regression
tests now pass, including reopening the saved Raid tab in both modes, switching
tabs, live All/count changes and reset. Strict linter: 0 errors, 0 advisories;
diff check passed. No manifest, dependency or SavedVariables changes.

[UNVERIFIED - TEST FIRST] Sync this correction to the actual game folder, reload,
open /ft and select Raid Frames. Toggle Show All Buffs on/off, switch tabs and
reopen. The corrected version still requires this in-client confirmation.

Retrospective: UI mocks must reject known unsupported frame methods instead of
silently supplying them. This is a scoped project regression; no framework or
other addon changes are needed.
