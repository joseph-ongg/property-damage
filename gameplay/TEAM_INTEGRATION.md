# Gameplay team integration handoff

**Scope:** Independent two-player gameplay prototype for the Oct 15 MSD.
This branch does not own the repository's `main.tscn`, Simulation storage,
Angela's collision prototype, or the Art team's final mage textures.
Experimental books, appliances, magic, and fantasy quests are not approved
requirements and should be reviewed separately from core MSD gameplay.

## Run without changing the team's main scene

Open **`res://gameplay/playtest_main.tscn`**, press **F6** in Godot 4.7.2,
and use the controls in the root README. This scene creates two players,
world collision, a temporary material grid, UI, and optional prop prototypes.
`main.tscn` is kept identical to the repository's `main` branch so it can
remain under the project's integration owner's control.

For the separate fantasy experiment, open
`res://gameplay/demo/gameplay_test.tscn` and press F6.

## Team ownership and collision contracts

| Team / work | Current integration point | Required coordination |
| --- | --- | --- |
| Angela: `angela/CollisionShape2D` | Her `gameplay/player.tscn` is a 32×64 `CharacterBody2D` with world mask 1, player layer 2 | Gameplay's full prefab is now `gameplay/prefabs/gameplay_player.tscn` so the two files do not collide; decide whether to keep hers as the simple test character or replace it with the full prefab in the real arena |
| Ethan: `ethan/burn-box-grid` | `GameplayFireBridge.grid_path` uses the public `MaterialGrid` API; production must supply real storage | Never merge temporary demo storage into the production Simulation. Swap the `MaterialGrid` scene script from Gameplay's `demo_material_grid.gd` to Ethan's `material_grid.gd` once merged; configure the final material map |
| Jackson: `sim/jackson/burn-box-render` | Renderers use `MaterialGrid.cell_changed(x,y)` and `is_burning()` | His production grid renderer and Gameplay's decorative fire visuals serve different purposes; use the production renderer with the real map and disable duplicate whole-grid debug previews |
| Art | `GameplayPlayer.sprite_override`, `Sprite2D`, and `CollisionShape2D` | Set `sprite_override` per player in the inspector; leave it null to use temporary mage sprites. Adjust the collider and sprite offset for final art; one-way platform drop reads the actual collider height |
| Gameplay | `GameplayPlayer`, `GameplayMotor`, `GameplayPlatformDrop`, `GameplaySparkEmitter`, `GameplayFireBridge` | Instantiate the complete prefab twice and point each `fire_bridge_path` at the bridge and the bridge `grid_path` at the actual Simulation node |

## Required gameplay inputs and physics

- P1 uses A/D movement, W jump/double jump, S+W platform drop, F Spark;
  E interactions and G ranged magic are optional prototypes.
- P2 uses Left/Right, Up jump/double jump, Down+Up drop, Enter Spark;
  Shift interactions and period ranged magic are optional prototypes.
- Independent `p1_*`/`p2_*` actions are registered at runtime by
  `gameplay/input_actions.gd` without changing global `project.godot`.
- Players use collision layer 2 and mask 1. World bodies use layer 1;
  solid walls/floors must be separate physics bodies, and furniture tops use
  `CollisionShape2D.one_way_collision`.
- Both the Gameplay prefab and Angela's basic player scene now use a
  **32×64** rectangle, with collision layer 2 / mask 1. The Gameplay collider
  has a local **(0, -12)** offset to preserve the temporary 28×44 mage art's
  existing feet alignment and Spark/interaction positions. Angela's sample
  shape is centered at (0, 0); adjust that local offset alongside the final
  mage art rather than shifting the entire room. The platform-drop component
  calculates the real shape bounds and also handles a centered 32×64 or older
  22×40 body. Keep the `CollisionShape2D` node name in the final prefab.

## Review / merge order

1. Land Ethan's Simulation implementation and resolve any changes to its
   public material API. Do not take ownership of `onboarding/` through Gameplay.
2. Decide with Angela and Zander which player prefab is the production one.
   Both scenes can coexist; the complete Gameplay prefab is already isolated.
3. Have the arena owner create the production arena with the agreed collision
   geometry, real MaterialGrid, and art. Instantiate Gameplay's player prefabs
   into that arena without replacing its root scene.
4. Wire the real Grid node to `GameplayFireBridge.grid_path`, then enable the
   final renderer and test actual ignition of combustible cells.
5. Merge approved core Gameplay first. Review the optional props, magic, and
   fantasy-level experiment separately.

## Regression coverage

Run every `.gd` in `gameplay/tests/` headlessly using Godot 4.7.2. The most
relevant handoff checks are `gameplay_full_flow_test.gd` (whole cooperative
session), `gameplay_keyboard_chords_test.gd` (physical-key combinations),
`gameplay_collider_handoff_test.gd` (two 32×64 placements and legacy 22×40),
`gameplay_art_handoff_test.gd` (Inspector texture overrides),
`gameplay_simulation_contract_test.gd` and
`gameplay_grid_scene_handoff_test.gd` (Simulation integration), and
`gameplay_restart_playtest.gd` (pause/restart).

Angela's test arena and the Ethan+Jackson Simulation components were also
loaded together with Gameplay in an **isolated temporary project copy**. That
smoke test does not change or merge anyone's upstream branch.
