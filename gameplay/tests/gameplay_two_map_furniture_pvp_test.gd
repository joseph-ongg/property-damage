## PR21-only regression: Living Room PvP must not override furniture ignition.
## Probes the existing MaterialGrid and real physics/key-input collisions.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)

func frames(n: int) -> void:
    for _i in n:
        await physics_frame

func key(code: Key, down: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.physical_keycode = code
    e.pressed = down
    Input.parse_input_event(e)
    Input.flush_buffered_events()

func attack() -> void:
    key(KEY_G, true)
    await frames(2)
    key(KEY_G, false)
    await frames(33)

func _run() -> void:
    # Reproduce the original Living Room "fireball hits TABLE" sequence
    # with the PvP adapter, while both players are clear of the flight path.
    var standalone := (load("res://gameplay/msd/gameplay_msd.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(standalone)
    await frames(8)
    var grid := standalone.get_node("MaterialGrid") as MaterialGrid
    var bolt := GameplayLivingRoomPvPBolt.new()
    standalone.get_node("Projectiles").add_child(bolt)
    bolt.global_position = Vector2(350, 392)
    bolt.direction = 1
    var hits: Array[String] = []
    bolt.hit.connect(func(name: String, _source: int) -> void: hits.append(name))
    await frames(9)
    check(hits.has("TABLE"), "PvP adapter preserves native Living Room TABLE hit event")
    check(grid.is_burning(23, 24), "PvP adapter still ignites real tabletop fuel")

    # Exercise the original optional object handlers, not just the fire grid.
    # The stock GameplayMagicBolt regression uses this same disabled-grid
    # setup to isolate book/PC scorch events from the Simulation fire bridge.
    standalone.get_node("FireBridge").grid_path = NodePath("../NotReadyYet")
    var loose_book := standalone.get_node("Books/FloorBooks") as GameplayBurnableProp
    var computer := standalone.get_node("Appliances/ComputerDevice") as GameplayAppliance
    var book_caster := standalone.get_node("Player1") as GameplayPlayer
    # Austin's newly integrated PLUSHIE sits ahead of the book by default,
    # so move it out of this isolated book-specific regression lane. In the
    # actual arena it must continue to intercept projectiles.
    (standalone.get_node("WorldItems/Plushie") as GameplayWorldItem).global_position = Vector2(850, 480)
    book_caster.global_position = Vector2(249, 478)
    book_caster.velocity = Vector2.ZERO
    book_caster.facing = 1
    await frames(5)
    var book_bolt := GameplayLivingRoomPvPBolt.new()
    standalone.get_node("Projectiles").add_child(book_bolt)
    book_bolt.initialize(book_caster)
    await frames(26)
    check(loose_book.scorched, "PvP adapter retains original book scorch interaction")

    var pc_caster := standalone.get_node("Player2") as GameplayPlayer
    pc_caster.global_position = Vector2(620, 384)
    pc_caster.velocity = Vector2.ZERO
    pc_caster.facing = -1
    await frames(5)
    var pc_bolt := GameplayLivingRoomPvPBolt.new()
    standalone.get_node("Projectiles").add_child(pc_bolt)
    pc_bolt.initialize(pc_caster)
    await frames(26)
    check(computer.charred, "PvP adapter retains original computer hit interaction")
    standalone.queue_free()
    await frames(4)

    # Run a real playtest session with actual key presses and collision masks.
    var app := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(app)
    await frames(6)
    app._on_map_selected("res://gameplay/playtest_main.tscn")
    await frames(10)
    var room := app.arena as Node2D
    var p1 := room.get_node("Player1") as GameplayPlayer
    var p2 := room.get_node("Player2") as GameplayPlayer
    p1.global_position = Vector2(430, 468)
    p2.global_position = Vector2(520, 468)
    p1.facing = 1
    p2.facing = -1
    p1.velocity = Vector2.ZERO
    p2.velocity = Vector2.ZERO
    await frames(7)

    var obstacle := StaticBody2D.new()
    obstacle.name = "TestSolidObstacle"
    obstacle.position = Vector2(482, 462)
    obstacle.collision_layer = 1
    obstacle.collision_mask = 0
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(16, 44)
    shape.shape = rectangle
    obstacle.add_child(shape)
    room.add_child(obstacle)
    await frames(4)
    await attack()
    check(p2.health_component.hp == 120, "Solid object blocks player damage")
    check(room.status_text.text.find("PLAYER 2") == -1, "No false PvP hit reported behind obstacle")

    obstacle.queue_free()
    await frames(4)
    p1._magic_cooldown = 0.0
    await attack()
    check(p2.health_component.hp == 110, "Unobstructed real G key hits player for Design's 10 HP")
    check(room.status_text.text.contains("PLAYER 2"), "Native Living Room status display still handles impact signal")
    check(not app.round_over, "Non-lethal player attack never ends the playtest round")
    app.queue_free()
    await frames(3)

    for problem in failures:
        print("QA_BLOCKER: " + problem)
    print("LIVING_ROOM_FURNITURE_PVP_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 2)
