## Reproducible Mac graphical evidence: actual original Piskel plus
## rose collision outline, real player 5HP hit and fractional throw HUD.
extends SceneTree

var failed: Array[String] = []
var screenshots := 0

func _initialize() -> void:
    call_deferred("_run")
func frames(n: int) -> void:
    for _i in n:
        await physics_frame
func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok: failed.append(label)
func capture(name: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    var im := root.get_texture().get_image()
    var file := "/tmp/pr21_design_review_" + name + ".png"
    check(im.save_png(file) == OK and im.get_width() >= 960,
        "Real Mac graphical screenshot " + name)
    print("DESIGN_GARDEN_SCREENSHOT ",file)
    screenshots += 1

func _run() -> void:
    var scene := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(scene)
    await frames(9)
    var overlay := Node2D.new()
    overlay.name="DesignQARoseCollisionOverlayOnly"
    overlay.z_index=24
    overlay.set_script(load("res://gameplay/tests/design_rose_qa_overlay.gd"))
    scene.add_child(overlay)
    await frames(4)
    overlay.queue_redraw()
    await capture("rose_collision_over_original_piskel")
    var p1 := scene.get_node("Player1") as GameplayPlayer
    var p2 := scene.get_node("Player2") as GameplayPlayer
    p1.global_position=Vector2(360,320)
    p1.velocity=Vector2.ZERO
    await frames(8)
    check(p1.health_component.hp == p1.health_component.max_hp-5,
        "Actually touching rose in live physics deals documented 5HP")
    await capture("rose_true_player_contact")
    overlay.visible=false
    p1.global_position=Vector2(200,455)
    p2.global_position=Vector2(800,445)
    p2.velocity=Vector2.ZERO
    p2.health_component.reset()
    await frames(3)
    var mechanics := scene.get_node("GardenMechanics")
    var apple: GameplayGardenThrowable = mechanics._make_throwable(
        GameplayGardenThrowable.Kind.APPLE,Vector2(745,435),"Visual20x20Apple")
    apple.last_thrower_index=1
    apple.thrower_index=1
    apple.flying=true
    apple.flight_velocity=Vector2(300,0)
    apple._physics_process(0.17)
    check(apple._impact_spent and p2.health_component.hp == p2.health_component.max_hp,
        "Actual 20x20 thrown '?' causes 0.04HP, no invented 1HP hit")
    check(mechanics.last_action.contains("0.04 HP EXACT"),
        "Existing Garden HUD reports exact fractional Design damage")
    await frames(2)
    await capture("throw_fractional_damage_feedback")
    scene.queue_free()
    await frames(2)
    print("DESIGN_ROSE_VISUAL_CAPTURE_SUMMARY failures=",failed.size()," screenshots=",screenshots)
    quit(0 if failed.is_empty() else 2)
