# Property Damage — Two-Map Playtest Integration (EXPERIMENTAL)

**Integrated two-map Design delivery candidate. Design / PM must review
outstanding match-rule decisions before approving a production merge.**

This branch validates the minimum gameplay loop against the Design-approved
arenas **Living Room / Bedroom** and **Garden**. No Arena 3, speculative
attacks, or new Design specifications are included.

## Launch

Import this worktree's project.godot into Godot 4.7.2, then press F5.
This experimental branch changes the main-scene setting **only here**.

1. Choose P1 and P2 from Wizard, Ninja, Werewolf.
2. Use Angela's original, authored MapSelection two-map selector scene and buttons. The adapter
   remaps GardenPlaceholder to the real PR #18 Garden, without modifying
   her files.
3. P1: A/D move, W jump, G attack. P2: arrows move/jump, period attack.
   Players must move into range, and destructible/flammable furniture can
   intercept spells according to existing world logic.
4. An actual Eva Health death ends the round, freezes both controllers,
   removes projectiles, shows KO, increments a **provisional** score.
5. Next Round continues as long as testers choose. Finish Playtest
   explicitly ends the session with a round-history summary, not a match winner.

No best-of-three threshold, automatic match winner, or final match format
is implemented. Final rules and production UI are owned by Design and Angela.

## Ownership and implementation boundaries

- Existing Garden/Living Room scene files and GameplayPlayer are unchanged.
- An isolated \`GameplayLivingRoomPvPBolt\` subclass adds **only** player
  collision and Eva Health to the original Living Room \`GameplayMagicBolt\`;
  world/furniture/item collision and \`MaterialGrid\` ignition continue through
  the unchanged base projectile. Austin's MagicBolt and MSD controller
  are unchanged. Verified by the separate furniture-ignition/PvP regression.
- Eva Health is the only HP store; no duplicate health.
- Each new round instantiates a fresh existing arena, clearing transient state.
- Existing character art and stats are used, with no new characters/attacks.
- The experimental F5 launch path is a scoped change to project.godot only.
- The Design delivery branch contains only Living Room/Bedroom and Garden.
  Earlier experimental Arena3 contents remain in Git commit history only,
  not in the deliverable code or map selector.

## Reproducible tests

    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_two_map_full_playtest_test.gd
    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_two_map_furniture_pvp_test.gd
    ./gameplay/garden/verify_pr18.sh --local

The test drives real Godot button signals and physical input events,
projectiles, collision, Eva Health KO, per-round results, explicit finish and playtest restart.
To be deterministic it places fighters into **known unobstructed lanes**;
this is not proof that all human navigation, props or fire simulations are
free of bugs. Test windowed behavior and visually inspect the scenes.

## Release gate beyond this experiment

- Angela: real character/map selection, approved match rules and win UI.
- Austin: shared Living Room player/item projectile hit routing.
- Eva: Health, fall damage and invulnerability integration.
- Ethan/Jackson: live fire, wind, object HP and environmental interactions.
- Design/Joseph: approve playtest experience and specify final match rules.

Design source:
https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit
