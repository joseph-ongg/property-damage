# Garden — Design-specified mechanics (separate Draft PR)

This branch adds a **standalone Garden scene** at
`res://gameplay/garden/garden_level.tscn`. It is stacked on the
smaller character/art PR #17. It does **not** modify
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
  Art Team Piskel pixels* disappear. The fence is a projectile target,
  not a new solid barrier to local two-player movement.
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
- **Rematches:** Angela can call
  `$GardenMechanics.reset_garden_for_round()`: resets eight fence
  sections, movable props, apples, bird timer and hose without
  changing her separate game loop.

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

- `/usr/bin/python3 gameplay/garden/extract_original_fence.py`:
  source SHA and exact Piskel pixel reconstruction.
- `Godot --headless --path . --script res://gameplay/tests/gameplay_garden_design_contract_test.gd`:
  tree holes, all eight 4-HP fences, real Magic rays, rose 5 HP, bird
  apples, reusable throw API, water extinguishing, 10-second timer,
  tentative 1 HP/second toggle, four 1-HP placeholder projectile
  impacts, and Garden round reset.
- `Godot --headless --path . --script res://gameplay/tests/gameplay_garden_input_test.gd`:
  **actual P1/P2 key events** and collision/contact testing.
