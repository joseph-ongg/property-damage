## Source of truth: [PUBLIC] DP Designs: visible pixel area / 10000 HP.
extends SceneTree
var failures: Array[String] = []
var passes := 0
func _initialize() -> void:
    call_deferred("_run")
func frames(n: int) -> void:
    for _i in n: await physics_frame
func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if ok: passes += 1
    else: failures.append(message)
func _run() -> void:
    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(stage)
    await frames(7)
    var gm := stage.get_node("GardenMechanics")
    var p2 := stage.get_node("Player2") as GameplayPlayer
    var sizes: Dictionary = {
        GameplayGardenThrowable.Kind.APPLE: 400.0,
        GameplayGardenThrowable.Kind.GNOME: 400.0,
        GameplayGardenThrowable.Kind.MUSHROOM: 3220.0,
        GameplayGardenThrowable.Kind.HOSE_END: 800.0
    }
    for kind in sizes:
        var item: GameplayGardenThrowable = gm._make_throwable(kind, Vector2(300, 415), "Size%d" % int(kind))
        check(is_equal_approx(item._throw_pixel_area(), sizes[kind]),
            "Garden item %d uses measured Piskel art or 20x20 '?' pixels" % int(kind))
    var blue: GameplayGardenThrowable = gm._make_throwable(GameplayGardenThrowable.Kind.MUSHROOM,
        Vector2(330, 415), "BlueSize", 1)
    check(is_equal_approx(blue._throw_pixel_area(), 3100.0),
        "Blue mushroom measures its own visible Piskel crop (25x31 @2x)")
    p2.health_component.reset()
    var apple: GameplayGardenThrowable = gm._make_throwable(GameplayGardenThrowable.Kind.APPLE,
        Vector2(380, 415), "SmallApple")
    for i in 24:
        apple._impact_spent = false
        apple._apply_throw_damage_to_player(p2)
    check(p2.health_component.hp == p2.health_component.max_hp,
        "24 valid 20x20 hits = 0.96HP, not 24 rounded-up HP")
    check(is_equal_approx(float(p2.health_component.get_meta("design_throw_fraction")), 0.96),
        "Eva's integer HP retains unrounded exact throw remainder")
    apple._impact_spent = false
    apple._apply_throw_damage_to_player(p2)
    check(p2.health_component.hp == p2.health_component.max_hp - 1
        and float(p2.health_component.get_meta("design_throw_fraction")) < 0.0001,
        "25th 0.04HP apple hit yields exactly 1 cumulative HP")
    p2.health_component.reset()
    check(is_zero_approx(float(p2.health_component.get_meta("design_throw_fraction",0.0))),
        "New health life clears sub-HP pending damage")

    # Use a measured 400x400 QA object to assert Design's explicit example;
    # this does not create a fake real-world 400px gnome sprite.
    var big: GameplayGardenThrowable = gm._make_throwable(GameplayGardenThrowable.Kind.GNOME,
        Vector2(745, 435), "Big400")
    big.design_art_size_override = Vector2(400,400)
    p2.global_position = Vector2(800,445)
    p2.velocity = Vector2.ZERO
    await frames(2)
    big.last_thrower_index = 1
    big.thrower_index = 1
    big.flying = true
    big.flight_velocity = Vector2(300,0)
    big._physics_process(0.17)
    check(big._impact_spent and p2.health_component.hp == p2.health_component.max_hp-16,
        "Real moving item hits for 400*400/10000 = 16HP via Eva Health")
    var remainder_before := float(p2.health_component.get_meta("design_throw_fraction",0.0))
    var ignored: GameplayGardenThrowable = gm._make_throwable(GameplayGardenThrowable.Kind.APPLE,
        Vector2(350,420),"IframeIgnored")
    ignored._apply_throw_damage_to_player(p2)
    check(is_equal_approx(float(p2.health_component.get_meta("design_throw_fraction",0.0)),
        remainder_before), "A hit rejected during Eva invulnerability cannot bank damage")
    stage.queue_free()
    await frames(2)
    print("DESIGN_THROW_AREA_FORMULA_SUMMARY failures=",failures.size()," passes=",passes)
    quit(0 if failures.is_empty() else 2)
