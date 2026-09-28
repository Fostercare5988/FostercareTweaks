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

## Ctrl+Shift follow-up — 2026-09-27

Task: scoped bug fix, starting at ffa1213. The maintainer reported that holding
Ctrl+Shift did not show the grid. An additional inspected defect let an aura
refresh overwrite the first unsaved drag's anchor and bounds.

[SOURCE-VERIFIED] ClassicAPI updates its left/right modifier bitmap and fires
MODIFIER_STATE_CHANGED in its thread message hook before engine key dispatch.
The old mover queried native merged state, which follows a separate path.
The corrected handler reads ClassicAPI's left/right queries; no polling,
deferred timer or compatibility fallback was added. See pinned
[Modifier.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/input/Modifier.cpp),
blob 7071459ca029f220881208df1d3cec10c0b3849f. This establishes the event ordering;
it does not prove the state of the maintainer's running game process.

Movement activation is now reconciled when configuration is applied. A session
starting with movement disabled can enable it live without missing the grid or
event registration. Initialization is idempotent and no longer restores anchors
again during an active drag. Disabling movement still stops and saves the drag.

Aura identity continues updating during a drag, but automatic row anchors/bounds
leave the dragged area alone. After a drop or modifier release, save the position
first and reconcile current aura bounds immediately. Buff/debuff areas retain
their relative owner and existing position keys. Native clicks and visibility
are unchanged; no TOC, DLL support floor or SavedVariables declaration changes.

Validation: 39 Lua mock regressions passed. New cases reproduce the old missed
modifier combination for eight side/order combinations, live off-to-on grid
activation, and the first unsaved player/target buff/debuff drag at a different
scale. Existing modifier-release, native aura and settings tests also pass.
Strict linter: 0 errors, 0 advisories. Complete diff and whitespace checked.

[UNVERIFIED - TEST FIRST] With Movable Unit Frames enabled, hold Ctrl+Shift in
both orders and with either side of the keyboard. Expect the grid and handles
before clicking. Release a modifier, then try again after Alt+Tab. Drag player,
raid and aura areas; let buffs appear/disappear while dragging. Confirm the drop
and saved position after reload. Test the movement toggle live without reloading.

Retrospective: mocks previously gave native and enhanced modifier queries the
same state, hiding the event-ordering distinction. Model the differing source
contracts rather than assuming every available API shares a state snapshot.
General widget/mock and modifier-event facts were deliberately promoted to
VanillaForge references/workflow; this addon's geometry stays with the addon.

## Mirrored standard target aura layout — 2026-09-27

Task: scoped visual/layout bug fix from 03032de. The maintainer's screenshot
showed six player buffs on one line, but five target buffs and a lone sixth
on a second line beside the target's right-side portrait. FT imposed five
columns on the standard target and eight on the player; both grew from the left.

[SOURCE-VERIFIED] The native 1.12 target portrait is anchored TOPRIGHT, while
its health/mana bars sit to its left. The native target-of-target extends ten
pixels below the root frame. See pinned
[TargetFrame.xml](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/TargetFrame.xml).
Stock aura rows grow from the left: the new right-aligned growth is an FT
presentation choice, not a claimed Blizzard requirement. Native GetRight is
used by the same build's
[UIParent.lua](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/UIParent.lua).
FT's native target castbar can sit another 24 pixels below the root. The new
default rows start 34 pixels below the root, leaving room for both controls.

Standard target buffs/debuffs now grow left from a stable right edge, with eight
icons per row. The ninth starts another row at the same right edge. Enumeration,
texture orientation, tooltip indices and timer text do not reverse. Creation
and resizing share the same icon placement helper. Player and modern layouts
keep their existing growth direction.

Existing target aura TOPLEFT saves convert once to TOPRIGHT using the first
displayed row's width; the same relative anchor and vertical offset are retained.
Old saves do not store prior aura count/width, so the exact historical rectangle
cannot be reconstructed. This preserves the configured area as initially laid
out by the new code and stabilizes its right edge thereafter, without discarding
the position. Later drops save the right edge relative to TargetFrame at the
correct effective scale. Other saved position keys keep their existing format.
Active-drag geometry protection and current modifier-state handling remain intact.
No TOC, dependency floor, new toggle or SavedVariables declaration changes.

Validation: reproduced the old five-column/right-anchor failures before fixing.
All 42 Lua 5.1 frame regressions pass; strict linter reports 0 errors and 0
advisories. Covered six/eight/nine buffs and debuffs, wrapped bounds and tooltip
identity, resize/drop at different scales, one-time saved-anchor conversion and
container recreation, and unchanged player/modern layout behavior.

[UNVERIFIED - TEST FIRST] Sync the new commit to the actual game folder and reload.
Target a friendly player with six, eight and more than eight buffs; expect upright
icons in right-aligned rows. Check debuff tooltips/own-debuff filtering, target
casts and target-of-target. Adjust the separate areas with Ctrl+Shift if desired;
remove buffs, change icon size and reload to check the stable right edge. Existing
areas above the frame remain where configured. Rendering at the maintainer's UI
scale needs in-game confirmation; mock tests establish geometry/state contracts.

Retrospective: the screenshot exposed inconsistent row capacity and anchoring,
which visibility-only checks missed. The native layout review also prevented
widened default rows covering target-of-target/castbar. This is addon-specific
layout knowledge; no VanillaForge Known Pattern or framework change is needed.

## Permanent standard-frame class colors — 2026-09-28

The maintainer clarified that standard Blizzard player/target name backgrounds
and party names must always use class colors. The old class-color checkbox and
its registered optional module path have been removed. Core initialization
installs the hooks unconditionally, so an old per-character
`Unit Frame Class Colors = 0` setting cannot suppress coloring. The old key is
ignored; this change does not rewrite the player's SavedVariables file.

[SOURCE-VERIFIED] The implementation uses FT's fixed unit-frame class palette,
not the shared `RAID_CLASS_COLORS` table or its possible grey fallback. Native
`TargetFrame_CheckFaction` still supplies NPC, reaction/PvP and tapped colors;
the hook recolors known player classes after native updates. The player's name
background also receives the class color at initialization and again on
`PLAYER_ENTERING_WORLD`.

The local Niko2 `Claude` SavedVariables file and its September 12 backup both
contain an enabled old setting. They do not establish why the separate game
folder showed a green self-target while the player background was dark. A
stored disabled setting is one source-confirmed way the previous optional
module could fail to run. The screenshot's exact cause remains unverified.

The top-right Blizzard buff, debuff and weapon-enchant borders retain three
independent live toggles in **Blizzard & Frame Aura Borders**. Buff/debuff
borders default off; weapon enchant item-quality borders default on.

The headless Lua regression verifies color application even with the old saved
value set to 0, the absence of a checkbox/module registration, fixed-palette
colors, and native fallback for unknown classes and NPCs. Strict linter and
load-graph validation also pass. [UNVERIFIED - TEST FIRST] After syncing and
relogging in the actual game folder, target self, another player, an NPC and a
tapped NPC. Check class colors at login and after target changes. Verify that
no class-color checkbox appears in `/ft` and that the three aura-border toggles
still act independently.

Retrospective: a permanent visual rule should be initialized by the owning
component rather than routed through a per-character optional-module key.
This is an addon-specific policy, so no VanillaForge Known Pattern change is
required.
