## Actual keyboard controls for room items, distinct from direct-method QA.
extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func frames(n:int) -> void:
    for i in n: await physics_frame
func check(ok:bool,label:String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok: failures.append(label)
func key(code:Key,pressed:bool) -> void:
    var ev:=InputEventKey.new()
    ev.keycode=code
    ev.physical_keycode=code
    ev.pressed=pressed
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
func tap(code:Key) -> void:
    key(code,true)
    await frames(2)
    key(code,false)
    await frames(2)
func _run() -> void:
    var room:= (load("res://gameplay/msd/gameplay_msd.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(room)
    await frames(9)
    var p1:=room.get_node("Player1") as GameplayPlayer
    var p2:=room.get_node("Player2") as GameplayPlayer
    p2.global_position=Vector2(850,455)
    p2.velocity=Vector2.ZERO
    p1.global_position=Vector2(324,455)
    p1.velocity=Vector2.ZERO
    await frames(6)
    await tap(KEY_C)
    var carried:=room.held_items.get(1) as GameplayBurnableProp
    check(is_instance_valid(carried) and carried.item_name=="PLUSHIE",
        "Real P1 C key picks up unauthored ? Plushie without breaking item rules")
    await tap(KEY_C)
    check(not room.held_items.has(1), "Second real C key throws held object")
    p1.global_position=Vector2(648,455)
    p1.velocity=Vector2.ZERO
    await frames(6)
    var ac:=room.get_node("Appliances/ACDevice") as GameplayAppliance
    await tap(KEY_E)
    check(ac.switched_on, "Real E activates AC")
    await tap(KEY_E)
    check(not ac.switched_on, "Real E deactivates AC")
    p1.global_position=Vector2(780,455)
    p1.velocity=Vector2.ZERO
    await frames(6)
    var fridge:=room.get_node("Appliances/FridgeDevice") as GameplayAppliance
    await tap(KEY_E)
    check(fridge.switched_on,"Real E opens original room fridge")
    p1.global_position=Vector2(748,455)
    p1.velocity=Vector2.ZERO
    await frames(6)
    var microwave:=room.get_node("WorldItems/Microwave") as GameplayWorldItem
    await tap(KEY_E)
    check(microwave.opened,"Real E opens the microwave")
    key(KEY_S,true)
    await frames(2)
    await tap(KEY_E)
    check(not microwave.opened and not microwave.powered,
        "First real S+E closes microwave door before cooking")
    await tap(KEY_E)
    key(KEY_S,false)
    await frames(2)
    check(microwave.powered,"Second real S+E starts microwave cooking")
    # P2 has a distinct interaction input; both players must be able to act.
    p1.global_position=Vector2(230,455)
    p2.global_position=Vector2(648,455)
    p2.velocity=Vector2.ZERO
    await frames(5)
    await tap(KEY_SHIFT)
    check(ac.switched_on, "P2 physical Shift also interacts with AC")
    room.queue_free()
    await frames(2)
    print("LIVING_KEYBOARD_INTERACTION_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 2)
