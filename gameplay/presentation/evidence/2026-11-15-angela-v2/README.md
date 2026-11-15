# Angela V2 + Fantasy UI — corrected 12-scene QA

These images are **actual Godot 4.7.2 viewport screenshots**, not generated
concept art. They were captured from this 55fe753-first-parent branch,
after correcting the previous overlapping title/map controls, crowded
battle HUD and cut-off result buttons.

[**Corrected 12-scene contact sheet**](visual_qa_contact_sheet.png)

- 01 Original fantasy title
- 02 Angela's original map buttons, with a static 3-character showcase
  clearly **not** presented as character selection
- 03-04 Actual playable Garden and movement
- 05-06 Shared pause and help
- 07-08 Round result and final victory with unclipped buttons
- 09 Living Room with split name, HP and round header
- 10-12 Tutorial, visual-only settings and project credits

Angela's source `map_select.gd` is byte-for-byte identical to `55fe753`.
Her original Garden link is serviced by a route adapter to playable Garden.
Original Art Piskel files remain unchanged. No audio is added.

Re-run from the repo root with a real Mac display:
```bash
Godot --path . --windowed --script res://gameplay/tests/gameplay_arcane_journey_playtest.gd
```
