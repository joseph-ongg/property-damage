# PR #18 cross-branch integration report — 2026-11-18

Real Godot tests were executed in disposable, unpublished Git worktrees. Testing
covers both individual branches and a combined owner-branch run. **No original
branches were force-pushed, modified or merged to main.**

| Owner / exact branch | Automatic Git merge vs PR #18 | Verified result and limitation |
|---|---|---|
| Angela: angela/map-select-v2 (55fe753; PR #16) | Clean | Godot combined import and Garden tests pass; her menu still links to the DELETED GardenPlaceholder.tscn. Must change the Garden option to res://gameplay/garden/garden_level.tscn and connect rematch and startup. |
| Austin: austin/items (a9b7827) | One manual scene conflict | Resolved in a TEMP worktree by preserving main's platform scenes AND Austin's 12 WorldItems. His item test, Garden input/hose, and Garden HP synchronization tests pass. Living Room still has separate historic numeric health. |
| Eva: eva-hp (f3da066) | 45 old conflicts | Did not blindly merge historical branch; swapped in her exact newer Health, FireHazard and FallDamage files in a disposable worktree. Five tests passed. Eva's later Spark up/down aim is a different commit, not included. |
| Ethan: ethan/fan-wind (3ddaf72; PR #19) | Clean alone | Wind and Garden/Simulation tests pass. Ethan/Jackson combined controller changes still need a human merge. |
| Jackson: sim/jackson/environment-burning (a8d8cd6) | Clean alone | Combined with Ethan and Austin only after temporarily resolving controller and scene conflicts. Real Godot tests pass. |

## All-owner combination tested

One disposable local worktree combined PR #18, Angela #16, Austin items,
Ethan #19 and Jackson burning. Only Eva's updated **Health, FireHazard and
FallDamage component files** were substituted, not her conflicting old branch.

To get the temporary combination running, human decisions were required:
- gameplay/msd/gameplay_msd.tscn: preserve main's one-way platform nodes,
  all 12 Austin WorldItems and Jackson's metadata.
- gameplay/msd/msd_controller.gd: preserve Austin item pickups/destroy
  callbacks, Ethan wind setup/cleanup and Jackson furniture destruction signals.

After a successful fresh Godot import, **8/8 selected actual runtime tests
passed**: item_system, local_wind, Garden cross_branch, Garden regression_edges,
Garden design_contract, Garden input, character_art_scope, simulation_contract.

This verifies a **manually integrated combination**, NOT automatic mergeability
or finished global game navigation. All integration commits existed ONLY in
the disposable worktree and were not pushed.

## Garden adapters added to PR #18

- Garden throwable initialization detects Austin's optional item/tag/HP API
  without requiring it on current main. Unconditional parent _ready() is not
  valid on main because the older base has no script-level _ready().
- A Garden throw impact applies ONE provisional 1-HP Eva Health hit even if
  Austin's older base also touched its numeric health field. Those fields
  are synchronized in Garden only; global Living Room player health is a
  separate owner-reviewed integration task.
- Garden activates Eva's FireHazard for 2 HP/sec contact (Design 20 HP over
  ten seconds). The updated Eva damage-over-time bypass is used only when
  the newer Health API exposes it.
- Garden loads Eva's unmerged FallDamage class when it is actually available;
  the fall calculation is not copied or replaced by Garden.
- Every **visible Art Team fence pixel**, including edges, contributes to
  Simulation fire. The derived mask is generated reproducibly by the original
  Art Team image extractor; no pixels or art files are changed.
- Bird apples continue periodically, keeping up to six active apples and
  recycling only old unheld apples. Carried items are never removed.

## Must still coordinate before marking Ready

1. Angela: correct Garden menu path/startup and wire best-of-three, winner UI
   and call Garden.prepare_new_round() for each new round. That resets
   players, Health, projectiles and stage, unlike the props-only reset.
   This PR does not alter her menu files.
2. Austin + Eva: unify the **entire game's** numeric player.health versus
   Eva Health.hp before merging Austin's global player code. His existing
   take_damage() auto-respawn and the winner signal need a shared decision.
3. Ethan + Jackson: resolve the shared MSD controller and scene conflict,
   preserving both Simulation callbacks.
4. Eva: confirm FallDamage main integration and her separate Spark vertical
   aiming feature. Neither is silently copied from old experimental branches.
5. Design + Art: approve Garden object placeholder 1-HP hits, hose tentative
   damage, Ninja temporary higher jump/shuriken, apple/gnome final art,
   and the still-undecided Werewolf attack.

## Local recheck

First import images: Godot --headless --editor --path . --import --quit

Then run:
- Godot --headless --path . --script res://gameplay/tests/gameplay_garden_cross_branch_contract_test.gd
- Godot --headless --path . --script res://gameplay/tests/gameplay_garden_regression_edges_test.gd
- Godot --headless --path . --script res://gameplay/tests/gameplay_garden_input_test.gd

Only Garden-owned code and tests were changed in PR #18; no owner APIs were
replaced simply to hide a conflict.


## Garden round handoff follow-up

The scene now exposes a Garden-only live Eva Health HUD and complete
prepare_new_round() reset. At 0 HP it blocks late attacks and emits one
winner signal. Angela remains responsible for the best-of-three
scoreboard/navigation and for linking the Garden map button.

Ninja's temporary shuriken art still applies only to Garden. Austin's
open items branch also edits the shared Living Room magic_bolt.gd;
that cross-owner visual integration needs a coordinated merge.


## Attack accounting regression

A real PVP projectile test now verifies that a 10.5 HP boosted Magic
shot *rejected by Eva's invulnerability frames* does not bank the 0.5 HP
fraction. Only the next **accepted** two boosted shots apply 10 + 11 HP.
See gameplay_garden_attack_accounting_test.gd. No Eva Health internals
were modified to implement this behavior.


## Follow-up verification — November 18 afternoon (latest owner changes)

The PR #18 round/lifecycle and Garden throwable-fire fixes were retested
against the **latest** fetched Jackson PR #20, as well as Angela #16,
Austin items, Ethan #19 and Eva Health/FireHazard/FallDamage components.
The combined worktree used **manual, unpublished** resolutions in:
- gameplay/msd/gameplay_msd.tscn: original main one-way platforms + Austin
  12 WorldItems + Jackson projectile metadata
- gameplay/msd/msd_controller.gd: Austin item signals, Ethan wind and
  Jackson furniture destruction callbacks preserved together
- gameplay/msd/appliance.gd: Austin item durability lifecycle and Jackson
  vanish() both preserved
- gameplay/integration/material_setup.gd: preserved Austin's actual item
  fuel seeding and Jackson's revised refrigerator exterior cells

**12 / 12 selected real Godot tests passed** after that integration.
PR #18 itself did NOT change any of those four files. An actual
cross-team merge must still have the respective owners review these
resolutions; passing tests does not establish automatic mergeability.

Garden-scoped new contract: `Garden.prepare_new_round()` resets players,
Eva Health, status HUD, all stage items/fire and projectiles; winner
signal fires only once. The 10.5 HP bonus now accrues only when Eva
actually applies the damage, not when invulnerability rejects the hit.
Garden's burnable throwables turn into ash via Austin's item API if
available and fall back to the user-approved 1 HP placeholder on old
main; burned hoses stop spraying and items reset correctly for replay.

Ninja's Living Room shuriken remains an acknowledged owner integration
because Austin's open items branch modifies shared magic_bolt.gd.
Angela's menu still points to GardenPlaceholder.tscn, absent from her
branch: Garden's correct scene is gameplay/garden/garden_level.tscn.
