# Selective Fantasy UI + Garden share — windowed Godot QA

All **12 scenes** are actual screenshots from a Godot 4.7.2 graphical
session of **this no-audio, Angela-selection-preserving branch**.

[Visual QA contact sheet](visual_qa_contact_sheet.png)

They cover the new title, decorative original character portraits layered
over Angela's unchanged selector logic, original map buttons, countdown,
Garden gameplay, silent shared pause, round and match result, Living Room,
How to Play, display settings and credits.

Reproduce with a graphical display:

```bash
Godot --path . --windowed --script res://gameplay/tests/gameplay_arcane_journey_playtest.gd
```

`regression.txt` records all selected headless tests; these are automated
playthroughs, not a replacement for two human players' feedback.
