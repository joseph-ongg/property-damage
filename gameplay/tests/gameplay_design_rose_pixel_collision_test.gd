## Art-grounded rose physics: original Garden Piskel colored pixels,
## no legacy giant hazard rectangles or transparent-sky damage.
extends SceneTree
var errors: Array[String] = []
var successes := 0
func _initialize() -> void:
    call_deferred("_run")
func frames(n: int) -> void:
    for _i in n:
        await physics_frame
func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if ok: successes += 1
    else: errors.append(message)
func overlap_rose(stage: Node2D, pos: Vector2) -> bool:
    var q := PhysicsPointQueryParameters2D.new()
    q.position = pos
    q.collision_mask = 8
    q.collide_with_areas = true
    q.collide_with_bodies = false
    return not stage.get_world_2d().direct_space_state.intersect_point(q).is_empty()
func world_pixel(x: int, y: int) -> Vector2:
    return Vector2(54.0 + (float(x) + 0.5) * 2.0,
        -16.0 + (float(y) + 0.5) * 2.0)
func _run() -> void:
    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate() as Node2D
    root.add_child(stage)
    await frames(8)
    var mechanics := stage.get_node("GardenMechanics")
    var source := (stage.get_node("ArtTeamGardenBackground") as Sprite2D).texture.get_image()
    var zones := stage.get_node("RoseThorns")
    check(zones.get_child_count() == 3,
        "All painted rose zones: upper arch, left stem and right stem")
    var total_polygons := 0
    for area in zones.get_children():
        check(area is Area2D and area.collision_mask == 2
            and area.collision_layer == 8, area.name + " only detects players")
        var shapes := area.get_children()
        total_polygons += shapes.size()
        check(shapes.size() > 0 and shapes.all(func(c: Node) -> bool:
            return c is CollisionPolygon2D),
            area.name + " uses real Piskel pixel outlines, no giant rectangle")
        var region: Rect2i = area.get_meta("source_rect")
        var tinted := 0
        var touched := 0
        var clear := 0
        var ghost := 0
        for y in range(region.position.y + 1, region.end.y - 1, 3):
            for x in range(region.position.x + 1, region.end.x - 1, 3):
                var color := source.get_pixel(x, y)
                var rose: bool = mechanics._is_rose_art_pixel(color)
                var collision := overlap_rose(stage, world_pixel(x, y))
                if rose:
                    tinted += 1
                    if collision: touched += 1
                elif color.a8 == 0:
                    clear += 1
                    if collision: ghost += 1
        check(tinted > 2 and float(touched) / float(tinted) >= 0.80,
            area.name + " covers real painted rose colors")
        check(clear > 30 and float(ghost) / float(clear) <= 0.05,
            area.name + " leaves transparent sky clear")
        print("ROSE_AREA ",area.name," pixels=",tinted," hit=",touched,
            " clear=",clear," ghost=",ghost," polygons=",shapes.size())
    check(total_polygons >= 5 and total_polygons < 350,
        "Source art represented by compact detailed polygons, not broad rectangles")
    check(not overlap_rose(stage, world_pixel(23,206)),
        "Old left rectangle's solid fence no longer registers rose damage")
    check(not overlap_rose(stage, world_pixel(100,150)),
        "Sky between rose columns has no invisible hazard")
    check(overlap_rose(stage, world_pixel(153,213)),
        "Painted lower right thorn vine registers a real contact hazard")
    var p1 := stage.get_node("Player1") as GameplayPlayer
    p1.health_component.reset()
    p1.global_position = Vector2(360, 320)
    p1.velocity = Vector2.ZERO
    await frames(8)
    check(p1.health_component.hp == p1.health_component.max_hp - 5,
        "Actual player physics collision inflicts Design's exact 5HP")
    stage.queue_free()
    await frames(2)
    print("DESIGN_ROSE_PIXEL_COLLISION_SUMMARY failures=",errors.size()," passes=",successes)
    quit(0 if errors.is_empty() else 2)
