## Actual Godot Mac window screenshots, physical keyboard turns, and source
## Piskel roof physical solidity. NOT a 2-human playtest or new artwork.
extends SceneTree
var failures: Array[String] = []
var screenshot_count := 0
func _initialize() -> void:
    call_deferred("_run")
func frames(n:int) -> void:
    for _i in n: await physics_frame
func check(ok:bool,label:String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok: failures.append(label)
func input_key(k:Key,on:bool) -> void:
    var e := InputEventKey.new()
    e.keycode=k
    e.physical_keycode=k
    e.pressed=on
    Input.parse_input_event(e)
    Input.flush_buffered_events()
func shot(name:String) -> void:
    if DisplayServer.get_name() == "headless":return
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var path: String = "/tmp/pr21_20261121_"+name+".png"
    check(image.save_png(path)==OK and image.get_width()>=960,
        "Real Mac graphical screenshot "+name)
    print("FACING_GATE_WINDOW_SCREENSHOT ",path)
    screenshot_count+=1
func _run() -> void:
    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(stage)
    await frames(8)
    var p1 := stage.get_node("Player1") as GameplayPlayer
    var p2 := stage.get_node("Player2") as GameplayPlayer
    var solid := stage.get_node("RoseGateSolids")
    check(solid.get_child_count()==1,
        "Original Garden gate arch has actual collision, side thorns remain Area-only")
    var overlay := Node2D.new()
    overlay.name="QAGateRoofOutlineOnly"
    overlay.z_index=30
    overlay.set_script(load("res://gameplay/tests/design_gate_top_solid_qa_overlay.gd"))
    stage.add_child(overlay)
    await frames(2)
    overlay.queue_redraw()
    await shot("garden_gate_real_source_roof_colliders")
    overlay.visible=false

    # Both characters on actual Garden ground, repeat with independent
    # P1 and P2 to catch source Piskel's left-facing native art.
    for selection in [["ninja","werewolf"],["werewolf","ninja"]]:
        p1.set_character_kind(selection[0])
        p2.set_character_kind(selection[1])
        p1.global_position=Vector2(427,450)
        p2.global_position=Vector2(625,450)
        p1.velocity=Vector2.ZERO
        p2.velocity=Vector2.ZERO
        p1.facing=-1
        p2.facing=-1
        p1._update_character_sprite(false)
        p2._update_character_sprite(false)
        await frames(2)
        check(not p1.sprite.flip_h and not p2.sprite.flip_h,
            "Both original Art Team left-source textures face real world LEFT")
        await shot(selection[0]+"_p1_"+selection[1]+"_p2_left_idle")
        input_key(KEY_D,true);input_key(KEY_RIGHT,true)
        await frames(10)
        check(p1.facing==1 and p2.facing==1
            and p1.sprite.flip_h and p2.sprite.flip_h
            and p1.velocity.x>0 and p2.velocity.x>0,
            "Physical P1 D + P2 Right: two characters walk RIGHT with mirrored native left art")
        await shot(selection[0]+"_p1_"+selection[1]+"_p2_right_run")
        input_key(KEY_D,false);input_key(KEY_RIGHT,false)
        await frames(3)
        input_key(KEY_A,true);input_key(KEY_LEFT,true)
        await frames(10)
        check(p1.facing==-1 and p2.facing==-1
            and not p1.sprite.flip_h and not p2.sprite.flip_h
            and p1.velocity.x<0 and p2.velocity.x<0,
            "Physical P1 A + P2 Left: both sprites turn back LEFT without reversed animation")
        await shot(selection[0]+"_p1_"+selection[1]+"_p2_left_run")
        input_key(KEY_A,false);input_key(KEY_LEFT,false)
        await frames(3)

    p1.set_physics_process(false)
    p1.global_position=Vector2(206,20)
    p1.velocity=Vector2.ZERO
    await frames(3)
    var top_collision := p1.move_and_collide(Vector2.DOWN*200)
    check(top_collision!=null
        and (top_collision.get_collider() as Node).is_in_group("garden_rose_gate_solids"),
        "Real player's solid collision stops at painted Garden arch top")
    overlay.visible=true
    overlay.queue_redraw()
    await shot("gate_top_player_actual_solid_contact")
    stage.queue_free()
    await frames(3)
    print("FACING_GATE_WINDOW_SUMMARY failures=",failures.size(),
        " original_graphics_screenshots=",screenshot_count)
    quit(0 if failures.is_empty() else 1)
