## Real physics regression cases discovered during PR #18's second review.
## Run after Godot --headless --editor --path . --import --quit on a clean machine.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, description: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + description)
    if not ok:
        failures.append(description)
        push_error(description)


func _frames(count: int = 2) -> void:
    for _index in count:
        await physics_frame


func _shoot(stage: Node2D, shooter: GameplayPlayer, at: Vector2, delta: float) -> void:
    var projectile := GameplayGardenMagicBolt.new()
    stage.get_node("Projectiles").add_child(projectile)
    projectile.set_physics_process(false)
    projectile.initialize(shooter)
    projectile.global_position = at
    projectile._physics_process(delta)


func _run() -> void:
    var stage: Node2D = (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await _frames(5)
    var p1: GameplayPlayer = stage.get_node("Player1") as GameplayPlayer
    var p2: GameplayPlayer = stage.get_node("Player2") as GameplayPlayer
    var controller := stage.get_node("GardenMechanics")
    var fence: GameplayGardenFenceSegment = stage.get_node("Fences/Fence01") as GameplayGardenFenceSegment
    p1.set_physics_process(false)
    p2.set_physics_process(false)
    # Isolate this attack-order test from nearby rose thorn Area2Ds.
    # Real rose collision/damage is independently verified by Garden tests.
    for rose in stage.get_node("RoseThorns").get_children():
        (rose as Area2D).set_deferred("monitoring",false)
    await _frames(2)


    p1.global_position = Vector2(35, 455)
    p1.facing = 1
    var original_hp := fence.hp
    var transparent_point := Vector2(88, 439)
    check((fence.get_node("ArtTeamFencePixels") as Sprite2D).texture.get_image().get_pixel(17, 227).a < 0.01,
        "Original Piskel fence source at lower shot Y is fully transparent")
    check(fence.first_opaque_hit_on_ray(Vector2(45,439),Vector2(200,439)).is_empty(),
        "Pixel-accurate hit test rejects invisible lower fence")
    _shoot(stage, p1, Vector2(45,439), 0.4)
    await _frames()
    check(fence.hp == original_hp, "Projectile passing through invisible fence does NOT inflict phantom 1 HP")

    p1.global_position = Vector2(35,357)
    _shoot(stage, p1, Vector2(45,350), 0.4)
    await _frames()
    check(fence.hp == 3, "Same visible Art Team fence loses exactly 1 HP when actually struck")

    # PVP: with fences excluded, actual Magic projectiles must hit the
    # other player's collision geometry using Eva Health, not a stub.
    for item in stage.get_node("Fences").get_children():
        (item as GameplayGardenFenceSegment).collision_layer = 0
    p1.global_position = Vector2(260,455)
    p2.global_position = Vector2(375,455)
    p2.health_component.reset()
    await _frames(2)  # teleport transforms need a physics-server sync
    _shoot(stage, p1, Vector2(279,448), 0.50)
    await _frames()
    check(p2.health_component.hp == 110,
        "Garden P1 Magic causes Design base 10 damage through Eva Health")

    p2.health_component.reset()
    p2.facing = -1
    p1.health_component.reset()
    _shoot(stage, p2, Vector2(356,448), 0.45)
    await _frames()
    check(p1.health_component.hp == 110, "Garden P2 Magic left also causes 10 damage")

    # True geometric priority when a victim stands in front of Art pixels:
    # large coarse fence rectangle must not steal a player-targeted hit.
    p2.health_component.reset()
    p1.global_position = Vector2(35,357)
    p2.global_position = Vector2(85,357)
    fence.collision_layer = 4
    var fence_before := fence.hp
    await _frames(2)
    _shoot(stage, p1, Vector2(45,350), 0.40)
    await _frames()
    check(p2.health_component.hp == 110 and fence.hp == fence_before,
        "Player physically in front of painted fence gets priority")

    # Now the painted fence is in front; the attack must hit the item
    # instead of the player (explicit Design target priority).
    p2.health_component.reset()
    p2.global_position = Vector2(175,357)
    await _frames(2)
    _shoot(stage, p1, Vector2(45,350), 0.40)
    await _frames()
    check(fence.hp == fence_before-1 and p2.health_component.hp == 120,
        "Visible damageable fence blocks player damage behind it")

    # The Design says a broken property grants +5% attack. Health is int,
    # so retain the fractional half-HP over consecutive attacks.
    fence.take_hit(1)
    fence.take_hit(1)
    check(fence.destroyed_segment and controller._destroyed_by_player[1] == 1,
        "Only destroying the fence earns P1 one 5% attack reward")
    check(controller.damage_for_player_attack(1) == 10
        and controller.damage_for_player_attack(1) == 11,
        "Two boosted attacks apply 10 then 11 HP (each 10.5 average)")
    check(controller.damage_for_player_attack(2) == 10,
        "P2 does not inherit P1 damage reward")

    # Reset must restore *all* material cells, not only painted seed cells.
    var grid: MaterialGrid = stage.get_node("MaterialGrid") as MaterialGrid
    var bridge: GameplayFireBridge = stage.get_node("FireBridge") as GameplayFireBridge
    var fire_at := Vector2(325,375)
    var c: Vector2i = grid.world_to_cell(fire_at)
    var original_material: MaterialGrid.Materials = controller._initial_grid_materials[c.x][c.y]
    grid.set_cell_material(c.x,c.y,MaterialGrid.Materials.WOOD)
    check(bridge.ignite_world(fire_at) and grid.is_burning(c.x,c.y),
        "Unseeded Garden material cell can actually burn")
    controller.reset_garden_for_round()
    check(not grid.is_burning(c.x,c.y)
        and grid.get_cell_material(c.x,c.y) == original_material,
        "Garden round reset clears stray fire and restores initial materials")
    check(fence.hp == 4 and controller._destroyed_by_player[1] == 0
        and controller.damage_for_player_attack(1) == 10,
        "Round reset restores both fence HP and combat bonus")

    # The Design permits reusable throwables and separately tags fragile.
    p1.global_position = Vector2(120,455)
    p2.global_position = Vector2(800,445)
    p2.health_component.reset()
    var reusable: GameplayGardenThrowable = controller._make_throwable(
        GameplayGardenThrowable.Kind.MUSHROOM, Vector2(769,433), "ReviewReusable")
    reusable.last_thrower_index = 1
    reusable.flying = true
    reusable.flight_velocity = Vector2(300,0)
    reusable._physics_process(0.12)
    check(p2.health_component.hp == p2.health_component.max_hp
        and reusable._impact_spent and reusable.visible
        and not reusable.consumed and not reusable.fragile
        and is_equal_approx(float(p2.health_component.get_meta(
            "design_throw_fraction", 0.0)),
            reusable._throw_pixel_area() / 10000.0),
        "Ordinary mushroom banks exact painted-size damage without vanishing")
    p2.health_component.reset()
    var fragile: GameplayGardenThrowable = controller._make_throwable(
        GameplayGardenThrowable.Kind.APPLE, Vector2(769,433), "ReviewFragile")
    fragile.fragile = true
    fragile.last_thrower_index = 1
    fragile.flying = true
    fragile.flight_velocity = Vector2(300,0)
    fragile._physics_process(0.12)
    check(fragile.consumed and not fragile.visible,
        "Explicit Design fragile tag consumes the object after impact")

    # Fire-on-fence: fire uses Ethan's grid as the source of truth and
    # removes exactly one fence HP per 3 seconds (explicit Design rule).
    controller.reset_garden_for_round()
    var burning_fence: GameplayGardenFenceSegment = stage.get_node("Fences/Fence02")
    var fence_cell: Vector2i = controller._fence_occupied_cells[1][0]
    var sample_world := grid.to_global(Vector2(
        (float(fence_cell.x)+0.5)*float(grid.cell_size),
        (float(fence_cell.y)+0.5)*float(grid.cell_size)))
    check(bridge.ignite_world(sample_world),
        "Painted Garden fence can ignite in upstream MaterialGrid")
    controller._tick_fence_fire(2.99)
    check(burning_fence.hp == 4, "Flammable fence does not take damage before 3 seconds")
    controller._tick_fence_fire(0.02)
    check(burning_fence.hp == 3, "Burning fence takes exactly 1 HP every 3 seconds")
    controller.reset_garden_for_round()
    check(burning_fence.hp == 4 and not grid.is_burning(fence_cell.x,fence_cell.y),
        "Garden reset restores burned fence art and removes active fire")

    # Explicit Design Ninja attack and higher jump, without pretending the
    # placeholder vector shuriken is final Art Team sprite work.
    p1.set_character_kind("ninja")
    var shuriken := GameplayGardenMagicBolt.new()
    stage.get_node("Projectiles").add_child(shuriken)
    shuriken.set_physics_process(false)
    shuriken.initialize(p1)
    check(shuriken.projectile_kind == "shuriken"
        and p1.motor.jump_speed > 460.0
        and p1.health_component.max_hp == 100,
        "Ninja gets design-defined shuriken attack and higher provisional jump")
    shuriken.queue_free()
    p1.set_character_kind("mage")
    check(is_equal_approx(p1.motor.jump_speed,460.0),
        "Switching back to Mage restores original jump physics")
    var fighter := GameplayGardenMagicBolt.new()
    stage.get_node("Projectiles").add_child(fighter)
    fighter.set_physics_process(false)
    fighter.initialize(p1)
    check(fighter.projectile_kind == "fireball",
        "Wizard uses its original fireball visuals")
    fighter.queue_free()

    # Player death remains Eva's HP event; Garden emits only the signal
    # Angela can use for win-screen/rematch without stealing her game loop.
    var defeats: Array = []
    stage.player_defeated.connect(func(loser: int,winner: int) -> void:
        defeats.append([loser,winner]))
    p2.health_component.reset()
    p2.health_component.take_damage(120)
    check(defeats == [[2,1]],
        "Eva's 0 HP causes Garden to notify Angela's winner/round handoff")

    stage.queue_free()
    await _frames()
    print("GARDEN_EDGE_REGRESSION_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
