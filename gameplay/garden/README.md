# Garden — Design-aligned gameplay (Draft PR #18)

PR #18 is the single combined character/art + Garden Draft PR, targeting
`main`. It includes the standalone Garden scene at
`res://gameplay/garden/garden_level.tscn`. It does **not** modify
`gameplay/MapSelection/map_select.gd`, `LevelSelection` or
the gameplay-loop/round-controller code owned by Angela.

Design: [PUBLIC DP Designs](https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit), Garden section.
Assignment: Angela's 2026-11-14 Gameplay Slack handoff ("Suwen is working
on gameplay and character implementations for the garden map ... I will
continue working on map selection ... once Suwen finishes the Garden map").
Austin owns the **general-purpose** item mechanics, Eva owns Health,
Ethan/Simulation owns MaterialGrid; this PR does not modify their files.

## Implemented and how to test

Open `gameplay/garden/garden_level.tscn` in Godot 4.7.2 and use F6
(Run Current Scene). Two original `GameplayPlayer` prefabs, a reusable
upstream `MaterialGrid`, Art Team Garden and bird animation load.

- **Tree holes:** Near the painted lower hollow, press P1 E / P2 Shift
  to travel to the upper branch; repeat by the upper hollow to return
  to ground. The transit has a 0.55s cooldown to prevent auto-bounce.
  This is actual **vertical travel**, not invented invulnerability/cover.
- **Fence:** Eight independent segments, each exactly **4 HP**. Magic
  bolts hit each section for one HP; after four hits its *original
  Art Team Piskel pixels* disappear. Shots are tested against the **real
  opaque Piskel pixels**, not a rectangular phantom collider. This may
  require jumping to shoot upper fence sections. The fence does not block
  local player movement.
- **Roses:** Original thorn arch has contact areas; entering applies
  **5 HP** using Eva's existing Health component and invulnerability.
- **Bird / apples:** The Art Team bird sprite loops at its authored
  7 FPS and periodically flies from the tree. It drops physical apples
  that fall and can be picked up and thrown using the existing
  existing `GameplayBurnableProp` helper from main (not Austin's newer item branch).
  "Occasionally" has no numerical frequency in Design: export
  `bird_drop_interval` for review (default 5 seconds).
- **Mushrooms / gnomes:** Pickup/throw are wired to that same
  existing base prop behavior, without changing global Gameplay item classes; Austin's newer item system still needs its separate integration review.
  Red and blue mushrooms use transparent pieces **pixel-extracted
  from the Garden Art Team Piskel**.
- **Water hose:** Its portable nozzle pixels are extracted from the
  same Piskel. E/Shift near its authored source point picks it up,
  and it sprays for **10 seconds** from the carrying player's facing.
  Press interact a second time to throw the nozzle itself; after the
  ten-second duration it drops and can be collected again.
  Water extinguishes cells using Ethan's original
  `MaterialGrid.extinguish()`; no new fire store.
- **Tentative hose damage:** The Design sentence contains `(?)`:
  `tentative_hose_damage_enabled = true` for this playable draft,
  using the **1 HP/second** already written in Design. It is marked
  tentative and can be disabled via the exported Inspector property.
- **Garden-only PVP:** Magic projectiles hit the opposing player for
  Design's base **10 HP** through Eva Health. Visible destructible
  items take priority over a player behind them; empty pixels do not.
  Destroying a fence gives its attacker **+5% attack**. Fractional 0.5
  damage is carried to the next shot because Eva Health stores integer HP.
- **Flammable Garden props:** Actual Simulation `MaterialGrid` fire
  removes **1 fence HP per 3 seconds**. Apples, gnomes, mushrooms and the
  hose-end also take fire damage and turn into unpickupable ash, using
  Austin's own `GameplayInteractableItem` burn/HP contract when that
  branch is present. Current main still has an older book prototype,
  so Garden uses an explicitly temporary **1 HP** local fallback for
  its own item sprites only. This does **not** copy or replace Austin's
  general item system. Original Art Team art stays unchanged.
- **Fragile tags:** Garden apples, gnomes, mushrooms and hose head are
  reusable unless their `fragile` property is explicitly checked.
  An ordinary item can hit once per flight, then fall and be picked up
  again; only a marked fragile item disappears after impact.
- **Garden handoff for rematches:** Angela can call the scene-level
  `Garden.prepare_new_round()`, which resets both fighters, Eva HP,
  projectiles, positions/momentum, eight fences, movable props, apples,
  bird timer, earned 5% bonuses, hose, and all original MaterialGrid
  cells. The lower-level `GardenMechanics.reset_garden_for_round()`
  restores **props only**; use the scene-level API for complete rounds.
  Garden emits `player_defeated(loser_index, winner_index)` once when
  Eva Health reaches zero, suppresses later attacks and shows a
  temporary live Eva HP HUD. Angela still owns the proper winner UI,
  scorekeeping, selection and best-of-three match controller.

P1: A/D move, W jump, S crouch, G Magic, F Spark, E interact.
P2: arrows move/jump/crouch, period Magic, Enter Spark,
Shift interact.

## Art provenance / limitations

All Garden illustration pixels, **including the rose, tree, eight fence
parts, mushroom heads, hose nozzle and animated bird**, come from
Art Team's existing `garden.piskel` (426x286) and
`Bird drop animation.piskel`, included without modification in
`gameplay/art_team/source`. The reversible extraction script
`extract_original_fence.py` partitions these pixels into independent
original-art layers. The source-image reconstruction is **byte-for-byte
pixel identical** and checked by script, including transparency.
No AI art, new game theme, rebrand or audio.

**Missing Art Team assets:** The shared Art folder contains no
independent gnome or apple Piskel. Those two item icons are **small
explicit temporary debug placeholders**, not invented Art Team art.
Art Team should replace them before release.

**User-approved temporary balancing:** Design gives **no impact damage**
for thrown Garden apples, gnomes, mushrooms, or hose ends. Their
Garden-only swept-hit adapter applies **1 HP per impact as a placeholder**,
via Eva's existing Health component. Pickup, carrying, throwing and world movement use
the existing main-branch GameplayBurnableProp helper,
which Git attributes to Suwen. Austin owns the newer
item-system branch and its final integration. This 1 HP value is NOT presented as a Design
decision, and is deliberately separate from Austin's general item
damage-balancing work. Austin/Design must confirm final numbers and
any future shared throwable-damage API.

**Awaiting Angela:** Her map-selection owner can point the existing
Garden entry to `res://gameplay/garden/garden_level.tscn`. This
branch intentionally does not modify that selection script, her
character selector, HUD/rounds, or restart flow. The Garden scene
is mechanically interactive but **not yet a complete best-of-three
match or released, fully approved Garden**.

## Verification

On a fresh checkout, **import the new PNG resources first**:

```sh
Godot --headless --editor --path . --import --quit
```

Only then run the tests. Without initial import, Godot may reject PNG
preloads before any Garden logic executes.

- `/usr/bin/python3 gameplay/garden/extract_original_fence.py`:
  source SHA and exact Piskel pixel reconstruction.
- `Godot --headless --path . --script res://gameplay/tests/gameplay_garden_design_contract_test.gd`:
  tree holes, all eight 4-HP fences, real Magic rays, rose 5 HP, bird
  apples, reusable throw API, water extinguishing, 10-second timer,
  tentative 1 HP/second toggle, four 1-HP placeholder projectile
  impacts, and Garden round reset.
- `Godot --headless --path . --script res://gameplay/tests/gameplay_garden_input_test.gd`:
  **actual P1/P2 key events** and collision/contact testing.

- `Godot --headless --path . --script res://gameplay/tests/gameplay_garden_regression_edges_test.gd`:
  direct P1/P2 10-HP combat, transparent-vs-visible fence precision,
  true item/player target priority, 5% break reward, 1-HP-per-3-sec
  fence burning, complete fire reset, regular vs fragile throwables,
  provisional Ninja shuriken/jump and Eva death/winner handoff.

**Known review dependencies:** Garden is still not connected to Angela's
main map-selection/round flow. Austin's separate newer item mechanics
need an owner-approved interface merge; only Garden fences have the
new 3-second fire-to-HP adapter. Ninja's higher-jump multiplier and
vector shuriken art, Werewolf's unspecified attack, Garden gnome/apple
sprites and hose rule marked `(?)` all require Design/Art confirmation.


## November 18 cross-branch compatibility pass

See CROSS_BRANCH_COMPATIBILITY.md for actual individual and all-branch
runtime tests, the manual conflicts, and explicit owner dependencies.
This Garden PR now adapts to optional Austin item tags/HP, keeps Eva
Health authoritative in Garden, enables Eva FireHazard, conditionally
loads Eva FallDamage, accounts for all visible fence fire pixels and
recirculates old unheld apples rather than permanently stopping bird drops.
This is NOT a claim that Angela's missing Garden menu target, the
Living Room duplicate HP, or the Ethan/Jackson controller conflict was
automatically fixed.


## Complete Garden round handoff

Angela can call `Garden.prepare_new_round()` once at each new round:
it restores both player positions, Eva Health, movement state, all Garden
items/trees, the Simulation fire grid, attack bonuses and any stray
projectiles, then re-enables actions. Do not use only
`GardenMechanics.reset_garden_for_round()` for a full match rematch.
The standalone Garden HUD displays Eva HP for both fighters; it does
not replace Angela's shared match scoreboard.

At zero HP the scene emits `player_defeated(loser,winner)` once,
freezes Garden Magic, items and rose damage, and cancels late projectiles.
The two-round regression is
`gameplay/tests/gameplay_garden_round_handoff_test.gd`.


## Final scoped review (2026-11-18)

- 23/23 Godot tests pass, including Garden complete round handoff,
  post-round interaction lockout, Eva i-frame attack bonus accounting,
  and Garden flammable props with ash/reset.
- A temporary cross-owner merge with the updated Jackson PR #20,
  Ethan PR #19, Angela PR #16, Austin items and Eva Health components
  passes 12/12 selected runtime tests after **manual** merge decisions.
  No other owner's source was pushed or rewritten in PR #18.
- Latest evidence: evidence/2026-11-18-original-art/qa_results.md
- Remaining inter-team tasks: Angela menu/startup and best-of-three;
  Austin/Eva Living Room HP unification; Ethan/Jackson controller and
  scene conflict sign-off; Design's Garden item HP/damage values; Art
  placeholders and Ninja's Living Room projectile appearance.
