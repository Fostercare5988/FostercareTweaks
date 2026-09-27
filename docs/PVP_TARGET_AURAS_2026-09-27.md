# PvP target aura refresh — 2026-09-27

## Bounded bug fix

Objective: responsive, readable enemy-target debuffs, including poison
applications, refreshes and removals. Baseline: 277bbcd23c37caa39d0aab6cc62099ac9ef0a4c4.
Scope: shared aura rendering, native target aura suppression, related castbar
hook and regression coverage. Existing border toggles, filters, mirrored
alignment, movement and raid layout are retained. No new polling, dependency,
SavedVariables or poison duration table. Publication uses the maintainer's
standing commit/push authorization.

## Findings and source evidence

[SOURCE-VERIFIED] Original 1.12.1 FrameXML uses TargetDebuffButton_Update,
not TargetFrame_UpdateAuras. TargetFrame events call it; TargetofTarget_Update
also calls it and runs through the target-of-target render path. FT hooked the
wrong name, so that native path could show stock icons again alongside FT.
The corrected posthook only suppresses the native icons; it does not rescan
ClassicAPI auras on each native redraw. Disabling Improved Standard Auras
restores the actual native updater. The related castbar anchor hook uses the
same verified function.

Archived Blizzard source: commit 5a98d3fd8172c95966426c62cb4e8a72165a4fd5.
- [TargetFrame.lua](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/TargetFrame.lua): blob 0aac66ef50f024ae33874b19aab10b093b827d58.
- [Cooldown.lua](https://github.com/tekkub/wow-ui-source/blob/5a98d3fd8172c95966426c62cb4e8a72165a4fd5/FrameXML/Cooldown.lua): blob c919a7bcbb52e2fe918233db54b6af64a62c151a.

[SOURCE-VERIFIED] CooldownFrame_SetTimer calls SetSequence(0) every time.
FT previously called it on every timed aura refresh. Shared player/target
rendering now synchronizes only when unit GUID, spell, caster GUID, start or
duration changes, or the sweep is re-enabled. Countdown labels are updated
without restarting the model. Reset/hide paths clear that transient identity.
Unknown timing clears the timer while preserving the API-reported aura icon.

[SOURCE-VERIFIED] ClassicAPI v1.15.15 commit
71805db62f1e8a154477033dc1f50960c535af8b:
- [src/aura/Source.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/aura/Source.cpp): blob 481efd8a645aa369bdb084297661b1434b59ca7c. In-place cast refreshes update timing and queue a native UNIT_AURA broadcast, coalesced at the world tick.
- [src/aura/Data.cpp](https://github.com/brues-code/ClassicAPI/blob/71805db62f1e8a154477033dc1f50960c535af8b/src/aura/Data.cpp): blob 7dbe3647bad1a362a721355fd4e9705d09c828e6. Enemy timing/caster attribution comes from the observed cast cache; unknown expiration is 0. Expired cache timing may become unknown while the descriptor still contains the aura.

Downloaded ClassicAPI blobs were independently checked against the retained
v1.15.15 Git tree. No local cast-success guess, tooltip scraping or synthetic
poison duration is introduced. UnitIsUnit routes aura events for aliases of
the current target/player, including self-targets. Target loss clears the
standard aura bindings and timers. Existing own-debuff filtering still needs
known player/pet attribution; unknown source is not proof of another caster.

## Validation

- 53 Lua 5.1 frame regressions, including seven new target-aura tests.
- Original archived TargetFrame.lua and Cooldown.lua executed with mocked
  unit/UI data: repeated redraw suppression, unchanged/reapplied poison timing
  and native restoration passed. This is source integration testing, not game
  rendering verification.
- Negative control: all seven new regressions fail against the prior published
  aura renderer, then pass with the fix. Baseline files were loaded in memory;
  repository files were never reset or replaced.
- Full syntax, affected TOC/load graph, config persistence, strict linter and
  cumulative diff reviewed. No version floor or TOC changes are needed.

## In-game checks — [UNVERIFIED - TEST FIRST]

Sync and reload. Against an enemy player, apply Crippling Poison, reapply it,
then have it dispelled or expire. Check that the icon appears/removes promptly
and a known timer refreshes once; unrelated aura updates should not jerk its
sweep. Target another player with the same effect, clear/reacquire the target,
and repeat with target-of-target visible. Check for duplicate small icons.
Test standard and modern target presentations, own-debuff filtering on/off,
sweep/text on/off, and Ctrl+Shift positions. If the icon is present without
numbers, confirm returned expiration before calling it a missing timer.
Test values in the regression fixtures are synthetic, not server spell tuning.

## Retrospective and lesson decision

The most useful evidence was original FrameXML, not a guessed later-client
function name. Exact-source execution supplemented UI mocks and the negative
control demonstrated the regressions detect the previous faults. Existing
VanillaForge rules already cover verified APIs, recycled aura identity,
reversible native suppression and avoiding repeated UI mutation. No new Known
Pattern is warranted. This review records addon-specific source integration.
