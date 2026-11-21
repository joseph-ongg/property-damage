## Two approved maps use the Design requirement: wood/oil flames burn out
## after 10s, not the generic MaterialGrid prototype's 5s/2s defaults.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)

func frames(n: int) -> void:
    for i in n:
        await physics_frame

func _run() -> void:
    var maps: Array[Dictionary] = [
        {"name": "Living Room", "path": "res://gameplay/msd/gameplay_msd.tscn"},
        {"name": "Garden", "path": "res://gameplay/garden/garden_level.tscn"}
    ]
    for entry in maps:
        var room := (load(entry["path"]) as PackedScene).instantiate() as Node2D
        root.add_child(room)
        await frames(3)
        var g: MaterialGrid = room.get_node("MaterialGrid") as MaterialGrid
        var tag: String = entry["name"]
        check(is_equal_approx(g.wood_burn_time, 10.0), tag + " has 10-second wood fire duration")
        check(is_equal_approx(g.oil_burn_time, 10.0), tag + " has 10-second oil fire duration")
        var sample_x := 5
        var sample_y := 5
        for material in [MaterialGrid.Materials.WOOD, MaterialGrid.Materials.OIL]:
            g.set_cell_material(sample_x, sample_y, material)
            g.ignite(sample_x, sample_y)
            check(g.is_burning(sample_x, sample_y), tag + " flammable cell ignites")
            # Deterministic virtual time: do not depend on actual wall clock.
            for tick in 98:
                g._update_burn_timers()
            check(g.is_burning(sample_x, sample_y), tag + " fire remains at 9.8s")
            for tick in 4:
                g._update_burn_timers()
            check(not g.is_burning(sample_x, sample_y)
                and g.get_cell_material(sample_x,sample_y)==MaterialGrid.Materials.ASH,
                tag + " fire burns out by 10.2s and leaves ash")
        room.queue_free()
        await frames(2)
    print("DESIGN_BURN_DURATION_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 2)
