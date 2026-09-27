# Frame and aura integration review — 2026-09-27

## Task

- Type: addon audit and bounded frame/aura implementation.
- Starting revision: 65125e4 (main). No branch, commit, push, tag or DLL change.
- Objective: multiple raid buffs, clear standard/modern settings, enhanced auras
  on original Blizzard frames, and independent Ctrl+Shift aura movement.
- Scope: frame subsystem, settings, TOC order, affected behavior docs and tests.
- Invariants: Build 5875 / Interface 11200; existing user style choices and modern
  position keys; ClassicAPI 1.15.15 support floor; optional UnitXP.
- Engineering contract, workflow and task/review/retrospective templates used.

Follow-up: the original width-limited raid buff row documented below is
superseded by [wrapping rows and Show All Buffs](RAID_BUFF_LAYOUT_2026-09-27.md).

## Findings and changes

| Finding | Result |
| --- | --- |
| Raid aura code deliberately stopped at one HoT/buff icon | Independent buff row, default four, configurable 1–8 and 8–18 px. Width limits visible count. Roster/grid bounds include the row. Existing HoT corner remains separate. |
| Standard improvement only attached to TargetFrame | Standard PlayerFrame also gets the shared buff/debuff renderer. Original frame artwork and global Blizzard buff strip remain. |
| Standard settings were nested in Modern Unit Frames | Separate Standard Blizzard Frames and Modern Unit Frames sections, explicit mutually exclusive choices per unit, Shared Frame Features section. |
| Unknown aura expiry synthesized a fresh full duration | Removed the guess in shared and original-target duration paths. Icons follow observed aura presence; unknown/past timing does not create a fresh clock. |
| Spell tooltips concealed aura-specific data; filtered indices could refer to another aura | GameTooltip:SetUnitAura uses the plain polarity-list index. Own filtering retains player/pet attribution and excludes unknown casters. |
| Player cancellation translated unstable indices into native slots | C_Spell.CancelSpellByID cancels the displayed identity; server validates cancellation. |
| Movement replaced native drag handlers and saved undragged/inactive frames | Separate modifier-gated overlays preserve native handlers. Save only completed/active drags; no hidden inactive previews. Native and modern positions stay separate. |
| Standard target updates reset aura anchors | Saved owner-relative buff/debuff anchors survive refresh/resize and follow their owner. Visible-row geometry determines mover bounds. |
| Aura buttons each had a throttled OnUpdate text loop | One shared C_Timer text ticker. The radial Model animation remains the existing render path. |
| Raid range sampling used OnUpdate | Native 250 ms ticker; no claimed frame-rate benefit. |
| Modern scale resized raid frames too | Scale owners are separate. |
| Native party frames were unregistered and never re-registered on restore | Suppress visibility while retaining native event subscriptions; toggling custom groups reconciles both presentations. |
| Raid preview ignored configured spacing | Preview uses current spacing and shows multiple buffs. Badge hover/click preserves raid unit interaction. |
| Live settings offered misleading Cancel | Dedicated frame/raid pages use Close; login-enabled shared features have an explicit reload button. |
| Internal addon version and README dependency table were stale | Internal 3.1.0 matches existing TOC; published support minimum and guard now match v1.15.15. No release bump. |

## Evidence

[SOURCE-VERIFIED] Findings were traced in this addon. Official version-pinned
[ClassicAPI API documentation](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/docs/API.md)
defines aura timing, player/pet filters, plain-index SetUnitAura tooltips,
CancelSpellByID and native timer contracts. Unknown non-player expiry is zero;
the duration alone is not a remaining-time observation. The APIs predate .15's
equipment-set release; the maintainer subsequently chose the higher v1.15.15 support floor.

Mock regression evidence is not [EMPIRICALLY VERIFIED] client evidence.

## Validation and integration

- 18 Lua mock tests: unknown timing, player auras, multiple rows, plain tooltip
  indices, compacted cancellation, movement ownership, saved coordinates,
  raid buff count/width/spacing, badge identity/stacks, preview and style settings.
- All addon Lua files compile in the Lua 5.1 harness. TOC/XML paths exist and
  resolve; movement helpers load before frame/aura construction.
- Addon linter: 0 errors, 0 advisories. Complete tracked diff and added artifacts
  reviewed; git diff --check passed.
- Persistence adds optional Show Raid Buffs, raid_buff_count/raid_buff_size in
  overwrites, and position entries in the existing per-character config.
  No new SavedVariables declarations or transient state persistence.
- Existing modern frame keys remain player/target/targettarget/raid. Native
  keys are standard_player/standard_target/standard_targettarget. Aura keys
  distinguish standard and modern owners. Reset positions clears both.

## Runtime checklist — [UNVERIFIED - TEST FIRST]

1. `/reload` with Lua errors enabled. `/ft uf`: retain standard frames, inspect
   player/target buffs and debuffs, timers, stacks and tooltip contents.
2. Hold Ctrl+Shift, move the unit and each aura area separately; release the
   modifier mid-drag, then reload. Confirm positions at your UI scale and near
   screen edges. Target/ToT must exist to move their visible frames.
3. Remove a middle player buff, right-click another buff, and enable own-target
   debuffs. Expect the selected identity/tooltip and no fabricated duration.
4. `/ft testraid`: vary count, icon size, width, spacing and scale. Four buffs are
   the default; up to eight require sufficient width. Rows must not overlap
   the next player or the health/name text. Test with real party and raid auras.
5. Switch each standard/modern presentation in both directions, toggle custom
   group frames, and verify native party frames still update. Apply shared
   login-enabled features with the explicit reload button.

Remaining independent audit candidates: the old health-number module owns some
native text Show methods; raid aggro indication relies on an optional provider or
current target information and is not certified raid-wide threat telemetry.

## Retrospective

The integrated diff review caught a badge identity/stack assignment that the
initial visibility tests did not cover; added actual tooltip-identity tests.
Tests should cover visible data identity, not only icon counts. Mock geometry
is useful for ownership and layout bounds, but cannot certify WoW rendering.
These facts stay project-specific; no framework pattern promotion was needed.
