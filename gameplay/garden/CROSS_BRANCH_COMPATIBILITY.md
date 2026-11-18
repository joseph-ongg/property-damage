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
   and reset_garden_for_round. This PR does not alter her menu files.
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
