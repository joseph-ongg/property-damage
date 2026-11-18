## Actual bolt hits: earned attack fractions must NOT advance on Eva i-frames.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, description: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + description)
    if not ok:
        failures.append(description)
        push_error(description)

func _frames(n: int=2) -> void:
    for _i in n:
        await physics_frame

func _shoot(arena: Node2D, player: GameplayPlayer) -> void:
    var bolt := GameplayGardenMagicBolt.new()
    arena.get_node("Projectiles").add_child(bolt)
    bolt.set_physics_process(false)
    bolt.initialize(player)
    bolt.global_position = Vector2(279,448)
    bolt._physics_process(0.5)

func _run() -> void:
    var arena: Node2D = (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(arena)
    await _frames(5)
    var p1: GameplayPlayer = arena.get_node("Player1")
    var p2: GameplayPlayer = arena.get_node("Player2")
    var gm: Node2D = arena.get_node("GardenMechanics")
    p1.set_physics_process(false)
    p2.set_physics_process(false)
    p1.global_position = Vector2(260,455)
    p2.global_position = Vector2(375,455)
    for fence in arena.get_node("Fences").get_children():
        (fence as GameplayGardenFenceSegment).collision_layer = 0
    var target_fence: GameplayGardenFenceSegment = arena.get_node("Fences/Fence01")
    for _i in 4:
        target_fence.take_hit(1)
    check(gm._destroyed_by_player[1] == 1,
        "Destroying an actual Garden fence grants one 5-percent attack bonus")
    await _frames(2)

    p2.health_component.reset()
    p2.health_component._invuln_left = 0.7
    _shoot(arena,p1)
    await _frames(1)
    check(p2.health_component.hp == 120,
        "Eva invulnerability rejects an actual projectile hit")
    check(is_equal_approx(float(gm._fractional_damage_by_player[1]),0.0),
        "Rejected hit must not advance 0.5 HP attack-fraction accumulator")

    p2.health_component._process(1.0)
    _shoot(arena,p1)
    await _frames(1)
    check(p2.health_component.hp == 110,
        "First accepted 10.5 HP attack applies 10 integer HP")
    check(is_equal_approx(float(gm._fractional_damage_by_player[1]),0.5),
        "Only accepted attacks earn the banked 0.5 HP fraction")

    p2.health_component._process(1.0)
    _shoot(arena,p1)
    await _frames(1)
    check(p2.health_component.hp == 99,
        "Second accepted 10.5 HP attack applies 11 (total 21 HP)")
    check(is_equal_approx(float(gm._fractional_damage_by_player[1]),0.0),
        "The two accepted attacks leave no leftover fraction")

    arena.queue_free()
    await _frames()
    print("GARDEN_ATTACK_ACCOUNTING_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 1)
