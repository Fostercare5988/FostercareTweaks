# Module ownership review — 2026-09-28

## Task and scope

Task class: architecture/audit refresh, bounded bug fixes, integration review.
Starting revision: `b004c7371a31376873efef7ed6a6281e2af24fe0`, clean `main`,
matching the actual remote. Commit and push authorized; no release or tag.

Reused the frame, standard aura controls, raid layout and PvP target aura reviews
from September 27 and the permanent class-color follow-up. Those implemented
contracts remain covered by 54 existing regressions. This review extends coverage
to nameplates, health text, the native target debuff timer, merchant selling and
target-of-target lifecycle. It is not a claim that every optional module has been
empirically tested.

Invariants: standard-frame class colors remain unconditional; buff, debuff and
weapon-enchant borders retain independent toggles; player settings remain intact;
Build 5875 semantics and the existing enhanced-client dependency floor remain.

## Architecture

- TOC: Core -> Helpers -> Options -> action bars -> movement/native player auras
  -> shared unit-frame core/auras -> player/target/ToT/raid -> native frame
  enhancements -> nameplates -> map/minimap -> items -> chat/social -> gameplay.
  Runtime code is Lua; no new manifest entry is needed.
- Core registers optional modules and enables selected modules once at variables
  loaded/login. Standard class colors initialize independently of the old key.
  Options owns the settings UI and live frame/aura controls; some older optional
  modules intentionally apply after reload.
- Per-character persistence: `FostercareTweaks_Config` contains module choices,
  overwrites and positions; `FostercareTweaks_Cache` stores player metadata and
  chat history. Plate bindings, cooldown identity and ToT state remain local/frame
  runtime fields. No migration or new SavedVariables declaration is introduced.
- Frame events drive health/power/roster/aura updates; shared aura and raid-range
  timers remain. Nameplate render callbacks drive cast interpolation and restore
  class color after native painting. Discovery no longer scans WorldFrame.
  ToT retains its existing target-scoped 150 ms sampling; this change repairs
  ownership rather than claiming a measured performance improvement.
- Native frames own their normal scripts. Health-number posthooks now constrain
  writes to player/target/pet bars. Custom frames, aura containers and movement
  handles retain the ownership described in the existing frame review.
- Actual dependencies: ClassicAPI 1.15.15+; SuperWoW 2.2+ (cast events/GUID and
  mouseover integration remain elsewhere); optional UnitXP SP3 health queries.
  No NamPower or DXVK Lua dependency. AutoBG's class lookup remains an optional
  read-only social/player-cache integration, but no longer determines plate identity.
- Tests: headless Lua 5.1 via Lupa; existing frame suite plus strict method mocks
  for the newly covered module widgets and optional pinned FrameXML integration.

## Findings and bounded corrections

Locations refer to the starting revision, so they remain reproducible.
All five are **[SOURCE-VERIFIED]**, reproduced in Lua regressions; none is claimed
as **[EMPIRICALLY VERIFIED]** gameplay. No P0/P1 defect was established.

| Priority | Location | Reproduction and impact | Correction |
| --- | --- | --- | --- |
| P2 | `mods/nameplate-castbar.lua:233`, `mods/nameplate-classcolor.lua:95`, `Helpers.lua:685` | Two units share a name; target/mouseover can supply another plate's cast/class. A recycled plate or positional callback can also retain/misread ownership. Misleading combat UI. | Bind lifecycle events to GUIDs, verify the engine's live GUID-to-frame association, consume direct cast/channel/class state, remove name/alpha guesses and redundant cast cache. |
| P2 | `mods/health-numbers.lua:80` and `:116` | Native `TextStatusBar_UpdateTextString` rewrites text while health is unchanged; the addon cache skips restoration. The global hook also formats unrelated unit bars. | Compare the actual FontString contents and restrict the hook to its six owned bars. |
| P2 | `mods/unitframes/tot.lua:150`, `:195`, `:205` | Clear a target until the sampler hides, then reacquire it. The earlier handler references a global instead of the later local ticker. World-entry also returns early when ToT is hidden. | Forward-declare ticker ownership and handle world-entry before the hidden-frame guard. |
| P2 | `mods/sell-junk.lua:129` | Sell with an occupied cursor or a locked/rejected item. The loop clears unrelated cursor work and counts expected revenue before acceptance; slot-based processed flags do not represent item identity. | Submit the engine's item-GUID queue, refresh the button from current state and remove unconfirmed earnings. No Lua sale loop or cursor mutation remains. |
| P2 | `mods/target-debufftimer.lua:110` | Disable Improved Standard Auras and allow repeated native target/ToT redraws. Every redraw restarts the same cooldown sequence. | Restart only for changed target, caster, spell or timing. Unknown expiry remains untimed. |

## API/source evidence

ClassicAPI is pinned to v1.15.15, commit
`71805db62f1e8a154477033dc1f50960c535af8b`; the existing minimum is unchanged.

- [Nameplate Info.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/nameplate/Info.cpp)
  implements stable frame wrappers and live GUID-to-frame queries.
- [Nameplate Events.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/nameplate/Events.cpp)
  owns added/removed tokens and protects removal lookups from reassigned frames.
  Its implementation retains surviving token slots; older prose about shifting
  positional indices is not used as evidence for a runtime defect.
- [Spell Cast.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/spell/Cast.cpp)
  supplies per-caster remote cast data and validates channel state. Unknown
  channel times stay unknown. Remote observation/pushback limitations remain.
- [Merchant Frame.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/merchant/Frame.cpp)
  selects quality-0 items, snapshots item GUIDs, drains one per frame and cancels
  when the merchant GUID closes/changes. It does not return confirmed sales.
  Zero-value grey items may be submitted; server acceptance is authoritative.
- [Native TextStatusBar.lua](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/TextStatusBar.lua)
  rewrites the text on every update. Git blob:
  `8417d749e9e14ce27b7aae3b760674b0ada8c8cc`.
- Native cooldown restart semantics and aura signatures reuse the exact-source
  evidence in [the PvP aura review](PVP_TARGET_AURAS_2026-09-27.md).

## Validation and integration review

54 existing frame regressions and 14 module ownership regressions pass.
The existing suite includes the old disabled class-color SavedVariables value,
normal settings opening/reopening, reset, native redraw, drag during refresh,
scale, independent border toggles and aura event sequences.

The new module suite also passes with the pinned native TextStatusBar source
executing before the addon hook. Set `FT_TEXT_STATUS_BAR_SOURCE` to that downloaded
file; the test verifies its Git blob before execution. Set `FT_TEST_REVISION` to
the starting revision to reproduce the defects without altering the checkout.
All 14 new tests fail on that revision at behavior assertions. Source integration
and mock evidence are separate from client/server execution.

Integration review: correctness, lifecycle ownership, verified APIs, persistence,
load order and dependency metadata reconciled. No runtime files added/removed,
no new persisted scratch state, no support-floor increase. Strict linter,
full Lua syntax, TOC resolution and whitespace checks pass. Complete diff reviewed.
Ready for the authorized code publication; in-game acceptance remains pending.

## In-game acceptance — [UNVERIFIED - TEST FIRST]

1. Enable Lua errors and reload. Open `/ft`, `/ft uf` and `/ft raid`, reopen them,
   reset frame positions, and check old profiles. Standard class colors must
   remain active without a toggle. Test each of the three border toggles alone.
2. Target two same-named enemies casting different spells; change target and
   mouseover, interrupt one, let the other finish, and leave/re-enter plate range.
   Check player/NPC class colors and recycled plates. Repeat across zoning/reload.
3. Watch standard player/pet/target health through damage, healing, target switch,
   death and repeated native redraws. Check another addon's unit bars remain normal.
4. Enable modern ToT, clear target, wait, reacquire and switch the target's target;
   zone while ToT is hidden, then enable/disable its presentation.
5. With Improved Standard Auras disabled, test native target debuffs through
   apply, unchanged redraw, reapply, caster/target change, dispel and expiry.
   Repeat normal improved-aura PvP poison checks from the earlier review.
6. At a merchant, sell multiple grey stacks; keep a non-grey item on the cursor,
   move/lock a queued item, close the merchant mid-drain, open another merchant,
   switch Buyback and return. Verify inventory/buyback and money actually received.
   No unconfirmed earnings message should appear. Mocks do not test server sales.
7. Retain the earlier Ctrl+Shift/scale, native aura cancellation, six/eight/nine
   target icons and raid all-buff tests at the actual UI scale.

## Remaining observations

- P3 **[UNVERIFIED - TEST FIRST]**: `mods/health-numbers.lua:35` deliberately
  suppresses optional custom-FrameXML target texts. Review a concrete conflicting
  provider before changing that ownership; no stock-client fallback is proposed.
- P3 **[UNVERIFIED - TEST FIRST]**: raid aggro indication remains dependent on
  optional provider/current-target data. It is not certified raid-wide threat data.
- Some unrelated helpers retain capability guards and older timer wrappers.
  No speculative removal or broad API rewrite is included in this correctness pass.

## Retrospective

Exact source distinguished engine-owned queues from sale confirmation and exposed
native writes missed by addon-only caches. Strict widget mocks and testing the
starting revision caught behavior rather than merely checking implementation text.
The existing audits avoided repeating frame geometry and dependency-floor research.
These ownership lessons are already covered by the engineering contract; no
framework modification or new general rule is proposed.
