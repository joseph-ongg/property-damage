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
    var fighter := current_scene
    check(fighter != null and fighter.name == "FighterSelect",
        "start enters new two-player character registration")
    if fighter != null and fighter.name == "FighterSelect":
        check(fighter.start_button.disabled and fighter.player_kinds.size() == 2,
            "both players must confirm their independent character choices")
        fighter.ready_buttons[0].button_pressed = true
        fighter.ready_buttons[1].button_pressed = true
        fighter._continue_to_maps()
        await create_timer(0.13).timeout
    for i in 3:
        await physics_frame
    var lobby := current_scene
    check(lobby != null and lobby.name == "MapSelect",
        "ready players reach Angela's original map selection")
    if lobby != null and lobby.name == "MapSelect":
        check(lobby.list.get_child_count() == 3,
            "Angela's original label and two map buttons are unchanged")
        check(lobby.has_node("LobbyDecor"),
            "the third arena button belongs to a separate UI layer")
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
