## Garden's painted gate has solid source-aligned collision, including the
## overhead rose arch. Previous implementation had only damaging Area2Ds.
## Design's 5HP thorn contact stays owned by its existing Area/Health.
extends SceneTree

var failures: Array[String] = []
var passed: int = 0

func _initialize() -> void:
    call_deferred("_run")

func frames(n: int) -> void:
    for _i in n:
        await physics_frame

func check(ok: bool, name: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + name)
    if ok:
        passed += 1
    else:
        failures.append(name)

func world_pixel(x: int,y: int) -> Vector2:
    return Vector2(54.0 + (float(x)+0.5) * 2.0,
        -16.0 + (float(y)+0.5)*2.0)

func world_solid_at(stage: Node2D, pt: Vector2) -> bool:
    var q := PhysicsPointQueryParameters2D.new()
    q.position = pt
    q.collision_mask = 1
    q.collide_with_bodies = true
    q.collide_with_areas = false
    var hits := stage.get_world_2d().direct_space_state.intersect_point(q)
    return hits.any(func(item: Dictionary) -> bool:
        return (item["collider"] as Node).is_in_group("garden_rose_gate_solids"))

func collision_ray(stage: Node2D, a: Vector2,b: Vector2) -> Dictionary:
    var q := PhysicsRayQueryParameters2D.create(a,b,1)
    return stage.get_world_2d().direct_space_state.intersect_ray(q)

func _run() -> void:
    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(stage)
    await frames(9)
    var controller := stage.get_node("GardenMechanics")
    var source := (stage.get_node("ArtTeamGardenBackground") as Sprite2D).texture.get_image()
    var solid_group := stage.get_node("RoseGateSolids")
    var thorn_group := stage.get_node("RoseThorns")

    check(solid_group.get_child_count() == 1 and thorn_group.get_child_count() == 3,
        "Only TOP gate arch is solid; three original zones retain 5HP thorn contact")
    var totals := 0
    for body in solid_group.get_children():
        check(body is StaticBody2D and body.collision_layer == 1
            and body.collision_mask == 0,
            body.name + " is a solid player/world obstacle")
        var names := body.get_children()
        check(names.size() > 0 and names.all(func(n: Node) -> bool:
            return n is CollisionPolygon2D),
            body.name + " uses original-image polygons (not fake rectangles)")
        totals += names.size()
    check(totals == 1, "Original top arch physical shape matches its single Piskel contour")

    var coverage := 0
    var candidates := 0
    var ghosts := 0
    var empties := 0
    for area in thorn_group.get_children():
        if area.name != "UpperRoseThorns":
            continue
        var crop: Rect2i = area.get_meta("source_rect")
        for y in range(crop.position.y + 1,crop.end.y - 1,4):
            for x in range(crop.position.x + 1,crop.end.x - 1,4):
                var source_color: Color = source.get_pixel(x,y)
                var art_color: bool = controller._is_rose_art_pixel(source_color)
                var physical := world_solid_at(stage,world_pixel(x,y))
                if art_color:
                    candidates += 1
                    if physical:
                        coverage += 1
                elif source_color.a8 == 0:
                    empties += 1
                    if physical:
                        ghosts += 1
    print("GATE_SOURCE_PIXEL_SCAN solid=",coverage, "/",candidates,
        " transparent_ghost=",ghosts, "/",empties)
    check(candidates > 50 and float(coverage)/float(candidates) > 0.88,
        "Painted gate top/side pixels are physically solid")
    check(empties > 300 and float(ghosts)/float(empties) < 0.04,
        "Transparent arch doorway and sky stay physically empty")
    var upper := collision_ray(stage, Vector2(206,20),Vector2(206,210))
    check(not upper.is_empty() and (upper["collider"] as Node).is_in_group("garden_rose_gate_solids"),
        "Vertical physics ray now hits the TOP of left Garden gate")
    check(not world_solid_at(stage,Vector2(226,198)),
        "Gate interior below top arch remains open; no phantom roof rectangle")
    check(not world_solid_at(stage,world_pixel(153,213)),
        "Lower rose stems stay 5HP thorn contact, not speculative solid walls")
    var p1 := stage.get_node("Player1") as GameplayPlayer
    p1.set_physics_process(false)
    p1.global_position = Vector2(206,20)
    p1.velocity=Vector2.ZERO
    await frames(2)
    var player_contact := p1.move_and_collide(Vector2(0,200),true)
    check(player_contact != null and
        (player_contact.get_collider() as Node).is_in_group("garden_rose_gate_solids"),
        "Real CharacterBody2D sweep collides with painted gate top, not only Area2D hurt")
    check(p1.health_component.is_alive(),"Gate correction does not kill player or change Eva HP formula")
    stage.queue_free()
    await frames(3)
    print("GARDEN_GATE_SOLID_ART_SUMMARY failures=",failures.size()," passes=",passed)
    quit(0 if failures.is_empty() else 1)
