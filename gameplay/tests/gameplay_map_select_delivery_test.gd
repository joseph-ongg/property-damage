## Direct Angela native map scene must never open an obsolete placeholder.
extends SceneTree
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok:bool, label:String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        errors.append(label)

func _run() -> void:
    var selector := (load("res://gameplay/MapSelection/map_select.tscn") as PackedScene).instantiate() as Control
    root.add_child(selector)
    await physics_frame
    var maps: Array = selector.MAPS
    check(maps.size() == 2, "Angela native map selector contains only two Design arenas")
    check(maps[0]["name"] == "Living Room" and maps[1]["name"] == "Garden",
        "Design authorized Living Room and Garden are the only buttons")
    for map in maps:
        check(ResourceLoader.exists(map["path"]),map["name"] + " points to an existing play scene")
    check(maps[1]["path"] == "res://gameplay/garden/garden_level.tscn",
        "Garden button opens real PR18 Garden rather than obsolete placeholder")
    var choices := selector.get_node("CenterContainer/VBoxContainer")
    check(choices.get_child_count() == 3,
        "Angela menu retains one title and exactly two functional map buttons")
    selector.queue_free()
    await physics_frame
    print("DESIGN_MAP_SELECTION_SUMMARY failures=",errors.size())
    quit(0 if errors.is_empty() else 2)
