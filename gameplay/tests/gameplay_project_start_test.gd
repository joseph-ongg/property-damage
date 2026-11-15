## Product F5 launcher regression: Title -> Lobby -> Arena.
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
    check(startup == "res://gameplay/presentation/main_menu.tscn",
        "F5 starts a dedicated pixel fantasy title screen")
    var scene := load(startup) as PackedScene
    check(scene != null, "title scene loads")
    if scene == null:
        quit(1)
        return
    var main := scene.instantiate()
    root.add_child(main)
    current_scene = main
    await physics_frame
    check(main.has_node("Background") and main.start_button != null,
        "title displays original pixel backdrop and LOCAL VERSUS")
    main.start_button.pressed.emit()
    await create_timer(0.12).timeout
    for i in 4:
        await physics_frame
    var lobby := current_scene
    check(lobby != null and lobby.name == "MapSelect", "start enters the local duel lobby")
    if lobby != null:
        check(lobby.list.get_child_count() == 3,
            "Angela's 55fe753 original map label and two map buttons remain")
        check(lobby.has_node("LobbyDecor"),
            "cosmetic lobby decor is layered behind Angela's original map choices")
        lobby._load_map("res://gameplay/playtest_main.tscn")
    for i in 8:
        await physics_frame
    var game := current_scene
    var arena := game.get_node_or_null("GameplayMSD") if game != null else null
    check(arena != null, "lobby leads to actual Living Room battle")
    if arena != null:
        var p1 := arena.get_node("Player1") as GameplayPlayer
        var p2 := arena.get_node("Player2") as GameplayPlayer
        check(p1 != null and p2 != null, "two fighters spawn")
        check(arena.get_node("MatchManager") is GameplayMatchManager,
            "match manages rounds and best-of-three result")
        check(arena.get_node("PauseOverlay") != null, "arena has shared pause")
    if game != null:
        game.queue_free()
    print("PROJECT_START_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
