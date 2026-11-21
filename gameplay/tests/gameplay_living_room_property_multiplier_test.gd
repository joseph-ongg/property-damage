## Design +5% attack for each destroyed property, rounding preserved over hits.
## Physical-key PvP test against Eva Health. No new official match rules.
extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func frames(n:int) -> void:
    for _i in n:
        await physics_frame

func check(ok:bool,label:String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)

func physical_attack() -> void:
    var ev := InputEventKey.new()
    ev.keycode = KEY_G
    ev.physical_keycode = KEY_G
    ev.pressed = true
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(2)
    ev = InputEventKey.new()
    ev.keycode = KEY_G
    ev.physical_keycode = KEY_G
    ev.pressed = false
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(75)

func _run() -> void:
    var app := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate()
    root.add_child(app)
    await frames(8)
    app._on_map_selected("res://gameplay/playtest_main.tscn")
    await frames(9)
    var room := app.arena as Node2D
    var p1 := room.get_node("Player1") as GameplayPlayer
    var p2 := room.get_node("Player2") as GameplayPlayer
    p1.global_position = Vector2(430,468)
    p2.global_position = Vector2(520,468)
    p1.velocity = Vector2.ZERO
    p2.velocity = Vector2.ZERO
    p1.facing = 1
    p2.facing = -1
    await frames(5)
    var clock := room.get_node("WorldItems/Clock") as GameplayWorldItem
    check(clock.hp == 5.0, "Clock starts with Design's 5 HP")
    clock.take_damage(clock.hp,1)
    check(clock.destroyed_item and p1.destroyed_objects == 1,
        "Destroying an actual item credits its original attacking player")
    check(is_equal_approx(p1.attack_damage,10.5) and is_equal_approx(p2.attack_damage,10.0),
        "Only the destroying player receives Design +5% bonus")
    await physical_attack()
    check(p2.health_component.hp == 110, "First scaled player hit applies 10 HP")
    await physical_attack()
    check(p2.health_component.hp == 99,
        "Second scaled player hit applies 11 HP with carried half damage")
    check(not app.round_over, "Damage multiplier does not invent a match or KO")
    app.queue_free()
    await frames(2)
    print("LIVING_ROOM_PROPERTY_MULTIPLIER_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 2)
