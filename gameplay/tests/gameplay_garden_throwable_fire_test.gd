## All Garden props are Design-flammable: fallback on main and Austin API.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)
        push_error(label)

func _frames(n: int=2) -> void:
    for _i in n:
        await physics_frame

func _run() -> void:
    var stage: Node2D = (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await _frames(5)
    var grid: MaterialGrid = stage.get_node("MaterialGrid")
    var bridge: GameplayFireBridge = stage.get_node("FireBridge")
    var gm := stage.get_node("GardenMechanics")
    var mushroom: GameplayGardenThrowable = stage.get_node("Throwables/Mushrooms1")
    var hose: GameplayGardenThrowable = stage.get_node("Throwables/HoseEnd")
    var cell := grid.world_to_cell(mushroom.global_position)
    check(grid.get_cell_material(cell.x,cell.y) == MaterialGrid.Materials.WOOD,
        "Garden sprite's source position registers flammable Simulation fuel")
    check(bridge.ignite_world(mushroom.global_position),
        "Spark can ignite Garden throwable source wood via upstream MaterialGrid")
    check(bridge.is_in_group("room_fire_bridge"),
        "Austin's optional item base locates the same Garden FireBridge")

    mushroom.set_process(false)
    mushroom._process(2.99)
    var before_ash := mushroom.consumed if not mushroom.has_method("ignite") else bool(mushroom.get("destroyed_item"))
    check(not before_ash,
        "Garden flammable object survives before the Design 3-second tick")
    mushroom._process(0.02)
    var is_ash := mushroom._fallback_ash if not mushroom.has_method("ignite") else bool(mushroom.get("burned_to_ash"))
    check(is_ash and not mushroom.can_pick_up(stage.get_node("Player1")),
        "After 3 seconds, 1-HP placeholder Garden item turns into unpickupable ash")
    stage.prepare_new_round()
    await _frames(2)
    var restored := not mushroom.consumed
    if mushroom.has_method("ignite"):
        restored = restored and not bool(mushroom.get("destroyed_item"))
    else:
        restored = restored and not mushroom._fallback_ash
    check(restored and not bridge.is_burning_world(mushroom.global_position),
        "Angela next-round API restores burned item and clears its fire")

    # Burning a carried/active hose must stop the water loop, not spray
    # indefinitely from an ash nozzle.
    var p1: GameplayPlayer = stage.get_node("Player1")
    p1.global_position = gm.HOSE_ART_ORIGIN
    await _frames(2)
    gm._on_player_interact(1,p1)
    check(gm._hose_owner == p1, "Portable hose is active before burn test")
    var hose_cell := grid.world_to_cell(hose.global_position)
    grid.set_cell_material(hose_cell.x,hose_cell.y,MaterialGrid.Materials.WOOD)
    check(bridge.ignite_world(hose.global_position),
        "Held Garden hose's fire contact uses same upstream grid")
    hose.set_process(false)
    hose._process(3.01)
    gm._physics_process(0.01)
    check(gm._hose_owner == null,
        "Destroyed hose cannot keep emitting water after burning to ash")

    stage.queue_free()
    await _frames()
    print("GARDEN_THROWABLE_FIRE_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 1)
