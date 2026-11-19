## Standalone experiment: exercise REAL physical-key input and Eva Health.
## This is not part of the official main-menu/Design acceptance tests.
extends SceneTree

var failures: Array[String] = []
var winners: Array = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)

func frames(n: int = 2) -> void:
    for _i in n:
        await physics_frame

func key(code: Key, down: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func attack(code: Key) -> void:
    key(code, true)
    await frames(2)
    key(code, false)
    await frames(95)

func _run() -> void:
    var arena := (load("res://gameplay/experimental/minimal_arena/minimal_arena.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(arena)
    await frames(6)
    check(arena.name == "ExperimentalArena", "Standalone experimental scene loads")
    check(arena.get_node("HUD/Title").text.contains("NOT DESIGN APPROVED"),
        "Experimental-only status is visible and explicit")
    var p1 := arena.get_node("Player1") as GameplayPlayer
    var p2 := arena.get_node("Player2") as GameplayPlayer
    arena.player_defeated.connect(func(loser: int, winner: int) -> void:
        winners.append([loser, winner]))
    check(p1.health_component.max_hp == 120 and p2.health_component.max_hp == 120,
        "Only the shared Design-aligned existing Health values are used")
    await attack(KEY_G)
    check(p2.health_component.hp == 110, "P1 physical G input hits P2 for 10 HP")
    await attack(KEY_PERIOD)
    check(p1.health_component.hp == 110, "P2 physical period input hits P1 for 10 HP")
    for _i in range(11):
        await attack(KEY_G)
    check(p2.health_component.hp == 0 and winners == [[2, 1]],
        "Real physical-key attacks finish at zero HP with exactly one winner signal")
    check(arena.round_finished and not p1.is_physics_processing() and not p2.is_physics_processing(),
        "KO disables both player controllers, with no post-death input")
    check(p2.get_node("NameTag").text == "KO" and not is_zero_approx(p2.sprite.rotation),
        "KO visual appears on the defeated character")
    check(arena.get_node("Projectiles").get_child_count() == 0,
        "No projectile continues after round end")
    # The visible R control is a supported standalone reset action, not a
    # persistent score or an unauthorized match format.
    key(KEY_R, true)
    await frames(3)
    key(KEY_R, false)
    await frames(3)
    check(not arena.round_finished and p1.is_physics_processing() and p2.is_physics_processing(),
        "Physical R press restarts a new test round")
    check(p1.health_component.hp == 120 and p2.health_component.hp == 120,
        "Reset restores authoritative Health, not a duplicate HP store")
    check(p2.get_node("NameTag").text == "P2" and is_zero_approx(p2.sprite.rotation),
        "Reset clears KO visuals")
    await attack(KEY_G)
    check(p2.health_component.hp == 110, "Real projectile combat works after restart")
    arena.queue_free()
    await frames(2)
    for issue in failures:
        print("KNOWN_ISSUE: " + issue)
    print("EXPERIMENTAL_MINIMAL_ARENA_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 2)
