# Gameplay integration compatibility (Draft PR #17)

This branch is character/art work based on main, not a replacement for
Austin's items, Eva's HP/fall damage, Angela's selection, or Simulation.

## Eva Health

- Our player owns exactly one Eva Health child.
- Access the existing component via player.health_component (a typed
  Health Node); set_character_kind updates max_hp using Design numbers.
- No changes were made to Eva's health.gd and there is no second HP store.
- Eva's eva-hp adds an optional bypass_invuln parameter to take_damage,
  plus defaults, fall damage and fire-sensor improvements. Our current
  one-argument Health calls are interface-compatible with both versions.
- The older eva-hp branch has roughly 45 Git conflicts with unmodified
  main, mostly duplicate Godot .import files and reused HP resources.
  Selectively port Eva's logic instead of merging obsolete generated files.

## Austin items

- Austin's older austin/items branch adds carry_pressed, items,
  pickup/throw and its own numeric player.health field.
- This branch now calls the component player.health_component to avoid
  the conflicting player.health identifier. It does not copy Austin's
  independent numerical HP store or replace his mechanics.
- At integration time Austin's item callbacks take_damage, heal,
  reward_destruction, respawn need to be routed through the existing
  authoritative Eva Health component. The item trashcan's numerical
  player.health check needs to read Health.hp instead.
- The old Austin branch has one pre-existing scene conflict against
  unmodified main: gameplay/msd/gameplay_msd.tscn. A proper integration
  resolution must retain main's newer platforms AND Austin's approved
  WorldItems. Choosing an entire side blindly discards work.
- Do not move Austin's mechanics into this character/art PR.

## Safe team integration workflow

- Git merge simulation: Angela map-select-v2 and Jackson environment-burning
  are clean with this branch. Review gameplay behavior after merging.
- Austin and Eva's old branch conflicts already exist with main; they
  cannot be made Git-conflict-free by editing unrelated character art.
- Work in a separate temporary integration branch based on current
  main, resolve team-owned conflicts with the owner, then run Godot QA.
- Experimental suwen/game-ready is preserved for reference only.
- This PR does not change Austin/Eva/Angela/Simulation-owned code.

Compatibility here means documented API boundaries and checked
coexistence, NOT a guarantee that every old branch can be merged
without manual review.
