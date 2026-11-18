# Fan + AC wind handoff to Simulation — 2026-11-15

**Local implementation only. Not yet in remote main or PR #14.**

Both devices are interactive in the Living Room:
- Fan: gameplay/msd/gameplay_msd.tscn, Appliances/FanDevice, stable ID living_room_fan_01
- AC: gameplay/msd/gameplay_msd.tscn, Appliances/ACDevice, stable ID living_room_ac_01
- P1 activates a nearby device with E; P2 uses Shift. The Fan can also be powered by the cable/outlet.

## Public Gameplay API in gameplay/msd/appliance.gd

- fan.set_fan_power(bool)
- ac.set_ac_power(bool)
- device.simulation_wind_state(): {id, device, powered, operational, direction, strength, effect_radius}
- device.simulation_wind_direction(): Vector2 in Godot world coordinates
- device.simulation_wind_strength(): 0 when off, destroyed, or charred
- device.simulation_wind_contains(world_position): actual affected region
- fan.fan_runtime_state() and fan.fan_wind_contains(world_position): existing fan API
- room.simulation_wind_sources(): one live snapshot for both devices

## Fire spread integration

gameplay/msd/msd_controller.gd reads both devices every physics tick.
It applies wind to the *existing* MaterialGrid via the public
grid.wind_direction and grid.wind_strength properties.

The fan defaults left at 0.70, the AC defaults left at 0.45.
Wind only contributes while the device is active and burning material
is inside that device's actual effect region. Simultaneously active
devices add signed vectors and their combined strength is clamped
to [0, 1]. Opposing directions partially cancel.

The upstream WindModel.adjusted_spread_chance() already uses these
fields to bias downwind/upwind fire spread. There is NO second fire
simulation and no changes to Simulation-owned source files.

Limitation: upstream MaterialGrid has one room-global wind vector,
not independent per-cell local wind fields. If the Simulation team
implements local wind, they should use the public device methods
above and remove room aggregation as needed.

## Acceptance tests

Run with the local Godot 4.7.2 engine:

    Godot --headless --path . --script res://gameplay/tests/gameplay_simulation_fan_ac_wind_test.gd
    Godot --headless --path . --script res://gameplay/tests/gameplay_fan_direction_test.gd

Both pass, covering AC on/off, Fan on/off, combined and opposing
wind, upstream WindModel actual spread bias, and original fan
direction/physics behavior.
