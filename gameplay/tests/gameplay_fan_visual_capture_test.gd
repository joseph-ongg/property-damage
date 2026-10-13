## Optional real Godot viewport capture. Run in GUI with CAPTURE_FAN_PREFIX.
extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

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
    assert(not fan.switched_on and fan.can_interact(p1))
    await capture("off")
    Input.action_press("p1_interact")
    await frames(2)
    Input.action_release("p1_interact")
    await frames(25)
    assert(fan.switched_on)
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
    assert(fan.applies_to(p1) and not fan.applies_to(p2))
    assert(p1.motor.environment_acceleration_x < -100.0)
    assert(is_zero_approx(p2.motor.environment_acceleration_x))
    await capture("left_only")
    # P2 stands behind the fan: no force, but its control is still usable.
    assert(fan.can_interact(p2))
    Input.action_press("p2_interact")
    await frames(3)
    Input.action_release("p2_interact")
    await frames(5)
    assert(not fan.switched_on)
    assert(is_zero_approx(p1.motor.environment_acceleration_x))
    assert(is_zero_approx(p2.motor.environment_acceleration_x))
    await capture("off_by_p2")
    print("FAN_VISUAL_CAPTURE_SUMMARY success")
    game.queue_free()
    quit()
