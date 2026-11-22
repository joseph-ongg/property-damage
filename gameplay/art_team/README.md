# Art Team sprite import (scoped)

This branch contains **only six original Piskel sources** from the
[Art Team's shared Drive](https://drive.google.com/drive/folders/1-bNX0VyVeyccPiMAJbUSJDj4b6Q0kjnJ):
Ninja_side, Ninja_walk, Wolf walk, Wolf damage sprite, garden, and Bird drop animation.

Their 13 exported PNG frames are derived reproducibly with
`/usr/bin/python3 gameplay/art_team/export_piskel.py`. The unmodified Piskel
sources and their SHA-256 checksums are recorded in `catalog.json`.
**All artwork is credited to Art Team, not Gameplay or AI generation.**

The Ninja and Werewolf walking/idle sprites are hooked to the reusable
Gameplay player through replaceable .tres resources. Other character
animations are **not invented** in this PR. Bird frames and the Garden
background are *art resources only* and do not imply a finished Garden.
No audio, music, AI-generated art, new UI theme or game rebranding.

## New Art Team handoff, Nov 21 (PR #21)

Six unchanged original Piskels were added: Ninja_fire, Ninja_injured,
Ninja_dead, Wolf walking on fire, Tree and Hose. Run
python3 gameplay/art_team/export_piskel.py to export all frames
and regenerate SHA/dimension/FPS catalog metadata. Original Art
has not been repainted. The Hose composite is cropped to separate
the real detachable nozzle from the original breakable fence.
See the Design-aligned integration audit:
gameplay/integration/two_map_playtest/ART_TEAM_LATEST_ASSETS_2026-11-21.md.
