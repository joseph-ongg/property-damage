# Garden PR #18 QA recheck — 2026-11-18

**20 / 20 selected headless Godot regressions passed, 0 failures**.
This is targeted QA, not complete game or other-owners sign-off.

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

## Cross-branch runtime verification
- Austin items (after temporary scene merge): Austin item test plus Garden/character tests pass.
- Eva latest Health/FireHazard/FallDamage component substitution: five related tests pass.
- Angela + Ethan PR19 + Jackson: seven tests pass after temporary controller conflict resolution.
- All owner changes combined, with Eva component substitution: **8/8 Godot tests pass** after temporary resolution of scene/controller conflicts.

Documented with exact branches, caveats and unresolved integration in:
gameplay/garden/CROSS_BRANCH_COMPATIBILITY.md.

New QA includes pixel-accurate fence edge burning, continued apple drops,
active Eva FireHazard, optional Eva FallDamage, Austin item tags, and
Garden-local synchronization with Eva authoritative HP.

**Must import on fresh clone:** Godot --headless --editor --path . --import --quit.
Original Piskel artwork still round-trips pixel-for-pixel.
