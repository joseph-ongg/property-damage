# Original Garden art disassembly / destruction QA

The original 426×286 Art & Audio `garden.piskel` pixels are **unchanged**.
`build_garden_stage.py` composes a 2× integer-scale backdrop and keeps its
three plant silhouette layers separate and reversible.

This evidence uses the **actual Godot 4.7.2 game renderer**:

- [Before damage](01_tree_intact.png)
- [After tree HP reaches zero](02_tree_destroyed.png)
- [After new-match reset](03_tree_restored.png)
- [Three-scene comparison](comparison_contact_sheet.png)

In the cropped 252×272 tree region (610,78 to 862,350):

- Destroyed vs. intact: **30,722 pixels differ**
- Restored vs. intact: **0 pixels differ**

This verifies the tree is physically removed from the rendered stage
when its HP reaches zero, and restored precisely by MatchManager.

Run `Godot --path . --script res://gameplay/tests/gameplay_garden_visual_playtest.gd`
with a graphical display to regenerate the screenshots into `/tmp`.

This is a **Gameplay-owned MVP implementation**, not a claim that Art
delivered final Garden destruction animation or that Design signed it off.
