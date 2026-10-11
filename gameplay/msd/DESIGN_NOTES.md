# Property Damage — gameplay design proposal (not a finalized game spec)

Prepared for the local prototype. **Status: proposal; PM/design approval pending**.
The existing repo title **Property Damage** is the actual project name. The
older "Moonlit Ruins", "Ember Shards", brazier and combo objectives were local
inventions in a separate experiment and are not official game rules.

## Evidence: what the team has actually requested

**Confirmed for Oct 15 MSD** (Zander, Gameplay group, Oct 6; all PRs requested
merged by Oct 11): two players on one keyboard (P1 WASD, P2 arrow keys), run,
jump, face L/R, Spark into the grid cell directly ahead, solid world walls and
floor, one-way furniture platforms, no out-of-bounds falling. Code belongs in
`gameplay/`, fake test arena now, do not modify `burn_box.tscn`. Use
`CharacterBody2D` + `move_and_slide()`, world layer 1 and player layer 2.
Simulation owns `ignite`, `is_burning` and real material storage.

**Proposed by Design** (Sandra, Oct 5, [PUBLIC] DP Designs): domestic living
room/bedroom arena, direction-based magical attacks, an interaction key, books
that might be picked up/thrown/burned, bookcase ladders, fridge, A/C slowdown,
clock or picture interactions, plug-in fan and damaged computer. The document
states all ideas are subject to change. Mana and damage scaling are explicitly
future possibilities. **No confirmed full-game scoring/winning rule** is
specified in these sources.

## Design references — principles, not copied mechanics or assets

- [TowerFall, official site](https://www.towerfallgame.com/): accessible local
  multiplayer, distinct fighters and strong attack feedback. Apply **one-screen
  spatial awareness, contrasting player colors, few core buttons, readable
  attack origin**. We do *not* import TowerFall combat or scoring.
- [Noita, official site](https://www.noitagame.com/): spells alter physical
  materials. Apply **clear visual before/after fire response** and keep it
  consistent with the future material API. Our stand-in fire storage is **not**
  Noita-like per-pixel simulation; do not promise spread, thermodynamics or
  real destructibility until Simulation implements it.
- [TowerFall designer interview](https://blog.playstation.com/2014/03/14/towerfall-ascension-on-ps4-behind-the-arena/): local players benefit from
  low-friction, immediately comprehensible interactions. This supports a tiny
  one-line HUD and separate clear player labels instead of large score panels.
- Responsive platformers: jump buffering, variable-height jumps, and coyote
  forgiveness already live in `gameplay/components/player_motor.gd`; their
  tunable values should be evaluated against the final furniture arena.

## Recommended demo loop / UX

**Now:** move or jump to a useful position → face left or right → spark at the
adjacent cell → see a short, legible fire result → continue exploring furniture.
There is **no winner** in this technical showcase; the target is demonstrable
movement, collisions, correct spark direction, and Simulation handoff.

**Optional visual exploration**, clearly labeled: three staged book bundles
can become charred by a nearby Spark. Implemented in
`gameplay/msd/burnable_prop.gd` and selectable via
`GameplayMSD.experimental_books_enabled`. It only adds pixels, not actual
material damage or fire spread; toggle it off if the team wants pure MSD.

## Prioritized implementation plan and ownership

| Priority | Status | Feature / acceptance evidence | Ownership |
| --- | --- | --- | --- |
| P0, Oct 11 | Implemented locally, not merged | 2 independent keyboard players move and jump; one-way table, shelves, fridge; world wall/floor; directional Spark | Gameplay |
| P0 | Implemented with demo grid | World-to-cell bridge works; double-check actual `MaterialGrid` signatures; stand-in does not imply storage is ready | Gameplay + Simulation |
| P0 | Implemented locally | One-screen legibility: P1 mint / P2 warm amber; few HUD labels; test scene isolated from `burn_box.tscn` | Gameplay |
| P1, after Simulation handoff | Pending | Replace fake grid/arena paths, validate real materials and burn visuals, remove experimental fallback | Simulation + Gameplay |
| P1, with Design/Art review | Proposed, optional prototype exists | 3 book props can show local scorch feedback; confirm interaction rules, materials and ownership | Design + Art + Gameplay |
| P2, after agreement | Not implemented | Pickup/throw, outlet/fan force, fridge trapping, clock and other complex furniture | Design + relevant teams |
| P2, after PM approval | Undefined | Damage scoring, victory/defeat, rounds, mana or power scaling | Design + PM |

## Pixel-art style guide

- Original assets only; no game screenshots/sprites copied from references.
- Draw a room at **480 × 270** native pixels; scale 2× with **nearest-neighbor**
  sampling to the 960 × 540 logical viewport. Maintain hard pixel edges.
- Palette: low-contrast blue-charcoal walls, cream moonlight, amber household
  lamps, warm wood, and distinct mint vs orange players.
- Prefer crisp object silhouettes and modest highlights; fiery areas should
  not become as large as the player, and HUD should not cover the arena.
- Keep all art changes outside Simulation scenes and collision definitions.
- `art/generate_room.py` regenerates `living_room_pixel.png` deterministically;
  Pillow is a *development-only* art tool and isn't needed to run the game.

## Before integrating into the team's real scene

1. Coordinate branch ownership and merge order; local branch commits are not
   remote PRs, and the Oct 11 target has not been met by these local commits.
2. Recheck the Art team's mage sprites and the Simulation team's final arena;
   the current local mage pixels are temporary.
3. Decide with Design whether props should take damage via actual
   `MaterialGrid` rather than this simple visual stub. Remove stub if it
   duplicates Simulation.
4. Get actual victory/round rules in writing before shipping scores or win UI.
5. Run `gameplay/tests/gameplay_msd_test.gd` and
   `gameplay/tests/gameplay_props_test.gd` on the merged branch.

Sources: Gameplay subteam Slack 2026-10-06;
https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit

## Local interaction prototype update (not approved rules)

Implemented after the initial MSD prototype as separately editable modules:
`GameplayMotor` now supports a fixed-height double jump with inherited
midair horizontal momentum. `GameplayBurnableProp` supports E/Shift pickup and
throw, and `GameplayAppliance` toggles four distinct appliance experiments.
`GameplayMagicBolt` provides a second, directional visual magic attack on
G/period, while Spark F/Enter continues through `MaterialGrid`'s adapter.
All these actions are **technical prototypes** based on the public doc's
possible interactions, not a final approved combat, health, or scoring system.
Future balancing needs team input on double-jump reach, whether books should
use true physics bodies, and which appliance effects are wanted in production.
