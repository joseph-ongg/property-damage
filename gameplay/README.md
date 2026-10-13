# Gameplay Module Guide

Start with the [root README](../README.md) for the complete feature list, controls, run instructions, and current limitations. This document focuses on module boundaries, integration, and testing.

## 1. Default and optional scenes

| Scene | Path | Purpose |
| --- | --- | --- |
| Gameplay playtest (F5 or F6) | `gameplay/playtest_main.tscn` | Default startup in this branch; independent Property Damage two-player living-room prototype with movement, collision, Spark, and optional interactions |
| Optional (F6) | `gameplay/demo/gameplay_test.tscn` | Separate Moonlit Ruins fantasy prototype with Dash, collectibles, brazier mechanics, and experimental victory conditions |

**Moonlit Ruins, collectibles, combos, and its win conditions are not Zander's confirmed MSD requirements.** Do not include that separate experiment in the team's core Gameplay PR without approval.

## 2. Core modules

| Module | Path | Purpose |
| --- | --- | --- |
| Player | `player.gd`, `prefabs/gameplay_player.tscn` | `CharacterBody2D`, action inputs, facing, and component connections |
| Input mapping | `input_actions.gd` | Registers `p1_*` / `p2_*` actions without requiring shared `project.godot` input changes |
| Motor | `components/player_motor.gd` | Fixed-height double jump, air momentum, coyote time, and jump buffer |
| Platform drop | `components/platform_drop.gd` | Temporarily ignores the one-way platform under the player, never solid ground |
| Spark | `components/spark_emitter.gd` | Directional ignition target and independent cooldown |
| Simulation bridge | `components/fire_bridge.gd` | Calls the Simulation `MaterialGrid` public API and checks actual burning state |
| Optional components | `components/player_dash.gd`, `components/fire_hazard.gd` | Experimental Dash (disabled in default MSD) and fire-contact logic |

Player collision layer is 2 and the world collision layer is 1. Players collide with the world, not each other. Static world collision bodies must exist separately from visual background textures.

## 3. Optional living-room modules

- `msd/msd_controller.gd`: Connects players, interactable props, Spark, and appliance effects. Includes the `experimental_books_enabled` and `experimental_appliances_enabled` switches.
- `msd/burnable_prop.gd`: Lightweight book pickup, carrying, throwing, and scorch visuals—not a full physical material-destruction system.
- `msd/appliance.gd`: Fridge toggle, fan push, AC slowdown (`effect_radius=130`, `cold_speed_scale=0.45`), and computer damage visuals.
- `msd/magic_bolt.gd`: Experimental `G` / `.` projectile that changes prop visuals without assigning combat damage.
- `msd/interaction_hints.gd`: Nearby interaction instructions that share target selection with the controller's `get_interaction_offer()`.
- `msd/player_conditions.gd`: `SLOW` and `WIND` visual states; physics remains owned by the motor and MSD controller.
- `msd/room_visuals.gd`, `msd/art/generate_room.py`: Pixel-art room visuals, independent of collisions.
- `integration/ethan_material_grid.gd`: Gameplay-scoped compatibility adapter using **Ethan's storage and ignition rules** from commit `46c3df2`, active in the default MSD arena. It inherits the existing `MaterialGrid` scaffold and adds no new fire algorithm. Replace it with the production Simulation path after upstream merges.
- `integration/team_material_renderer.gd`: Jackson-derived material palette and signal-driven updates, displayed as translucent pixel stripes instead of an opaque full-grid overlay.
- `integration/demo_material_grid.gd`: Legacy temporary storage for the separate Moonlit Ruins experiment only.
- `integration/material_setup.gd`: Paints test materials only; it does not store burning state.
- `demo/fire_visuals.gd`: Listens to `MaterialGrid.cell_changed` and draws subtle fire effects without implementing ignition or storage.

## 4. Integrating with the team's scene

1. Instantiate `gameplay/prefabs/gameplay_player.tscn` twice, using `player_index=1` and `2`, and configure distinct appearances.
2. Replace the standalone scene's `GameplayDemoMaterialGrid` script with the merged Simulation `MaterialGrid` and configure its real material map. Point `GameplayFireBridge.grid_path` to that grid; both players' `fire_bridge_path` references should resolve to the bridge.
3. Use world collision layer 1 and player layer 2 (player mask 1). Configure one-way tabletops using `CollisionShape2D.one_way_collision`.
4. Replace the temporary living room, material seeding, and test HUD with final team art and scenes. **Do not modify `onboarding/burn-box/burn_box.tscn`.**
5. Confirm final materials, mage sprites, propagation API, interactions, and game objectives with the Simulation, Art, and Design teams before including optional mechanics in the main build.

Austin's jump counter and platform-drop approach were adapted for this prototype. Ethan's `MaterialGrid` real implementation is now used as a Gameplay-scoped method snapshot for the default MSD arena, without touching Simulation-owned files. The separate fantasy demo still uses the older test implementation. See [`UPSTREAM_INTEGRATION.md`](UPSTREAM_INTEGRATION.md) for original commit SHAs and merge boundaries. Local integration does not mean a team PR has been approved.

## 5. Regression tests

Run an individual test from the repository root using Godot 4.7.2 Standard:

```bash
"../Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_msd_test.gd
```

| Test | Coverage |
| --- | --- |
| `gameplay_smoke_test.gd` | Two-player basics and ignition |
| `gameplay_edge_test.gd` | Jump buffering, boundary checks, and movement tolerances |
| `gameplay_controls_test.gd` | Actions and control response |
| `gameplay_msd_test.gd` | Default MSD scene with Gameplay-only demo material storage |
| `gameplay_upstream_drop_test.gd` | Independent one-way-platform drop and solid-floor safety |
| `gameplay_upstream_grid_test.gd` | Demo grid and Simulation-compatible fire API, materials, redraw events |
| `gameplay_simulation_contract_test.gd` | Integration behavior against main's scaffold or the installed Ethan grid |
| `gameplay_grid_scene_handoff_test.gd` | Active MSD scene wiring, material seeding, Spark, and grid replacement smoke test |
| `gameplay_advanced_test.gd` | Double jumps, air momentum, book pickup, and appliances |
| `gameplay_full_flow_test.gd` | Combined two-player movement, double jumps, Spark, drops, interactions, simultaneous magic, and long play |
| `gameplay_keyboard_chords_test.gd` | Physical Shift+W, concurrent keyboard controls, and F/Enter Spark |
| `gameplay_input_layout_test.gd` | Down+Jump on solid floors, independent on-screen P1/P2 key guides |
| `gameplay_visual_design_test.gd` | PPT character sprite footprints, room artwork dimensions, measured HUD text fitting |
| `gameplay_project_start_test.gd` | F5 startup loads the actual playable two-player scene, not the placeholder |
| `gameplay_midsem_art_test.gd` | Character design static/run GIF frames, red P2, Art Team furniture sprites and 6-frame pixel fireball |
| `gameplay_art_scene_alignment_test.gd` | Art Team sprite proportions, one-way platform/sprite alignment, material-cell ownership, nearest-neighbor pixels, real appliance interaction |
| `gameplay_collider_handoff_test.gd` | One-way drops with Angela-compatible 32×64 geometry and legacy 22×40 shapes |
| `gameplay_art_handoff_test.gd` | Replace mage art without changing player physics or controls |
| `gameplay_fan_playtest.gd` | Floor-level P1/P2 fan interaction, physical wind push, and safe turn-off near books |
| `gameplay_magic_test.gd` | Directional magic projectiles and prop effects |
| `gameplay_props_test.gd` | Scorching, embers, and repeated-hit protection |
| `gameplay_layout_feedback_test.gd` | Context prompts, AC slowdown, and range exit |
| `gameplay_render_layers_test.gd` | Fridge/AC art behind players; prompts and status overlays above |
| `gameplay_restart_playtest.gd` | Actual pause, resume, and R-restart input flows without freed-viewport errors |
| `gameplay_quest_test.gd` | Optional fantasy-level quest logic |
| `gameplay_ui_test.gd`, `gameplay_guidance_test.gd` | Optional-level HUD, help, and pause controls |

Run the whole Gameplay suite:

```bash
GODOT="../Godot.app/Contents/MacOS/Godot"
for script in gameplay/tests/*.gd; do
  "$GODOT" --headless --path . --script "res://$script" || exit 1
done
```

## 6. Code comments

Gameplay currently contains both Chinese and English maintenance comments. Their content is preserved without language labels. Comments document non-obvious movement behavior, interaction selection, Simulation integration boundaries, and original upstream contributors. Godot APIs and GDScript identifiers remain in English.

See [`ART_SOURCES.md`](ART_SOURCES.md) for pixel-art provenance and [`msd/DESIGN_NOTES.md`](msd/DESIGN_NOTES.md) for proposed versus confirmed game design.

## 7. Rendering layers

The independent living-room scene explicitly sets `z_index` values to keep the open fridge interior and wall-mounted AC behind the players: room backdrop **-5**, appliances **2**, players **10**, books **12**, projectiles **14**, interaction prompts **30**, and status overlays **31**. This changes drawing order, not collision. Run `gameplay_render_layers_test.gd` to prevent regressions.

## 8. Working with other teams

See [`TEAM_INTEGRATION.md`](TEAM_INTEGRATION.md) for collision shape compatibility with Angela, Ethan/Jackson Simulation handoff, Art sprite overrides, and the independent playtest entry point.

## 9. Local playtest presentation

The MSD living-room scene uses a 960×540 pixel layout. P1 and P2 have separate always-visible control panels with their required core keys and optional interactions; a compact top banner shows pause/restart keys and real Simulation status. The pause overlay uses the same blue/red player palette. `S+W` or `Down+Up` is a dedicated drop attempt: it will never trigger an accidental jump on a solid floor. Character idle/run art is imported from the Art Team Character design slide via `art/import_midsem_art.py` (original uncropped 736×736 PNG and GIF frames, scaled only at runtime in Godot), and matches Angela-compatible 32×64 colliders while retaining the original feet height. P2 is recolored red; the room imports Art Team furniture tiles, and projectiles use hand-painted pixel fireball frames.

## 10. Art Team scene and material alignment

The independent playtest keeps the Art Team's source sprite PNGs intact. The
room renderer lays out two properly proportioned shelf modules, a window below
the persistent HUD, and furniture whose rendered bounds agree with the Godot
collision platforms. The fridge uses a **90 × 154 px** image, with its top
aligned to the y=344 platform collision and its base on the y=498 floor; the
matching local fridge platform is 96 px wide. The air conditioner and monitor
retain their source width/height ratios. These changes apply to the isolated
Gameplay arena, not to the production Arena scene owned by other teams.

Spark's demo material seeding now includes bookshelf standing height (grid
row 19), and avoids painting flammable WOOD under the fridge footprint
(columns 45–52, row 29): those cells are STONE. Both the temporary floor
material grid and the fire overlay continue to use the **same** MaterialGrid
node, so no duplicate material state is introduced. The hit effects and fire
visuals use hard-edge pixel rectangles rather than blurred anti-aliased glows.
The production material grid remains Simulation-owned.

## 11. Design map, official Simulation snapshot, and second Art pose

- **Design slide 12 (Crime Scene):** The large moonlit/city window was removed
  because it was not in the Design Team's central desk/upper-wall AC layout.
  The room keeps the source Art Team's smaller left window, left bookcases,
  center desk and computer, clock, and right refrigerator; all original tested
  one-way physics platform positions remain unchanged.
- **Materials:** Seed WOOD across the real floor collision (rows 29–31),
  bookshelf standing row 19, and central desk rows 23–25. Fridge columns 45–52
  are STONE through row 31 and the wall-mounted AC is STONE in rows 20–21.
  Spark still targets material via `GameplayFireBridge` alone.
- **Ethan's working grid:** The normal MSD scene's `MaterialGrid` now uses
  `gameplay/integration/ethan_material_grid.gd`: Ethan-compatible storage/burn state,
  burn timers, signals, and extinction methods adapted from `ethan/burn-box-grid`
  commit `46c3df2`. This is *not* a production merge; the source-owned grid
  under `onboarding/` remains unchanged. After the upstream merges, the adapter
  automatically delegates to Ethan's parent methods instead of allocating
  duplicate arrays. We also test the merged-state configuration in a separate
  temporary project.
  There is still **no spread, oil movement, collapse, or physics damage** in
  this upstream commit; those were only proposed future features on the slides.
- **Jackson's rendering:** `TeamMaterialRenderer` listens to the same grid's
  `cell_changed` and uses Jackson's material/fire colors (source commit
  `c897a2e`). Air is hidden; non-air material receives transparent pixel
  markers instead of covering the entire original room with opaque quads.
- **Art Team slide 15:** The second original 736×736 static pose is displayed
  briefly for P1/P2 on Spark, interactions and magic. P2 is an exact pose copy
  with blue robe hues recolored red. Static idle and GIF movement frames
  remain unchanged. `art/import_midsem_art.py` locates slides by their actual
  titles, so reordering slides in the presentation does not break extraction.

`gameplay/tests/gameplay_team_integration_test.gd` guards the active storage,
renderer signals and alpha, Design's seeded material geometry, and both Art
interaction poses. The separate fantasy demo still uses its prior grid.

## 12. Merge-safe Simulation adapter and immediate Art action poses

The adapter used to redeclare `materials`, `burning`, `burn_timers` as inherited
members. When Ethan's upstream file is merged into the parent
`MaterialGrid`, that code fails Godot parsing because those names already
exist in the parent. The fallback fields now use private names, and the
adapter delegates directly to the parent's methods once their three storage
properties exist. No second set of fire cells is created in that state.
`gameplay_integration_merge_safety_test.gd` is exercised against both current
main's API scaffold **and an isolated copy where the exact original Ethan
`material_grid.gd` is installed**. The Art Team's alternate 736×736 casting
pose is now selected *after* processing the relevant input event, removing
the previous one-physics-frame latency for Spark/interact/magic.

## 13. Pixel depth and restored wall clock

The Art Team clock crop in the presentation's furniture composition is missing
part of its right border. The Gameplay room now reconstructs a complete analog
clock at the same wall location in `msd/art/generate_room.py`, while preserving
the original `team_clock.png`. The room is composited with independent
`RoomLighting` and `RoomForeground` sprites, both 960x540 transparent PNGs.
Their Z depth is: background (-5), material markers (-4), soft stepped light
(-3), actors (10), and only edge-of-frame foreground plants (11). All use
pixelated, nearest-neighbor sampling, not blurred upscaling. Source files and
attribution are listed in `ART_SOURCES.md`.

The enhanced wall paneling, wood floor perspective, baseboard, shadow contacts
and clock are **visual only**; static bodies, character interactions, material
IDs and Simulation storage remain unchanged. The old Art Team clock texture
is still included but intentionally no longer composited into the wall.
`gameplay_room_depth_test.gd` checks pixel completeness and physics boundaries.

## Compact dual-player playtest feedback

The bottom strip uses concise, independently labeled P1/P2 input reminders
and matches the blue/red Art Team character colors. The room remains marked
as a **prototype** to avoid implying an approved final game mode.
`interaction_hints.gd` lays out the two nearby prompts together, keeping
panels in the playable vertical range and avoiding overlap when both players
reach the same object. Device prompt and event text share physical state:
refrigerators now report `OPEN`/`CLOSED` rather than power `ON`/`OFF`, while
fan/air-conditioner/computer retain their existing power semantics. See
`gameplay_interaction_polish_test.gd` for scene-based acceptance checks.

## 14. Simultaneous co-op device input

Two characters can press their use buttons during the same physics frame.
Previously, a shared refrigerator or air-conditioner received **two**
sequential toggle requests, leaving it in the original state with confusing
feedback. `msd/msd_controller.gd` now remembers the physics frame of a
**successful** device interaction for each device instance and ignores only
additional toggles of that same device in that frame. A new deliberate press
on any later frame still works, and two separate appliances can be controlled
independently. This logic lives in the Gameplay controller and does not alter
Simulation storage, Art textures, world collisions, or upstream furniture
scenes.

`tests/gameplay_simultaneous_use_test.gd` exercises actual dual-player
inputs on the real Gameplay scene: shared fridge, shared AC (including both
players being slowed), subsequent deliberate close, and simultaneous use of
different appliances. The regression was reproduced before the fix and passes
with the fix. The editor-run `.uid` files for the new test and the existing
cross-team arena check are included to avoid regenerating them on each import.

## 15. Magic bolt occlusion and book throw inspection

The optional projectile previously raycasted to the next frame's endpoint
but still performed proximity-based book/computer hits at the wall impact
point. This could scorch books just behind the collider. The computer's
wider 49px interaction radius also triggered *before* the bolt reached
certain thin barriers. `msd/magic_bolt.gd` now stops when the swept
projectile ray hits world layer 1, and verifies an unobstructed world-layer
ray toward each nearby candidate **before** applying any visual effect.
Player bodies remain on layer 2 and cannot block another player's shot.
This only changes local optional prop feedback; it does not modify
Simulation ignition, mana, scores or damage systems.

`gameplay_magic_occlusion_test.gd` includes before/after regression cases
for a book immediately beyond a world obstacle, a computer triggering from
its larger radius, and unobstructed positive controls for both prop types.
The original behavior was reproduced with a failing test before this fix.
Book pickup/throw were also operated in the Godot runtime and photographed
for visual inspection; the existing throw physics and material layout were
not changed.

## 16. Book throw collision sweep

The optional book prop previously cast a single diagonal ray from its lower
edge. A high-speed sideways throw into a layer-1 wall could pass through it
or incorrectly count the wall as a floor, leaving the book suspended in air.
`msd/burnable_prop.gd` now separates **horizontal sweeps** from **downward
support checks**. It tests the book's leading edge at three heights against
solid world geometry, excludes the sides of one-way platforms, applies a
small horizontal rebound at a real side impact, and tests three bottom-edge
sample points for downward landings. Books still pass upward through the
same one-way shelf and table platforms that the players use. The playtest
room's bottom safety clamp is retained; it is not a new upstream Simulation
or production arena physics system.

`tests/gameplay_book_collision_test.gd` guards against tunneling, false
mid-air landings, shelf underside obstruction, bookshelf top landing,
falling outside platform bounds, partly overlapping the table edge, and
P2 recovering and re-throwing a settled book. The original two wall bugs
were reproduced with failing assertions before this change. A real Godot
runtime shelf-landing capture is kept under
`presentation_media/screenshots/book_shelf_landing_live.png` locally.

## 17. Resting book support after landing

Thrown books previously stopped updating physics as soon as they landed.
That left them suspended if a supporting `StaticBody2D` was moved, disabled,
removed, or if the book was nudged over a platform edge. The standalone
Gameplay prop now tracks the last **actual layer-1 collision body** it landed
on, carries the book by that body's change in position, and probes bottom
contact points each physics frame while the book is resting. Losing that
support starts a new fall; a queued-for-deletion platform is handled without
accessing a freed object. Landings keep a small fraction of horizontal
momentum, reduced by friction, to allow a book to slide off marginal ledges.
Support tracking is cleared on pickup and throw. Static books authored in the
scene are left at their original art coordinates until first interacted with,
so the Design/Art teams' initial furniture composition is unchanged.

`gameplay_book_support_test.gd` covers stable tabletop landings, translating
platforms, disabled collision, removed bodies, bookshelf edge departure,
natural post-landing momentum sliding, stable floor recovery, and alternating
P1/P2 pickup and re-throw. These tests modify **runtime instances only**, not
team-owned scenes or Simulation `MaterialGrid`. The original unsupported
behavior was reproduced by failing tests before the fix.

The optional Gameplay bookshelf/table/floor are still prototype geometry;
this change does not imply the final shared arena has dynamic platforms.
Local Godot runtime evidence is recorded in
`presentation_media/screenshots/book_platform_support_before_after.png`.

## 18. Interaction reachability across world obstacles

Proximity alone previously allowed players to **pick up books or operate
appliances through solid walls** if the target was within the 56px/78px
interaction radius. This contradicted the optional Gameplay prop collision
rules. The new shared `msd/interaction_los.gd` tests a ray from the player
to the selected book or appliance control against solid world layer 1.
It ignores **one-way furniture platforms**, preserving their original
pass-through behavior from below and the existing two-player separation
on player collision layer 2. All existing distance limits remain enforced.
The controller and its hint UI already share `can_pick_up()` and
`can_interact()`, so they now correctly exclude unreachable objects without
maintaining a second target-selection implementation.

`gameplay_interaction_occlusion_test.gd` reproduces blocked and unblocked
book pickup using P1's actual E input, verifies throwing a retrieved book,
blocks fridge interactions through a thin wall, validates removal of that
wall, and checks reachable books under one-way platforms for both P1 and P2.
It first reproduced the original problem with failing assertions, then
passed after the shared reachability guard was installed. The optional
`CAPTURE_INTERACTION_LOS` environment variable saves actual Godot runtime
images of a temporary wall in an isolated test scene. The before/after
comparison is at `presentation_media/screenshots/interaction_wall_before_after.png`
in local project files. No Simulation source or other teammates' scenes
were edited, and this remains an experimental gameplay interaction rule.

## 19. Moving-platform crush and extreme thrown-book collision

The optional book prop previously followed a moving support by directly
adding the support body's displacement to its global position. A horizontal
platform motion could therefore **embed the book inside a layer-1 wall**.
Similarly, the old single-step book path could tunnel diagonally through
thin walls or vertically through a solid ceiling at artificially high debug
velocities. `msd/burnable_prop.gd` now sweeps its leading edge against solid
geometry while being carried, including upward motion under a ceiling. The
free-flying book resolves its displacement in bounded 4px substeps with
horizontal world-wall contact, downward-only landings on one-way platforms,
and upward collision against fully solid ceilings. A hit consumes the
remaining movement in the corresponding axis for that frame, so further
substeps do not re-enter the obstacle. Normal throw impulses and UI behavior
are unchanged; this is local prototype collision code, not a new Simulation
mechanic.

`tests/gameplay_crush_speed_test.gd` uses *real* runtime layer-1 collision
shapes. It reproduces wall embedding by translating the book's supported
platform, tests a player near a wall on a moving one-way platform, and
checks temporary roof obstruction. It also tests debug throws at 12,000px/s
(diagonal), 16,000px/s (upward into a roof), 24,000px/s (thin wall),
13,000px/s (downward landing) and 9,000px/s (upward pass-through). The old
wall, diagonal and roof bugs were demonstrated by failing tests before the
fix. For tests which teleport colliders directly, allow physics-server
synchronization before probing; immediate queries may see the old transform.

**Remaining integration boundary:** a `CharacterBody2D` loses support and
falls safely to the arena floor in the tested scenario where a manually
translated *one-way StaticBody2D* rises into insufficient ceiling space.
This is not a finished passenger-carrying elevator or a general-purpose
crush-resolution system. Moving platforms in the final team scene should
use an appropriate Godot dynamic-platform body/motion contract (e.g.
`AnimatableBody2D`) and be separately tested after integration.

Optional actual Godot screenshot evidence (temporary collision markers only)
is kept locally in `presentation_media/screenshots/crush_speed_actual_review.png`.
No Art Team sprites, Simulation storage, or other teams' scenes are modified.

## 20. Simulated AnimatableBody2D platform integration

`tests/gameplay_animatable_platform_test.gd` is a **simulated integration
handoff**, not the final Property Damage arena. It instantiates the actual
Gameplay main scene, existing GameplayPlayer and GameplayBurnableProp, then
adds temporary layer-1 `AnimatableBody2D` and solid wall/ceiling collision
bodies at runtime. The dynamic lift is physically translated each frame.
Godot runs the real CharacterBody2D `move_and_slide()` and the book's current
runtime collision queries; no mocked collision results are used.

The scenario covers stationary boarding, horizontal carriage of player and
book, a rising lift, wall pressure, ceiling pressure, and lost support.
A previous static-platform test had missed an **actual bug:** the book could
be carried through a ceiling by a rising platform because a successful roof
hit was followed by another snap to the supporting platform. The book now
**drops that support immediately at roof impact**, resumes gravity, and
never crosses the roof in the test's per-physics-frame checks. The player
rides the moving lift and is stopped by solid world geometry; in the tested
roof squeeze, it safely loses the lift and settles below. It is **not** a
full dynamic elevator/crush gameplay system and does not implement damage.

To retest in Godot from the project root (adapt the Godot binary path):

```sh
../Godot.app/Contents/MacOS/Godot --headless --path . \
  --script res://gameplay/tests/gameplay_animatable_platform_test.gd
```

To capture the *actual runtime* viewport for all four phases, run Godot
without `--headless` and set `CAPTURE_ANIM_PLATFORM` to an absolute output
file prefix. Temporary colored platform/wall/roof markers are inserted only
by the test script when capturing screenshots. Screenshots generated in the
local working copy are combined at
`presentation_media/screenshots/animated_platform_simulated_review.png`.

The team's eventual arena path, body types, moving-platform collision layers,
velocity and animation methods have not been established by this isolated
simulation. Re-run an equivalent test in that exact final arena once it is
merged. This change leaves upstream scene files, material grids, Art sources,
real level furniture and `project.godot` untouched.
