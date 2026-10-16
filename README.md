# Property Damage — Two-Player Gameplay Prototype

> **Status:** A playable, independent Gameplay prototype for the Property Damage project, **not** a merged or officially approved final build. The extra furniture interactions, ranged spells, and pixel-art room are optional experiments. Final win conditions have not been confirmed.

[Getting started](#getting-started) · [Controls](#controls) · [Features](#implemented-features) · [Code map](#code-map) · [Tests](#testing) · [Credits](#code-and-art-attribution)

## Getting started

1. Install **Godot 4.7.2 Standard** (GDScript; the .NET edition is not required).
2. Import the repository root containing `project.godot` into Godot.
3. Press **F5** to run the independent two-player living-room prototype, now configured as the branch's default project startup scene. You can also open `gameplay/playtest_main.tscn` and press **F6**. The repository-owned `main.tscn` file remains unchanged.
4. To try the unrelated fantasy prototype, open `gameplay/demo/gameplay_test.tscn` and press **F6**. Its Moonlit Ruins theme, collectibles, brazier objectives, and victory conditions are *not* confirmed team requirements.

## Controls

| Action | Player 1 (mint) | Player 2 (orange) |
| --- | --- | --- |
| Move / steer in air | `A` / `D` | Left / Right arrows |
| Fixed-height first jump and double jump | `W` (press twice) | Up arrow (press twice) |
| Drop through a one-way platform | `S` + `W` | Down + Up arrows |
| Spark: attempt to ignite the cell ahead | `F` | `Enter` |
| Ranged magic projectile (experimental) | `G` | `.` (period) |
| Pick up / throw a book; interact with furniture | `E` | `Shift` |
| Pause / resume | `P` or `Esc` | Shared |
| Restart the currently played Gameplay scene when unpaused | `R` | Shared |

Down+Jump only drops through one-way platforms; it does not jump from solid floors. Dash is disabled in the living-room playtest. The separate fantasy test scene uses `Q` and `/` for Dash. Available interactions appear contextually near nearby objects.

## Implemented features

### Core Gameplay

- Two independent players with horizontal movement, left/right facing, jumping, and a second jump that resets upon landing.
- Fixed-height jumps, horizontal momentum retained when releasing direction in midair, aerial steering, coyote time, and jump buffering.
- Solid floors and walls; one-way furniture platforms that can be jumped through from below or deliberately dropped through.
- Players on collision layer 2 interact with world layer 1 but pass through each other.
- Directional Spark via `GameplayFireBridge`, using the **`MaterialGrid` public API**. The default MSD scene now uses Ethan-compatible storage/ignition rules, implemented in an upstream-aware Gameplay adapter until his branch is officially merged; the separate fantasy experiment still uses a lightweight demo subclass. Production must switch to the Simulation-owned grid after merge. No extra burning-state store exists in the bridge or effects renderer.

### Optional visual and interaction prototypes

- Art-team-inspired pixel-art living room with clear platform edges, original uncropped Art-team Character design 736×736 blue/red mage stills and moving frames, scaled in Godot, split P1/P2 control panels, landing and Spark feedback, and nearby interaction prompts.
- Books can be picked up, carried, thrown, and visually scorched by Spark or magic.
- A fridge with an opening door; a fan that pushes nearby players; an AC that slows nearby movement; and a computer with switch/shorted states.
- When the AC is on, its **130-pixel** effect radius applies a **0.45** movement-speed multiplier. Inherited airborne momentum also slows toward the adjusted speed cap; `SLOW` and cool-colored particles indicate the effect. Movement returns to normal outside its range.
- A separate ranged magic projectile can scorch books or short the computer. It has no mana cost or health damage.
- The optional prop interactions can be disabled via `experimental_books_enabled` and `experimental_appliances_enabled` on the MSD controller.
- The fridge interior and wall-mounted AC are deliberately rendered **behind** player sprites; interaction and status overlays remain above players.

### Not implemented or not yet approved

- Real fire propagation, burnout, full material destruction, or final physics-based furniture damage.
- Mana, player health, scaling damage based on property destruction, official scoring, rounds, or win/loss rules.
- Final integration of the team's Art and Simulation scenes and gameplay approval.

## Code map

| Path | Responsibility |
| --- | --- |
| `gameplay/player.gd` / `gameplay/prefabs/gameplay_player.tscn` | Player character, input handling, and component wiring |
| `gameplay/input_actions.gd` | Independent P1/P2 action maps |
| `gameplay/components/player_motor.gd` | Acceleration, jump logic, air momentum |
| `gameplay/components/platform_drop.gd` | Safe drop-through on one-way platforms |
| `gameplay/components/spark_emitter.gd` / `gameplay/components/fire_bridge.gd` | Spark direction, cooldown, Simulation integration |
| `onboarding/burn-box/material_grid.gd` | Simulation-owned public interface, left identical to `main` |
| `gameplay/integration/ethan_material_grid.gd` | Ethan-compatible storage/ignition logic adapted from `ethan/burn-box-grid@46c3df2`, with delegation to official upstream state once merged; active in the MSD arena |
| `gameplay/integration/team_material_renderer.gd` | Jackson's material palette and signal-driven renderer adapted as a translucent pixel layer so the Art team scene remains visible |
| `gameplay/integration/demo_material_grid.gd` | Legacy lightweight grid, retained only for the separate fantasy experiment |
| `gameplay/msd/msd_controller.gd` | Living-room controller for players, Spark, props, and appliances |
| `gameplay/msd/burnable_prop.gd` | Book carrying, throwing, and scorch visuals |
| `gameplay/msd/appliance.gd` | Fridge, fan, AC, and computer |
| `gameplay/msd/magic_bolt.gd` | Experimental ranged attack |
| `gameplay/msd/interaction_hints.gd` / `gameplay/msd/player_conditions.gd` | Contextual prompts and `SLOW` / `WIND` indicators |
| `gameplay/msd/art/generate_room.py` | Pillow script that redraws the room with Art Team source sprites aligned to Gameplay collision geometry |
| `gameplay/demo/gameplay_test.tscn` | Separate fantasy mechanics experiment |

See [`gameplay/README.md`](gameplay/README.md) for module integration details and a complete test list. For the cross-team handoff, see [`gameplay/TEAM_INTEGRATION.md`](gameplay/TEAM_INTEGRATION.md).

## Testing

The `gameplay/tests/` directory contains checks for movement, double jumping, one-way collisions, fire interfaces, two-player controls, furniture interactions, and UI. From the repository root, run:

```bash
"../Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_msd_test.gd
"../Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_layout_feedback_test.gd
```

These are representative tests, not the entire suite. See the Gameplay README for all test scripts.

## Code and art attribution

- **Austin:** Remaining-jump counting and the approach to dropping through one-way platforms, adapted for independent two-player controls.
- **Ethan:** The `MaterialGrid` public API and storage implementation on his separate `ethan/burn-box-grid` branch. The Gameplay branch does not modify or ship his Simulation file, and his PR has not yet been merged into `main`.
- **Jackson:** `cell_changed`-driven material and burning-state rendering approach, adapted into lightweight visual feedback.
- **Gameplay art attribution:** P1 is derived from the Art Team's Character design PNG/GIF in the project MidSem deck; P2 recolors that sprite to red. The room uses Art Team furniture tiles, with local layout/redraw through `gameplay/msd/art/generate_room.py`. The fireball pixel frames are generated locally using `gameplay/msd/art/generate_fireball.py`. See [`gameplay/ART_SOURCES.md`](gameplay/ART_SOURCES.md) for exact provenance.

For source commits and integration boundaries, see [`gameplay/UPSTREAM_INTEGRATION.md`](gameplay/UPSTREAM_INTEGRATION.md). For assets, see [`gameplay/ART_SOURCES.md`](gameplay/ART_SOURCES.md); for design scope, see [`gameplay/msd/DESIGN_NOTES.md`](gameplay/msd/DESIGN_NOTES.md).

Local Godot editor metadata and MCP settings are not necessary to run the game and should not be committed as shared project settings.
