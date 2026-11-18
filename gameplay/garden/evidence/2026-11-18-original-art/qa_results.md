# PR #18 Garden / character QA — 2026-11-18

Tested under Godot 4.7.2 on macOS against the current PR #18 worktree.

**23 / 23 scoped Godot headless regressions PASSED, 0 failures.**
This is a focused regression suite, **not** final multi-arena gameplay or
peer Design acceptance.

| Test | Result |
|---|---|
| gameplay_character_art_scope_test | PASS |
| gameplay_project_start_test | PASS |
| gameplay_smoke_test | PASS |
| gameplay_controls_test | PASS |
| gameplay_msd_test | PASS |
| gameplay_fan_direction_test | PASS |
| gameplay_render_layers_test | PASS |
| gameplay_simulation_contract_test | PASS |
| gameplay_upstream_grid_test | PASS |
| gameplay_magic_test | PASS |
| gameplay_platform_v2_test | PASS |
| gameplay_keyboard_chords_test | PASS |
| gameplay_art_handoff_test | PASS |
| gameplay_team_integration_test | PASS |
| gameplay_integration_merge_safety_test | PASS |
| gameplay_interaction_polish_test | PASS |
| gameplay_garden_design_contract_test | PASS |
| gameplay_garden_input_test | PASS |
| gameplay_garden_regression_edges_test | PASS |
| gameplay_garden_cross_branch_contract_test | PASS |
| gameplay_garden_round_handoff_test | PASS |
| gameplay_garden_attack_accounting_test | PASS |
| gameplay_garden_throwable_fire_test | PASS |

## All-owner temporary integration

One unpublished detached worktree combined Angela PR #16, Austin items,
Ethan PR #19, Jackson PR #20 (including the Nov 18 update), and **Eva
Health / FireHazard / FallDamage component files only** with PR #18.
Git had cross-owner conflicts in Austin scene, Simulation controller,
appliance and material-setup files; these were manually resolved for QA
without modifying their remote branches.

**12 / 12 selected combined runtime Godot tests PASSED, 0 failures.**

| Combined test | Result |
|---|---|
| gameplay_item_system_test | PASS |
| gameplay_local_wind_test | PASS |
| gameplay_garden_round_handoff_test | PASS |
| gameplay_garden_attack_accounting_test | PASS |
| gameplay_garden_throwable_fire_test | PASS |
| gameplay_garden_cross_branch_contract_test | PASS |
| gameplay_garden_input_test | PASS |
| gameplay_garden_regression_edges_test | PASS |
| gameplay_garden_design_contract_test | PASS |
| gameplay_character_art_scope_test | PASS |
| gameplay_simulation_contract_test | PASS |
| gameplay_project_start_test | PASS |

## New bug regression cases verified in this review

- Two consecutive Garden round endings and full replay resets;
  actual Eva Health, HUD, positions, movement, pending projectiles and fire
- Post-winner Magic, item/portal and rose-damage lockout
- Correct 5% fractional bonus when an attack is rejected by Eva i-frames
- All Garden throwable items become unpickupable ash after 3 seconds
  of fire at their pixel-derived, upstream-Simulation WOOD position;
  old main uses **1 HP explicit placeholder** and Austin uses his
  existing item durability/burning code
- Burnt mushroom and hose restored/reset for rematches; burned hose cannot
  keep spraying water while destroyed
- Original Art Team Garden background/fence/mushroom/nozzle Piskel
  extraction still reconstructs pixel-exactly
- Four refreshed windowed Godot captures stored next to this report

## Repro instructions / limitations

On a fresh checkout, import all textures before running scripts:

    Godot --headless --editor --path . --import --quit

Then run the scene with F6 or run tests, e.g.:

    Godot --headless --path . --script res://gameplay/tests/gameplay_garden_round_handoff_test.gd
    Godot --headless --path . --script res://gameplay/tests/gameplay_garden_attack_accounting_test.gd
    Godot --headless --path . --script res://gameplay/tests/gameplay_garden_throwable_fire_test.gd

Angela map-startup/selection and Living Room shared HP integration remain
outside Suwen's PR; cross-owner conflict resolutions are NOT merged.
See gameplay/garden/CROSS_BRANCH_COMPATIBILITY.md.
