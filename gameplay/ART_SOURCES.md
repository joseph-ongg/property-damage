# Gameplay Art Sources and Ownership

- `gameplay/art/generate_art.py` produces original pixel-art assets in `gameplay/art/`: the new **32×60 mint and amber co-op mage sprites**, the optional Moonlit Ruins background, platforms, shards, and braziers. All geometry and palettes are drawn locally with Python Pillow; no downloaded character textures were used.
- `gameplay/msd/art/generate_room.py` produces `gameplay/msd/art/living_room_pixel.png`, an original 960×540 pixel living room. Its furniture is aligned with the Gameplay collision shapes; quieter wall sconces and small platform-edge inlays clarify where characters can land.
- `gameplay/msd/appliance.gd`, `burnable_prop.gd`, and `magic_bolt.gd` draw optional interactables with Godot's `_draw()` API, not downloaded image files.
- The root `icon.svg` predates this local Gameplay art and belongs to the repository.
- Artwork in `sim/jackson/burn-box-render` (including `stage_tiles.png`) comes from teammates. These assets are **not included** in the Gameplay prototype and are not claimed as original Gameplay artwork.
- External games informed general color, pixel readability, and responsive action-feedback principles only. No commercial game art was copied. Any future externally licensed asset needs its creator, source URL, and license recorded here.

## Rebuild the original PNGs

From the repository root, with Pillow installed:

```bash
python3 gameplay/art/generate_art.py
python3 gameplay/msd/art/generate_room.py
```

These scripts are deterministic. Godot 4.7.2 loads the committed PNGs directly; neither Python nor Pillow is required at runtime. Final team sprites can be substituted per player via the `sprite_override` Inspector property, without modifying movement or Simulation code.
