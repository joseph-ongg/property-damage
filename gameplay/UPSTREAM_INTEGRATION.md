# Gameplay–Simulation integration boundary

**Status:** Draft Gameplay PR #4 exists, but the newer Design/Simulation/Art changes are local-only and not yet pushed. The Gameplay
branch leaves all files in `onboarding/` exactly as they are in `main`.

## Ownership

| Owner | Source reference | Adaptation in Gameplay |
| --- | --- | --- |
| Austin | `a529274` from `sim/jackson/burn-box-render` | Adapted independent jump counters and Down+Jump one-way platform drops in `gameplay/components/` |
| Ethan | `46c3df2` from `ethan/burn-box-grid` | Followed the public `MaterialGrid` methods, enum, and `cell_changed` signal in `GameplayFireBridge` |
| Jackson | `c897a2e` from `sim/jackson/burn-box-render` | Optional `cell_changed`-driven fire and material preview in `gameplay/` only |

**Do not merge or overwrite Ethan's `onboarding/burn-box/material_grid.gd` via a
Gameplay PR.** Main still has a scaffold for that file; Ethan owns the real
implementation. The exact `MaterialGrid` file in this branch was restored to
`main`, so the Gameplay PR will have no diff in `onboarding/`.

## Why the standalone demo still ignites cells

The default MSD room now uses a Gameplay-local snapshot of **Ethan's actual
`46c3df2` code** (`ethan_material_grid.gd`). Its `materials`, `burning`, and
`burn_timers` arrays and all ignition/extinguish methods come from his
upstream file. This snapshot extends the main branch's still-empty
`MaterialGrid` scaffold and does not override any Simulation-owned source.
The separate fantasy experiment retains `demo_material_grid.gd` for legacy
tests. Gameplay's `FireBridge` and renderers never own fire state.

`team_material_renderer.gd` uses Jackson's material palette and
`cell_changed` signal approach with transparent blocks, because his current
opaque AIR/full-grid renderer would cover the room artwork. No fire spread,
water flow or structural collapse is present in Ethan's branch yet.

## Handoff procedure after Ethan's PR merges

1. Pull the latest `main` after the Simulation owners merge Ethan's grid.
2. In the production scene, change the `MaterialGrid` node's script from
   `res://gameplay/integration/ethan_material_grid.gd` to
   `res://onboarding/burn-box/material_grid.gd`.
3. Replace `DesignMaterialSeed` test painting with the real arena's material data.
4. Keep `GameplayFireBridge.grid_path` pointing to the scene's grid and both
   players' `fire_bridge_path` pointing to the bridge. It checks actual
   `is_burning()` state after calling `ignite()` (which returns `void`).
5. Re-run the Gameplay tests, especially `gameplay_simulation_contract_test.gd`,
   `gameplay_upstream_grid_test.gd`, and `gameplay_msd_test.gd`. Also test the
   exact production scene in Godot before merging.

The tests are designed to handle both the current unimplemented `main` scaffold
and Ethan's actual storage. Compatibility with Ethan's original file can be
verified in a **temporary project copy**, replacing only that file there;
never do this by editing the production branch's Simulation file.

## Original references

- [Austin: `a529274`](https://github.com/joseph-ongg/property-damage/commit/a5292743351c673dcd095efabcba34f6f996219b)
- [Ethan: `46c3df2`](https://github.com/joseph-ongg/property-damage/commit/46c3df2d01275ce1ebbaee87bb3f7ba19e4dabb4)
- [Jackson: `c897a2e`](https://github.com/joseph-ongg/property-damage/commit/c897a2e735c4c65f4173cb4b4a542e94f512323b)
