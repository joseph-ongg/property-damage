# Gameplay team integration handoff

**Scope:** Independent two-player gameplay prototype for the Oct 15 MSD.
This branch does not own the repository's `main.tscn`, Simulation storage,
Angela's collision prototype, or the Art team's final animation delivery. The current Gameplay placeholder sprites are extracted from the Art team's MidSem presentation (blue P1, red-tinted P2), with the original two-frame run loop.
Experimental books, appliances, magic, and fantasy quests are not approved
requirements and should be reviewed separately from core MSD gameplay.

## Run without changing the team's main scene

Press **F5** in Godot 4.7.2, or open
**`res://gameplay/playtest_main.tscn`** and press **F6**. This scene creates two
players, world collision, Ethan's real method snapshot in a Gameplay-local
grid class, Jackson-style translucent material pixels, UI and optional props. **For convenient branch playtesting, `project.godot` now sets only
`run/main_scene` to that Gameplay scene.** The root `main.tscn` file stays
identical to the repository's `main` branch; project integrators may restore
`run/main_scene="res://main.tscn"` (or point to the new production arena)
when deciding the eventual default startup scene. Do not merge unrelated local
Godot MCP autoloads or editor plugins.

For the separate fantasy experiment, open
`res://gameplay/demo/gameplay_test.tscn` and press F6.

## Team ownership and collision contracts

| Team / work | Current integration point | Required coordination |
| --- | --- | --- |
| Angela: `angela/CollisionShape2D` | Her `gameplay/player.tscn` is a 32×64 `CharacterBody2D` with world mask 1, player layer 2 | Gameplay's full prefab is now `gameplay/prefabs/gameplay_player.tscn` so the two files do not collide; decide whether to keep hers as the simple test character or replace it with the full prefab in the real arena |
| Ethan: `ethan/burn-box-grid` | Default MSD now runs his full commit `46c3df2` storage/ignition methods, copied into Gameplay's `ethan_material_grid.gd` as a subclass of the still-unmerged public base scaffold | No `onboarding/` files have changed. When Ethan's branch lands in main, change the scene's grid script to the **production** `material_grid.gd` and remove the temporary Gameplay snapshot |
| Jackson: `sim/jackson/burn-box-render` | Translucent gameplay renderer imports his real material/fire colors and `cell_changed(x,y)` invalidation logic | Opaque whole-grid renderer obscures the Art stage; review/replace `TeamMaterialRenderer` with his eventual production renderer after the official merge |
| Art | `GameplayPlayer.sprite_override`, `Sprite2D`, and `CollisionShape2D` | Set `sprite_override` per player in the inspector; leave it null to use the imported Art-team idle and run frames (blue P1 / recolored red P2). Adjust the collider and sprite offset for final art; one-way platform drop reads the actual collider height |
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
  has a local **(0, -12)** offset to preserve the current full-resolution 736×736 Art-team mage image (shown 60px tall in Godot)'s
  feet alignment and Spark/interaction positions. Angela's sample
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

## Art and material integration notes

- The independent Gameplay test scene derives visual composition and the mage
  PNG/GIF from the Art Team's MidSem deck. The team keeps ownership of final
  map art; Gameplay should not replace or overwrite a future production map.
- The refrigerator's local one-way collider now matches the drawn Art Team
  texture (96px platform versus 90px visual). Its top and bottom match
  y=344 and y=498 respectively; the desk, bookshelf and world walls stay
  at their existing positions.
- The **demo-only** `gameplay/integration/material_setup.gd` must seed
  flammable shelf cells at the standing player's Spark row. It intentionally
  marks the fridge region, including the fridge footprint at floor level,
  as nonflammable STONE. Production simulation's world material map should be
  configured separately by the Simulation owners.
- `gameplay_art_scene_alignment_test.gd` checks texture sizes, physical
  overlap, nearest-neighbor rendering, and the Spark/Simulation boundary.

## Additional MidSem deck handoff (Design, Simulation, Art)

The Design team's slide 12 "Crime Scene" shows a left bookcase/window,
central computer desk, upper AC, wall clock and right refrigerator. The MSD
room artwork now follows those zones without moving the agreed physics
platforms. `DesignMaterialSeed` is a temporary material **map**, not a fire
storage system; it should be replaced when the production arena provides its
own material layout. The normal Gameplay room uses Ethan's real `46c3df2`
method bodies in `ethan_material_grid.gd` and Jackson's color/signal renderer
in `team_material_renderer.gd`, but both are explicitly scoped to Gameplay
until upstream Simulation is merged. Do not ship duplicate implementations of
Ethan/Jackson's code after the final integration.
