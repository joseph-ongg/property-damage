## Design-defined Ninja: actual G/. shuriken-category projectile, existing
## hit physics and 10HP; '?' marker because there is NO Art Team sprite.
extends SceneTree

var failures: Array[String] = []
var count := 0
func _initialize() -> void:
    call_deferred("_run")
func frames(n: int) -> void:
    for _i in n: await physics_frame
func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if ok: count += 1
    else: failures.append(message)
func tap(code: Key) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.physical_keycode = code
    e.pressed = true
    Input.parse_input_event(e)
    Input.flush_buffered_events()
    await frames(2)
    e = InputEventKey.new()
    e.keycode = code
    e.physical_keycode = code
    e.pressed = false
    Input.parse_input_event(e)
    Input.flush_buffered_events()
    await frames(2)
func capture(tag: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    var output: String = "/tmp/pr21_design_ninja_" + tag + ".png"
    check(image.save_png(output) == OK and image.get_width() >= 960,
        "Mac game window screenshot saved " + tag)
    print("DESIGN_NINJA_SCREENSHOT ",output)
func _run() -> void:
    var maps: Array[String] = [
        "res://gameplay/garden/garden_level.tscn",
        "res://gameplay/playtest_main.tscn"
    ]
    for map in maps:
        var tag := "garden" if map.contains("garden") else "living"
        var shell := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate()
        var choice: Array[String] = ["ninja","ninja"]
        shell.selected_kinds = choice
        root.add_child(shell)
        await frames(7)
        shell._on_map_selected(map)
        await frames(10)
        var p1 := shell.arena.get_node("Player1") as GameplayPlayer
        var p2 := shell.arena.get_node("Player2") as GameplayPlayer
        check(p1.character_kind=="ninja" and p2.character_kind=="ninja",
            tag + " both selected Ninja, not Wizard")
        check(p1.health_component.max_hp==100 and p2.health_component.max_hp==100
            and p1.motor.jump_speed > p1._base_motor_jump_speed,
            tag + " Design 100HP, higher jump")
        if tag=="garden":
            p1.global_position=Vector2(710,455)
            p2.global_position=Vector2(800,455)
        else:
            p1.global_position=Vector2(430,468)
            p2.global_position=Vector2(520,468)
        p1.velocity=Vector2.ZERO
        p2.velocity=Vector2.ZERO
        p1.facing=1
        p2.facing=-1
        await frames(6)
        var before2 := p2.health_component.hp
        await tap(KEY_G)
        var shots: Array[Node] = shell.arena.get_node("Projectiles").get_children()
        check(shots.size()==1 and (shots[0] as GameplayMagicBolt).projectile_kind=="shuriken",
            tag + " physical P1 G launches shuriken, not Mage fireball")
        await capture(tag + "_p1_shuriken")
        await frames(24)
        check(p2.health_component.hp==before2-10,
            tag + " real Ninja P1 ranged hit applies Design 10HP")
        var before1 := p1.health_component.hp
        await tap(KEY_PERIOD)
        shots=shell.arena.get_node("Projectiles").get_children()
        check(shots.size()==1 and (shots[0] as GameplayMagicBolt).projectile_kind=="shuriken",
            tag + " physical P2 period launches independent shuriken")
        await capture(tag + "_p2_shuriken")
        await frames(24)
        check(p1.health_component.hp==before1-10,
            tag + " Ninja P2 real ranged hit also applies Design 10HP")
        shell.queue_free()
        await frames(3)
    print("DESIGN_NINJA_SHURIKEN_ACTUAL_SUMMARY failures=",failures.size()," passes=",count)
    quit(0 if failures.is_empty() else 2)
