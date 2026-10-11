# Property Damage — Two-Player Gameplay Prototype

> **Status:** A playable, independent Gameplay prototype for the Property Damage project, **not** a merged or officially approved final build. The extra furniture interactions, ranged spells, and pixel-art room are optional experiments. Final win conditions have not been confirmed.

[Getting started](#getting-started) · [Controls](#controls) · [Features](#implemented-features) · [Code map](#code-map) · [Tests](#testing) · [Credits](#code-and-art-attribution)

## Getting started

1. Install **Godot 4.7.2 Standard** (GDScript; the .NET edition is not required).
2. Import the repository root containing `project.godot` into Godot.
3. Press **F5** to run `main.tscn`, which loads `gameplay/msd/gameplay_msd.tscn` (the pixel-art living room).
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
| Restart the default scene when unpaused | `R` | Shared |

Dash is disabled in the default living-room scene. The separate fantasy test scene uses `Q` and `/` for Dash. Available interactions appear contextually near nearby objects.

## Implemented features

### Core Gameplay

- Two independent players with horizontal movement, left/right facing, jumping, and a second jump that resets upon landing.
- Fixed-height jumps, horizontal momentum retained when releasing direction in midair, aerial steering, coyote time, and jump buffering.
- Solid floors and walls; one-way furniture platforms that can be jumped through from below or deliberately dropped through.
- Players on collision layer 2 interact with world layer 1 but pass through each other.
- Directional Spark via `GameplayFireBridge`, connected to **Ethan's `MaterialGrid`** for material and burning state. Gameplay does not maintain a duplicate flame-state store.

### Optional visual and interaction prototypes

- Original pixel-art living room, distinct player palettes, concise HUD, landing and spark feedback, and nearby interaction prompts.
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
| `gameplay/player.gd` / `gameplay/player.tscn` | Player character, input handling, and component wiring |
| `gameplay/input_actions.gd` | Independent P1/P2 action maps |
| `gameplay/components/player_motor.gd` | Acceleration, jump logic, air momentum |
| `gameplay/components/platform_drop.gd` | Safe drop-through on one-way platforms |
| `gameplay/components/spark_emitter.gd` / `gameplay/components/fire_bridge.gd` | Spark direction, cooldown, Simulation integration |
| `onboarding/burn-box/material_grid.gd` | Material and burning storage synchronized from Ethan's remote branch |
| `gameplay/msd/msd_controller.gd` | Living-room controller for players, Spark, props, and appliances |
| `gameplay/msd/burnable_prop.gd` | Book carrying, throwing, and scorch visuals |
| `gameplay/msd/appliance.gd` | Fridge, fan, AC, and computer |
| `gameplay/msd/magic_bolt.gd` | Experimental ranged attack |
| `gameplay/msd/interaction_hints.gd` / `gameplay/msd/player_conditions.gd` | Contextual prompts and `SLOW` / `WIND` indicators |
| `gameplay/msd/art/generate_room.py` | Pillow script that generates the original pixel-art living room |
| `gameplay/demo/gameplay_test.tscn` | Separate fantasy mechanics experiment |

See [`gameplay/README.md`](gameplay/README.md) for module integration details and a complete test list.

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
- **Ethan:** Original `MaterialGrid` implementation, synchronized locally. This does **not** imply his PR is merged into the team's `main` branch.
- **Jackson:** `cell_changed`-driven material and burning-state rendering approach, adapted into lightweight visual feedback.
- **Local prototype artwork:** Generated with original Pillow drawing scripts (`gameplay/art/generate_art.py` and `gameplay/msd/art/generate_room.py`), rather than downloaded commercial-game assets.

For source commits and integration boundaries, see [`gameplay/UPSTREAM_INTEGRATION.md`](gameplay/UPSTREAM_INTEGRATION.md). For assets, see [`gameplay/ART_SOURCES.md`](gameplay/ART_SOURCES.md); for design scope, see [`gameplay/msd/DESIGN_NOTES.md`](gameplay/msd/DESIGN_NOTES.md).

Local Godot editor metadata and MCP settings are not necessary to run the game and should not be committed as shared project settings.
