# Art & Audio Piskel integration (November 14, 2026)

Source: [Art Team shared Drive folder](https://drive.google.com/drive/folders/1-bNX0VyVeyccPiMAJbUSJDj4b6Q0kjnJ).

## Ownership and provenance

**All 14 `source/*.piskel` projects come from Art & Audio.** These are kept
unchanged, with SHA-256 hashes, frame dimensions, FPS, and generated filenames
recorded in `catalog.json`. Files originally shared without a suffix have
been given the `.piskel` suffix only after confirming they are Piskel JSON.
The team art is not presented as Gameplay-created art.

`export_piskel.py` uses Pillow to composite Piskel layers and export the 25
original pixel frames as transparent PNGs. No AI image generator was used.
Regenerate with:

```bash
/usr/bin/python3 gameplay/art_team/export_piskel.py
```

## Integration boundaries

- **Ninja (live)**: `ninja_side` idle, all four `ninja_walk` frames at
  12 FPS. Existing temporary jump/attack/hurt remain until Art provides those.
- **Werewolf (live)**: `wolf_walk` idle and two run frames at 7 FPS;
  `wolf_damage_1` for the Hurt pose. Existing temporary jump/attack remain.
  Both frames of Wolf damage are exported; the current character API only
  displays one Hurt frame at a time.
- **Mage (optional)**: `mage_visuals.tres` contains the new Art Team
  32x32 main character and hurt image. Assign it to a Mage player's
  `character_art_override` in the Inspector; original deck-derived
  blue/red Mage art stays the default, preserving both player variants.
  Art Team Mage burning/death/hit frames are exported, not yet wired to an
  unfinished death/fire status game loop. `Hit MC` and `Dead sprite`
  are byte-identical as supplied, so they do not establish a distinct
  death animation.
- **Garden (preview)**: Angela's existing `GardenPlaceholder.tscn` shows
  Art Team's `garden.png`; this is still a static placeholder, **not** a
  completed Garden arena.
- **Living Room (preview only)**: `living_room_map.png` remains available
  in `art_gallery.tscn`. Its original 575x417 composition does not align
  with the current 960x540 Living Room physics/furniture grid; replacing
  the live backdrop without scene-layout work would misrepresent collisions.
- **Fire (live visual only)**: `fire_0.png` is drawn by the existing
  `FireVisuals` renderer, with `use_art_team_flame` toggle for the
  previous procedural flame. Burning state and spread still come exclusively
  from Ethan's `MaterialGrid`.
- **Bird drop**: all 3 frames are available for the future Garden mechanic.

## Preview and tests

In Godot, open `res://gameplay/art_team/art_gallery.tscn` and run with F6
for source-accurate previews of both backgrounds and a sprite strip.
The map preview doesn't modify runtime game mechanics.

Art integration tests:
```bash
Godot --headless --editor --path . --import --quit
Godot --headless --path . --script res://gameplay/tests/gameplay_art_team_assets_test.gd
```

No existing Gameplay mechanics, HP, Simulation API, or Design rules are changed.
