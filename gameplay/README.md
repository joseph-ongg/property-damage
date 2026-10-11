# Property Damage — Gameplay development

**Default F5 / Godot `main.tscn`:** `gameplay/msd/gameplay_msd.tscn`,
which implements the Gameplay subteam's Oct 15 MSD scope. Two players run,
jump and face left/right; each has a Spark key to ignite a grid cell in front
of them. They collide with solid floor/walls and one-way furniture platforms.
This prototype uses a stand-in `DemoFireGrid` until the actual arena and
Simulation storage are integrated.

**Experimental optional scene:** `gameplay/demo/gameplay_test.tscn` (the
previously-created "Moonlit Ruins" art/quest prototype with shards, braziers,
dash, combos and a victory screen). Its invented fantasy names, quests,
collectibles and win conditions are **NOT** official Property Damage design.
They are not in the default scene, and should not be submitted as team
requirements without design approval.

**Sources of record:** Zander's Oct 6 Gameplay subteam MSD instructions; the
project's [PUBLIC] DP Designs document. The design document describes
possible living-room/bedroom environments, magic attacks, object interaction,
bookshelves, fridge, clock, fan and destructible furniture. Several suggestions
are explicitly tentative; an overall winning condition has not been confirmed.

## Controls

| | Run | Jump | Spark |
| --- | --- | --- | --- |
| P1 (turquoise) | A / D | W | F |
| P2 (orange) | Left / Right | Up | Enter/Return |

The default MSD scene does not activate the optional Q or / dash mechanic;
those controls are available in the separate experimental quest scene only.

Sparks target one grid cell just ahead of the character's current facing.
P1 and P2 share the same keyboard but have separate InputMap actions. Players
are `CharacterBody2D`s on layer **2** with mask **1** (world), so they pass
through each other; the arena's floor/walls use world layer **1**.

## Modules — submit only what your assigned task needs

| Feature / independent PR area | Owned file(s) | Depends on |
| --- | --- | --- |
| Input mappings | `gameplay/input_actions.gd` | Godot InputMap |
| Character movement/jump physics | `gameplay/components/player_motor.gd` | CharacterBody2D |
| Simulation grid adapter | `gameplay/components/fire_bridge.gd` | Existing `MaterialGrid` API (or any compatible grid) |
| Facing-aware spark & feedback | `gameplay/components/spark_emitter.gd` | Fire bridge |
| Optional fire damage contact | `gameplay/components/fire_hazard.gd` | Fire bridge |
| Reusable player + colored placeholder | `gameplay/player.gd`, `gameplay/player.tscn` | Input + Motor + Spark + Hazard |
| Fake static arena + graphics | `gameplay/demo/gameplay_test.tscn`, `arena_visuals.gd` | Player prefab |
| Demo-only fire storage | `gameplay/demo/demo_fire_grid.gd` | No Sim dependencies |
| Demo bootstrap and UI | `gameplay/demo/demo_controller.gd` | All above; registered input |
| F5 entry point | `main.tscn` | Demo scene |

Files are intentionally separate. For a small PR, select the script(s)
corresponding to your task **and their dependencies**; don't push the complete
demo if your assigned task only covers a component. The local git history is
also separated into topic commits to make cherry-picking easier.

## Integrating with Simulation

1. Instance `gameplay/player.tscn` twice inside the real arena. Assign
   `player_index=1` and `2` and distinct tints. Keep `collision_layer=2`,
   `collision_mask=1` and add world colliders on layer 1.
2. Add `gameplay/components/fire_bridge.gd` to a Node and set its `grid_path`
   to the real `MaterialGrid` node (the Node with `world_to_cell`, `ignite`,
   `is_burning`, and optionally `in_bounds`).
3. Point both Player nodes' `fire_bridge_path` at that FireBridge Node.
4. Controls register automatically when each player enters the scene tree;
   you do not need to edit the project's Input Map or write bootstrap code.
5. Remove the `DemoFireGrid`, fake arena and HUD from the real game. **Never
   modify `onboarding/burn-box/burn_box.tscn`.**

The demo fire grid is purely a testing stand-in because the current Simulation
storage methods are placeholders. Its cells glow for eight seconds after
ignition. It is **not** the production fire simulation or an implementation
of propagation/material rules. Spark feedback appears even when a real grid
ignition has no visible effect yet.

`GameplayFireHazard` is an **optional disabled-by-default** sensor. Enable it
and connect `touched_fire` to a future health component once Sim has working
`is_burning` storage. No health/damage system is asserted to be complete.

## Tests

```sh
"/path/to/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_smoke_test.gd
```

Run the extended edge-case checks as well:

```sh
"/path/to/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_edge_test.gd
```

The smoke test covers both control schemes, movement, jumping, one-way
collisions, wall boundaries, player layers, facing, spark keys, and the fire
adapter. The edge tests cover coyote jumps, buffered jumps, cooldown, grid
reconnection, and out-of-bounds recovery. An exit status of 0 means all checks
passed.

Jump timing is configurable in the `Motor` subnode: `coyote_time` (0.10s)
and `jump_buffer_time` (0.12s). Sparks have independent `cooldown` tuning.
The HUD explicitly distinguishes successful demo fire from requests sent to
a Simulation backend that hasn't implemented cell storage yet.

## Suggested independent team PRs

- `suwen/input-movement`: input actions + motor (or compose player if needed)
- `suwen/spark-fire-bridge`: grid integration + spark component
- `suwen/player-prefab`: reusable player scene; include its dependencies
- `suwen/test-arena`: demo-only sandbox; submit only if requested

The MCP Toolkit is a **local development tool**; it is not a project runtime
dependency. Do not commit `project.godot` changes caused by enabling the MCP
plugin, or the local `addons/godot_mcp_toolkit/` folder, to team PRs.

## Moonlit Ruins — optional art and quest layer

This original pixel-art direction uses a layered dusk sky, warm lantern light,
ornate mages, textured stone, copper-topped wood, and atmospheric ruins.
It draws from the general mood of HD-2D RPGs, but all artwork here is freshly
created and **does not reuse any existing game's assets or characters**.

The new gameplay features are **separate from the required two-player core**:

| Mechanic | Files | Details |
| --- | --- | --- |
| Dashing | `components/player_dash.gd` | P1 = Q, P2 = `/`; tuned 0.15s / 0.8s cooldown |
| Ember shards | `interactables/ember_shard.gd`, `.tscn` | Five pickups; either player collects on overlap |
| Fire braziers | `interactables/ember_brazier.gd`, `.tscn` | Directional spark ignites three nearby shrines |
| Duo spark combo | `demo/demo_controller.gd` | Alternating players within 2.5 seconds adds a combo |
| Completion condition | `demo/demo_controller.gd` | Gather all shards + light all three shrines |
| Restart | `demo/demo_controller.gd` | Press R in the playable demo |
| Original visual assets | `art/*.png` | Nine pixel-art PNGs, all local and reusable |
| Art source | `art/generate_art.py` | Deterministic source for regenerating PNGs (Pillow, development only) |
| World rendering | `demo/environment_art.gd`, `arena_visuals.gd` | Decorative backgrounds and tile visuals only; physics is untouched |

The base `GameplayPlayer` prefab now includes a `Dash` component and sprite.
It still only collides with World Layer 1, still uses `CharacterBody2D`, and
remains compatible with real Simulation once the fire bridge points to it.
The test arena is still isolated from `onboarding/burn-box/burn_box.tscn`.

```sh
"/path/to/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_quest_test.gd
```

**Porting note:** omit the entire demo quest layer in production if the team
assigns only movement, spark, or arena work. The quests never modify fire
storage, spread, or MaterialGrid scripts. Default maze art is a prototype, not
an exact implementation of a final Simulation arena or a real HD-2D renderer.

## Presentation polish (optional, no Simulation dependency)

- `demo/hud_frame.gd`: legible framed HUD with separate player colors and
  real-time shard/brazier progress meters.
- `demo/ambient_motes.gd`: lightweight deterministic background motes, drawn
  at a 24 fps cadence independently of gameplay physics.
- `demo/visual_feedback.gd`: pooled ephemeral burst labels on sparks,
  pickups, and braziers; expires automatically after 1.05 seconds.
- `demo/pause_overlay.gd`: press P or Escape to pause/resume. In the paused
  screen press R to restart; this has no effect on other teams' scenes.
- `demo/victory_overlay.gd`: completion presentation with player contributions
  and combo stats. Press R to play the demo again.

Run `gameplay/tests/gameplay_ui_test.gd` headlessly to verify pause/resume,
visual-feedback expiry, HUD progress updates and completion overlay.
These additions affect the standalone demo, not `burn_box.tscn`.


## Input and visual response refinements

- Jump **tap** now produces a short hop; **hold** jump to reach tall one-way
  platforms. `GameplayMotor.jump_cut_multiplier` (default `0.48`) controls the
  shortened arc. Coyote time and buffering continue to work.
- Dash locks its starting direction for the full burst, even if the opposite
  direction is pressed. Steering returns automatically when the dash ends.
  Both players retain separate cooldowns and collision with world only.
- `components/spark_aim.gd` draws a small pixel target at exactly the same
  offset used by `SparkEmitter` for ignition. It dims during cooldown.
- `components/landing_fx.gd` provides a brief landing dust effect, independent
  of Simulation and character art. Neither VFX script modifies collisions.
- In the **demo only**, fire cells now appear as subtle ember clusters rather
  than opaque burning squares in empty air; the `MaterialGrid` API and stored
  fire state have not been changed.
- Nearby fire braziers can still be lit by a valid spark target if the real
  Simulation grid is disconnected. Gameplay objectives are therefore not
  incorrectly blocked by placeholder Simulation storage.

```sh
"/path/to/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_controls_test.gd
```

This checks short-vs-high jumps, dash direction locking under opposing input,
aim marker alignment, landing FX cleanup, and the missing-grid fire-brazier
fallback. All new systems remain inside `gameplay/`.

## Compact in-game HUD, controls help and objective guidance

- The default upper-left HUD is intentionally compact; long key mappings no
  longer obscure the moonlit level. **Press H** for the full two-player control
  guide (including short/long jump tips and the three objectives).
- While the help guide is visible, the world is paused; **H closes it**.
  The help and `P`/`Esc` pause menu are mutually exclusive and cannot stack.
- `demo/objective_guides.gd` places subtle gold marks above uncollected shards
  and amber chevrons above unlit braziers. When a player's spark target is
  within the brazier's ignition radius, its guide turns green; once completed,
  the marker disappears.
- These are self-contained, optional demo visual modules. All existing
  `GameplayPlayer`, `MaterialGrid`, collision, and Simulation APIs are unchanged.
- Check `gameplay/tests/gameplay_guidance_test.gd` for help/pause and objective
  regression coverage.

## Testing the team-scoped default MSD

- Open the repository with Godot 4, press F5.
- P1: A/D to move, W to jump, F to Spark.
- P2: left/right to move, Up to jump, Enter to Spark.
- Press P or Escape to pause, R to restart when not paused.
- The colored player art is a temporary independent local sprite, **not** the
  Art team's approved final sprite.
- In `gameplay/msd/`, `room_visuals.gd` is a decorative placeholder for a
  living room with bookshelf, table and fridge. `gameplay_msd.tscn` owns their
  world collision and one-way platform setup. Replace this fake arena once
  Simulation supplies the real collisions.
- There is no score, health bar, fake win condition or invented quest UI.
  Spark status only reports whether a fire-grid ignition request was accepted.
  Real material damage/spread and victory mechanics remain unimplemented.
- Test the official MSD independently with:

```sh
"/path/to/Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_msd_test.gd
```

## Living-room pixel art + property-damage exploration (optional)

See `gameplay/msd/DESIGN_NOTES.md` for the confirmed Slack acceptance criteria,
design-team proposals, comparison principles from TowerFall and Noita, and
recommended staged implementation order. The pixel scene is generated from
`gameplay/msd/art/generate_room.py` into `living_room_pixel.png` (Pillow only
needed when **regenerating** this checked-in asset).

The three book bundles in the default living-room prototype are a **tentative
visual experiment**, not agreed scoring/game objectives. Spark near one to
briefly show embers and leave a persistent charred appearance. This does not
modify `MaterialGrid` or spread fire; switch
`GameplayMSD.experimental_books_enabled = false` to disable the mock response.
Run `gameplay/tests/gameplay_props_test.gd` for its interaction regression.
