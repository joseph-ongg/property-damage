# Gameplay Art Sources and Ownership

## Team presentation artwork (now in the live Godot prototype)

The visual reference is the user's local **`Property Damage MidSem Presentation (1).pptx`**:

- **Slide 13, "Character design" (Art & Audio):** The blue hooded wizard with yellow eyes is the actual Player 1 static sprite; its two-frame animation GIF is used as the movement cycle. Player 2 is recolored red from those same blue-source sprites while keeping the black silhouette and yellow eyes. Each PNG is resized to **40×60 pixels** and visually anchored against the unchanged **32×64 collider**.
- **Slide 12, "Art subteam":** Bookcase, window, clock, fridge, air conditioner and monitor pixels are extracted from the displayed Art-team furniture composition. The local room is rebuilt around the existing Gameplay floor, wall, and one-way platform coordinates.
- **Magic fireball:** Six crisp original 24×16 RGBA pixel frames drawn by `gameplay/msd/art/generate_fireball.py` replace the prior procedural soft glow. They are visual only and do not modify hit detection or the MaterialGrid API.

The Art Team assets and designs **belong to the Art subteam**. Gameplay imports and adapts them; do not describe them as original Suwen artwork or as newly generated AI images.

## Files and regeneration

- `gameplay/art/mage_1.png`, `mage_2.png`: PPT-derived standing sprites (P2 recolored red).
- `gameplay/art/mage_1_run_0.png`, `_1.png`, `mage_2_run_0.png`, `_1.png`: frames extracted from the presentation GIF, used by Godot in `_physics_process` when the player moves. Frames change every **80 ms**; movement stopping switches back to the corresponding static PNG.
- `gameplay/art/mage_1_run.gif`, `mage_2_run.gif`: animation previews matching the runtime PNG frame pairs. Godot uses the PNGs, not direct GIF decoding.
- `gameplay/msd/art/team_*.png`: cropped Art-team room elements.
- `gameplay/msd/art/living_room_pixel.png`: rebuilt 960×540 raster environment; source `generate_room.py`, composed from original raster artwork and procedural hard-edge pixel shapes.
- `gameplay/msd/art/fireball_*.png`: six generated pixel projectile frames; source `generate_fireball.py`.

To rebuild from the same local presentation:

```bash
python3 -m pip install Pillow python-pptx
python3 gameplay/art/import_midsem_art.py
python3 gameplay/msd/art/generate_room.py
python3 gameplay/msd/art/generate_fireball.py
```

The PPTX is an **input asset**, not part of the Gameplay code commit; the resulting PNGs are committed so Godot and teammates can run without Python, Pillow, or the presentation file. Other fantasy demo resources made by `gameplay/art/generate_art.py` can be regenerated independently without overwriting the Art-team mage sprites.

Final Art can use `GameplayPlayer.sprite_override` to replace the default idle sprite; this intentionally disables the built-in GIF-derived animation when an override texture is configured, until the final Art animation set is integrated.
