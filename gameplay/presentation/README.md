# Property Damage — corrected fantasy pixel UI on Angela Map Selection V2

**Branch:** `suwen/fantasy-ui-angela-v2-layout-20261115`.
**First parent:** Angela's `55fe753` (Remade the map selection page).
**Second parent:** previous tested Gameplay integration, retained to preserve
other teammates' authored commit ancestry. This is an integration candidate,
not a team-approved release.

## What was corrected

The previous 12-screenshot version had real layout problems: the title
intersected the moon; captions and duplicate map/character headings
overlapped the lobby; battle HP text competed with HUD bars and the
old room header; match-result buttons had clipped text; help and
settings headers sat on distracting high-contrast background art.

This version uses an explicit 960×540 pixel-grid presentation:
- Title and menu occupy two separate, opaque left-aligned panels,
  leaving the illustration and the moon unobstructed.
- Original Angela **map choice** controls sit on the **left**.
  A distinct **static** Art Team character showcase fills the right,
  explicitly labelled as a preview, not a functional character picker.
- Health headers each have distinct name, bar, and stat rows.
  The scoreboard splits scores from round/timer on separate baselines.
  The prototype top-room header is hidden when the new HUD is present.
- Result buttons have short, non-truncated labels (**CHOOSE MAP**).
- Full-screen titles and help text have opaque backgrounds and
  consistent page margins.
- Angela's Living Room back-to-maps button has a smaller, aligned
  visual presentation, without changing its click handler.

## Strict ownership and functionality

Angela's exact original `gameplay/MapSelection/map_select.gd` from
`55fe753` is **unchanged**. Her two dynamic buttons, `MAPS` constant,
keyboard focus and `_load_map` behavior are still hers. Only the
scene layout and a cosmetic `lobby_decor.gd` layer were added.

**Important:** Angela's `55fe753` implements *map selection*, not
character selection. The portrait cards in this branch are deliberately
read-only. Gameplay's pre-existing `CharacterSelectionState` and
character mechanics are present, but selecting two different characters
through this UI will require Angela's subsequent feature delivery.
The exact original Garden destination is kept and backed by a
`LevelSelection/GardenPlaceholder.tscn` compatibility scene that
instantiates the **real playable Garden**, preserving her link.

No audio or music, no SoundBus, no WAV/OGG files and no
generated music or SFX are included.

## Visual and gameplay contributions

Original Python/Pillow-generated academy pixel-art backdrops,
spell sigils, map and portrait frames, title, instructions, visual
settings and credits. Source Piskel sprites from Art & Audio are
retained and credited. Garden plants are separated into visibly
damageable layers with source-derived flammable cells, ash and restore;
the match manager also implements timer, win screens, HP HUD, KO and
rematch stability. Temporary Ninja/Werewolf actions remain labelled
Gameplay placeholders, not official Art delivery.

No Blue Archive, Fate or Wandering Witch artwork, characters, logos
or audio were copied into the project.

## QA / run

Open `project.godot` in Godot 4.7.2; press F5. Select LOCAL VERSUS,
then **Living Room** or **Garden** with Angela's original map buttons.
The original menu has no character selection. The gameplay returns to
the same map selection and can be replayed.

Reproducible tests:

```sh
Godot --headless --editor --path . --import --quit
Godot --headless --path . --script res://gameplay/tests/gameplay_project_start_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_character_selection_health_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_complete_match_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_garden_destructible_test.gd
Godot --headless --path . --script res://gameplay/tests/gameplay_long_session_test.gd
Godot --path . --windowed --script res://gameplay/tests/gameplay_arcane_journey_playtest.gd
python3 gameplay/tests/verify_fantasy_share_scope.py
```

Verify Angela's authorship and unchanged map script:

```sh
git merge-base --is-ancestor 55fe753 HEAD
git diff 55fe753 HEAD -- gameplay/MapSelection/map_select.gd
git log --oneline --graph -7
```

The diff for her script should be empty. The Git history contains her
original `55fe753` and prior `e7f142e` commits.

See [new 12-scene visual QA](evidence/2026-11-15-angela-v2/README.md).
Native signed standalone app templates and final team art/balance sign-off
are still not complete.
