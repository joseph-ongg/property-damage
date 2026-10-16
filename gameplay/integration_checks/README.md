# Test Gameplay against an actual upstream team arena

**Status (2026-10-12): NO final merged arena exists in `origin/main`.**
Only `main.tscn` (placeholder) and `onboarding/burn-box/burn_box.tscn`
are present. The current GitHub repository has only an open Gameplay
Draft PR #4. The usable arena file from an external Gameplay member is
Angela's `gameplay/test_arena.tscn` from `angela/CollisionShape2D`. It
contains a single rectangular StaticBody2D floor and a 32x64 placeholder
player, **not** a final MSD arena. Eva's `eva/world-floor-walls` branch
contains no new arena scene. Austin's historical `stage.tscn` in commit
`a529274` was reverted from `sim/jackson/burn-box-render`; do not treat it as
an official merged arena or overwrite the team's `main.tscn` with it.

## Real isolated branch-combination test

From the repository root, run (on a machine with Godot and git):

```bash
# Assumes the standard remote refs exist; fetch them if needed:
git fetch origin angela/CollisionShape2D ethan/burn-box-grid

TMP="$(mktemp -d /tmp/property-team-arena.XXXXXXXX)"
git archive HEAD | tar -xf - -C "$TMP"
# Preserve newly written, not-yet-committed Gameplay tests when testing locally.
rsync -a --exclude='.godot/' gameplay/ "$TMP/gameplay/"

# These are the teammates' ORIGINAL scene and player files.
# Only the disposable copy receives them.
git show origin/angela/CollisionShape2D:gameplay/test_arena.tscn > "$TMP/gameplay/test_arena.tscn"
git show origin/angela/CollisionShape2D:gameplay/player.tscn > "$TMP/gameplay/player.tscn"

# Put the ORIGINAL Ethan grid into a second disposable configuration.
# This reproduces the real Simulation API, not a fake shared array.
git show origin/ethan/burn-box-grid:onboarding/burn-box/material_grid.gd > "$TMP/onboarding/burn-box/material_grid.gd"

GODOT='/Users/suwen/Documents/cal26fall/open project/Godot.app/Contents/MacOS/Godot'
"$GODOT" --headless --editor --path "$TMP" --quit
TEAM_ARENA_SCENE='res://gameplay/test_arena.tscn' \
 "$GODOT" --headless --path "$TMP" \
 --script res://gameplay/integration_checks/team_arena_handoff_test.gd
```

This loads the actual Angela scene at runtime, removes **only its instantiated**
static placeholder, and attaches P1 and P2 using the real Gameplay prefab.
The test also attaches the Ethan-compatible grid/bridge and Jackson-derived
material renderer to the actual scene root. It never changes source `.tscn`
files in your repository or in teammates' branches. Materials are explicitly
seeded on two small test targets because Angela's scene does **not** provide
a real room MaterialGrid map. The resulting Spark checks demonstrate correct
API integration **only**, not finished level material authoring.

To capture an actual Godot 960x540 rendering, use the non-headless version
of the same command with the optional `CAPTURE_TEAM_ARENA` output path:

```bash
TEAM_ARENA_SCENE='res://gameplay/test_arena.tscn' \
CAPTURE_TEAM_ARENA='/tmp/angela-gameplay-handoff.png' \
 "$GODOT" --resolution 960x540 --path "$TMP" \
 --script res://gameplay/integration_checks/team_arena_handoff_test.gd
```

## Acceptance results against Angela's actual arena

Verified 2026-10-12 against both current main's Gameplay adapter and the
**unmodified** Ethan `46c3df2` MaterialGrid installed in a disposable copy:

- **16/16 assertions pass** in both configurations, with zero script errors.
- P1/P2 use real 32x64 colliders, with an upward **-12px** shape offset;
  the floor top is world y=480 (Angela's scene). Both stand correctly.
- Independent horizontal movement, passing through each other in the real
  physics world, both double jumps, directional P1 F / P2 Enter Sparks.
- Both Sparks ignite explicitly seeded wood cells via a single shared Grid.
- Exact render screenshot captured at
  `presentation_media/screenshots/angela_upstream_arena_with_gameplay.png`.

**Three upstream integration blockers (not Gameplay test failures):**

1. The source scene has no left/right boundary walls.
2. It has no one-way fridge, bookshelf or table platforms.
3. It has no production material grid layout/furniture material seed.

Because there is no final merged arena in `origin/main`, no test here
establishes that the complete MSD will work in a final team scene. Retest
once the team has merged that exact scene. At that point, set
`TEAM_ARENA_SCENE` to the *real merged scene path*, or adjust floor node
lookup if the team changes its scene hierarchy. Do not report the prototype
or Angela's floor-only scene as the final integrated arena.
