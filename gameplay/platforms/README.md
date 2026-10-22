# Gameplay platforms — Suwen's October 20 subteam task

The Gameplay Subteam assigned Suwen **"Add platforms"** in its October 20 meeting. This implementation branches from `origin/main`, which already includes the team's material-grid and fire PRs. It leaves Eva's HP values, Austin's grid conversion, Angela's interactions, and Simulation code untouched.

## Room installation

The local living-room playtest instantiates four `res://gameplay/platforms/one_way_ledge.tscn` platforms as direct children of `GameplayMSD`:

| Scene node | World center | Width (16px cells) | Finish | Navigation purpose |
|---|---|---:|---|---|
| `LeftStep` | (112, 416) | 6 (96px) | Painted wood | Ground → bookshelf |
| `GalleryStep` | (400, 288) | 7 (112px) | Stone | Bookshelf → higher shelf |
| `RightStep` | (880, 416) | 7 (112px) | Painted wood | Ground → fridge top |
| `UpperRightStep` | (704, 256) | 6 (96px) | Brass | Fridge top → upper right |

These are **independent, optional Gameplay collision platforms**. Their Art/Design materials are visual tags only, not authoritative grid values or fire sources. The existing `BookshelfTop`, `TableTop`, and `FridgeTop` are retained unchanged. The scene's floor and outer walls remain fully solid.

## Public handoff contract

- Prefab root: `GameplayOneWayLedge` extends `StaticBody2D`; an instanced `CollisionShape2D` has `one_way_collision=true`, world `collision_layer=1` and `collision_mask=0`. Players remain on layer 2, colliding with world layer 1; P1/P2 still pass through each other.
- Inspector: `platform_id`, `span_cells`, `visual_finish`, `material_tag`, `design_cell_size`. Width derives from `span_cells * design_cell_size`, currently 16 px per cell. Collision shapes are independently duplicated on instantiation so changing one platform does not resize another one.
- Integration getters: `surface_width()`, `surface_center()`, `world_surface_bounds()`. Level Design can replace the prefab, set its ID and size or move it without modifying Gameplay's player controller.
- Grid boundary: **No MaterialGrid writes.** Austin can choose grid snapping and map `world_surface_bounds()` through the authoritative `world_to_cell()` API. Ethan owns cell storage/ignition and remains completely unmodified. A tag like `stone` does **not** claim to make the corresponding cell fireproof.
- Art boundary: `_draw()` renders a low-contrast, pixel-oriented top bevel, tile segments, and bracket support. This procedural placeholder is not Art Team artwork. It can be replaced by independent child sprites while keeping the collision prefab/ID contract.
- Dynamic-platform boundary: these new platforms are deliberately `StaticBody2D`, not `AnimatableBody2D`. Moving lifts should use the existing separate animated-platform test and explicit platform-motion logic; do not animate these static nodes expecting passenger transport.
- Both players' original `W` / `Up` jumping and `S+W` / `Down+Up` one-way drop controls remain unchanged.

## Verification

`res://gameplay/tests/gameplay_new_platforms_test.gd` tests both players' real jump and landing physics, one-way drop to solid floor, independent collider sizes, source-material separation, and real book support. Set the `CAPTURE_PLATFORMS` environment variable to an absolute screenshot prefix and run this test with a GUI Godot instance to save before/after frames.

Screenshots from the local test run are in `presentation_media/screenshots/platforms_placement_review.png`. Keep screenshot files outside team-facing Gameplay code commits unless expressly needed for the PR.
