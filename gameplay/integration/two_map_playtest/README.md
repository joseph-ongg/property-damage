# Property Damage — Two-Map Playtest Integration (EXPERIMENTAL)

**Isolated, unapproved integration test branch. Do not merge into PR #18 or
main without Angela / Austin / Eva / Design / Joseph review.**

This branch validates the minimum gameplay loop against the Design-approved
arenas **Living Room / Bedroom** and **Garden**. No Arena 3, speculative
attacks, or new Design specifications are included.

## Launch

Import this worktree's project.godot into Godot 4.7.2, then press F5.
This experimental branch changes the main-scene setting **only here**.

1. Choose P1 and P2 from Wizard, Ninja, Werewolf.
2. Use Angela's original two-map selector scene and buttons. The adapter
   remaps GardenPlaceholder to the real PR #18 Garden, without modifying
   her files.
3. P1: A/D move, W jump, G attack. P2: arrows move/jump, period attack.
   Players must move into range, and destructible/flammable furniture can
   intercept spells according to existing world logic.
4. An actual Eva Health death ends the round, freezes both controllers,
   removes projectiles, shows KO, increments a **provisional** score.
5. Next Round continues; two wins trigger a temporary match result and
   Rematch or return to map and characters.

The two-win score rule and temporary selection/result UI are a playtest
assumption, NOT an approved final Design rule or Angela's final UI.

## Ownership and implementation boundaries

- Existing Garden/Living Room scene files and GameplayPlayer are unchanged.
- Existing GardenMagicBolt is used as a *temporary session-local* PvP adapter
  for Living Room; Austin's MagicBolt and MSD controller are unchanged.
- Eva Health is the only HP store; no duplicate health.
- Each new round instantiates a fresh existing arena, clearing transient state.
- Existing character art and stats are used, with no new characters/attacks.
- The experimental F5 launch path is a scoped change to project.godot only.
- Neither experimental Arena 3 nor a third-map menu option is included.

## Reproducible tests

    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_two_map_full_playtest_test.gd
    ./gameplay/garden/verify_pr18.sh --local

The test drives real Godot button signals and physical input events,
projectiles, collision, Eva Health KO, round/match result and rematch.
To be deterministic it places fighters into **known unobstructed lanes**;
this is not proof that all human navigation, props or fire simulations are
free of bugs. Test windowed behavior and visually inspect the scenes.

## Release gate beyond this experiment

- Angela: real character/map selection, rule approval, match score and win UI.
- Austin: shared Living Room player/item projectile hit routing.
- Eva: Health, fall damage and invulnerability integration.
- Ethan/Jackson: live fire, wind, object HP and environmental interactions.
- Design/Joseph: approve playtest experience and any provisional rule.

Design source:
https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit
