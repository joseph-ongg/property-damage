# Property Damage — Full Local Gameplay Integration (November 14, 2026)

> **Status:** Playable local integration candidate with current upstream WindModel, Austin item mechanics, Eva Health/fall damage, Angela MapSelection v2, Art Team Piskel assets, and reusable best-of-three combat. **Not** an official upstream release; the planned third arena, production Garden polish and confirmed Werewolf attack are still pending. See [Full integration handoff](gameplay/FULL_INTEGRATION.md).

[Getting started](#getting-started) · [Controls](#controls) · [Features](#implemented-features) · [Code map](#code-map) · [Tests](#testing) · [Credits](#code-and-art-attribution)

## Getting started

1. Install **Godot 4.7.2 Standard** (GDScript; the .NET edition is not required).
2. Import the repository root containing `project.godot` into Godot.
3. Press **F5** to open Angela's updated character and map selection menu. Pick any two characters and enter either playable Living Room or Garden. Direct Living Room playtest remains at `gameplay/playtest_main.tscn` (F6).
4. To try the unrelated fantasy prototype, open `gameplay/demo/gameplay_test.tscn` and press **F6**. Its Moonlit Ruins theme, collectibles, brazier objectives, and victory conditions are *not* confirmed team requirements.

## Controls

| Action | Player 1 (mint) | Player 2 (orange) |
| --- | --- | --- |
| Move / steer in air | `A` / `D` | Left / Right arrows |
| Fixed-height first jump and double jump | `W` (press twice) | Up arrow (press twice) |
| Drop through a one-way platform | `S` + `W` | Down + Up arrows |
| Spark: attempt to ignite the cell ahead | `F` | `Enter` |
| Ranged magic projectile (experimental) | `G` | `.` (period) |
| Pick up / throw a throwable item | `C` | `,` (comma) |
| Use furniture or eat food | `E` | `Shift` |
| Start / stop microwave, or close its door | Down + `E` | Down + `Shift` |
| Pause / resume | `P` or `Esc` | Shared |
| Next round / restart match at result screen | `R` | Shared |
| Back to character/map menu | `M` | Shared |

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
- Books, the clock, painting, plushie, plant, food, and fan cable can be picked up and thrown. Fragile objects break on impact; thrown damage uses their pixel width × height / 10,000.
- Room objects share flammable, throwable, and fragile tags plus HP. Fire from the existing grid burns items for 1 HP every 3 seconds and self extinguishes after 10 seconds. Attacks remove 1 item HP each; the destroying player gains 5% of base attack damage.
- Characters use 120/100/160 real HP for Mage/Ninja/Werewolf; grid fire deals 2 HP per second. Damageable objects block shots before players. First to win two rounds takes the best-of-three match.
- The fridge opens to reveal throwable healing food. Its existing top-mounted microwave holds three nuggets: open and eat for 20 HP, or hold Down and press Use to cook for 10 seconds, then eat for 50 HP. The fan cable plugs in automatically near the outlet, leaves the player's hand, and stays locked until unplugged with Use. The AC can disperse its fire when turned on. The bookshelf can be climbed; falling through the trashcan opening hurts and respawns a player after two seconds; broken plant shards hurt players who step on them.
- Characters render in front of room items. Burning and burned-out objects show placeholder flame and ash sprites.
- When the AC is on, its **130-pixel** effect radius applies a **0.45** movement-speed multiplier. Inherited airborne momentum also slows toward the adjusted speed cap; `SLOW` and cool-colored particles indicate the effect. Movement returns to normal outside its range.
- A separate ranged magic projectile damages the first item or player along its path. It has no mana cost.
- The optional prop interactions can be disabled via `experimental_books_enabled` and `experimental_appliances_enabled` on the MSD controller.
- Designers can adjust a world item's exported tags, HP, hit size, and burn timing in the scene; set `use_kind_defaults` to `false` to retain Inspector values instead of the prototype presets. Appliances have the corresponding `use_device_defaults` switch.
- The fridge interior and wall-mounted AC are deliberately rendered **behind** player sprites; interaction and status overlays remain above players.

### Not implemented or not yet approved

- Third arena, final Garden-specific physics and scenery, final Werewolf attack approval, full game-balance pass, and final Art Team animations.
- Official upstream merge and team QA/sign-off. The present candidate is local-only.

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
| `gameplay/msd/interactable_item.gd` / `gameplay/msd/world_item.gd` | Shared tags, HP, grid fire response, and configurable room props |
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
- **Ethan:** The `MaterialGrid` public API, burning state, fire spread and the WindModel merged in upstream PR #13. Existing Simulation implementation remains owned by Ethan.
- **Jackson:** `cell_changed`-driven material and burning-state rendering approach, adapted into lightweight visual feedback.
- **Gameplay art attribution:** P1 is derived from the Art Team's Character design PNG/GIF in the project MidSem deck; P2 recolors that sprite to red. The room uses Art Team furniture tiles, with local layout/redraw through `gameplay/msd/art/generate_room.py`. The fireball pixel frames are generated locally using `gameplay/msd/art/generate_fireball.py`. See [`gameplay/ART_SOURCES.md`](gameplay/ART_SOURCES.md) for exact provenance.

For source commits and integration boundaries, see [`gameplay/UPSTREAM_INTEGRATION.md`](gameplay/UPSTREAM_INTEGRATION.md). For assets, see [`gameplay/ART_SOURCES.md`](gameplay/ART_SOURCES.md); for design scope, see [`gameplay/msd/DESIGN_NOTES.md`](gameplay/msd/DESIGN_NOTES.md).

Local Godot editor metadata and MCP settings are not necessary to run the game and should not be committed as shared project settings.
