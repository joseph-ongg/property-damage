## Real physical key input, both players, using the Garden scene and Eva Health.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")


func _check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)
        push_error(label)


func _frames(n: int = 1) -> void:
    for i in n:
        await physics_frame


func _key(code: Key, down: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.physical_keycode = code
    e.pressed = down
    Input.parse_input_event(e)
    Input.flush_buffered_events()


func _tap(code: Key) -> void:
    _key(code, true)
    await _frames(2)
    _key(code, false)
    await _frames(2)


func _run() -> void:
    var arena := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(arena)
    await _frames(5)
    var p1 := arena.get_node("Player1") as GameplayPlayer
    var p2 := arena.get_node("Player2") as GameplayPlayer
    var controller := arena.get_node("GardenMechanics")
    var first := arena.get_node("Fences/Fence01") as GameplayGardenFenceSegment
    var last := arena.get_node("Fences/Fence08") as GameplayGardenFenceSegment

    p1.global_position = Vector2(35,357)
    p1.velocity = Vector2(0,-90)
    p1.facing = 1
    var first_hp := first.hp
    await _tap(KEY_G)
    await _frames(21)
    _check(first.hp == first_hp - 1,
        "P1 jumps / fires at visible Piskel fence pixels for 1/4 HP")

    p2.global_position = Vector2(930,371)
    p2.velocity = Vector2(0,-80)
    p2.facing = -1
    var last_hp := last.hp
    await _tap(KEY_PERIOD)
    await _frames(23)
    _check(last.hp == last_hp - 1,
        "P2 fires left at visible Piskel fence pixels for 1/4 HP")

    p1.global_position = controller.TREE_LOWER
    p1.velocity = Vector2.ZERO
    await _tap(KEY_E)
    _check(p1.global_position.distance_to(controller.TREE_UPPER_EXIT) < 14,
        "P1 physically presses E at painted tree hole to travel upward")

    p2.global_position = controller.TREE_LOWER
    p2.velocity = Vector2.ZERO
    await _tap(KEY_SHIFT)
    _check(p2.global_position.distance_to(controller.TREE_UPPER_EXIT) < 14,
        "P2 physically presses Shift at tree hole to travel upward")

    p2.health_component.reset()
    p2.global_position = Vector2(369,405)
    p2.velocity = Vector2.ZERO
    await _frames(3)
    _check(p2.health_component.hp == 115,
        "real rose Area2D physics contact applies exactly 5 Eva HP damage")

    controller._portal_cooldown[1] = 0.0
    p1.global_position = controller.HOSE_ART_ORIGIN
    p1.velocity = Vector2.ZERO
    await _tap(KEY_E)
    _check(controller._hose_owner == p1 and controller.hose_seconds_left > 9.0,
        "P1 physical E press picks original Piskel hose and activates spray")

    arena.queue_free()
    await _frames(2)
    print("GARDEN_INPUT_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
