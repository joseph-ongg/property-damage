## Handoff acceptance: Fan + AC both affect the actual Ethan wind model,
## without making a second fire state or changing Simulation's core source.
extends SceneTree

const WIND_MODEL = preload("res://onboarding/burn-box/wind_model.gd")

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)
        push_error("FAIL: " + label)


func _light(grid: MaterialGrid, point: Vector2) -> void:
    var cell := grid.world_to_cell(point)
    check(grid.in_bounds(cell.x, cell.y), "test fire cell is in real grid")
    grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)
    grid.ignite(cell.x, cell.y)
    check(grid.is_burning(cell.x, cell.y), "fire ignited via Simulation API")


func _run() -> void:
    var level := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(level)
    await physics_frame
    var room: Node2D = level.get_node("GameplayMSD")
    var grid: MaterialGrid = room.get_node("MaterialGrid")
    var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
    var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")

    check(fan.simulation_id == "living_room_fan_01"
        and ac.simulation_id == "living_room_ac_01",
        "Simulation sees distinct stable fan and AC device IDs")
    var sources: Array[Dictionary] = room.simulation_wind_sources()
    check(sources.size() == 2 and sources[0]["device"] == "FAN"
        and sources[1]["device"] == "AIR CONDITIONER",
        "the integration API exposes Fan and AC in one snapshot")
    room._physics_process(0.016)
    check(grid.wind_strength == 0.0, "both devices off means no forced wind")
    ac.set_ac_power(true)
    check(ac.switched_on and ac.simulation_wind_strength() > 0.0,
        "AC can be powered directly by Simulation")
    _light(grid, ac.global_position + Vector2(-33, -23))
    room._physics_process(0.016)
    check(grid.wind_direction == Vector2.LEFT
        and is_equal_approx(grid.wind_strength, ac.ac_fire_wind_strength),
        "AC alone now creates leftward fire-spread wind")
    check(WIND_MODEL.adjusted_spread_chance(0.15, grid.wind_direction,
        grid.wind_strength, Vector2.LEFT) > 0.15
        and WIND_MODEL.adjusted_spread_chance(0.15, grid.wind_direction,
        grid.wind_strength, Vector2.RIGHT) < 0.15,
        "upstream Simulation WindModel actually biases fire downwind")

    fan.set_fan_power(true)
    _light(grid, fan.global_position + Vector2(-41, 40))
    room._physics_process(0.016)
    check(is_equal_approx(grid.wind_strength, 1.0)
        and grid.wind_direction == Vector2.LEFT,
        "Fan and AC local effects combine, clipped to Simulation 0..1")
    fan.fan_facing_left = false
    _light(grid, fan.global_position + Vector2(38, 40))
    room._physics_process(0.016)
    check(grid.wind_direction == Vector2.RIGHT
        and is_equal_approx(grid.wind_strength,
            fan.fan_fire_wind_strength - ac.ac_fire_wind_strength),
        "opposing Fan and AC fields combine deterministically")
    ac.set_ac_power(false)
    room._physics_process(0.016)
    check(grid.wind_direction == Vector2.RIGHT and
        is_equal_approx(grid.wind_strength, fan.fan_fire_wind_strength),
        "switching AC off removes only AC contribution")
    fan.set_fan_power(false)
    room._physics_process(0.016)
    check(grid.wind_strength == 0.0 and grid.wind_direction == Vector2.ZERO,
        "switching both off restores calm Simulation wind")
    check(room.get_node("MaterialGrid") == grid and
        not level.has_node("OtherFireGrid"),
        "wind uses existing MaterialGrid without shadow fire storage")
    level.queue_free()
    print("FAN_AC_WIND_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
