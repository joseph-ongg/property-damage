# Real Mac Godot gameplay captures: Design-first PR #21 QA

All seven PNGs and the six-frame JPEG contact sheet are actual 960x540
Godot 4.7.2 Mac graphical game window screenshots. They are NOT new art
assets, generated illustrations, or proof of a human playtest.

- rose_collision_over_original_piskel.png: the game's original Art Team
  Garden background with a temporary QA-only yellow outline over the
  Piskel-derived rose collision polygons. The overlay is not part of F5.
- rose_true_player_contact.png: actual CharacterBody2D touching the
  upper/right rose, receiving exactly Design's 5HP hit.
- throw_fractional_damage_feedback.png: real 20x20 '?' placeholder
  physically thrown into P2, the status HUD reports 0.04 exact HP,
  0 whole HP deducted and 0.04 pending. No bogus 1HP minimum.
- garden_p1_shuriken.png: real P1 G-key shuriken-category projectile in
  Garden (unapproved Art represented by a literal '?' token).
- garden_p2_shuriken.png: P2 physical period key in Garden.
- living_p1_shuriken.png: P1 physical G key in Living Room.
- living_p2_shuriken.png: P2 period key in Living Room.
- six_frame_real_window_contact_sheet.jpg: resized JPEG contact sheet
  of actual captures above, with QA captions, not final game assets.

To reproduce the evidence on the same project/Mac: import original art
with Godot --headless --editor --path . --import --quit, then run

    Godot --path . --resolution 960x540 --script res://gameplay/tests/gameplay_design_rose_visual_capture_test.gd
    Godot --path . --resolution 960x540 --script res://gameplay/tests/gameplay_design_ninja_shuriken_actual_test.gd

Use the actual Godot 4.7.x binary from the parent folder; commands are
relative to project root. The scripts simulate physical game-key events
inside a real Mac graphics window. Two independent human players have
NOT completed a manual session; the manual checklist and open approvals
remain in the Design-gate review document.
