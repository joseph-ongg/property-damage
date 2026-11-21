## Exact [PUBLIC] DP Designs item durability checks for an integrated Living Room.
## Original authored systems preserved; these values override older prototypes.
extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)
func _run() -> void:
    var room := (load("res://gameplay/msd/gameplay_msd.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(room)
    await physics_frame
    var spec := {
        "WorldItems/Clock": 5.0, "WorldItems/Painting": 3.0,
        "WorldItems/Microwave": 8.0, "WorldItems/Trashcan": 5.0,
        "WorldItems/Plushie": 3.0, "WorldItems/Plant": 5.0,
        "WorldItems/Bookshelf": INF, "WorldItems/Outlet": INF,
        "WorldItems/Food": 1.0,
        "Appliances/ACDevice": 10.0, "Appliances/ComputerDevice": 7.0,
        "Appliances/FanDevice": 10.0, "Appliances/FridgeDevice": INF,
        "Books/FloorBooks": 3.0, "Books/TableBooks": 3.0,
        "Books/ShelfBooks": 3.0
    }
    for path in spec:
        var item := room.get_node(path) as GameplayInteractableItem
        check(item != null and item.max_hp == float(spec[path]), "%s uses Design HP %s" % [path,str(spec[path])])
    var art := room.get_node("MaterialGrid/FurnitureFireLayer") as GameplayFurnitureFireLayer
    check(art.hp_for("CLOCK") == 5.0 and art.hp_for("PLANT") == 5.0 and
        art.hp_for("COMPUTER") == 7.0, "Simulation furniture layer agrees with item HP")
    check(is_inf(art.hp_for("BOOKSHELF")),"Bookshelf artwork remains indestructible")
    room.queue_free()
    print("DESIGN_ITEM_HP_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 2)
