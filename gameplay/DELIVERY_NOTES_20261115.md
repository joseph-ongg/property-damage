# Property Damage local November 15 delivery candidate

Worktree: property-damage-game-ready-20261115

This is a local-only branch. Published PR #14 and the team's main
branch have not been modified.

## Open the RIGHT project

Double-click Open Godot Editor.command to open the correct editor.
Double-click Run Property Damage.command to play the LIVE SOURCE,
not a potentially stale build pack.

Alternatively, in Godot Project Manager choose Import and select
the project.godot in this directory; then press F5.
The actual startup should show original Arcane Academy title,
then Fighter Registration, Angela's unchanged map screen and 3 arenas.

## New work

- Two independent fighter choices and Ready confirmations on their own
  scene BEFORE Angela's original two-map screen.
- Garden: original Garden Piskel visuals plus 2 destructible gnomes,
  player-activated extinguishing hose, living-tree crouch cover, moving
  bird and dropping hazard, full round reset and attack bonus on breaking.
- New Clocktower Observatory third arena with original Python/Pillow
  pixel backdrop, 4 original breakable crystals, telegraphed horizontal
  beam and falling meteor hazards. Same players, Health, timers, win,
  fire, pause, HUD and rematch logic as the other maps.
- Reusable visual hit feedback: screen shake, short hit-stop, procedural
  pixel particles, no generated images and no new audio.
- Fan and AC both export active wind source state and contribute to
  Ethan's existing fire-spread grid via room wind direction and strength.
  See gameplay/integration/FAN_AC_SIMULATION_HANDOFF.md.

## Production caveats

Not yet tested on a non-team laptop, not a signed standalone executable.
Real-person two-player gameplay balance, Design approval of third-arena
hazards, final Art character animations and Werewolf claw sign-off are
still external team review items. No sound or music has been added.
The upstream Simulation material grid provides a single room-global
wind vector; Simulation may choose a more spatially localized model.
