## Optional real Godot viewport capture. Run in GUI with CAPTURE_FAN_PREFIX.
extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)

func frames(n: int) -> void:
    for _i in n: await physics_frame

func capture(phase: String) -> void:
    var prefix := OS.get_environment("CAPTURE_FAN_PREFIX")
    if prefix.is_empty() or DisplayServer.get_name() == "headless":
        return
    await process_frame
    RenderingServer.force_draw(false)
    var result: Error = root.get_texture().get_image().save_png(prefix+"_"+phase+".png")
    assert(result == OK, "failed to capture fan viewport")
    print("FAN_SCREENSHOT ",prefix+"_"+phase+".png")

func _run() -> void:
    var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await frames(65)
    var room := game.get_node("GameplayMSD")
    var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
    var p1: GameplayPlayer = room.get_node("Player1")
    var p2: GameplayPlayer = room.get_node("Player2")
    p1.global_position=Vector2(413,478)
    p1.velocity=Vector2.ZERO
    p1.motor.reset()
    p2.global_position=Vector2(890,478)
    p2.velocity=Vector2.ZERO
    p2.motor.reset()
    await frames(7)
    # Austin's integrated cable/outlet is authoritative: a switch press
    # without a plug should *not* power the fan. Establish a plugged-in
    # fixture through the real room adapter, then switch it back off
    # before capturing the actual on/off keyboard interactions.
    var cable: GameplayWorldItem = room.get_node("WorldItems/FanCable")
    var outlet: GameplayWorldItem = room.get_node("WorldItems/Outlet")
    room._plug_fan_cable(cable, outlet)
    fan.set_fan_power(false)
    await frames(3)
    check(outlet.plugged and cable.plugged, "Austin fan cable must be plugged")
    check(not fan.switched_on and fan.can_interact(p1),
        "Plugged fan can be switched on, starts off")
    await capture("off")
    Input.action_press("p1_interact")
    await frames(2)
    Input.action_release("p1_interact")
    await frames(25)
    check(fan.switched_on, "P1 interaction switches plugged fan on")
    await capture("on")
    # Capture both players on opposite sides of the SAME live fan while on.
    # Wind and status must affect the left player only, despite P2 being
    # closer to the rear motor casing on the right.
    p1.global_position=Vector2(363,478)
    p2.global_position=Vector2(445,478)
    p1.velocity=Vector2.ZERO
    p2.velocity=Vector2.ZERO
    p1.motor.reset()
    p2.motor.reset()
    await frames(4)
    check(fan.applies_to(p1) and not fan.applies_to(p2), "Fan only influences players in front")
    check(p1.motor.environment_acceleration_x < -100.0, "P1 gets leftward fan wind")
    check(is_zero_approx(p2.motor.environment_acceleration_x), "P2 behind fan gets no wind")
    await capture("left_only")
    # P2 stands behind the fan: no force, but its control is still usable.
    check(fan.can_interact(p2), "P2 can reach fan controls")
    Input.action_press("p2_interact")
    await frames(3)
    Input.action_release("p2_interact")
    await frames(5)
    check(not fan.switched_on, "P2 interaction switches fan off")
    check(is_zero_approx(p1.motor.environment_acceleration_x), "P1 wind clears when fan off")
    assert(is_zero_approx(p2.motor.environment_acceleration_x))
    await capture("off_by_p2")
    print("FAN_VISUAL_CAPTURE_SUMMARY failures=", failures.size())
    game.queue_free()
    quit(0 if failures.is_empty() else 2)
