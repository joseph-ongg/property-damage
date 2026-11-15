# Full local Gameplay integration — November 14, 2026

**Status:** playable local integration candidate; **not** reviewed/merged as an
official team release. Includes two playable arenas (Living Room and a new
Garden battle), three selectable characters, item destruction, fire damage,
and best-of-three rounds. The team's planned third arena is not available.

## Run

Open this repository folder in **Godot 4.7** and press **F5**. F5 enters
Angela's updated character/map menu, not the old direct playtest. Select
a character for each player (Mage, Ninja, Werewolf) and choose Living Room
or Garden.

| Action | P1 | P2 |
| --- | --- | --- |
| Move and double jump | A/D, W | Left/Right, Up |
| Drop down | S+W | Down+Up |
| Attack | G | Period |
| Ignite nearby cells | F | Enter |
| Pick up / throw | C | Comma |
| Interact | E | Shift |
| Pause (Living Room) | P / Esc | Shared |
| Next round / new match after round-end | R | Shared |
| Return to character/map menu | M / on-screen button | Shared |

The winner overlay handles the **best-of-three** match: first to win two
rounds takes the match. Each new round resets HP, attack bonuses, item state,
item positions, active fire, and the material grid to its initial layout.

## Grounded sources merged and adapted

- **Current upstream main**: `f490107` (2026-11-14), including Ethan's
  `WindModel` PR #13. We did not modify that Simulation model.
- **Austin**: `origin/austin/items` @ `a9b7827`. Integrated full item
  interactions, hitboxes, durability, projectile-first-hit, item fire damage,
  throw collisions, AC/fan/outlet effects, new props and tests. The source
  branch isn't merged to the upstream project as of this checkpoint.
- **Eva**: reused her original `gameplay/components/fall_damage.gd` from
  `origin/eva-hp` @ `6681c63`. Uses her `Health` component (already on
  main through PR #10) as the **only** player HP store. Austin's separate
  float HP variables were deliberately not duplicated.
- **Angela**: imported the new `MapSelection` scene and back button
  from `origin/angela/map-select-v2` @ `55fe753`, retaining
  Suwen's compatible character-picking logic and old LevelSelection route for
  existing tests.
- **Art & Audio**: previously integrated the team's 14 Piskel source
  projects and 25 exported original PNG frames. Source attribution is in
  `gameplay/art_team/README.md` and `catalog.json`.
- **Suwen**: two-player controls, playable Living Room prototype,
  Ninja/Werewolf character integration, original placeholder art and
  code, this cross-branch integration and its acceptance tests.

## Added Gameplay features

1. **PvP combat:** Mage fires real damaging fire bolts; Ninja fires a faster
   projectile with an original small shuriken drawing; Werewolf uses a
   **temporary** short-range claw attack pending Design confirmation.
   Projectiles prioritize the closest damageable item before a player behind
   it. Hits apply 10 base HP damage (or an attack bonus).
2. **HP and hazards:** Mage 120 HP, Ninja 100 HP, Werewolf 160 HP.
   Fire contact does 2 HP per second while touching an ignited
   `MaterialGrid` cell. Eva's invulnerability window is preserved.
   Her fall sensor triggers on hard landings above a 220-pixel safe
   distance (tunable; original Design criteria require clarification).
3. **Destructible props:** Austin's tagged, configurable HP items lose 1 HP
   per 3 seconds while burning; lost items become ash. The player credited
   with a destroyed item gains +5% base attack damage per destruction.
4. **Rounds:** Winner/score HUD, two wins to take a best-of-three match,
   next round, rematch and map menu buttons. Results come from Eva's real
   `Health.died` signals.
5. **Garden:** separate playable arena with Art Team's Garden backdrop,
   world physics, two real players, Ethan fire grid and three simple Garden
   destructibles (roses, tree, mushrooms). This is an **MVP Garden layout**,
   not the Garden physics/art team's final level.
6. **Editable balance:** `gameplay/tuning/gameplay_balance.tres` exposes
   major combat, hazard, item-burn, fall, projectile and match parameters.

## Test commands

First import the project once:

```bash
Godot --headless --editor --path . --import --quit
```

Then, from the project root:

```bash
Godot --headless --path . --script res://gameplay/tests/gameplay_complete_match_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_project_start_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_item_system_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_art_team_assets_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_character_selection_health_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_furniture_fire_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_full_flow_test.gd
```

The live Living Room can still be launched directly at
`res://gameplay/playtest_main.tscn`; Art source gallery at
`res://gameplay/art_team/art_gallery.tscn`.

## Still requires team review

- **Third arena:** missing. Only two arena choices are offered rather than
  inventing a supposedly finished third level.
- **Garden production readiness:** scenery, detailed art-layer placement,
  Garden-specific items and collision/terrain polish still need testing and
  design approval.
- **Werewolf attack contract:** Design had not confirmed final projectile
  behavior; the short-range claw is a working placeholder.
- **Art completion:** Ninja jump/attack/hurt and Werewolf jump/attack still
  use Suwen's placeholders where the Art folder did not include final frames.
- **Systems ownership:** `MaterialGrid` handles material cells and fire,
  while Austin's item component handles object-level HP; the two are
  connected, but this is not a single Simulation-owned object-HP system.
- **Balance and manual gameplay QA:** normal attacks, throw damage, fire,
  item HP and fall thresholds are configurable but require a playtest and
  sign-off; automated smoke tests don't prove final game balance.
- **No publishing:** branch exists on Suwen's local Mac only. Nothing was
  pushed to GitHub or merged into upstream main.
