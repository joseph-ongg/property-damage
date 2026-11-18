# Eva's Spark aim — PR #15 integration evidence

Source credit: EvaJiangdy, original commit
[b5543ff](https://github.com/joseph-ongg/property-damage/commit/b5543ff9cd6cd0f553b34070b4cddc8fd12c1f33).
Her original SparkAim and SparkEmitter changes were imported as a
separate Eva-authored commit. Gameplay then wired the shared reticle
target into the real Spark ignition call in gameplay/player.gd.

## User controls

- P1: double-tap W to toggle diagonally up, double-tap S for down;
  press F to cast at the reticle. Facing left/right controls the x side.
- P2: double-tap Up arrow for up, double-tap Down arrow for down;
  press Enter to cast.
- Repeating a direction's double-tap switches back to forward;
  choosing the opposite double-tap switches directly to that mode.
- A single W/S/Up/Down press preserves jump/crouch. S+W or Down+Up
  retains platform drop, and Magic attacks (G / period) remain unchanged.
- Both players' aim modes reset to forward on new round/rematch.
- Aim is independent for both players; no shared direction variable.

## Verification

The new gameplay/tests/gameplay_spark_aim_six_way_test.gd test uses
six actual physical-key Spark casts, not renderer-only reticle changes.
For each of P1 and P2, it checks forward/up/down: the exact
emitted world point, rendered reticle, Eva's Spark flash offset,
correct player attribution and success in the existing upstream
Simulation MaterialGrid. It also covers input isolation, single-tap
movement, platform-drop chords and rematch resets.

Headless test:

    Godot --headless --path . --script res://gameplay/tests/gameplay_spark_aim_six_way_test.gd

Graphical test (same source and assertions, saves actual renderer captures):

    Godot --path . --windowed --script res://gameplay/tests/gameplay_spark_aim_six_way_test.gd

See [six screenshot contact sheet](six_direction_contact_sheet.png),
captured from the actual Godot renderer on the local Mac.

Full existing Gameplay + Simulation integration regression results:
[regression.txt](regression.txt).

No other member's source code is overwritten; no music or audio added.
