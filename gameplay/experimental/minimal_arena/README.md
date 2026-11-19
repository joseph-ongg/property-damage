# Minimal Arena 3 — EXPERIMENTAL, NOT DESIGN APPROVED

Standalone integration/smoke-test scene. **Not** an approved Design Team arena.
The official game remains Living Room / Bedroom + Garden. This prototype is
not linked from the main game, menu, or PR #18.

## Launch
Open project.godot in Godot, load the scene at:
gameplay/experimental/minimal_arena/minimal_arena.tscn
Press F6.

- P1: A/D move, W jump, G attack.
- P2: arrows move/jump, period (.) attack.
- On KO both controllers stop; press R to start a fresh test round.

**No new mechanics, weapons, art, items, hazards, or score logic.**
Uses shared GameplayPlayer, Eva Health, and the tested Garden projectile
adapter. The empty Fences scene node is a compatibility requirement only.

## Boundaries
- Never merge this experimental branch to main or into PR #18 before
  Design/owner review.
- No third-map button is added to Angela's UI.
- No simulation, new official specification, or final art is implied.
- The PR is based on the head of PR #18 only to isolate its diff.
- This sandbox is *not* a substitute for official two-map end-to-end QA.

Design source: https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit
