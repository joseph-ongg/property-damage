# Pixel Fan – Gameplay/Art/Simulation Handoff

This is an **optional Gameplay prototype**, not an approved Production/Simulation damage mechanic. The original Art Team furniture assets are preserved. The new fan is original procedurally drawn pixel artwork (`generate_fan.py`, Pillow, no AI images or downloads).

## Scene and render contract

- Drop `res://gameplay/props/fan/fan_device.tscn` into the `Appliances` container. The Gameplay room already instantiates this prefab under the existing `Appliances/FanDevice` path, at world `(413, 389)` on the same tabletop. Do **not** edit `burn_box.tscn` or the final team's arena.
- The root extends `GameplayAppliance` via `res://gameplay/msd/appliance.gd` with `device = FAN`. Existing `can_interact()`, `interact()`, `interaction_point()`, `applies_to()`, `state_changed(device, powered, player_index)` and both-player input/feedback remain intact.
- The artwork consists of `rear.png` (housing, pivot, column, tabletop shadow), animated `blade_0.png`–`blade_5.png` (six transparent rotation poses) and `front.png` (near grille and rim). All are **48 × 56 RGBA pixel plates**, composed **rear → blades → front** with nearest-neighbor filtering. The offset rear housing gives a subtle three-quarter view facing left, without rotating the base or its interaction point.
- `generate_fan.py` regenerates PNGs deterministically via `/usr/bin/python3 gameplay/props/fan/generate_fan.py` on this Mac. `preview_sheet.png` is a visual reference, not loaded into gameplay. The source is **not** an Art Team deliverable.

## Art Team replacement

The prefab Inspector accepts `fan_rear_override: Texture2D`, `fan_front_override: Texture2D`, `fan_blade_override: SpriteFrames` (animation named **`spin`**), `fan_animation_fps`, and `fan_sprite_offset`. Supply the **same 48 × 56 visual bounds and transparent registration** for all plates; no script changes or new collisions are needed. Unassigned overrides fall back to the original code-painted assets, while a missing `spin` track also falls back to the six local blade textures.

## Simulation / integration boundary

- `simulation_id` is an Inspector-settable identifier. Make it unique per placed fan (`living_room_fan_01` for the existing room).
- `set_fan_power(powered: bool, source_player_index: int = -1)` is an **idempotent external entry point**; it emits the existing `state_changed` signal only on transitions. A source index of `-1` denotes an external controller. `fan_runtime_state()` returns the ID, powered/operational flags, facing, effect radius, and horizontal force for observation.
- These interfaces **do not** connect to Ethan's MaterialGrid, persist to Simulation, implement fire/breakage, or define ownership of power state. Future Simulation adapter code must perform that binding explicitly and decide authoritative synchronization.
- Existing Gameplay uses a **horizontal wind push**, not fan slow-down; **the AC remains the slow-down device**. `fan_facing_left` (default true) and `get_fan_force_x()` keep wind direction consistent with the art. The prototype retains the current radial `applies_to()` zone. It has not introduced book wind physics.

## Level Design placement

Adjust prefab position, `interaction_radius`, `effect_radius`, `wind_acceleration`, `fan_facing_left`, and `simulation_id` in Inspector. The prefab deliberately adds **no** StaticBody2D, physics collision, or independently drawn UI: the team's furniture collisions and Gameplay's existing unified interaction hints remain authoritative.

## Tests and captures

Run `gameplay/tests/gameplay_fan_art_handoff_test.gd` plus existing `gameplay_fan_playtest.gd` to verify the prefab, two players, separate Art overrides, force direction, idempotent external state, and unchanged tabletop collision. For real Godot GUI images, run `gameplay_fan_visual_capture_test.gd` with `CAPTURE_FAN_PREFIX=/absolute/file/prefix`; it records `*_off.png` and `*_on.png`. Local evidence is at `presentation_media/screenshots/fan_left_runtime_review.png`.
