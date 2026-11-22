# Art Team latest — real Property Damage Mac graphical evidence

Seven 960×540 PNG captures produced directly by real Godot 4.7.2
Mac GUI/Metal rendering from the actual Garden game, Nov 21 2026.
They are NOT AI-generated game art or manually painted composites.
The JPEG contact sheet is a resized index of six-and-one real
gameplay captures, not an exported game texture.

- garden_tree_hose_ninja_wolf_idle.png: exact new 190×245
  Tree.piskel overlay at original Garden source pixels x236,y0,
  actual Hose.piskel tube, original Ninja and Werewolf on stage
- ninja_shuriken_no_fire.png: G attack remains Ninja's real
  Design shuriken placeholder, not a fake fireball
- ninja_art_fire_spark_action.png: existing F Spark triggers
  original Ninja_fire 4-frame *character* animation
- ninja_art_injured.png: real Eva Health hit switches to original
  four-frame Ninja_injured Piskel
- wolf_art_walking_on_fire.png: real upstream Simulation burning
  material cell renders original Wolf walking on fire
- hose_art_team_latest_spraying.png: new source hose nozzle crop
  on actual original Garden map, displaying existing spray
- ninja_art_dead.png: original sideways Ninja_dead Piskel displayed
  without generic tilt; P1 and P2 KO are also covered by the
  gameplay_latest_art_match_ko_test.gd on both approved maps

Reproduce these PNGs:
 ../Godot.app/Contents/MacOS/Godot --path . --resolution 960x540 --script res://gameplay/tests/gameplay_latest_art_visual_window_test.gd

All downloaded .piskel files are checked in unchanged under
gameplay/art_team/source/. The deterministic exporter retains
original PNG frame pixels, never invents or replaces artwork.
Ninja's projectile still awaits independent Art shuriken sprite;
Ninja_fire is only the existing F Spark animation. The composite
Garden Hose source contains painted fence and was cropped to
avoid covering the eight original destructible 4HP fence segments.

This is a real Mac rendering and simulated-key/physics audit, not
a manual live session with two human players or Design approval.
