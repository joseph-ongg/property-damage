# Platform V2 – Suwen's assigned Gameplay platform work

Slack's Gameplay Subteam meeting on October 20, 2026 assigned **"Add platforms – Suwen"**. Eva owns character HP, Austin the grid conversion, and Angela additional interactions. This independent branch starts from the latest `origin/main` commit `bc4a5f1` (which includes Austin's burnable-bookshelf/table implementation), not the old gameplay prototype or unfinished HP branch.

## Platform installation

`gameplay/msd/gameplay_msd.tscn` has the original `BookshelfTop`, `TableTop`, and `FridgeTop` unchanged. Eight new prefabs sit under `GameplayMSD` (direct children; Godot instancing-safe):

| Node | Center (world px) | Width | Surface Y | Artwork / function |
| --- | --- | --- | --- | --- |
| `WindowSill` | (152,207) | 144 | 201 | Invisible collider on the window sill, keeping the bookshelf throw lane clear |
| `ACUpperRim` | (648,323) | 112 | 317 | Invisible top on the real AC sprite |
| `BedTop` | (72,393) | 128 | 387 | Invisible top over the low bed / sofa |
| `GalleryFrameTop` | (480,92) | 160 | 86 | Invisible top along the large picture's upper rim |
| `SmallFrameTop` | (746,135) | 80 | 129 | Invisible top on the small picture frame |
| `WallShelfLeft` | (382,280) | 96 | 274 | Painted wood wall bookshelf (new pixel texture) |
| `WallShelfCenter` | (540,270) | 112 | 264 | Teal-toned wood wall bookshelf |
| `WallShelfRight` | (846,287) | 96 | 281 | Dark walnut wall bookshelf |

Every platform is a **one-way** `StaticBody2D`, collision **layer 1**, collision mask **0**. Players remain on layer 2 with mask 1, so the two players still pass through each other. Passing from the side or below is allowed; players and thrown books can rest on the top. Down+Jump still drops through these one-way bodies. Geometry is registered to the art surface, not a solid full-furniture block.

## Reusable prefab and team boundaries

`one_way_ledge.tscn` / `one_way_ledge.gd` were **adapted from Suwen's local `suwen/arena-platforms-20261021` branch**, originally derived from `suwen/platforms` commit `7c96bdd`. The shape is duplicated as a scene-local resource before width updates, preventing one instance from resizing another. `span_cells` (16px default), `design_cell_size`, `world_surface_bounds()`, `surface_center()`, `platform_id`, and `material_tag` are Inspector-level handoff APIs for Austin and Level Design.

For existing Art-painted furniture set `visible_surface=false` to avoid drawing duplicate bars. New bookshelf plates are procedural, **original** 96×48 or 112×48 RGBA textures from `generate_bookshelves.py` (Pillow; no AI image generation, web assets, or downloaded sprites). The textured bookshelf cabinet top coincides with the actual one-way collider's top, and its detailed spines, braces and recessed body sit below the landing plane. Art Team can assign a replacement `sprite_texture` with the same proportions without altering physics.

All 8 platforms are **passive collision surfaces**. The script does not paint or set `MaterialGrid` materials, interfere with `GameplayFurnitureFireLayer`, define HP/burn states, or change Austin's furniture cell region. The `material_tag` is metadata, not a claim about fuel physics. Future grid snapping should be implemented by Austin using the already available `world_surface_bounds()` API; don't import an alternate storage array.

## Tests and screenshots

`res://gameplay/tests/gameplay_platform_v2_test.gd` checks one-way collisions, placement, independent sizes, material independence, landing / passing / dropping, and book support on actual Godot physics. To collect real viewport screenshots on macOS, run GUI Godot with `CAPTURE_PLATFORM_V2=/absolute/path/prefix` and the test script. Screenshots are stored outside the team's tracked gameplay code under `presentation_media/screenshots/`.
