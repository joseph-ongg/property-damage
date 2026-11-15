# Garden MVP — visual and Simulation handoff

The Art & Audio team provided `gameplay/art_team/source/garden.piskel`.
The Gameplay team retains that source **untouched**.

Earlier prototype limitations addressed here:

- Background art was stretched from 426×286 to 960×540, distorting pixels.
  `build_garden_stage.py` now uses exact 2× nearest-neighbor scaling,
  preserving original colors and source pixels.
- Three named props previously had invisible `GameplayInteractableItem`
  hitboxes but no drawable state. `GameplayGardenProp` now draws
  **three reversible source-pixel layers**; hit/damage flashes, HP and
  ash/debris communicate destruction. The art really vanishes on destruction.
- Flammable materials were previously large wood rectangles across empty
  sky. `art_generated/garden_fuel_mask.png` now contains only cells
  overlapping original rose, trunk and mushroom pixels. The game uses
  the original `MaterialGrid` public API and does not fork Ethan's code.
- Tree fire-damage, fire reset, and item state are tied to the correct
  *local arena* FireBridge; the match result freezes MaterialGrid Timer and
  item progression, and a new round restores exact initial material cells.
- The game floor has moved to the visible grass surface at y=476, and
  the upper/central fence rails have one-way ledges for platform movement.

To reproduce this artwork from the original Piskel pixels using only local
Python and Pillow:

```bash
/usr/bin/python3 gameplay/garden/build_garden_stage.py
```

Tests:
```bash
Godot --headless --path . --script res://gameplay/tests/gameplay_garden_destructible_test.gd
Godot --path . --script res://gameplay/tests/gameplay_garden_visual_playtest.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_long_session_test.gd
```

See [before/destroyed/restored comparison](evidence/2026-11-14/README.md).

Still pending **Design / Art review**: final Garden terrain platform feel,
additional map-specific actions, and completed death/burn/attack animation
from the Art team. Projectiles still use a rectangular 2D item hitbox for
the three Garden prop groups, not a per-pixel collision polygon.
