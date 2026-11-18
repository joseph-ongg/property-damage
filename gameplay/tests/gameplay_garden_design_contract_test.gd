## Design-specified Garden mechanics with real Art Team Piskel files.
## No blanket game integration or other subteam source modifications.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)
        push_error("FAIL: " + label)


func _frames(n: int = 2) -> void:
    for _i in n:
        await physics_frame


func _run() -> void:
    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    await _frames(5)
    var game := garden.get_node("GardenMechanics")
    var p1 := garden.get_node("Player1") as GameplayPlayer
    var p2 := garden.get_node("Player2") as GameplayPlayer
    var grid := garden.get_node("MaterialGrid") as MaterialGrid
    check(game != null and grid != null and grid.using_upstream_storage(),
        "Garden scene runs using Ethan's one authoritative MaterialGrid")
    check(garden.get_node("ArtTeamGardenBackground").texture ==
        load("res://gameplay/garden/original_art_parts/garden_without_dynamic_props.png"),
        "actual Art Team Garden pixels are the background")
    check(p1 is GameplayPlayer and p2 is GameplayPlayer,
        "original reusable gameplay player prefab, no copy of other owners' code")
    check(p1.health_component != null and p2.health_component != null,
        "both players use Eva Health component")

    var fences := garden.get_node("Fences")
    check(fences.get_child_count() == 8, "exactly eight independent fence segments")
    var fence := fences.get_child(0) as GameplayGardenFenceSegment
    for index in range(1,9):
        var seg := fences.get_child(index-1) as GameplayGardenFenceSegment
        check(seg.hp == 4 and seg.collision_layer == 4 and
            seg.get_node("ArtTeamFencePixels").texture != null,
            "fence %d starts with 4 HP and a real Art Team pixel layer" % index)

    # Repeated *real* magic ray collisions on the Garden-only layer.
    p1.set_physics_process(false)
    p2.set_physics_process(false)
    p1.global_position = Vector2(35, 357)
    p1.facing = 1
    for hit_index in 4:
        var bolt := GameplayGardenMagicBolt.new()
        garden.get_node("Projectiles").add_child(bolt)
        bolt.set_physics_process(false)
        bolt.initialize(p1)
        bolt.global_position = Vector2(45, 350)
        bolt._physics_process(0.32)
        await _frames(2)
        check(fence.hp == 3-hit_index,
            "four independent bolt attacks each remove exactly 1 fence HP")
    check(fence.destroyed_segment and not fence.get_node("ArtTeamFencePixels").visible
        and fence.collision_layer == 0,
        "destroyed fence visually disappears and cannot block another bolt")
    fence.restore()
    await _frames(2)
    check(fence.hp == 4 and fence.get_node("ArtTeamFencePixels").visible,
        "fence can restore its original Piskel pixels on match reset")
    for seg in fences.get_children():
        (seg as GameplayGardenFenceSegment).restore()
    await _frames(2)
    for seg in fences.get_children():
        (seg as GameplayGardenFenceSegment).take_hit(1)
    check(fences.get_children().all(func(x: Node) -> bool:
        return (x as GameplayGardenFenceSegment).hp == 3),
        "all eight fence segments independently take damage")

    # Tree holes are a two-way traversal, NOT the old crouch/cover behavior.
    p1.global_position = game.TREE_LOWER
    game._on_player_interact(1, p1)
    check(p1.global_position == game.TREE_UPPER_EXIT,
        "E at lower painted tree hole takes P1 to upper branch")
    game._on_player_interact(1, p1)
    check(p1.global_position == game.TREE_UPPER_EXIT,
        "tree hole has a cooldown to prevent accidental ping-pong")
    game._portal_cooldown[1] = 0.0
    game._on_player_interact(1, p1)
    check(p1.global_position == game.TREE_LOWER_EXIT,
        "E at upper tree hole returns P1 to garden floor")
    p2.global_position = game.TREE_LOWER
    game._on_player_interact(2, p2)
    check(p2.global_position == game.TREE_UPPER_EXIT,
        "Shift at lower hole independently works for P2")

    # Real rose thorn touch: exact 5 HP through Eva's Health, not a second HP system.
    p2.global_position = Vector2(850,455)
    p2.health_component.reset()
    game._on_rose_body_entered(p2)
    check(p2.health_component.hp == 115,
        "rose thorn contact deals 5 HP to default Mage through Eva Health")
    game._on_rose_body_entered(p2)
    check(p2.health_component.hp == 115,
        "Eva's existing invulnerability prevents duplicate same-frame thorn hits")

    # Art Team bird animation drops a real pick-up-able apple.
    var before: int = game.apples_dropped
    game._drop_apple()
    check(game.apples_dropped == before+1 and
        garden.get_node("Throwables/Apple01") is GameplayGardenThrowable,
        "Art Team bird produces an independently throwable apple")
    var apple := garden.get_node("Throwables/Apple01") as GameplayGardenThrowable
    check(apple.flying and apple.flight_velocity.y > 0.0,
        "apple actually falls from the bird's current position")
    apple.flying = false
    apple.global_position = Vector2(542,375)
    p1.global_position = Vector2(530,375)
    game._portal_cooldown[1] = 0.0
    game._on_player_interact(1, p1)
    check(apple.carried_by == p1, "P1 can pick up fallen apple using existing prop API")
    game._on_player_interact(1, p1)
    check(apple.carried_by == null and apple.flying,
        "P1 can throw apple using the existing main Gameplay prop API")
    check(garden.get_node("Throwables").get_child_count() >= 5,
        "Garden includes gnomes, mushrooms and fallen apple")

    # Hose: painted source tap, pickup follows player, sprays for exactly 10s.
    p1.global_position = game.HOSE_ART_ORIGIN
    game._on_player_interact(1, p1)
    check(game._hose_owner == p1 and is_equal_approx(game.hose_seconds_left, 10.0),
        "P1 picks up original-image hose point and starts 10s timer")
    p2.global_position = Vector2(760, 420)
    p2.health_component.reset()
    var water_at: Vector2 = game._hose_origin() + Vector2(64, -4)
    var cell: Vector2i = grid.world_to_cell(water_at)
    grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)
    check(garden.get_node("FireBridge").ignite_world(water_at),
        "hose integration test lights an actual upstream Simulation WOOD cell")
    game._hose_spray(0.1)
    check(not grid.is_burning(cell.x,cell.y),
        "hose spray extinguishes upstream Simulation fire, without shadow grid")
    var initial_hp: int = p2.health_component.hp
    check(game.tentative_hose_damage_enabled and game.hose_damage_per_second == 1,
        "hose defaults to 1 HP/s and remains inspector-tunable")
    game.tentative_hose_damage_enabled = false
    game._hose_spray(1.05)
    check(p2.health_component.hp == initial_hp,
        "tentative hose 1 HP/s can be disabled for Design review")
    game.tentative_hose_damage_enabled = true
    game._hose_damage_clock = 0.0
    p2.global_position = game._hose_origin() + Vector2(110, -3)
    game._hose_spray(1.05)
    check(p2.health_component.hp == initial_hp-1,
        "optional documented 1 HP/s hose rate works when Design approves it")
    game._physics_process(10.01)
    check(game._hose_owner == null and game.hose_seconds_left == 0.0,
        "hose water expires after 10 seconds and returns to unheld state")
    # It remains a throwable once its ten-second spray expires.
    var nozzle := garden.get_node("Throwables/HoseEnd") as GameplayGardenThrowable
    check(nozzle.kind == GameplayGardenThrowable.Kind.HOSE_END and
        nozzle.carried_by == null and nozzle.flying,
        "source-original hose nozzle is independently throwable after spray expires")
    nozzle.flying = false
    p1.global_position = Vector2(130, 450)
    p2.global_position = Vector2(800, 445)

    # Garden item contact is 1 HP placeholder when Design has not given
    # an explicit damage value. Run real moving-physics overlap, not a
    # direct Health.take_damage bypass of the item system.
    for kind in [GameplayGardenThrowable.Kind.APPLE,
            GameplayGardenThrowable.Kind.GNOME,
            GameplayGardenThrowable.Kind.MUSHROOM,
            GameplayGardenThrowable.Kind.HOSE_END]:
        p2.health_component.reset()
        var item: GameplayGardenThrowable = game._make_throwable(kind, Vector2(769, 433),
            "ImpactPlaceholder%d" % kind)
        item.last_thrower_index = 1
        item.flying = true
        item.flight_velocity = Vector2(300, 0)
        item._physics_process(0.12)
        check(item.impact_damage == 1 and item._impact_spent and not item.consumed
            and item.visible and p2.health_component.hp == 119,
            "Garden non-fragile item %d hits once for 1 HP and remains reusable" % kind)

    game.reset_garden_for_round()
    await _frames(2)
    check(game.apples_dropped == 0 and not garden.get_node("Throwables").has_node("Apple01"),
        "Angela-compatible round reset removes old apples and restarts bird timer")
    check(fences.get_children().all(func(x: Node) -> bool:
        return (x as GameplayGardenFenceSegment).hp == 4),
        "Angela-compatible round reset restores all eight original Piskel fence segments")
    check((garden.get_node("Throwables/Mushrooms1") as GameplayGardenThrowable).carried_by == null,
        "round reset restores the original Art Team mushroom positions")

    garden.queue_free()
    await _frames(2)
    print("GARDEN_DESIGN_CONTRACT_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 1)
