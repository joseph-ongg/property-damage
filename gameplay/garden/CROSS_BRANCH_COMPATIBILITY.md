# PR #18 — Cross-team compatibility verification

Updated **2026-11-18** after fetching current remote refs. **Compatibility checked** means source review + reproducible non-mutating Git checks + actual Godot tests; it does **not** imply that every branch merges automatically or that all owners' full implementation is already present.

## Exact remote revisions checked

| Owner | Ref SHA | Merge vs PR #18 base | Evidence and honest limitation |
|---|---|---|---|
| Angela — `angela/map-select-v2` / PR #16 | `6181700eabf3774c481ed01b1ffaa4c97d2fe597` | **14 conflicts** | Her current branch includes the earlier `game-ready` experimental history (354 changed files vs main). Rather than overwrite it, we extracted **only the exact current MapSelection and presentation dependencies** into a disposable worktree and temporarily corrected its Garden path. The real menu-button → Garden two-round → menu test **passed**. **The whole Angela branch does not merge cleanly.** Her current Garden button still links to `GardenPlaceholder.tscn`. |
| Austin — `austin/items` | `a9b7827dae949bbd0833b98fdece4e6e467ff1ad` | **1 conflict** in `gameplay_msd.tscn` | A disposable merge preserved main platform nodes and Austin's 12 WorldItems. Garden hose input/throwing/legacy HP mirror and Austin's item system passed runtime tests in the earlier integration run. **The new shared Ninja visual change in `magic_bolt.gd` auto-merges cleanly with Austin's swept combat logic**; no override of `_hit_combat_target()`. Global Living Room HP unification remains Austin/Eva-owned. |
| Eva — `eva-hp` | `f3da0667c62a8188f6b94788217509b271f4a643` | **45 historical conflicts** | We tested Eva's exact latest Health, FireHazard and FallDamage **components in isolation**, rather than merge her divergent old branch wholesale. Garden Health/fire/fall hooks passed. Spark up/down from the older experimental integration is not included here. |
| Ethan — `ethan/fan-wind` / PR #19 | `3ddaf722fc748460496db3e6e56160a43aa3ce7c` | **Clean individually** | Real local wind and Garden integration tests previously passed; combining with Austin/Jackson needs controller conflict resolution. |
| Jackson — `sim/jackson/environment-burning` / PR #20 | `b7dec542bb651ca4ec6e10babbe53f5887573887` | **Clean individually** | His latest furniture/ash integration passed in a temporary manually resolved multi-owner Godot worktree. |

Run `./gameplay/garden/verify_pr18.sh --branch-report` to refresh actual conflict counts when anyone pushes. The table above is a dated snapshot; latest refs can change at any time.

## Runtime scenarios actually exercised

**PR #18 alone:** import resources from a fresh worktree and run local tests, including original physical P1/P2 input, 4-HP fence, 5-HP rose, tree traversal, 10-second hose, fire/ash, player Health, two sequential round resets, and real boosted Magic hits.

**Earlier all-owner worktree:** Angela's older MapSelection state, Austin items, Ethan PR #19, Jackson's later PR #20 and only Eva's replacement component sources were manually integrated. **12/12 selected runtime tests passed** after resolving scene/controller/appliance/material-setup conflicts. This is not a clean merge of today's 6181700 Angela head.

**Current Angela menu-only E2E (2026-11-18):** copied exactly her current menu script/scene and required art/UI dependencies, changed only its *temporary* Garden destination from the old placeholder to `res://gameplay/garden/garden_level.tscn`. The test exercised the **real Button.pressed** handler, loaded Garden, played two actual Magic-based 10-HP-per-shot winning rounds, called `Garden.prepare_new_round()`, and returned to Angela's map menu. All checks passed. Angela's live PR was never changed. Her full best-of-three winner UI/scoreboard is still not verified by this focused test. Her current branch's legacy lobby decor includes a third arena from the old experimental integration; **PR #18 does not adopt this Design drift**.

**Current Austin shared-bolt compatibility:** in a disposable merge of the exact Austin items branch with the new PR #18 projectile visual change, only the **preexisting scene file** conflicts; the shared `gameplay/msd/magic_bolt.gd` auto-merged Austin's real hit logic and Ninja's drawing change without conflict. Austin/PR #18 damage logic and item behavior were separately verified in earlier tests; final owner-approved integration remains pending.

## Integration boundaries and actionable handoffs

- **Angela:** Correct Garden map destination to `res://gameplay/garden/garden_level.tscn` in her own map menu. Use `Garden.player_defeated(loser, winner)` for scoring and `Garden.prepare_new_round()` for complete player/projectile/fire/item reset; own final best-of-three menu and keyboard focus. Avoid reintroducing the experimental third arena.
- **Austin/Eva:** Agree on one Health authority across **both** arenas. Garden only adapts Austin's legacy `player.health` into Eva's `Health.hp` and uses Austin's native item HP if available. Do not silently replace Austin's collision, formula, or respawn logic in his files.
- **Ethan/Jackson/Austin:** During an owner-reviewed merge, retain original main platforms, 12 Austin WorldItems, Ethan wind setup/cleanup, Jackson furniture destruction, and the newer ash/fuel/appliance behavior. Historic temporary conflict resolutions were not pushed.
- **Sandra/Art:** Approve Garden temporary 1 HP item damage/durability, Ninja 1.10× jump, temporary shuriken glyph, provisional bird timing and final standalone gnome/apple art.

## How to reproduce without modifying anyone else's branch

```bash
./gameplay/garden/verify_pr18.sh --branch-report
./gameplay/garden/verify_pr18.sh --local
```

The menu E2E script is **integration-only**. In a disposable worktree, transplant Angela's current `gameplay/MapSelection/map_select.gd/.tscn` with `gameplay/presentation/lobby_decor.gd`, `stylekit.gd` and its original image dependencies; correct only the temporary Garden path, then run:

```bash
./gameplay/garden/verify_pr18.sh --menu
```

On an unmodified PR #18 checkout this intentionally fails with “Angela MapSelection not in checkout” instead of claiming the menu already works.

Nothing in the procedure pushes, force-pushes, deletes team branches or merges to `main`.
