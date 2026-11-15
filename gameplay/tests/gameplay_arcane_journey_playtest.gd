## Actual Godot windowed art, Angela map selection, and match UI journey.
## Twelve distinct real renderer screenshots, no image-gen and no audio.
extends SceneTree

var failures: Array[String] = []
const PREFIX := "/tmp/property_damage_angela_v2_layout_20261115_"


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)
        push_error("FAIL: " + label)


func frames(n: int) -> void:
    for i in n:
        await physics_frame


func snap(name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var path := PREFIX + name + ".png"
    var err := image.save_png(path)
    check(err == OK and image.get_size() == Vector2i(960, 540), "render " + name)
    print("SCREENSHOT ", path)


func fight_round(p1: GameplayPlayer, p2: GameplayPlayer) -> void:
    p1.global_position = Vector2(110, 452)
    p2.global_position = Vector2(225, 452)
    p1.facing = 1
    p1._magic_cooldown = 0.0
    p2.health.hp = 10
    Input.action_press("p1_attack")
    await frames(2)
    Input.action_release("p1_attack")
    await frames(28)


func _run() -> void:
    root.size = Vector2i(960, 540)
    var main := (load("res://gameplay/presentation/main_menu.tscn") as PackedScene).instantiate()
    root.add_child(main)
    current_scene = main
    await frames(4)
    await snap("01_title")
    check(main.start_button != null, "local versus title menu button works")

    main.start_button.pressed.emit()
    await create_timer(0.17).timeout
    var lobby := current_scene
    check(lobby != null and lobby.name == "MapSelect", "Angela's original map scene loads")
    check(lobby.list.get_child_count() == 3, "one label and two Angela-owned map buttons")
    check(lobby.has_node("LobbyDecor"), "thematic cosmetics load without changing selection")
    await snap("02_angela_map_select")
    var garden_button: Button
    for child in lobby.list.get_children():
        if child is Button and child.text == "Garden":
            garden_button = child
    check(garden_button != null, "Garden button is still connected by Angela")
    garden_button.pressed.emit()
    await create_timer(0.17).timeout
    var garden := current_scene
    check(garden != null and garden.name == "GardenBattle",
        "55fe753 GardenPlaceholder path opens actual Garden through adapter")
    var manager := garden.get_node("MatchManager") as GameplayMatchManager
    var p1 := garden.get_node("Player1") as GameplayPlayer
    var p2 := garden.get_node("Player2") as GameplayPlayer
    await snap("03_garden_entry")
    var old_x := p1.global_position.x
    Input.action_press("p1_right")
    await frames(17)
    Input.action_release("p1_right")
    check(p1.global_position.x > old_x + 4.0, "real Garden player movement")
    await snap("04_garden_fight")

    var pause := garden.get_node("PauseOverlay")
    pause.set_paused(true)
    check(paused and pause.is_paused, "Garden shared pause")
    await snap("05_pause")
    pause._show_help(true)
    await snap("06_pause_controls")
    pause.set_paused(false)

    await fight_round(p1, p2)
    check(manager.round_over and manager.p1_wins == 1, "actual projectile wins first round")
    await snap("07_round_result")
    manager.continue_after_round()
    await frames(7)
    await fight_round(p1, p2)
    check(manager.match_over and manager.p1_wins == 2, "best of three resolves final victory")
    await snap("08_match_result")

    manager.back_to_menu()
    await create_timer(0.17).timeout
    lobby = current_scene
    check(lobby.name == "MapSelect", "results return to Angela's original map screen")
    var room_button: Button
    for child in lobby.list.get_children():
        if child is Button and child.text == "Living Room":
            room_button = child
    check(room_button != null, "original Living Room button exists")
    room_button.pressed.emit()
    await create_timer(0.17).timeout
    var living := current_scene
    check(living.get_node("GameplayMSD/MatchManager") is GameplayMatchManager,
        "Living Room loads with updated compact battle HUD")
    await snap("09_living_room")
    living.queue_free()
    await frames(3)

    var help := (load("res://gameplay/presentation/help_screen.tscn") as PackedScene).instantiate()
    root.add_child(help)
    current_scene = help
    await frames(3)
    await snap("10_help")
    help.queue_free()
    await frames(3)
    var settings := (load("res://gameplay/presentation/settings_screen.tscn") as PackedScene).instantiate()
    root.add_child(settings)
    current_scene = settings
    await frames(3)
    await snap("11_settings")
    settings.queue_free()
    await frames(3)
    var credits := (load("res://gameplay/presentation/credits_screen.tscn") as PackedScene).instantiate()
    root.add_child(credits)
    current_scene = credits
    await frames(3)
    await snap("12_credits")
    credits.queue_free()
    print("ANGELA_V2_LAYOUT_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
