## Eva's aiming end-to-end: six real physical-key cases in Ethan's fire grid.
## P1: double W/S + F; P2: double Up/Down + Enter.
## Assert the *actual* Grid ignition cell, fired signal, emitted pixel direction,
## reticle location, separate per-player states, and Magic / drop compatibility.
extends SceneTree

var failures: Array[String] = []
var records: Array[Dictionary] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, description: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + description)
    if not ok:
        failures.append(description)
        push_error("FAIL: " + description)


func _frames(n: int = 1) -> void:
    for _i in n:
        await physics_frame


func _key(code: Key, down: bool, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _tap(code: Key) -> void:
    _key(code, true)
    await _frames(2)
    _key(code, false)
    await _frames(2)


func _double_tap(code: Key) -> void:
    await _tap(code)
    await _tap(code)


func _capture(index: int, target: Vector2, accepted: bool, player: GameplayPlayer) -> void:
    records.append({
        "player": index,
        "target": target,
        "accepted": accepted,
        "origin": player.global_position,
        "reticle": player.get_node("SparkAim").target_world_position(),
        "offset": player.spark._last_target_offset,
        "mode": player.get_node("SparkAim").aim_mode(),
        "facing": player.facing,
    })


func _fire(player: GameplayPlayer, grid: MaterialGrid, key: Key,
        expected_mode: int, label: String) -> void:
    var reticle := player.get_node("SparkAim")
    check(reticle.aim_mode() == expected_mode,
        label + " aim state and marker selected")

    var target: Vector2 = reticle.target_world_position()
    var cell := grid.world_to_cell(target)
    # The character still obeys gravity during a real physical-key action.
    # Fuel a small surrounding patch; check the *emitted* cell exactly.
    for x in range(cell.x - 2, cell.x + 3):
        for y in range(cell.y - 2, cell.y + 3):
            if grid.in_bounds(x, y):
                grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)

    player.spark._cooldown_remaining = 0.0
    var before := records.size()
    _key(key, true)
    await _frames(2)
    _key(key, false)
    await _frames(1)
    check(records.size() == before + 1, label + " physical Spark key fires once")
    if records.size() <= before:
        return
    var record: Dictionary = records[-1]
    var result_target: Vector2 = record["target"]
    var result_cell: Vector2i = grid.world_to_cell(result_target)
    var predicted: Vector2 = record["origin"] + Vector2(
        float(record["facing"]) * player.spark.reach,
        -float(expected_mode) * reticle.max_vertical_reach)

    check(int(record["player"]) == player.player_index and bool(record["accepted"]),
        label + " is attributed to the right player and ignition accepted")
    check(result_target.distance_to(predicted) <= 0.01,
        label + " actual ignition coordinate has correct vertical offset")
    check(result_target.distance_to(record["reticle"]) <= 0.01,
        label + " emitted location exactly equals visible reticle")
    check((record["offset"] as Vector2).distance_to(result_target - record["origin"]) <= 0.01,
        label + " original Eva Spark emitter uses the same aim vector")
    check(grid.is_burning(result_cell.x, result_cell.y),
        label + " Ethan MaterialGrid actually ignites the aimed cell")

    # Actual Godot viewport evidence when run in windowed mode. The same
    # unmodified six-direction path also runs headless in regression suites.
    if DisplayServer.get_name() != "headless":
        RenderingServer.force_draw(false)
        var filename := "/tmp/property_damage_spark_aim_%d_%d.png" % [
            player.player_index, expected_mode]
        var error := root.get_texture().get_image().save_png(filename)
        check(error == OK, label + " actual Godot screenshot saved")
        print("SPARK_SCREENSHOT ", filename)


func _run() -> void:
    var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await _frames(7)
    var room := scene.get_node("GameplayMSD")
    var grid: MaterialGrid = room.get_node("MaterialGrid") as MaterialGrid
    var p1: GameplayPlayer = room.get_node("Player1") as GameplayPlayer
    var p2: GameplayPlayer = room.get_node("Player2") as GameplayPlayer
    var aim1 := p1.get_node("SparkAim")
    var aim2 := p2.get_node("SparkAim")
    var bridge: GameplayFireBridge = room.get_node("FireBridge") as GameplayFireBridge
    check(grid != null and grid.using_upstream_storage(),
        "six-direction Spark test runs against real upstream Simulation storage")
    check(p1.facing == 1 and p2.facing == -1,
        "P1 starts right, P2 starts left")
    p1.sparked.connect(_capture.bind(p1))
    p2.sparked.connect(_capture.bind(p2))

    # Neutral/horizontal: no direction key is required.
    await _fire(p1, grid, KEY_F, 0, "P1 FORWARD")
    await _fire(p2, grid, KEY_ENTER, 0, "P2 FORWARD")

    # Single jump/down press never changes aim, preserving normal controls.
    await _tap(KEY_W)
    check(aim1.aim_mode() == 0 and aim2.aim_mode() == 0,
        "P1 single W retains normal jump and does not change either aim")
    await _tap(KEY_DOWN)
    check(aim2.aim_mode() == 0 and aim1.aim_mode() == 0,
        "P2 single Down retains crouch and does not change either aim")

    # Clear single-tap memory before the paired gestures. Each gesture must
    # use two physical presses and must not control the other player.
    aim1.reset_aim()
    aim2.reset_aim()
    await _double_tap(KEY_W)
    check(aim1.aim_mode() == 1 and aim2.aim_mode() == 0,
        "double W changes only P1 to up")
    await _fire(p1, grid, KEY_F, 1, "P1 UP")

    await _double_tap(KEY_UP)
    check(aim2.aim_mode() == 1 and aim1.aim_mode() == 1,
        "double Up arrow changes only P2 to up")
    await _fire(p2, grid, KEY_ENTER, 1, "P2 UP")

    await _double_tap(KEY_S)
    check(aim1.aim_mode() == -1 and aim2.aim_mode() == 1,
        "double S changes only P1 to down")
    await _fire(p1, grid, KEY_F, -1, "P1 DOWN")

    await _double_tap(KEY_DOWN)
    check(aim2.aim_mode() == -1 and aim1.aim_mode() == -1,
        "double Down arrow changes only P2 to down")
    await _fire(p2, grid, KEY_ENTER, -1, "P2 DOWN")

    # Double-tap toggles back to forward, and normal movement/drop keys
    # still work without re-targeting Spark.
    await _double_tap(KEY_S)
    await _double_tap(KEY_DOWN)
    check(aim1.aim_mode() == 0 and aim2.aim_mode() == 0,
        "repeating current down gesture resets both independently to forward")

    _key(KEY_S, true)
    await _frames(1)
    _key(KEY_W, true)
    await _frames(2)
    _key(KEY_W, false)
    _key(KEY_S, false)
    await _frames(1)
    check(aim1.aim_mode() == 0,
        "P1 S+W platform drop chord does not toggle Spark aim")
    _key(KEY_DOWN, true)
    await _frames(1)
    _key(KEY_UP, true)
    await _frames(2)
    _key(KEY_UP, false)
    _key(KEY_DOWN, false)
    await _frames(1)
    check(aim2.aim_mode() == 0,
        "P2 Down+Up platform drop chord does not toggle Spark aim")

    await _double_tap(KEY_W)
    check(aim1.aim_mode() == 1, "aim can be set again before a new match")
    room.get_node("MatchManager").new_match()
    check(aim1.aim_mode() == 0 and aim2.aim_mode() == 0,
        "starting a new match restores both players' neutral Spark directions")

    check(records.size() == 6 and room.sparks_p1 == 3 and room.sparks_p2 == 3,
        "exactly six real Spark casts were recorded, three per player")
    check(bridge.grid() == grid,
        "all six cases use the existing Simulation bridge (no shadow grid)")
    scene.queue_free()
    await _frames(1)
    print("SPARK_AIM_SIX_WAY_SUMMARY failures=", failures.size(),
        " physical_casts=", records.size())
    quit(0 if failures.is_empty() else 1)
