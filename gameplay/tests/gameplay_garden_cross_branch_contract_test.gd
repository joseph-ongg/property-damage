## Guardrails for unmerged Austin/Eva branches and edge bugs found in QA.
## Run on main and on a temporary integration worktree before merging.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, description: String) -> void:
    if ok:
        print("PASS: ",description)
    else:
        failures.append(description)
        push_error("FAIL: " + description)


func _frames(n: int=2) -> void:
    for _i in n:
        await physics_frame


func _run() -> void:
    var stage: Node2D = (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await _frames(5)
    var gm: Node2D = stage.get_node("GardenMechanics")
    var p1: GameplayPlayer = stage.get_node("Player1") as GameplayPlayer
    var grid: MaterialGrid = stage.get_node("MaterialGrid") as MaterialGrid
    var bridge: GameplayFireBridge = stage.get_node("FireBridge") as GameplayFireBridge

    # Every source-visible Piskel fence pixel contributes to the Simulation
    # footprint. Center-only sampling missed actual burning edge pixels.
    var fence: GameplayGardenFenceSegment = stage.get_node("Fences/Fence01")
    var pixel := Vector2(98,344)  # source x=22,y=180, alpha=255
    var cell := grid.world_to_cell(pixel)
    check(not fence.first_opaque_hit_on_ray(pixel,pixel).is_empty(),
        "Exact Garden Art Team fence pixel is visibly opaque")
    check(cell in gm._fence_occupied_cells[0],
        "Pixel-derived fire footprint includes the fence edge")
    check(bridge.ignite_world(pixel), "Real fence edge ignites through Ethan grid")
    gm._tick_fence_fire(3.01)
    check(fence.hp == 3,"Fence edge fire removes 1 HP after 3 seconds")
    gm.reset_garden_for_round()
    check(fence.hp == 4 and not grid.is_burning(cell.x,cell.y),
        "Reset restores fence HP and extinguishes its edge cell")

    # Continuous bird drops must not silently stop after six apples.
    for _i in 9:
        gm._drop_apple()
        await _frames(1)
    var count := 0
    for item in stage.get_node("Throwables").get_children():
        var garden_item := item as GameplayGardenThrowable
        if garden_item != null and garden_item.kind == GameplayGardenThrowable.Kind.APPLE:
            count += 1
    check(gm.apples_dropped == 9 and count == 6,
        "Bird drops indefinitely while recycling old unheld apples (cap 6)")

    # Garden adapts to Austin's optional shared item/HP API without
    # requiring the older main branch to already contain his code.
    var hose: GameplayGardenThrowable = stage.get_node("Throwables/HoseEnd")
    if hose.has_method("has_tag"):
        check(hose.has_tag("flammable") and hose.has_tag("throwable") and hose.hp > 0,
            "Austin item base: hose is tagged, initialized and damageable")
        p1.global_position = gm.HOSE_ART_ORIGIN
        await _frames()
        check(hose.can_pick_up(p1),"Austin item base: E/Shift can pick up Garden hose")
    else:
        check(not hose.consumed,"Original main prototype remains functional")

    # Fire DoT uses Eva Health, not a duplicate health variable. The
    # upstream FireHazard is enabled only for the Garden scene.
    check(p1.hazard.enabled and not p1.hazard.touched_fire.get_connections().is_empty(),
        "Garden player has an active Eva FireHazard damage callback")
    p1.set_physics_process(false)
    p1.health_component.reset()
    var fire_feet := p1.global_position + Vector2(0,13)
    var feet_cell := grid.world_to_cell(fire_feet)
    grid.set_cell_material(feet_cell.x,feet_cell.y,MaterialGrid.Materials.WOOD)
    check(bridge.ignite_world(fire_feet),"Fire under player feet ignites on Simulation grid")
    var initial_hp := p1.health_component.hp
    # The integrated Eva FireHazard sends one tick per 0.5 s (1 HP each).
    # Drive both scheduled ticks rather than collapsing one second into a
    # single manual tick; Health DoT bypasses projectile invulnerability.
    p1.hazard.tick(0.51,bridge,p1)
    p1.hazard.tick(0.51,bridge,p1)
    check(p1.health_component.hp == initial_hp-2,
        "One second of fire contact inflicts 2 HP via Eva Health")
    p1.health_component._process(0.9)
    p1.hazard.tick(0.51,bridge,p1)
    p1.hazard.tick(0.51,bridge,p1)
    check(p1.health_component.hp == initial_hp-4,
        "Sustained fire contact applies 2 HP each second, not just first hit")
    gm.reset_garden_for_round()

    # The shared prefab owns ONE Eva FallDamage instance; Garden must not
    # create a duplicate, which would apply landing damage twice.
    var fall_available := ResourceLoader.exists("res://gameplay/components/fall_damage.gd")
    check(p1.has_node("FallDamage") == fall_available and not p1.has_node("EvaFallDamageGarden"),
        "Single shared Eva FallDamage is wired without Garden duplicate sensor")

    if p1.has_method("take_damage"):
        # Eva's intentional 0.8s invulnerability applies to later
        # distinct projectile hits; do not expect two instant hits.
        p1.health_component._process(1.0)
        var before_hp := p1.health_component.hp
        check(is_equal_approx(float(p1.get("health")), float(before_hp)),
            "Austin numeric health starts as a mirror of Eva authoritative HP")
        p1.set("health",float(before_hp-7))
        stage._sync_optional_legacy_damage(p1)
        check(p1.health_component.hp == before_hp-7
            and is_equal_approx(float(p1.get("health")),float(before_hp-7)),
            "Garden adapter converts Austin numeric damage into Eva Health exactly once")
        var p2: GameplayPlayer = stage.get_node("Player2")
        p2.health_component.reset()
        p2.global_position = Vector2(800,445)
        await _frames()
        var thrown: GameplayGardenThrowable = gm._make_throwable(
            GameplayGardenThrowable.Kind.MUSHROOM,Vector2(769,433),"CompatImpact")
        thrown.last_thrower_index = 1
        thrown.flying = true
        thrown.flight_velocity = Vector2(300,0)
        thrown._physics_process(0.12)
        check(p2.health_component.hp == p2.health_component.max_hp - 1
            and is_equal_approx(float(p2.get("health")),float(p2.health_component.hp)),
            "Austin base impact plus Garden placeholder hits once and keeps Eva/numeric HP synchronized")
    stage.queue_free()
    await _frames()
    print("GARDEN_CROSS_BRANCH_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 1)
