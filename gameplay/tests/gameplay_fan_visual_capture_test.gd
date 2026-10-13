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
    # Wind has blown P1 out of reach. Walk back before pressing the off key;
    # the reach restriction is intended gameplay, not an interaction bug.
    p1.global_position=Vector2(413,478)
    p1.velocity=Vector2.ZERO
    p1.motor.reset()
    await frames(3)
    Input.action_press("p1_interact")
    await frames(2)
    Input.action_release("p1_interact")
    await frames(6)
    assert(not fan.switched_on)
    print("FAN_VISUAL_CAPTURE_SUMMARY success")
    game.queue_free()
    quit()
