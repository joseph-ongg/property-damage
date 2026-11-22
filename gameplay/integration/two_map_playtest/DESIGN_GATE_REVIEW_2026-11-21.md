# Property Damage | Design-first playable QA and sign-off gate
Date: November 21, 2026
Scope: PR #21 integration branch, **not** PR #18 or remote main
Normative source: https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit

## Meaning of this report

This is an evidence-led code, original-Piskel-art, real-Mac-window,
keyboard-input and collision review. No human playtesting participant was
recruited, no two-human manual session took place, and no Design Team approval
has been obtained. A scripted physical keyboard event is not the same as
two human players. Passing tests does not prove the build is bug-free.

The approved official map list contains **only Living Room / Bedroom and
Garden**. The pre-approval third-arena experiment remains visible in old
Git history as a mistake, but its files are absent from the deliverable tree.
The existing Game title in project.godot is Property Damage. No unofficial
match-winner rule or new character ability was invented.

## Design acceptance, with honest boundaries

| Design requirement | Current verified PR #21 behavior | Status |
| --- | --- | --- |
| Mage: 120HP, speed 1.0, fireball | Original Art fireball, physical 10HP shots in both maps | Implemented/tested |
| Ninja: 100HP, speed 1.2, jumps higher, shuriken | Physical P1 G and P2 period generate independent shuriken-category moving bolts, each hits for 10HP, on both approved maps | Implemented/tested; final shuriken Art missing |
| Werewolf: 160HP, speed 0.85, Shoots cloth? | Stats and existing Art loaded; undefined attack retains explicit question-mark placeholder | Design decision required |
| All base player attacks 10HP | Actual swept hits through Eva HP in both maps; items intercept shots | Implemented/tested |
| Destroying properties grants 5% attack increase | Garden fence and room property reward / fractional 10.5HP ledger | Implemented/tested in approved scopes |
| Item tags, fire, 1HP per 3 seconds, 10-second fire | Original shared Austin/Ethan/Eva/Simulation layers and Garden fence burn tests | Implemented for tested items; full Art review still pending |
| Item shot-blocking | Real item/furniture hit takes priority over farther player | Implemented/tested |
| Throwable player damage = visible pixel width × height / 10000 | Both Austin's shared real swept throw and Garden original-source-Art adapter use exact area; 400x400=16HP; no invented 1HP minimum | **Corrected** |
| Sub-1 HP exact throw damage on integer Health | Eva Health stores remaining fractional throw damage per victim across valid hits, clears on Health.reset, ignores invulnerable hits | Technically exact; UI reports pending fractional HP in Garden |
| Non-fragile throw remains reusable; fragile breaks | Original flags, actual physical throw, destroyed item recovery | Implemented/tested |
| Fall threshold and damage formula | Eva component reused; original Garden below-stage reset remains | Implemented in tested scope; Design approval of edge presentation still pending |
| Garden fence: 8 separate segments, 4 HP | Original Piskel opaque fence art, actual hit/destruction, rail collisions removed on break | Implemented/tested |
| Rose thorns: 5HP actual contact | Original Piskel upper arch and two lower rose regions have source-pixel-derived CollisionPolygon2D areas. 1-pixel black outline; no transparent sky/fence hazard; real player -5HP | **Corrected; pixel and physics tested** |
| Tree holes and branch | Real upper/lower teleport, bark and visible branch collision | Implemented/tested |
| Bird drops apples | Bird's original Art sprite and real falling throwable | Implemented; exact interval provisional |
| Mushroom/gnome/apple/hose throwable | Real mushroom/nozzle Piskel pixels; absent apple/gnome Art remains literal 20x20 question-mark tokens | Functional prototype, Art pending |
| Garden hose 10 seconds and 1HP/s? | 10-second nozzle and shared extinguish, optional (unapproved) 1HP/s target damage | **Design approval required** |
| Map/character selection, rematch, player HP | Two maps and three characters navigate in real F5; existing provisional round controls | Playable candidate; match-win specification still unapproved |

## Pixel-area throw examples: no hidden balance changes

The original Garden Piskel has two mushroom crops and a nozzle, drawn in the
game at 2x, with transparent borders. Visible image alpha bounds (world px):

| Item / current visual | Visible width × height | Exact Design damage |
| --- | ---: | ---: |
| Red mushroom (23x35 native alpha) | 46 × 70 | 0.322 HP |
| Blue mushroom (25x31 native alpha) | 50 × 62 | 0.310 HP |
| Hose nozzle (20x10 native alpha) | 40 × 20 | 0.080 HP |
| Missing-art apple question mark | 20 × 20 | 0.040 HP |
| Missing-art gnome question mark | 20 × 20 | 0.040 HP |
| Design example, explicit QA-only large size | 400 × 400 | 16.000 HP |

With Eva's existing integer-HP model, 24 landed 0.04HP hits bank 0.96HP;
the 25th displays -1HP. During a valid contact, the Garden status line shows
the exact value, whole HP applied and pending fraction; during Eva
invulnerability it explicitly says damage blocked rather than secretly
banking it. This is a significant UX limitation of the small temporary Art,
**not** permission to invent bigger item sprites or a 1HP minimum.

## Original-art rose collision audit

Source file: gameplay/garden/original_art_parts/garden_without_dynamic_props.png
is the original Art Team image (426x286) displayed at 2x, offset (54,-16).
Only exact rose-red, stem-green, skin-color thorn pixels plus immediately
adjacent original opaque black outline pixels are collision candidates.
The mask is converted to six compact collision polygons: one upper rose arch,
two left lower sections and three right lower sections. Unrelated fence,
grass and transparent sky are not included. A live CharacterBody2D entering
the right rose incurs exactly 5HP; the F5 Art is NOT replaced.

The source-pixel test sampled 239/239 colored pixels on the overhead arch,
45/45 on the left and 82/82 on the right: all were registered. Across 781,
211 and 476 sampled transparent-sky points, ZERO phantom collisions were
observed. The official screenshot compares the rendered artwork against a
QA-only, yellow-outline collision overlay.

## Reproducible tests and original game captures

- gameplay/tests/gameplay_design_throw_area_formula_test.gd
- gameplay/tests/gameplay_design_rose_pixel_collision_test.gd
- gameplay/tests/gameplay_design_ninja_shuriken_actual_test.gd
- gameplay/tests/gameplay_design_rose_visual_capture_test.gd
- gameplay/tests/gameplay_all_character_art_skill_visual_test.gd
- gameplay/tests/gameplay_two_map_full_playtest_test.gd
- gameplay/garden/verify_pr18.sh --local

Original Mac Godot graphical-window PNGs and contact sheet:
gameplay/tests/evidence/2026-11-21-design-first-qa/
Screenshots are actual real window outputs, not generated new game art.

## Required 2-human manual playtest — NOT YET PERFORMED

Use the actual Mac build with two humans on a keyboard (P1 WASD/G/F/E/C,
P2 arrows/period/Enter/Shift/other contextual carry key). Record tester,
Godot version, game SHA, date, whether input keys conflict and actual
observed outcomes, not only expected assertions.

1. Start F5, choose both approved maps and every character combination.
2. Face left/right while moving/jumping, during hit animation and after KO.
   Verify Art's sprite mirroring and animation transitions visually.
3. Ninja P1 and P2 fire; check placeholder question mark appears during
   flight and that nearby furniture/fence intercepts a shot before player.
4. Carry and throw each Garden item; verify literal area-based damage
   feedback, hit registration, repeated small-hit fractions and rematch
   reset. Do not mislabel the tiny placeholder Art as final balance.
5. Walk/jump into rose petals/stems on left/right/arch and through clear
   openings; check exactly 5HP per accepted hit and no invisible walls.
6. Double-jump onto fence rails and tree branch, pass through tree holes,
   fall off actual painted Garden edge and verify current reset behavior.
7. Pick and release hose, wait 10sec, use mushrooms, gnomes, apple drops,
   fire, fence destruction, ashes, and 5% attack growth.
8. In Living Room, repeat book/food/plushie throws, AC/fan plug/wind,
   fridge/microwave/nuggets, plants/shards, fragile props, wall collisions.
9. KO, continue round, return to map select, choose rematch. Confirm the
   game does NOT claim a formally Design-approved winner condition.
10. Record every issue: map, characters, X/Y screen position, input
    sequence, expected Design rule, observed image/video, severity, and
    simple reproducible steps.

## Outstanding P0 / P1 handoffs

P0: Real 2-human playtest has NOT happened; PM/Design must sign off on
the submitted screenshot evidence and observed gameplay.

P0: Werewolf attack, final match winner/rules and hose tentative PvP
damage are unapproved Design decisions; never silently finalize them.

P1: Missing shuriken, gnome and apple Art and animation poses must be
supplied by Art Team. When Art sizes change, size-derived throw damage
changes accordingly; re-run Design test and ask for balance sign-off.

P1: Tiny question-mark items' 0.04HP impact is mathematically correct
but low-feedback/low-impact. UI now discloses sub-HP banking. Design and
Art should assess the correct real object sizes and UX.

P1: Existing original Piskel and music/audio completeness, real keyboard
comfort, and any remaining interaction collision visual errors require
manual review. This automated QA is not a zero-bug warranty.

Do not merge remote main until the responsible PM/Design reviewer approves.
Do not create a third official map, invent final Werewolf abilities, or
rewrite any contributor commit.


## Final automated QA result — reproducible evidence

Final 71/71 independent Godot SceneTree scripts passed (zero failed).
Original Garden 24/24 accepted tests passed; Mac windowed full 2-map
63/63 E2E passed. Ninja exact P1/P2 ranged action, all item/fence/tree
rules, Rose source-pixel contours, area-derived throw formula, actual
0.04HP pending HUD, item pickup and rematch are covered by individual
tests and captured original game screenshots.

Per-test list: gameplay/tests/evidence/2026-11-21-design-first-qa/
all_71_godot_results.txt. Seven actual Mac 960x540 game window
screenshots and a contact sheet are in the same evidence folder.
The reviewer should open rose_collision_over_original_piskel.png,
throw_fractional_damage_feedback.png, garden_p1_shuriken.png,
living_p2_shuriken.png, and check the full-resolution pixel details.

No second human entered any key; this is NOT an actual two-human
playtest and no formal Design sign-off was received. The checklist
above remains unresolved pending the team.
