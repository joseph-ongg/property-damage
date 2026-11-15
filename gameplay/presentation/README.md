# Property Damage — Pixel Fantasy UI & Garden Share

**Selective sharing branch, 2026-11-15.**

Built **on top of**
`origin/suwen/full-game-integration-20261114`, not the team's `main`.
The source of truth for selecting characters and levels remains Angela's
existing `gameplay/MapSelection/map_select.gd`, which is byte-identical to
the baseline (see the Git check below). No new selection behavior is
implemented on this branch.

## Included

- Original fantasy academy title and programmatically drawn pixel-art
  backdrops, spell symbols and portrait frames
- A **cosmetic-only** character lobby layer
  (`lobby_decor.gd`) over Angela's original picker buttons, showing the
  currently selected character and reading the existing selection state
- How-to-play, visual display settings, Credits and thematic menu styling
- The existing reusable match manager with polished HP bars, 120-second
  timer, start countdown, draw handling, victory and rematch screens
- Shared **silent** pause menu for both maps, with controls and navigation
- A Garden map with exact 2× integer-scaled original Piskel pixels;
  separate visible, destructible rose/tree/mushroom layers; flammable
  cells derived from the original Art Team plant-pixel mask
- Temporary Ninja/Werewolf action frames programmatically overlaid on
  the original Art Team sprite exports, not falsely labeled as
  Art Team's final delivery
- Test and stability fixes: correct arena-scoped FireBridge, result-screen
  fire/item freeze, rematch restoration, KO sprites, and repeat-match QA

## Deliberately excluded

- **No audio or music**: no WAV/OGG assets, SoundBus autoload, sound
  effects, procedural chiptune generation or audio configuration. All
  source files referring to a sound manager were adjusted. Audio is left
  for Art & Audio's ownership and handoff.
- **No new character or map selection functions.** Angela's existing
  pickers, option state, maps and `_load_map()` remain unchanged.
  The new portrait decoration only observes `OptionButton.item_selected`
  to refresh pictures; it never writes selection state or handles map
  choices. The `map_select.tscn` scene has added *visual-only* nodes.
- No new approved Werewolf mechanics, no third map, and no unapproved
  Art Team animation claim.

The genre inspiration is general, original magical-girl spell glyphs,
romantic moonlit witch-world scenery and academy-themed twin portraits.
No logos, characters or image files from Blue Archive, Fate or
Wandering Witch were copied. All new PNG source art is generated with
`/usr/bin/python3 gameplay/presentation/generate_assets.py` using Pillow.
Original team Piskel sprites are credited in
`gameplay/art_team/README.md`.

## Run and test

Open `project.godot` in Godot 4.7.2 and press F5. Title → LOCAL VERSUS
→ Angela's original character/map picker → Living Room or Garden →
match flow → title or the same picker.

```bash
Godot --headless --editor --path . --import --quit
Godot --headless --path . --script res://gameplay/tests/gameplay_project_start_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_arcane_features_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_garden_destructible_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_long_session_test.gd
Godot --path . --script res://gameplay/tests/gameplay_arcane_journey_playtest.gd
```

To verify scope, compare against
`origin/suwen/full-game-integration-20261114`:

```bash
git diff origin/suwen/full-game-integration-20261114...HEAD -- gameplay/MapSelection/map_select.gd
git diff --name-only origin/suwen/full-game-integration-20261114...HEAD | grep -E 'audio/|sound_bus'
```

Both commands should output nothing. The first is proof that Angela's
script is preserved, the second that audio files are absent.

## Outstanding for team review

Garden's final platforms/hitboxes and Art Team animation handoff still
need approval; the Werewolf's temporary claw attack remains a prototype;
and real players still need to test controls/feel and final balance.
Export presets do not substitute for signed native app builds.
