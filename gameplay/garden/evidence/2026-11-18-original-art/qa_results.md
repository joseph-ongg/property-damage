# Garden design-interaction QA evidence — 2026-11-18

Godot 4.7.2 on macOS, all tests executed against the isolated
suwen/garden-design-mechanics worktree (stacked on PR #17).

**18 / 18 focused headless regressions passed, 0 failures.**

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

Additionally, the original Garden Piskel extraction reconstructs the
complete supplied 426×286 artwork pixel-for-pixel with no new art.
A windowed Godot screenshot run produced four 960×540 captures:
source art, fence damage, upper tree-hole travel and working hose.
See garden_design_contact_sheet.png.

Explicit design numbers: fence 4 HP/segment ×8, rose 5 HP,
hose 10 sec and 1 HP/sec (tentative Design text).
Apple, gnome, mushroom, hose-end projectile impact = **1 HP
placeholder** per user, **not** a Design-approved balancing value.

Scope disclaimer: these are targeted tests, not full-team
match-controller, final-art, cross-machine or acceptance sign-off.
