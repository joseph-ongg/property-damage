# PR #18 character / Garden QA evidence — November 18, 2026

**24/24 current PR branch headless tests passed, 0 failures.**
Run from a clean checkout after importing assets. The exact executable is
`gameplay/garden/verify_pr18.sh --local`; per-test engine logs are
written to the temporary directory printed by that script.

| Headless Godot test | Result |
|---|---|
| `gameplay_character_art_scope_test` | PASS |
| `gameplay_project_start_test` | PASS |
| `gameplay_smoke_test` | PASS |
| `gameplay_controls_test` | PASS |
| `gameplay_msd_test` | PASS |
| `gameplay_fan_direction_test` | PASS |
| `gameplay_render_layers_test` | PASS |
| `gameplay_simulation_contract_test` | PASS |
| `gameplay_upstream_grid_test` | PASS |
| `gameplay_magic_test` | PASS |
| `gameplay_platform_v2_test` | PASS |
| `gameplay_keyboard_chords_test` | PASS |
| `gameplay_art_handoff_test` | PASS |
| `gameplay_team_integration_test` | PASS |
| `gameplay_integration_merge_safety_test` | PASS |
| `gameplay_interaction_polish_test` | PASS |
| `gameplay_garden_design_contract_test` | PASS |
| `gameplay_garden_input_test` | PASS |
| `gameplay_garden_regression_edges_test` | PASS |
| `gameplay_garden_cross_branch_contract_test` | PASS |
| `gameplay_garden_round_handoff_test` | PASS |
| `gameplay_garden_attack_accounting_test` | PASS |
| `gameplay_garden_throwable_fire_test` | PASS |
| `gameplay_ninja_cross_arena_test` | PASS |

## Current Angela menu → Garden integration-only E2E

- Exact menu code and required UI/presentation files were taken from the
  current `origin/angela/map-select-v2` revision
  `6181700eabf3774c481ed01b1ffaa4c97d2fe597`.
- Angela's old GardenPlaceholder path was changed **only in a disposable
  test worktree** to `res://gameplay/garden/garden_level.tscn`.
- The test used the real Garden button signal and `change_scene_to_file`,
  then two real 10-HP-per-shot PVP fights ending in Health death signals;
  it called `Garden.prepare_new_round()` between fights and returned to
  Angela's map scene.
- **PASS, zero errors** in both headless and actual windowed Godot runs;
  command: `./gameplay/garden/verify_pr18.sh --menu` in that
  **integration-only checkout**.
- **Not yet tested/finished:** Angela's actual best-of-three scoreboard,
  real menu path on her unmodified branch, character selection and user-driven
  round restart. The current Angela branch itself has 14 merge conflicts
  with PR #18 due to old game-ready history.

## Shared Ninja attack appearance

- `gameplay_ninja_cross_arena_test` exercises the actual shared
  `GameplayMagicBolt.initialize()` in Living Room and Garden for Ninja,
  Wizard and Werewolf, eight runtime checks total.
- Ninja displays a distinctive temporary shuriken in **both** maps;
  Wizard keeps original fireball frames. This is **not** final Art Team art.
- Windowed Godot screenshots from BOTH maps are captured in
  `ninja_cross_arena_visual.png`; yellow outlines/insets only magnify
  the original rendered projectile pixels, not generated artwork.
- Current Austin `austin/items` merge automatically retains both his
  swept `_hit_combat_target` and the Ninja-only visual modification; the
  separate legacy `gameplay_msd.tscn` scene conflict remains.

## Prior combined owner runtime evidence (historical snapshot)

- Earlier 12/12 targeted tests passed in an unpublished manually resolved
  worktree using Austin items, Ethan wind, Jackson's later burning code
  and Eva Health components with Angela's **earlier** menu state.
- Do **not** represent those 12 tests as a successful merge of Angela's
  **current** `6181700` branch; see CROSS_BRANCH_COMPATIBILITY.md.
- No peer branch was changed or pushed. The PR still requires an owner-reviewed
  final integration, Design/Art approval and a match UI E2E playtest.

## Art Team asset integrity

Original Garden Piskel source-derived layers still reconstruct exactly;
original Ninja/Werewolf/Bird frames are unchanged. The temporary drawn
shuriken, apple and gnome sprites are not attributed to Art Team.
The current Garden contact sheet and screenshots show an actual Godot
windowed render. Fresh image imports are required before Godot tests.
