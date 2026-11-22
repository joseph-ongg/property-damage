## Exact painted-ground bounds, physical tree bark, intact teleport access,
## real Garden pick/throw and hose/bird interactions.
extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("_run")
func frames(n: int) -> void:
    for _i in n: await physics_frame
func check(ok:bool,msg:String) -> void:
    print(("PASS: " if ok else "FAIL: ") + msg)
    if not ok: failures.append(msg)
func key(code:Key,on:bool) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=on
    Input.parse_input_event(event)
    Input.flush_buffered_events()
func tap(code:Key) -> void:
    key(code,true)
    await frames(2)
    key(code,false)
    await frames(2)
func ray(stage:Node2D,x:float,start_y:float,end_y:float) -> Dictionary:
    var q:=PhysicsRayQueryParameters2D.create(Vector2(x,start_y),Vector2(x,end_y),1)
    return stage.get_world_2d().direct_space_state.intersect_ray(q)
func point(stage:Node2D,xy:Vector2) -> bool:
    var q:=PhysicsPointQueryParameters2D.new()
    q.position=xy
    q.collision_mask=1
    return not stage.get_world_2d().direct_space_state.intersect_point(q).is_empty()
func _run() -> void:
    var stage:Node2D=(load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await frames(8)
    var art:=stage.get_node("ArtTeamGardenBackground") as Sprite2D
    check(art.texture != null and art.texture.get_width()==426,
        "Original Garden 426px Piskel remains intact at x2 scale")
    var floor:=stage.get_node("Floor") as StaticBody2D
    var floor_shape:=floor.get_node("CollisionShape2D") as CollisionShape2D
    check(floor_shape.shape is RectangleShape2D
        and is_equal_approx((floor_shape.shape as RectangleShape2D).size.x,852.0),
        "Floor collision exactly matches 426px x2 original painted garden width")
    check(ray(stage,25,425,510).is_empty() and ray(stage,935,425,510).is_empty(),
        "No phantom invisible ground beyond painted Garden left/right edges")
    var center_ground:=ray(stage,480,425,510)
    check(not center_ground.is_empty() and center_ground["collider"] == floor,
        "Players still stand on actual center garden grass")
    check(stage.get_node_or_null("LeftWall")==null and stage.get_node_or_null("RightWall")==null,
        "No invisible world walls outside the painted Garden")
    var tree:=stage.get_node_or_null("TreeTrunk") as StaticBody2D
    check(tree != null and tree.collision_layer == 1 and point(stage,Vector2(774,296)),
        "Original tree trunk owns a solid bark collider at a painted location")
    check(not point(stage,Vector2(700,232)) and not point(stage,Vector2(752,423)),
        "Tree portal upper/lower exits remain open, not sealed by bark physics")
    var mechanics:=stage.get_node("GardenMechanics")
    var p1:=stage.get_node("Player1") as GameplayPlayer
    p1.global_position=Vector2(704,429)
    p1.velocity=Vector2.ZERO
    await frames(5)
    await tap(KEY_E)
    check(p1.global_position.distance_to(Vector2(700,232)) < 50,
        "Real E interact still travels UP through the lower tree hole")
    mechanics._portal_cooldown[1]=0.0
    p1.global_position=Vector2(700,232)
    p1.velocity=Vector2.ZERO
    await frames(2)
    await tap(KEY_E)
    check(p1.global_position.distance_to(Vector2(752,440)) < 35,
        "Real E interact still travels DOWN through the upper tree hole")
    # Original Piskel mushroom art remains functional after placeholder
    # changes to unrelated no-art items (apple and gnome).
    p1.global_position=Vector2(419,435)
    p1.velocity=Vector2.ZERO
    await frames(5)
    await tap(KEY_E)
    var held:GameplayGardenThrowable=mechanics._held_throwables.get(1) as GameplayGardenThrowable
    check(is_instance_valid(held) and held.kind == GameplayGardenThrowable.Kind.MUSHROOM,
        "Garden real mushroom can be picked up using physical E key")
    await tap(KEY_E)
    check(not mechanics._held_throwables.has(1),
        "Garden real mushroom can be thrown using same physical E key")
    p1.global_position=Vector2(580,455)
    p1.velocity=Vector2.ZERO
    await frames(5)
    await tap(KEY_E)
    check(mechanics._hose_owner == p1 and mechanics.hose_seconds_left > 9.0,
        "Original Art water nozzle picks up and begins 10s spraying interaction")
    await tap(KEY_E)
    check(mechanics._hose_owner == null,
        "Hose can be released without changing provisional damage rules")
    var count:int=mechanics.apples_dropped
    mechanics._bird_drop_timer=0.001
    await frames(4)
    check(mechanics.apples_dropped > count,
        "Original Art bird still drops playable placeholder apple")
    stage.queue_free()
    await frames(2)
    print("GARDEN_GROUND_TREE_INTERACTION_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 2)
