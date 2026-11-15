## Actual macOS Godot windowed product-journey QA with rendering.
## All screenshots are captured by the real Godot viewport.
extends SceneTree

var problems: Array[String] = []
var screenshot_dir := "/tmp/property_damage_arcane_journey_20261115_"


func _initialize() -> void:
    call_deferred("_run")


func verify(ok: bool, text: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + text)
    if not ok:
        problems.append(text)


func wait_scene() -> void:
    await create_timer(0.17).timeout


func frames(count: int) -> void:
    for i in count:
        await physics_frame


func snap(name: String) -> void:
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    var path := screenshot_dir + name + ".png"
    var rc := picture.save_png(path)
    verify(rc == OK and picture.get_size() == Vector2i(960, 540),
        "render " + name)
    print("RENDER ", path, " size=", picture.get_size())


func tap_action(action: String) -> void:
    Input.action_press(action)
    await physics_frame
    Input.action_release(action)
    await physics_frame


func key(code: Key) -> void:
    var input := InputEventKey.new()
    input.physical_keycode = code
    input.keycode = code
    input.pressed = true
    Input.parse_input_event(input)
    await process_frame
    input.pressed = false
    Input.parse_input_event(input)
    await process_frame


func _run() -> void:
    root.size = Vector2i(960, 540)
    # F5 entry is the new title; don't shortcut into combat.
    var main := (load("res://gameplay/presentation/main_menu.tscn") as PackedScene).instantiate()
    root.add_child(main)
    current_scene = main
    await frames(4)
    await snap("01_title")
    verify(main.start_button != null, "title has usable Local Versus button")
    main.start_button.pressed.emit()
    await wait_scene()
    var lobby := current_scene
    verify(lobby != null and lobby.name == "MapSelect", "Title -> Lobby scene transition")
    lobby.player1_select.select(0)
    lobby.player2_select.select(1)
    lobby.player2_select.item_selected.emit(1)
    await frames(3)
    var art_layer := lobby.get_node_or_null("LobbyDecor")
    verify(art_layer != null and art_layer.left_image != null,
        "cosmetic lobby decor overlays Angela's original picker controls")
    verify(lobby.player1_select.item_count == 3 and lobby.player2_select.item_count == 3,
        "Angela's existing two-character selection logic is intact")
    await snap("02_fighters")
    verify(lobby.MAPS.size() == 2, "Angela's map choices remain intact")
    await snap("03_arena_choice")
    var garden_button: Button
    for b in lobby.list.get_children():
        if b is Button and b.text == "Garden":
            garden_button = b
    verify(garden_button != null, "Garden accessible from arena preview")
    garden_button.pressed.emit()
    await wait_scene()
    var garden := current_scene
    verify(garden != null and garden.name == "GardenBattle", "real Garden loaded")
    var p1 := garden.get_node("Player1") as GameplayPlayer
    var p2 := garden.get_node("Player2") as GameplayPlayer
    var manager := garden.get_node("MatchManager") as GameplayMatchManager
    verify(p1.character_kind == "mage" and p2.character_kind == "ninja",
        "character art/stats persisted through lobby")
    verify(p1.input_locked and manager.countdown_label.visible, "opening countdown locks combat input")
    await snap("04_garden_countdown")
    await create_timer(2.9).timeout
    verify(not p1.input_locked and not p2.input_locked, "countdown unlocks both players")
    var x := p1.global_position.x
    Input.action_press("p1_right")
    await frames(14)
    Input.action_release("p1_right")
    verify(p1.global_position.x > x + 8, "real movement input works after countdown")
    await snap("05_garden_fight")

    var pause := garden.get_node("PauseOverlay")
    pause.set_paused(true)
    verify(paused and pause.is_paused, "shared Garden pause halts the world")
    await snap("06_pause")
    pause.set_paused(false)
    verify(not paused, "pause resumes cleanly")

    p1.global_position = Vector2(110, 452)
    p2.global_position = Vector2(225, 452)
    p1.facing = 1
    p1._magic_cooldown = 0
    p2.health.hp = 10
    await tap_action("p1_attack")
    await frames(22)
    verify(manager.round_over and manager.p1_wins == 1, "real attack ends a round")
    await snap("07_round_result")
    manager.continue_button.pressed.emit()
    await frames(6)
    verify(not manager.round_over and manager.round_number == 2, "continue begins round two")
    await create_timer(2.9).timeout
    p1.global_position = Vector2(110, 452)
    p2.global_position = Vector2(225, 452)
    p1.facing = 1
    p1._magic_cooldown = 0
    p2.health.hp = 10
    await tap_action("p1_attack")
    await frames(23)
    verify(manager.match_over and manager.p1_wins == 2, "two wins end the match")
    await snap("08_final_result")

    manager.back_to_menu()
    await wait_scene()
    lobby = current_scene
    verify(lobby.name == "MapSelect", "result -> character lobby")
    lobby._load_map("res://gameplay/playtest_main.tscn")
    await wait_scene()
    var living := current_scene
    var arena := living.get_node("GameplayMSD")
    verify(arena.get_node("PauseOverlay") != null, "Living Room shares pause menu")
    await create_timer(2.9).timeout
    await snap("09_living_room")
    var fighter := arena.get_node("Player1") as GameplayPlayer
    var before := fighter.global_position.x
    Input.action_press("p1_right")
    await frames(13)
    Input.action_release("p1_right")
    verify(fighter.global_position.x > before + 6, "Living Room player moves")
    # settings and tutorial are reachable from title, loaded separately to
    # verify no broken assets/scene compile.
    living.queue_free()
    await frames(2)
    var help := (load("res://gameplay/presentation/help_screen.tscn") as PackedScene).instantiate()
    root.add_child(help)
    current_scene = help
    await frames(2)
    await snap("10_help")
    help.queue_free()
    await frames(2)
    var settings := (load("res://gameplay/presentation/settings_screen.tscn") as PackedScene).instantiate()
    root.add_child(settings)
    current_scene = settings
    await frames(2)
    verify(settings.fullscreen_toggle != null and root.get_node_or_null("SoundBus") == null,
        "display-only settings load without any audio system")
    await snap("11_settings")
    settings.queue_free()
    await frames(2)
    var credits := (load("res://gameplay/presentation/credits_screen.tscn") as PackedScene).instantiate()
    root.add_child(credits)
    current_scene = credits
    await frames(2)
    verify(credits.has_node("Background"), "original project credits and source attribution are accessible")
    await snap("12_credits")
    credits.queue_free()
    print("ARCANE_JOURNEY_SUMMARY failures=", problems.size())
    quit(0 if problems.is_empty() else 1)
