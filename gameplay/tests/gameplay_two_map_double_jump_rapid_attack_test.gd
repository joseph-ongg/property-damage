## Test BOTH real Garden second jumps and two rapid real physical attack taps.
extends SceneTree
var failed := 0
func _initialize() -> void: call_deferred("_run")
func frames(n: int) -> void:
    for i in n: await physics_frame
func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok: failed += 1
func key(code: Key, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
func tap(code: Key) -> void:
    key(code,true)
    await frames(2)
    key(code,false)
    await frames(2)

func _run() -> void:
    var app := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate()
    root.add_child(app)
    await frames(6)
    app._on_map_selected("res://gameplay/garden/garden_level.tscn")
    await frames(12)
    var p1 := app.arena.get_node("Player1") as GameplayPlayer
    var p2 := app.arena.get_node("Player2") as GameplayPlayer
    check(p1.enhanced_jumping and p2.enhanced_jumping
        and p1.motor.max_jumps == 2 and p2.motor.max_jumps == 2,
        "Garden starts with TWO jumps for BOTH real local players")
    check(p1.health_component.invulnerable_time < 0.32
        and p2.health_component.invulnerable_time < 0.32,
        "PvP hit invulnerability is shorter than real attack cooldown")
    p1.global_position = Vector2(184,455)
    p2.global_position = Vector2(225,455)
    p1.velocity = Vector2.ZERO
    p2.velocity = Vector2.ZERO
    await frames(8)
    check(p1.is_on_floor() and p2.is_on_floor(), "Both players actually stand on ground")
    await tap(KEY_W)
    check(p1.motor.jumps_remaining() == 1 and p1.velocity.y < -50,
        "P1: real W key jumps, keeps one air jump")
    await frames(5)
    await tap(KEY_W)
    check(p1.motor.jumps_remaining() == 0 and p1.velocity.y < -100,
        "P1: second W in the air launches a real double jump")
    await tap(KEY_UP)
    check(p2.motor.jumps_remaining() == 1 and p2.velocity.y < -50,
        "P2: real Up key jumps, keeps one air jump")
    await frames(5)
    await tap(KEY_UP)
    check(p2.motor.jumps_remaining() == 0 and p2.velocity.y < -100,
        "P2: second Up in the air launches a real double jump")

    app._start_round()
    await frames(13)
    p1=app.arena.get_node("Player1") as GameplayPlayer
    p2=app.arena.get_node("Player2") as GameplayPlayer
    p1.global_position=Vector2(710,455)
    p2.global_position=Vector2(800,455)
    p1.velocity=Vector2.ZERO
    p2.velocity=Vector2.ZERO
    p1.facing=1
    p2.facing=-1
    await frames(9)
    var before := p2.health_component.hp
    await tap(KEY_G)
    await frames(4)
    await tap(KEY_G) # within cooldown; buffer must trigger later
    await frames(48)
    check(p2.health_component.hp == before-20,
        "P1 two fast real G presses each land exactly 10HP, not swallowed")
    before=p1.health_component.hp
    await tap(KEY_PERIOD)
    await frames(4)
    await tap(KEY_PERIOD)
    await frames(48)
    check(p1.health_component.hp == before-20,
        "P2 two fast period presses each land exactly 10HP, not swallowed")
    check(not app.round_over and p1.health_component.is_alive() and p2.health_component.is_alive(),
        "Rapid attacks preserve normal round and Eva authoritative Health")
    app.queue_free()
    await frames(2)
    # Angela's original selector may open Garden directly without F5 shell.
    # This path must not silently revert to 0.8s PvP immunity.
    var direct := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(direct)
    await frames(5)
    var direct_p1 := direct.get_node("Player1") as GameplayPlayer
    var direct_p2 := direct.get_node("Player2") as GameplayPlayer
    check(direct_p1.health_component.invulnerable_time == 0.24
        and direct_p2.health_component.invulnerable_time == 0.24,
        "Standalone native Garden has the same rapid-hit timing as F5")
    direct.queue_free()
    await frames(2)
    print("TWO_MAP_DOUBLE_JUMP_RAPID_ATTACK_SUMMARY failures=",failed)
    quit(0 if failed==0 else 2)
