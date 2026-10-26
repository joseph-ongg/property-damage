# Gameplay Art Sources and Ownership

## Team presentation artwork (now in the live Godot prototype)

The visual reference is the user's local **`Property Damage MidSem Presentation (1).pptx`**:

- **Slide 15, "Character design" (Art & Audio):** The blue hooded wizard with yellow eyes is the actual Player 1 static sprite; its two-frame animation GIF is used as the movement cycle. Player 2 is recolored red from those same blue-source sprites while keeping the black silhouette and yellow eyes. Both player PNGs retain the original **736×736 RGBA source resolution and uncropped transparent margins**; Godot scales them to about 60 visible pixels high through `Sprite2D.scale` against the unchanged **32×64 collider**. P1 static PNG and original GIF bytes are copied exactly from the PPT; P2 is the same RGB/alpha source except for the blue-to-red robe/hat pixel colors.
- **Slide 14, "Art subteam":** Bookcase, window, clock, fridge, air conditioner and monitor pixels are extracted from the displayed Art-team furniture composition. The local room is rebuilt around the existing Gameplay floor, wall, and one-way platform coordinates.
- **Magic fireball:** Six crisp original 24×16 RGBA pixel frames drawn by `gameplay/msd/art/generate_fireball.py` replace the prior procedural soft glow. The art is visual only; the projectile now ignites bookshelf and table fuel through the existing fire bridge and MaterialGrid API.

The Art Team assets and designs **belong to the Art subteam**. Gameplay imports and adapts them; do not describe them as original Suwen artwork or as newly generated AI images.

## Files and regeneration

- `gameplay/art/mage_1_action.png`: the other exact original PPT static PNG (P1 gesture pose); `mage_2_action.png` is its red recolor.
- `gameplay/art/mage_1.png`: exact original PPT Character design PNG (736×736, copied byte-for-byte); `mage_2.png`: same 736×736 RGBA artwork with blue costume pixels recolored red. Every original transparent and non-blue pixel is unchanged.
- `gameplay/art/mage_1_run_0.png`, `_1.png`, `mage_2_run_0.png`, `_1.png`: full-resolution, uncropped frames extracted from the original presentation GIF, used by Godot in `_physics_process` when the player moves. Frames change every **80 ms**; movement stopping switches back to the corresponding static PNG.
- `gameplay/art/mage_1_run.gif`, `mage_2_run.gif`: `mage_1_run.gif` is the exact original PPT GIF, copied byte-for-byte; `mage_2_run.gif` is its red recolor preview. Godot uses the PNGs, not direct GIF decoding.
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

## Art / collider reconciliation

The image layout is derived from the source team's **original image pixel
ratios**, rather than non-uniformly stretching a single shelf or fridge to
cover a wider physics region. Two small bookshelf units together cover the
unchanged top platform width. The refrigerator has its own narrowed one-way
surface matched to a source-proportional 90×154 pixel image. This alignment is
specific to the independent Gameplay playtest scene.

- **Design Team slide 12:** The central window was replaced by a smaller framed illustration to keep the agreed left-side window, shelf, desk, AC, clock and right-fridge hierarchy visible. Gameplay owns this independent prototype only.

## Repaired Art Team clock and layered 2D room (October 12)

The original `team_clock.png` is cropped at its rightmost edge in the source
Art Team furniture collage. It remains preserved, unmodified, as an upstream
source. `msd/art/generate_room.py` instead repaints **a complete pixel-art
clock in the same position**, with a full outer ring, ivory dial, twelve
hour ticks, two hands, a raised rim and a small drop shadow. This repair does
not claim to be a new official Art Team deliverable.

The isolated Gameplay room uses three distinct 960x540 painted pixel plates:

1. `living_room_pixel.png`: original furniture composition, wall paneling,
   stepped wood floor planks, platform edges, rug depth and grounding shadows.
2. `living_room_lighting.png`: a transparent overlay of cool window rays,
   warm light pools, and subtle wall occlusion. Runtime node `RoomLighting`
   appears above the material marker layer and below Gameplay characters.
3. `living_room_foreground.png`: transparent near-camera corner leaves and
   tabletop apron; runtime node `RoomForeground` appears above actors only at
   the scene edges, never across the core interactions.

The runtime `room_depth_layer.gd` uses nearest-neighbor rendering of the two
transparent plates. This is a deliberately restrained **HD-2D-inspired 2D
layering treatment**, not a reproduction of the Octopath Traveler art assets,
lighting engine or 3D environments. All assets were produced from local
code and the team's existing raster inputs; no online art was downloaded.

Regenerate the three aligned plates after layout tweaks:

```bash
/usr/bin/python3 gameplay/msd/art/generate_room.py
```

`gameplay/tests/gameplay_room_depth_test.gd` verifies the repaired clock dial
and rim, translucent spatial layers, intended Z ordering, center playfield
visibility and unchanged Simulation/physics contracts.

## Complete wall clock and room depth (October 13)

The Art Team source `team_clock.png` is a crop whose bezel meets the right image boundary. That credited source is unchanged. `generate_room.py` composites a separate transparent `clock_complete.png` with a full bezel, 12 ticks, hands, glass glint and cast shadow at the original position. The procedural 2D room also gains hand-pixelled contact shadows, lighting and foreground plates. Optional computer/AC glow PNGs are triggered by the actual appliance state through `room_lighting_fx.gd`. All are independent of collision and Ethan's material grid. The visual language is HD-2D-inspired, not imported artwork from any commercial game.

## Gameplay left-facing desk fan (October 13, 2026)

The angled desk fan in `gameplay/props/fan/sprites/` is **new original procedural pixel art** drawn by `gameplay/props/fan/generate_fan.py` with Pillow on the local Mac. No AI image generator, remote download, or reused copyrighted game art was used. Layered rear housing/stand, six rotor frames and front perspective grille are native 48x56 RGBA textures. They are distinct from the Art Team's PPT originals and can be overridden separately by that team. See `gameplay/props/fan/README.md` for exact replacement and state API contracts.
