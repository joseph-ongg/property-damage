## F5 release launcher regression: show Angela's character and map selection
## before loading the same real two-player room.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, message: String) -> void:
    if ok:
        print("PASS: ", message)
    else:
        failures.append(message)
        push_error("FAIL: " + message)


func _run() -> void:
    var startup := str(ProjectSettings.get_setting("application/run/main_scene", ""))
    check(startup == "res://gameplay/MapSelection/map_select.tscn",
        "F5 starts Angela's latest map and character selection menu")
    var scene := load(startup) as PackedScene
    check(scene != null, "project launcher loads")
    if scene == null:
        quit(1)
        return
    var menu := scene.instantiate()
    root.add_child(menu)
    current_scene = menu
    await physics_frame
    check(menu.player1_select != null and menu.player2_select != null,
        "F5 exposes both independent character selectors")
    menu._load_map("res://gameplay/playtest_main.tscn")
    for _i in 65:
        await physics_frame
    var instance := current_scene
    var arena := instance.get_node_or_null("GameplayMSD") if instance != null else null
    check(arena != null, "menu starts actual two-player Gameplay arena")
    if arena != null:
        var p1 := arena.get_node("Player1") as GameplayPlayer
        var p2 := arena.get_node("Player2") as GameplayPlayer
        check(p1 != null and p2 != null, "both player controllers exist")
        check(p1.is_on_floor() and p2.is_on_floor(), "players spawn on the arena floor")
        check(arena.get_node("FireBridge").grid() == arena.get_node("MaterialGrid"),
            "fire input is wired into Ethan's working MaterialGrid")
        check(arena.get_node("MatchManager") is GameplayMatchManager,
            "the arena has a best-of-three round manager")
        check(arena.has_node("WorldItems") and arena.has_node("Books"),
            "Austin's item interaction scene is active")
    if instance != null:
        instance.queue_free()
    print("PROJECT_START_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
