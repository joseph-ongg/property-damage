# PR #21 additive cross-member integration and Mac scene QA

## Git attribution (no rewrite)

This PR's original native two-parent merge commits remain reachable:

| Integrated team | Merge commit | Exact second parent / original tip |
| --- | --- | --- |
| Main (including Ethan wind) | c5134b0 | 29ff3df (contains Ethan 3ddaf72) |
| Austin / items | 5df9c35 | a9b7827 |
| Eva / HP, fire, fall | 3051452 | f3da066 (also contains ed94c21, 6681c63) |
| Jackson / furniture burning | c382178 | b7dec54 (also contains a8d8cd6) |
| Angela / approved 2-map selector | 086c6fb | 55fe753 (also contains e7f142e) |

Only a new Suwen-authored compatibility commit is added after the original
merge commits; do not squash or force-push away the original authorship.

The later Angela-associated map-select-v2 tip 6181700 is *not* grafted
wholesale because it includes gameplay/observatory and a Garden placeholder,
which are outside the two approved Design stages. The original two-map
selector source commits remain in this PR. Preservation of integrated
contributors does not imply inclusion of every experimental remote branch.

Run this read-only ancestry audit at the PR head:

    ./gameplay/tests/verify_pr21_contributor_history.sh

## Three integration-test repairs, not new mechanics

- Fan visual capture: test now uses the actual Austin outlet+cable adapter
  prerequisite to power the fan, then checks P1 and P2 controls, local
  wind and four real graphics-window states. Fan/plug code is not rewritten.
- Furniture fire: test now expects the visible AC to be owned by Jackson's
  furniture fuel mask with Ethan WOOD material, not a stale pre-merge
  assumption that the layer excludes AC. No item HP, damage or burn changes.
- Throw damage: a previously flaky test left Eva Health's target beside
  ongoing Ethan fire; renewed invulnerability sometimes swallowed the next
  Austin throw. Move the target to safety during the wait and then validate
  the same 400x400 -> 16 HP rule. No live combat immunity is disabled.

## Actual graphical Mac QA

The four fan_*.png files (960x540) and fan_real_gui_contact_sheet.jpg
are captured from a real Godot 4.7.2 Mac Metal game window with
CAPTURE_FAN_PREFIX set. They show fan off, on, one-sided wind and P2
switch-off. These are original screenshots, not synthetic artwork.

Run with:

    CAPTURE_FAN_PREFIX=/tmp/pr21_fan ../Godot.app/Contents/MacOS/Godot --path . --resolution 960x540 --script res://gameplay/tests/gameplay_fan_visual_capture_test.gd

For accurate graphics, first run Godot editor import for the worktree.
See the PR comments for full-run test outcomes; this folder is not a Design
approval statement and no unapproved third map or final match rule is added.

## Final recheck results

After the three test/fixture compatibility adjustments:
- 67/67 individual Godot SceneTree scripts PASSED, 0 failed.
- Full two-map match and all 3 character/2 stage Art/skills are included.
- Real Mac window fan screenshots captured with zero assertion failures.
- Repeat item damage test independently 3 times: 3/3 PASS.
- 10 original collaborator commits + 5 original two-parent merge commits
  are checked by verify_pr21_contributor_history.sh.

The per-test statuses and wall-clock durations appear in
all_67_godot_headless_results.txt. The suite does not require changing
Eva Health, Austin items, Jackson burn layer or Ethan grid source.
