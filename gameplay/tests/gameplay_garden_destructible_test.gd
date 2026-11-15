## Regression for real Garden Art Team pixel layers and round-state isolation.
## Must not mutate upstream MaterialGrid, game/player HP or untouched Piskel art.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)
        push_error("FAIL: " + label)


func _run() -> void:
    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    await physics_frame
    await process_frame
    var grid := garden.get_node("MaterialGrid") as MaterialGrid
    var bridge := garden.get_node("FireBridge") as GameplayFireBridge
    var manager := garden.get_node("MatchManager") as GameplayMatchManager
    var roses := garden.get_node("GardenItems/Roses") as GameplayGardenProp
    var tree := garden.get_node("GardenItems/Tree") as GameplayGardenProp
    var mushrooms := garden.get_node("GardenItems/Mushrooms") as GameplayGardenProp
    var player1 := garden.get_node("Player1") as GameplayPlayer
    var player2 := garden.get_node("Player2") as GameplayPlayer
    var mask := (load("res://gameplay/garden/art_generated/garden_fuel_mask.png") as Texture2D).get_image()
    var wood := 0
    var clear_air := 0
    var sample_tree := Vector2i(-1, -1)
    for x in grid.width:
        for y in grid.height:
            var pigment := mask.get_pixel(x, y)
            if pigment.r > 0.9 or pigment.g > 0.9 or pigment.b > 0.9:
                wood += 1
                if wood == 1:
                    check(grid.get_cell_material(x, y) == MaterialGrid.Materials.WOOD,
                        "plant-pixel fire material matches source mask")
                if sample_tree.x < 0 and pigment.g > 0.9:
                    sample_tree = Vector2i(x, y)
            elif grid.get_cell_material(x, y) == MaterialGrid.Materials.AIR:
                clear_air += 1
    check(wood > 400 and clear_air > 900, "only original plant pixel cells become flammable; sky stays AIR")
    check(roses.art != null and tree.art != null and mushrooms.art != null,
        "three breakable props render separately from the garden background")
    check(garden.get_node("Floor").position.y == 496.0,
        "physics floor now aligns to original grass at 476px")

    var original_tree_hp := tree.hp
    tree.take_damage(3, 1)
    check(tree.hp == original_tree_hp - 3 and not tree.destroyed_item,
        "tree visibly shows partial damage before destruction")
    var old_bonus := player1.attack_damage
    tree.take_damage(tree.hp, 1)
    check(tree.destroyed_item and player1.attack_damage > old_bonus,
        "tree is destroyed by the attacker and grants correct item bonus")
    check(grid.get_cell_material(sample_tree.x, sample_tree.y) == MaterialGrid.Materials.AIR,
        "destroyed tree fuel is removed from upstream MaterialGrid")

    manager.new_match()
    check(not tree.destroyed_item and tree.hp == tree.max_hp
        and tree.is_processing() and grid.get_cell_material(sample_tree.x, sample_tree.y) == MaterialGrid.Materials.WOOD,
        "rematch revives tree art and precise source-pixel fuel mask")

    grid.ignite(sample_tree.x, sample_tree.y)
    check(grid.is_burning(sample_tree.x, sample_tree.y), "live tree grid can ignite")
    tree._process(0.1)
    check(tree.burning, "the same burning grid ignites the tree item HP")
    var before_fire := tree.hp
    tree._process(3.1)
    check(tree.hp < before_fire, "flame contact damages living tree item over time")

    player2.health.take_damage(9999)
    check(manager.round_over, "lethal combat displays round result")
    var tick_timer := grid.get_node("TickTimer") as Timer
    check(tick_timer.paused and not tree.is_processing(),
        "winner result pauses fire spread and all Garden item burn damage")
    var frozen_hp := tree.hp
    await create_timer(0.25).timeout
    check(is_equal_approx(tree.hp, frozen_hp), "items do not burn while winner result panel is displayed")
    manager.continue_after_round()
    check(not manager.round_over and not tick_timer.paused and tree.is_processing(),
        "next round resumes original Simulation tick and item updates")
    check(not tree.burning and tree.hp == tree.max_hp and not grid.is_burning(sample_tree.x, sample_tree.y),
        "next round clears old fire state and restores item durability")

    # Two arenas can coexist temporarily (preview, tests, scene change).
    # A Garden item must not read fire state from the Living Room bridge.
    var living := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(living)
    await physics_frame
    var room := living.get_node("GameplayMSD")
    var clock := room.get_node("WorldItems/Clock") as GameplayWorldItem
    check(tree.room_fire_bridge() == bridge
        and clock.room_fire_bridge() == room.get_node("FireBridge"),
        "each item finds its own arena fire bridge, never a different loaded scene")

    living.queue_free()
    garden.queue_free()
    print("GARDEN_DESTRUCTIBLE_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
