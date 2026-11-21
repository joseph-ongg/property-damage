# Property Damage — Sunday Design Team delivery review

**Scope:** only the two approved maps, Living Room / Bedroom and Garden.
**Launch:** Open project.godot in Godot 4.7.x, import resources and press F5.
**GitHub:** existing PR #21, targeted for review against main.
**Final merge:** PM/team approval required; never push directly to main.

## Original contributors and Git history

All entries below are real two-parent merge commits, not squashed work.

| Owner | Original source SHA | Integration merge SHA |
| --- | --- | --- |
| Current main, including Ethan wind | 29ff3df | c5134b0 |
| Austin item and throw system | a9b7827 | 5df9c35 |
| Eva Health, FireHazard, FallDamage | f3da066, 6681c63 | 3051452 |
| Jackson furniture burning and ash | b7dec54, a8d8cd6 | c382178 |
| Angela original two-map selector | e7f142e, 55fe753 | 086c6fb |
| Suwen Garden and Art | PR #18 ca345d6 | PR #21 ancestry |

Conflicts and API adapters have separate integration commits. We deliberately
did not merge Angela's later branch tip containing unauthorized Observatory.
Angela's original commits, authorship and SHA remain reachable.

## Playable features

F5 enters Wizard/Ninja/Werewolf choice, Angela's two-map selector and
the real Living Room and Garden arenas. Both local players can move, attack,
damage items/each other, KO, proceed to next round, restart, return to maps or
explicitly finish a session. Physical props block projectiles.

Austin's Living Room item system includes microwave with food recovery and
10-second cooked nuggets, trashcan damage/trap, fan cable/outlet, plant shards,
books, painting, plushies, clock and appliances. Canonical Design item HP is
checked against both Austin's items and Jackson's burn layer.

Eva Health is the only player HP source, with one fire-contact and one
fall-damage sensor per player. Both stage fire grids use Design's 10-second
burnout. Original Garden art, eight fence segments, hose, roses, tree holes,
mushrooms, gnomes and birds remain.

## Pending team decisions — do not claim otherwise

The Design doc does not specify an official match winner, round limit or BO3.
This build records round winners and offers manual Finish Playtest; it does
not introduce an unauthorized final match rule. Hose damage is explicitly
marked uncertain in the Design doc, and some Garden throws, Ninja jump tuning
and Werewolf final attack art remain provisional.

This is an integrated Design delivery candidate; neither automated tests nor
the existence of a PR establish universal bug-freedom or Design approval.

## Reproducible acceptance commands

    ../Godot.app/Contents/MacOS/Godot --headless --editor --path . --import --quit
    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_two_map_full_playtest_test.gd
    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_item_system_test.gd
    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_design_item_hp_integration_test.gd
    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_design_burn_time_integration_test.gd
    ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://gameplay/tests/gameplay_two_map_furniture_pvp_test.gd
    ./gameplay/garden/verify_pr18.sh --local

Run E2E additionally in a real Mac window. Two human players should explore
every item, default spawn, collision, KO and restart. Automated E2E uses
actual Godot physical-key input but deterministic unobstructed test lanes.

Design: https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit
