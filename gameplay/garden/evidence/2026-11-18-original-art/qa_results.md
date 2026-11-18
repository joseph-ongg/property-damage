# Garden PR #18 acceptance recheck — 2026-11-18

Godot 4.7.2 on macOS; the imported, live PR #18 working tree.

**19/19 focused automated Godot tests passed; 0 errors.**
These are not a substitute for full-team release and gameplay QA.

| Godot test | Result |
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

Changes verified in the new edge test:
- No phantom Magic hit through transparent Art Team fence pixels
- Two-player Magic does 10 base HP and preserves visible item-before-player priority
- Fence destruction awards +5% with accumulated fractional 0.5 damage
- Round reset clears ALL upstream MaterialGrid fire and restores original cells
- Fence burning removes 1 HP each 3 seconds of Simulation fire
- Nonfragile throwable remains reusable; fragile tagged item is consumed
- Ninja shuriken has temporary code-drawn icon; higher jump at editable provisional 1.10x
- Eva Health death emits the Garden-to-Angela winner handoff signal

Art provenance: original Piskel exact-pixel reconstruction verified by
gameplay/garden/extract_original_fence.py. Earlier four windowed Godot
screenshots are stored beside this report.

**Important:** Fresh checkouts must run
`Godot --headless --editor --path . --import --quit` before the tests.
No global map-selection change, full match acceptance, non-team laptop
executable, or peer Design/Art sign-off is claimed.
