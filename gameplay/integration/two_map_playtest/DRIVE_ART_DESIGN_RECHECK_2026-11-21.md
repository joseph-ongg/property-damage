# Nov 21 — current Design + Art Team Drive review and gameplay fix

Source: connected School Google Drive, read Nov 21 2026 (Pacific).
All remote Drive files were read-only; none were altered.

## Design document

[PUBLIC] DP Designs:
https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit

Latest Drive modified timestamp observed: 2026-11-17T00:51:55Z
(Nov 16, 4:51 PM Pacific). No newer Design text was visible;
Drive returned no earlier revision to compare.

Original rules: Ninja shoots shuriken; Werewolf skill is
unapproved/question-mark; Garden has 8 independent fence sections
at 4HP, tree-hole travel, falling apples, roses/ thorns at 5HP
on contact, and provisional 1HP/sec (?) hose for 10 sec.

The Design doc does NOT prescribe whether the upper painted rose
gate is a one-way or fully solid platform. The geometry fix below
is user-reported Art-matching collision, requiring PM/Design
review rather than a claim of official design approval.

## Art Team sources checked

Property Damage Art folder:
https://drive.google.com/drive/folders/1-bNX0VyVeyccPiMAJbUSJDj4b6Q0kjnJ

Original ninja_side/walk and wolf_walk/damage PNG frames are
native LEFT-facing. In the previous code Sprite2D.flip_h treated
them as right-facing; the new source-relative flip fixes both
characters and preserves Mage's original right-facing mapping.
No source art pixels are modified.

NEW material in Drive on Nov 21 (UTC date Nov 21):
- Ninja_fire.piskel: 32x32, 4 frames, created ~15:26 PST
  https://drive.google.com/file/d/10CnLdDTlX48oifW2DwV9TzF1vc2g_f_1/view
- Ninja_injured.piskel: 32x32, 4 frames, ~15:26 PST
  https://drive.google.com/file/d/12RXrY219AEEqCyu-5QPj2FWOuuydmyyM/view
- Ninja_dead.piskel: 32x32, 1 frame, ~15:34 PST
  https://drive.google.com/file/d/1Ty-ObnWrlF2_MtSF3wS3qMuTJdJuOLCI/view
- Garden - Separated Pieces new folder, ~16:22 PST,
  with Hose.piskel, 280x66, 1 frame, ~16:26 PST
  https://drive.google.com/drive/folders/1vAUeOlzn-YvibjOrYKiQVeS64xeAaQZF
  https://drive.google.com/file/d/1uqggH3qZjJnsaM-cLQvnY0m9v9PjSR1G/view

Native Piskel contents were inspected read-only: Ninja_fire
shows a flame in its hand; Design STILL requires a shuriken as
the projectile. Do not silently replace Ninja's shuriken with
Wizard fire or invent its special rules. Hose.piskel contains
the fence + long hose on one 280x66 canvas, not only a nozzle.
Do not blindly replace the current independent nozzle crop.
This paragraph was the source inventory BEFORE the subsequent
Art integration commit on Nov 21. The original new source Piskels
were subsequently imported into gameplay/art_team/source/, their
native frames exported without redraw, and the specific character
animation events wired into PR #21. See the newer integration report:
ART_TEAM_LATEST_ASSETS_2026-11-21.md. The independent Ninja shuriken
sprite is STILL absent and is not confused with Ninja_fire.

The original garden.piskel modified 2026-10-31 is still the
authoritative source used for physical pixel masks. No fresh
approved Garden gate geometry was provided.

## Reviewed code and real game visuals

- Ninja/Wolf: world LEFT shows unflipped original-left Art.
  World RIGHT shows mirrored original Art, including running
  frames, P1/P2 and Garden round reset. Wizard unchanged.
- Garden rose gate: upper painted arch now has a real source-
  pixel-matched StaticBody2D, not only a 5HP hurt Area2D.
  No invisible rectangular platform across sky/door opening.
  Lower rose stems keep Design's 5HP contact Areas only.
- Initial broad attempt to make both stems physically solid
  blocked projectile lanes and broke Garden rounds. That
  approach was discarded. Upper arch only passes PvP
  regressions and actual player sweep/physics ray tests.
- Eight actual Godot Mac screenshots for source-art sprite
  direction and painted gate are committed with this review,
  alongside a two-map regression report.

Not yet approved: one-way-vs-solid gate top decision; the new
Ninja fire pose is integrated ONLY for the existing Spark (not G
shuriken); official Werewolf ranged skill, independent shuriken
projectile Art, final match-winner rule and two-human real gameplay
acceptance are still outstanding. Newly available original Tree
and Wolf fire walk are covered in the later report linked above.
