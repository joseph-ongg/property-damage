## Real Garden physics collision against original Art Team fence art.
extends SceneTree
var failed := 0
func _initialize() -> void:
    call_deferred("_run")
func frames(n: int) -> void:
    for i in n: await physics_frame
func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok: failed += 1
func ray(stage: Node2D, x: float, y0: float, y1: float) -> Dictionary:
    var q := PhysicsRayQueryParameters2D.create(Vector2(x, y0), Vector2(x, y1), 1)
    return stage.get_world_2d().direct_space_state.intersect_ray(q)
func _run() -> void:
    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(stage)
    await frames(7)
    var fences := stage.get_node("Fences")
    check(fences.get_child_count() == 8, "Eight independent Piskel fences retained")
    for i in range(8):
        var f := fences.get_child(i) as GameplayGardenFenceSegment
        var body := f.get_node_or_null("RailPlatforms") as StaticBody2D
        check(body != null and body.collision_layer == 1 and body.get_child_count() > 0,
            "Fence %d has source-alpha derived one-way physics platforms" % (i+1))
        if body != null:
            var im := (f.get_node("ArtTeamFencePixels") as Sprite2D).texture.get_image()
            var good := true
            for ledge in body.get_children():
                var c := ledge as CollisionShape2D
                var local := (f.get_node("ArtTeamFencePixels") as Sprite2D).to_local(c.global_position)
                var pix := Vector2i(floori(local.x+im.get_width()*0.5), floori(local.y+im.get_height()*0.5))
                good = good and c.one_way_collision and im.get_pixelv(pix).a > 0.1
            check(good, "Fence %d colliders occupy actual opaque pixels" % (i+1))
    var hit := ray(stage,500,232,275)
    check(not hit.is_empty() and (hit["collider"] as Node).name == "RailPlatforms",
        "Art top railing is a real platform at x500")
    hit=ray(stage,500,342,385)
    check(not hit.is_empty() and (hit["collider"] as Node).name == "RailPlatforms",
        "Lower railing has separate collision at x500")
    check(ray(stage,200,388,430).is_empty(),"Transparent lower fence has no ghost collision")
    hit=ray(stage,560,184,253)
    check(not hit.is_empty() and (hit["collider"] as Node).name == "TreeBranch",
        "Diagonal tree branch collides near visible wood, not at ghost horizontal")
    hit=ray(stage,800,240,279)
    check(hit.is_empty() or (hit["collider"] as Node).name != "TreeBranch",
        "Removed phantom tree rectangle from right side")
    var p1 := stage.get_node("Player1") as GameplayPlayer
    p1.global_position=Vector2(500,300)
    p1.velocity=Vector2.ZERO
    await frames(80)
    check(p1.is_on_floor() and absf(p1.global_position.y-337)<15,
        "Player actually lands on lower fence rail")
    # A second real CharacterBody2D must land on the diagonal tree branch,
    # not on an invisible 300px rectangle or the lower fence.
    p1.global_position=Vector2(560,162)
    p1.velocity=Vector2.ZERO
    await frames(70)
    check(p1.is_on_floor() and p1.global_position.y < 218,
        "Player lands on the angled tree artwork above the fence")

    var fence := fences.get_child(4) as GameplayGardenFenceSegment
    for i in 4: fence.take_hit(1)
    await frames(3)
    check(fence.destroyed_segment and fence.get_node("RailPlatforms").collision_layer == 0
        and ray(stage,500,232,275).is_empty(),
        "Four damage hits remove the solid platform with original pixels")
    fence.restore()
    await frames(3)
    check(not ray(stage,500,232,275).is_empty(),
        "Round restoration restores platform collision")
    stage.queue_free()
    await frames(2)
    print("GARDEN_PHYSICAL_PLATFORM_SUMMARY failures=",failed)
    quit(0 if failed == 0 else 2)
