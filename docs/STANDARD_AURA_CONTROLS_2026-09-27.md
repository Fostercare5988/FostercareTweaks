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
