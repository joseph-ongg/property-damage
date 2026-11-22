# Property Damage — Sunday Design Team delivery review

**Scope:** only the two approved maps, Living Room / Bedroom and Garden.
**Launch:** Open project.godot in Godot 4.7.x, import resources and press F5.
**GitHub:** existing PR #21, targeted for review against main.
**Final merge:** PM/team approval required; never push directly to main.

## Additive contributor-preserving integration policy

PR #21 must preserve the original contributor commits (not squash them).
A read-only audit at gameplay/tests/verify_pr21_contributor_history.sh
checks 10 original source commits and all five exact, native two-parent
merges for the Austin, Eva, Jackson, Angela and original main/Ethan lanes.
Future conflicts are handled with new, separately authored commits on top
of those merges. The later map-select-v2 branch head 6181700 contains
unapproved Observatory files and is deliberately not merged wholesale.

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


## Follow-up input and collision regression (Garden)

- Garden P1 and P2 both have original double-jump controls (W twice / Up twice).
- Presses during 0.32s attack cooldown have a single short input buffer
  rather than silently disappearing. F5 PvP hit invulnerability is 0.24s,
  shorter than the attack cooldown; Eva's shared Health class default of
  0.8s is unchanged. Standalone native Garden also uses 0.24s for combat.
- The original Garden fence PNG alpha creates one-way world collisions only
  along actual horizontal rails. Fence sections retain 4 HP; destruction
  removes their ledges and round reset restores them. Transparent art gaps
  remain passable.
- Original background tree has several sloped supports instead of the
  previously inaccurate 300x12 horizontal physics rectangle.
- Added real key-input and physical landing tests:
  gameplay/tests/gameplay_two_map_double_jump_rapid_attack_test.gd
  gameplay/tests/gameplay_garden_physical_platform_test.gd


## Nov 21 visual and complete interaction QA (PR #21 only)

Garden's 426px Piskel background is scaled 2x from x=54 to x=906; its
floor collision now ends on those exact painted edges rather than across
the empty 960px canvas. The unpainted side-wall collisions were removed.
No new fall penalty or match rule was introduced; existing below-stage
position reset still works. The tree's painted central bark is solid,
with upper/lower holes open for existing vertical teleport interaction.

Original supplied Wizard/Ninja/Werewolf idle/walk/hurt Art mirrors with
actual facing throughout animation and character changes. Wizard retains
original fireball. Ninja's shuriken art was not supplied as a separate
sprite; Werewolf's "Shoots cloth?" is an undecided Design question. Both
render explicit distinct colored "?" blocks, not the Wizard fireball.
They share the existing 10HP attack/damage pipeline, with no invented skill.

Apple/gnome (Garden) and outlet/trashcan/plushie/plant/food/fan plug
(Living Room) without separate Art textures use small "?" blocks. The
original Garden mushrooms, hose, fence, bird, room background, clock,
painting, microwave and all provided character frames remain unchanged.
Item HP, flammability, throwing and interactions still work.

Additional physical-input and visual checks:
- gameplay_all_character_art_skill_visual_test.gd: three characters on
  both maps; Art frames, left/right facing, Design HP/movement, Ninja
  higher jump, actual 10HP attacks, both players' Spark key skills.
- gameplay_garden_ground_tree_interaction_visual_test.gd: original
  painted ground edge rays, central tree bark, free teleport holes,
  E-key up/down portal, mushrooms, hose and bird drop.
- gameplay_living_room_keyboard_interaction_test.gd: physical C pickup/
  throw, P1 E air conditioning/fridge/microwave, S+E microwave cooking,
  P2 Shift appliance interaction.
- gameplay_ninja_cross_arena_test.gd: updated historical expectation
  from accidental Werewolf fireball to explicit pending-art placeholder.

Actual Mac Godot 4.7.2 screenshots (same 960x540 game window):
  /tmp/property_damage_final_garden_mage_attack.png
  /tmp/property_damage_final_garden_ninja_attack.png
  /tmp/property_damage_final_garden_werewolf_attack.png
  /tmp/property_damage_final_living_mage_attack.png
  /tmp/property_damage_final_living_ninja_attack.png
  /tmp/property_damage_final_living_werewolf_attack.png

Always import Godot assets before fresh windowed command-line testing;
without that step a new worktree may report missing PNG imports.

Remaining Design/Art decisions: actual Werewolf attack, Ninja shuriken
Art, final action pose sheets, hose balance and Garden placeholders.
Garden thorn Area2D rectangles are still approximate, not Art pixel masks;
Design/Art should review thorn hit contact if visual accuracy is disputed.
Automated success is not proof of zero unknown bugs.

The real six-scene Mac game screenshots and contact sheet are committed at
gameplay/tests/evidence/2026-11-21-visual-qa/ for PM/Design visual review.


## Nov 21 Design-first follow-up after PM review

Garden's old 1HP-per-throw placeholder was NOT the Design
pixel-area damage rule. PR #21 now uses exact visible pixel area
divided by 10,000, both in Austin's swept Living Room projectile
path and the Garden art adapter. Red/blue mushrooms and hose nozzle
use source Piskel crop alpha bounds at their actual 2x scale;
unauthored apple/gnome sprites use only the existing 20x20 ? marker.
Eva integer HP accumulates fractions across valid throws and resets
them with health; invulnerable hits are not accumulated. A real
400x400 moving throw inflicts exactly 16HP. Garden item durability
remains separately provisional.

The Piskel rose hazard is THREE sources, not two broad rectangles:
upper rose arch, left stem and right stem. Their red petals, green
stems, tan thorns and adjacent black outline pixels are converted
to physical CollisionPolygon2D shapes. Transparent sky and fence
pixels cause NO invisible hazard, and actual player body contact
deducts the documented 5HP. Original Art is unchanged.

Ninja already has an independent shuriken-category projectile and
both maps run its item-first 10HP attack. No final shuriken sprite
exists in Art Team assets, so Ninja keeps the requested ? marker.
No invented Ninja special skill or speculative Werewolf attack.

Actual 2-human playtesting is NOT the same as an automated Mac
graphics-window key simulation. The manual two-player checklist
and remaining Design approval questions are recorded separately.

## Nov 21 PM/Design follow-up: facing and painted Garden upper gate

See DRIVE_ART_DESIGN_RECHECK_2026-11-21.md for linked current Design
and exact Art Team Drive asset list. Original Ninja and Wolf source
pixels face left, so both characters now mirror ONLY when they face
world-right; Wizard preserves its original right-native convention.
Physical P1/P2 keys in the real Mac game window and the two-map
character-art tests demonstrate correct idle/run/turn direction.

The source-Piskel upper Garden rose arch, previously damage Area-only,
now also has precise solid world collision (one polygon). The two
lower thorn-vine sections intentionally remain 5HP contact-only
Areas; making all three solid initially blocked Garden physical
projectiles and broke rounds, so the broader change was rejected.
217/217 sampled colored upper-gate points registered solid and
0/883 transparent sky points registered phantom solids. The actual
player body sweep stopped against the painted roof. This top
solid geometry is a user-observed gameplay fix requiring eventual
Design approval (the document only specifies rose contact 5HP).

The screenshot QA is in the 2026-11-21-gate-facing-qa evidence
folder, alongside all 73 headless program pass results.
No Art source was redrawn, no new match or Werewolf rule invented,
and no two-human playtest or final Art signoff is claimed.
