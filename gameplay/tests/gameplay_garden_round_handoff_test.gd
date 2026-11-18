## Standalone playable Garden / Angela-owned match-controller handoff contract.
## Tests TWO rounds with real Health death, HUD, apples, fire and cleanup.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, text: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + text)
    if not ok:
        failures.append(text)
        push_error("FAIL: " + text)

func _frames(n: int = 2) -> void:
    for _i in n:
        await physics_frame

func _run() -> void:
    var arena: Node2D = (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(arena)
    await _frames(5)
    var gm: Node2D = arena.get_node("GardenMechanics")
    var p1: GameplayPlayer = arena.get_node("Player1")
    var p2: GameplayPlayer = arena.get_node("Player2")
    var label: Label = arena.get_node("HUD/PlayerHealth")
    var outcome: Array = []
    arena.player_defeated.connect(func(loser: int, winner: int) -> void:
        outcome.append([loser, winner]))

    check(label.text.contains("P1") and label.text.contains("120 / 120")
        and label.text.contains("P2"), "Garden preview HUD shows real Eva HP for both players")
    p2.health_component.take_damage(10)
    check(label.text.contains("110 / 120"),
        "Garden preview HUD updates on actual Eva Health.damage")
    # Prevent second hit inside Eva's intended short invulnerability window.
    p2.health_component._process(1.0)
    p2.health_component.take_damage(110)
    check(outcome == [[2,1]] and arena._round_finished and not gm.round_active,
        "Eva death announces winner exactly once and freezes round")
    var status: Label = arena.get_node("HUD/Status")
    check(status.text.contains("P1 WINS ROUND"),
        "Garden preview displays the round winner while Angela owns final win UI")

    var old_projectile_count: int = arena.get_node("Projectiles").get_child_count()
    arena._on_magic_attack(1,p1)
    check(arena.get_node("Projectiles").get_child_count() == old_projectile_count,
        "No new attacks spawn after round end")
    var before_action: String = gm.last_action
    gm._on_player_interact(1,p1)
    check(gm.last_action == before_action,
        "Tree/throwable interactions stop after round end")
    var before_thorns: int = p1.health_component.hp
    gm._on_rose_body_entered(p1)
    check(p1.health_component.hp == before_thorns,
        "Roses do not inflict damage after winner declared")

    # Set up stale state and then start the next round via one public API.
    var fence: GameplayGardenFenceSegment = arena.get_node("Fences/Fence01")
    fence.take_hit(1)
    gm._drop_apple()
    var grid: MaterialGrid = arena.get_node("MaterialGrid")
    var bridge: GameplayFireBridge = arena.get_node("FireBridge")
    var fire_at: Vector2 = Vector2(320,400)
    var cell := grid.world_to_cell(fire_at)
    grid.set_cell_material(cell.x,cell.y,MaterialGrid.Materials.WOOD)
    check(bridge.ignite_world(fire_at), "Temporary fire lit before round transition")
    p1.global_position = Vector2(540,255)
    p1.facing = -1
    p1.sprite.flip_h = true
    p1.velocity = Vector2(99,-70)
    gm._portal_cooldown[1] = 0.35
    p1.spark._cooldown_remaining = 0.22
    p1.spark._flash_remaining = 0.16
    var projectile := GameplayGardenMagicBolt.new()
    arena.get_node("Projectiles").add_child(projectile)
    projectile.initialize(p1)
    check(arena.get_node("Projectiles").get_child_count()>0,
        "Temporary projectile exists before reset")

    arena.prepare_new_round()
    await _frames(2)
    check(outcome == [[2,1]] and not arena._round_finished and gm.round_active,
        "Angela can start a new local Garden round without emitting extra winners")
    check(p1.health_component.hp == 120 and p2.health_component.hp == 120,
        "New round restores both Eva Health components")
    check(p1.global_position.distance_to(Vector2(200,455)) < 12 and p1.facing == 1
        and p1.velocity.length() < 30,
        "New round resets position, direction, momentum and motor")
    check(fence.hp == 4 and gm.apples_dropped == 0 and not grid.is_burning(cell.x,cell.y)
        and gm._portal_cooldown.is_empty(),
        "New round clears Garden props, bird apples, fire and tree cooldown")
    check(arena.get_node("Projectiles").get_child_count() == 0,
        "New round removes all stale projectiles before they can damage players")
    check(label.text.contains("120 / 120"),
        "Health HUD shows restored values for new round")
    check(p1.spark.is_ready() and p1.spark._flash_remaining == 0.0,
        "Replayed Garden round resets pre-existing Spark cooldown and flash")
    var count_before := arena.get_node("Projectiles").get_child_count()
    arena._on_magic_attack(1,p1)
    check(arena.get_node("Projectiles").get_child_count()==count_before+1,
        "Attacks become available again after new round")

    # Two consecutive rounds must work, not a one-shot cleanup.
    p1.health_component.take_damage(120)
    check(outcome == [[2,1],[1,2]] and arena._round_finished,
        "Second round announces opposite winner once")
    arena.prepare_new_round()
    await _frames(2)
    check(p1.health_component.hp == 120 and p2.health_component.hp == 120
        and not arena._round_finished, "Third round can start with healthy fighters")

    arena.queue_free()
    await _frames(2)
    print("GARDEN_ROUND_HANDOFF_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 1)
