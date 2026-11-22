# Property Damage — latest Art Team Drive integration (PR #21)

Source: connected School Google Drive, read Nov 21, 2026 (PST).
All supplied raw .piskel files are stored unchanged in
gameplay/art_team/source; deterministic, pixel-exact PNG frames
are exported by gameplay/art_team/export_piskel.py. The SHA-256,
native source dimensions, FPS and frame count are recorded in
gameplay/art_team/catalog.json. No Drive asset was edited.

Art folder:
https://drive.google.com/drive/folders/1-bNX0VyVeyccPiMAJbUSJDj4b6Q0kjnJ

| Original Art Team file | Frames | Actual integrated runtime |
|---|---|---|
| [Ninja_fire.piskel](https://drive.google.com/file/d/10CnLdDTlX48oifW2DwV9TzF1vc2g_f_1/view) | 4 at 32x32, 12FPS | Existing Ninja F Spark animation only; G attack remains Design's SHURIKEN, not a fireball |
| [Ninja_injured.piskel](https://drive.google.com/file/d/12RXrY219AEEqCyu-5QPj2FWOuuydmyyM/view) | 4 at 32x32, 12FPS | Real Eva HP hit triggers source 4-frame hurt animation, ~0.34 seconds |
| [Ninja_dead.piskel](https://drive.google.com/file/d/1Ty-ObnWrlF2_MtSF3wS3qMuTJdJuOLCI/view) | 1 at 32x32 | Real Ninja KO in both map rounds shows the sideways original, no generic idle tilting; rematch restores idle |
| [Wolf walking on fire.piskel](https://drive.google.com/file/d/1lD_QUPUKpipMPg4io3KL5pCgjzlocAAD/view) | 2 at 32x32, 2FPS | Actual Simulation burning-foot cell shows source Wolf fire walk (same Eva Health, no new fire damage) |
| [Tree.piskel](https://drive.google.com/file/d/1vHbgV2trwmdjR0UPPT0Xs0JxPGmuyvvu/view) | 1 at 190x245 | Garden overlay at original Piskel source x236,y0; world center (716,229), 2x pixel scale; existing tree-hole and branch physics unchanged |
| [Hose.piskel](https://drive.google.com/file/d/1uqggH3qZjJnsaM-cLQvnY0m9v9PjSR1G/view) | 1 at 280x66 | Original source map x0,y181; visible hose-only tube and exact detachable 20x10 source nozzle, not an unbreakable extra fence |

The new Tree was uploaded late Nov 21 Pacific time, after the
earlier Art audit. The older Wolf fire Piskel is newly connected
from an existing Art Team upload.

Hose is one composite painting that includes a fence. Rendering it
whole would reintroduce a permanent green fence over eight approved
4HP destructible segments. Exporter crops ONLY its authentic tube
pixels x80..279 and the tip x260..279,y56..65. Full unmodified
composite and raw source are both preserved. The exact visible
nozzle remains 40x20 world pixels and its Design formula throw
damage remains 40x20/10000 = 0.08HP, not a fabricated 1HP.

Ninja's fire-hands Piskel is an animation for existing Spark,
NOT a replacement for the Design-approved shuriken. No standalone
shuriken Art was in the folder; the projectile continues to show
the user-requested '?' marker. Werewolf's undefined attack also
remains pending Design; no match rules were invented.

Verification scripts:
- gameplay/tests/gameplay_latest_art_team_handoff_test.gd
- gameplay/tests/gameplay_latest_art_match_ko_test.gd
- gameplay/tests/gameplay_latest_art_visual_window_test.gd
- gameplay/tests/gameplay_two_map_full_playtest_test.gd

These are physical keyboard simulation and real Mac graphical
Godot tests, not a live manual session with two humans. Final
Art/Design review remains pending. All original contributors'
commits remain untouched. PR #21 only; no merge to remote main.
