## Regression: fan pixel art, unchanged co-op wind, replaceable Art/Simulation inputs.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
    if ok: print("PASS: ",label)
    else: failures.append(label); push_error("FAIL: " + label)
func frames(n: int) -> void:
    for i in n: await physics_frame

func _run() -> void:
    var game := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await frames(65)
    var room: Node2D = game.get_node("GameplayMSD")
    var p1: GameplayPlayer = room.get_node("Player1")
    var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
    var prefab: PackedScene = load("res://gameplay/props/fan/fan_device.tscn")
    var second: GameplayAppliance = prefab.instantiate() as GameplayAppliance
    check(second != null and second.device == GameplayAppliance.Device.FAN, "standalone prefabricated fan uses existing appliance interaction API")
    if second != null: second.free()
    check(fan.get_parent().name == "Appliances" and fan.device == GameplayAppliance.Device.FAN, "living room instantiates independent FanDevice at original gameplay path")
    check(fan.global_position == Vector2(413,389), "fan stays aligned on the existing table")
    check(fan.fan_facing_left and fan.get_fan_force_x() < -400.0, "left-facing fan preserves real leftward wind force")
    check(fan.simulation_id == "living_room_fan_01", "stable optional Simulation entity id is exposed")
    check(not fan.switched_on and fan.fan_runtime_state()["powered"] == false, "fan starts off and exports accurate runtime status")
    check(fan.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "fan art uses exact pixel sampling")
    var rear: Texture2D = load("res://gameplay/props/fan/sprites/rear.png")
    var front: Texture2D = load("res://gameplay/props/fan/sprites/front.png")
    var blade0: Texture2D = load("res://gameplay/props/fan/sprites/blade_0.png")
    var blade1: Texture2D = load("res://gameplay/props/fan/sprites/blade_1.png")
    check(rear.get_size() == Vector2(48,56) and front.get_size() == Vector2(48,56), "48x56 back housing and front grille use aligned transparent plates")
    check(blade0.get_size() == rear.get_size() and blade1.get_size() == rear.get_size(), "all blade frames match housing bounds")
    check(blade0.get_image().get_data() != blade1.get_image().get_data(), "spinning blade frames contain distinct original pixel artwork")
    var signals: Array[Array] = []
    fan.state_changed.connect(func(t: int, enabled: bool, source: int): signals.append([t,enabled,source]))
    fan.set_fan_power(true)
    check(fan.switched_on and fan.fan_runtime_state()["powered"] and signals == [[1,true,-1]], "external power setter emits exactly one source-tagged signal")
    fan.set_fan_power(true)
    check(signals.size() == 1, "repeated Simulation power sync is idempotent")
    p1.global_position = Vector2(413,478)
    p1.velocity = Vector2.ZERO
    p1.motor.reset()
    await frames(4)
    check(fan.applies_to(p1) and p1.motor.environment_acceleration_x < -300.0, "left-facing runtime wind still affects an actual nearby character")
    fan.fan_facing_left = false
    await frames(3)
    check(not fan.applies_to(p1) and is_zero_approx(p1.motor.environment_acceleration_x), "reverse direction removes wind from previously downwind player")
    p1.global_position = Vector2(440, 478)
    p1.velocity = Vector2.ZERO
    p1.motor.reset()
    await frames(3)
    check(fan.get_fan_force_x() > 400.0 and p1.motor.environment_acceleration_x > 300.0, "Level Design can reverse wind direction without changing player code")
    fan.fan_facing_left = true
    var custom := SpriteFrames.new()
    custom.add_animation("spin")
    custom.add_frame("spin",blade0)
    custom.add_frame("spin",blade1)
    fan.fan_blade_override = custom
    fan.fan_front_override = front
    fan.fan_rear_override = rear
    fan.fan_animation_fps = 7.0
    fan.fan_sprite_offset = Vector2(-1,0)
    await frames(2)
    check(fan.fan_blade_override.get_frame_count("spin") == 2 and fan.fan_rear_override == rear and fan.fan_front_override == front, "Art Team can supply an arbitrary SpriteFrames animation and two overlay textures")
    fan.set_fan_power(false)
    check(not fan.switched_on and signals == [[1,true,-1],[1,false,-1]], "external stop updates the display and state once")
    await frames(4)
    check(is_zero_approx(p1.motor.environment_acceleration_x), "existing gameplay removes wind on external power-off")
    check(room.get_node("TableTop").global_position == Vector2(485,411), "art replacement does not affect tabletop physics")
    game.queue_free()
    print("FAN_ART_HANDOFF_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
