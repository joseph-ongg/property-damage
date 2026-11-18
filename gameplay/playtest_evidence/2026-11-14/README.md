# Real-renderer local playtest — November 14, 2026

This is an actual **windowed Godot 4.7.2 game session** on macOS, with a live
OpenGL/Metal renderer, the shipped scene transitions, the real player physics
engine, and real action-input paths. The run is driven by a deterministic
**automated playtest script**, not by a human hand on the keyboard.

Reproduce from repository root with an active macOS display:

```bash
"../Godot.app/Contents/MacOS/Godot" --path . --windowed --resolution 960x540 \
  --script res://gameplay/tests/gameplay_live_render_playtest.gd
```

The script saves its screenshot evidence in
`/tmp/property_damage_playtest_20261114_*.png` and reports
`LIVE_RENDER_PLAYTEST_SUMMARY failures=0 screenshots=8`.

| Snapshot | Actual runtime state |
| --- | --- |
| [01_menu](01_menu.png) | Angela's map/character selection screen |
| [02_garden](02_garden.png) | Garden scene loaded with Mage vs. Ninja, before movement |
| [03_combat](03_combat.png) | Live attack processed, ten HP removed |
| [04_round_winner](04_round_winner.png) | First winner panel and score |
| [05_match_winner](05_match_winner.png) | Best-of-three winner after second combat round |
| [06_living_room](06_living_room.png) | Living Room after in-game return to menu |
| [07_throw](07_throw.png) | Live C-button pick-up / throw sequence |
| [08_living_room_fire](08_living_room_fire.png) | Live F-button Spark ignites Ethan material grid and shows Art flame |

Behavioral assertions: real GUI button changes scene; real controller input
moves and jumps; Mage attacks reduce real Health by ten; two lethal attacks
complete the round/match overlay; next-round button restores HP; menu
button returns to character/map selection; Austin's carry input picks up
and throws a book; Spark's actual F input lights seeded floor material.

**Test setup details:** enemy HP is reduced to ten before the *final hit* of
each round to shorten a deterministic playtest; that final hit itself still
comes from the actual attack input. Players are relocated to a clear shooting
lane before attack, to avoid incidental props. Before the book test, the
nearest Plushie is moved away, because Austin's target-selection correctly
prefers the nearest available item. Neither is a change to production rules.

**Limits:** this does not replace human game-feel QA, long-session
stability, platform-specific keyboard tests, visual regression tooling or
Simulation's full wind/fire-spread tuning sign-off.
