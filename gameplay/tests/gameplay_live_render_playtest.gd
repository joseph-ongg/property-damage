## Windowed end-to-end playtest: render the actual scenes, press real Input
## actions, click map/round buttons, record real Godot viewport screenshots.
## Run (with an active Mac display) via Godot --path . --script <this file>.
## This is deliberately distinct from headless unit tests.
extends SceneTree

const Selection = preload("res://gameplay/characters/character_selection_state.gd")

var failures: Array[String] = []
var screenshots: Array[String] = []
const EVIDENCE := "/tmp/property_damage_playtest_20261114_"


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, description: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + description)
    if not ok:
        failures.append(description)


func frames(count: int) -> void:
    for i in count:
        await physics_frame


func capture(name: String) -> void:
    # Avoid a renderer callback starvation when a match has just frozen
    # physics; request a frame explicitly in the diagnostic GUI runner.
    await process_frame
    RenderingServer.force_draw(false)
    var texture := root.get_texture()
    if texture == null:
        check(false, "display texture for " + name)
        return
    var image := texture.get_image()
    if image.is_empty():
        check(false, "rendered image for " + name)
        return
    var path := EVIDENCE + name + ".png"
    var error := image.save_png(path)
    check(error == OK and image.get_size().x >= 900, "rendered screenshot " + name)
    if error == OK:
        screenshots.append(path)
        print("SCREENSHOT ", path, " dimensions=", image.get_size())


func tap(action: String) -> void:
    Input.action_press(action)
    await physics_frame
    Input.action_release(action)
    await physics_frame


func _run() -> void:
    root.size = Vector2i(960, 540)
    var menu := (load("res://gameplay/MapSelection/map_select.tscn") as PackedScene).instantiate()
    root.add_child(menu)
    current_scene = menu
    await frames(4)
    await capture("01_menu")

    # Angela's 55fe753 page selects maps only. Set optional Gameplay
    # characters directly as a test fixture (not via invented pickers).
    Selection.choose("mage", "ninja")
    var garden_button: Button
    for child in menu.list.get_children():
        if child is Button and child.text == "Garden":
            garden_button = child
    check(garden_button != null, "Garden entry is a real clickable menu button")
    if garden_button == null:
        quit(1)
        return
    garden_button.pressed.emit()
    await frames(12)
    var garden := current_scene
    check(garden != null and garden.name == "GardenBattle", "map button transitions into a playable Garden")
    if garden == null:
        quit(1)
        return
    var p1 := garden.get_node("Player1") as GameplayPlayer
    var p2 := garden.get_node("Player2") as GameplayPlayer
    var match_manager := garden.get_node("MatchManager") as GameplayMatchManager
    check(p1.character_kind == "mage" and p2.character_kind == "ninja",
        "character selections reach actual fighter instances")
    await capture("02_garden")

    await create_timer(2.9).timeout
    var x0 := p1.global_position.x
    Input.action_press("p1_right")
    await frames(14)
    Input.action_release("p1_right")
    await frames(3)
    check(p1.global_position.x > x0 + 10.0, "real P1 right movement input moves character")
    var y0 := p1.global_position.y
    await tap("p1_jump")
    await frames(8)
    check(p1.global_position.y < y0 - 4.0, "real jump input produces upward movement")
    await frames(90)

    # Place two real fighters in a clear lane, so no Garden prop shields P2.
    # Subsequent combat is driven entirely by actual p1_attack input.
    p1.global_position = Vector2(110, 455)
    p2.global_position = Vector2(225, 455)
    p1.velocity = Vector2.ZERO
    p2.velocity = Vector2.ZERO
    p1.facing = 1
    p1._magic_cooldown = 0.0
    var before_hp := p2.health.hp
    await tap("p1_attack")
    await frames(25)
    check(p2.health.hp == before_hp - 10, "real Mage attack input causes 10 damage")
    await capture("03_combat")

    # Shorten the remaining HP only to avoid 10-second test playback.
    # The winning hit itself still comes from a real attack input.
    p2.health.hp = 10
    p2.health._invuln_left = 0.0
    p1._magic_cooldown = 0.0
    await tap("p1_attack")
    await frames(25)
    check(match_manager.round_over and match_manager.p1_wins == 1, "lethal real attack completes round one")
    await capture("04_round_winner")

    match_manager.continue_button.pressed.emit()
    await frames(5)
    await create_timer(2.9).timeout
    check(not match_manager.round_over and p2.health.hp == p2.health.max_hp,
        "next-round UI button resets fighter health")
    p1.global_position = Vector2(110, 455)
    p2.global_position = Vector2(225, 455)
    p1.facing = 1
    p2.health.hp = 10
    p2.health._invuln_left = 0.0
    p1._magic_cooldown = 0.0
    await tap("p1_attack")
    await frames(25)
    check(match_manager.match_over and match_manager.p1_wins == 2,
        "real combat input wins a complete best-of-three match")
    await capture("05_match_winner")

    match_manager.back_to_menu()
    await frames(10)
    menu = current_scene
    check(menu != null and menu.name == "MapSelect", "in-game menu button returns to map selection")
    var living_button: Button
    for child in menu.list.get_children():
        if child is Button and child.text == "Living Room":
            living_button = child
    living_button.pressed.emit()
    await frames(15)
    var living := current_scene
    check(living != null and living.has_node("GameplayMSD"), "Living Room map button loads Austin's room")
    var room := living.get_node("GameplayMSD")
    # An explicit Gameplay character fixture triggers the 3-2-1 intro in
    # each arena; let Living Room unlock before testing pickup and sparks.
    await create_timer(2.9).timeout
    p1 = room.get_node("Player1") as GameplayPlayer
    var book := room.get_node("Books/FloorBooks") as GameplayBurnableProp
    await capture("06_living_room")

    # The nearest valid item is picked up. Move the Plushie away before
    # explicitly verifying the book, as the live test otherwise (correctly)
    # picks up the nearer Plushie first.
    (room.get_node("WorldItems/Plushie") as GameplayWorldItem).global_position = Vector2(600, 480)
    p1.global_position = book.global_position + Vector2(-12.0, 0.0)
    p1.velocity = Vector2.ZERO
    check(room.get_carry_offer(p1).get("target") == book, "book is the nearest available carry target")
    await tap("p1_carry")
    check(book.carried_by == p1, "real carry input picks up a book")
    await tap("p1_carry")
    check(book.flying, "second carry input throws the held book")
    await capture("07_throw")

    # Real F key path: Spark -> GameplayFireBridge -> Ethan's active grid ->
    # Art Team flame visual. The seeded floor at (400, 472) is WOOD.
    var bridge := room.get_node("FireBridge") as GameplayFireBridge
    var flame_at := Vector2(400, 472)
    p1.global_position = flame_at - Vector2(34, 0)
    p1.velocity = Vector2.ZERO
    p1.facing = 1
    p1.spark._cooldown_remaining = 0.0
    await tap("p1_spark")
    check(bridge.is_burning_world(flame_at), "real F input ignites material-grid fuel")
    await frames(7)
    await capture("08_living_room_fire")

    print("LIVE_RENDER_PLAYTEST_SUMMARY failures=", failures.size(), " screenshots=", screenshots.size())
    quit(0 if failures.is_empty() else 1)
