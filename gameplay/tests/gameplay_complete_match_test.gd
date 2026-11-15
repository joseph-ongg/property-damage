## Release acceptance: current Art Team, Austin items, Eva health/fall, Ethan fire,
## Angela menu, Garden and local best-of-three match all work together.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, label: String) -> void:
    if ok:
        print("PASS: ", label)
    else:
        failures.append(label)
        push_error("FAIL: " + label)


func _run() -> void:
    var menu_path := "res://gameplay/MapSelection/map_select.tscn"
    var menu := (load(menu_path) as PackedScene).instantiate()
    root.add_child(menu)
    await physics_frame
    check(menu.player1_select.item_count == 3 and menu.player2_select.item_count == 3,
        "Angela's new menu preserves both character selectors")
    check(menu.MAPS[1]["path"] == "res://gameplay/garden/garden_level.tscn",
        "Garden button now opens a playable scene")
    check(menu.MAPS.size() == 2, "only two confirmed arenas are advertised")
    menu.queue_free()

    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    await physics_frame
    var p1 := garden.get_node("Player1") as GameplayPlayer
    var p2 := garden.get_node("Player2") as GameplayPlayer
    var manager := garden.get_node("MatchManager") as GameplayMatchManager
    var grid := garden.get_node("MaterialGrid") as MaterialGrid
    check(manager.player1 == p1 and manager.player2 == p2, "Garden shares the real match manager")
    check(garden.get_node("GardenItems").get_child_count() == 3,
        "Garden has three distinct destructible environment objects")
    var flame_mask: Texture2D = load("res://gameplay/garden/art_generated/garden_fuel_mask.png")
    var mask_image := flame_mask.get_image()
    var rose_cells := 0
    for x in grid.width:
        for y in grid.height:
            var pigment := mask_image.get_pixel(x, y)
            if pigment.r > 0.9:
                rose_cells += 1
                check(grid.get_cell_material(x, y) == MaterialGrid.Materials.WOOD,
                    "sampled Garden rose pixel is flammable in Ethan's grid")
                break
        if rose_cells > 0:
            break
    check(rose_cells > 0, "Garden sources flammable fuel from actual Art Team pixels")

    var bolt := GameplayMagicBolt.new()
    garden.get_node("Projectiles").add_child(bolt)
    p1.set_character_kind("mage")
    p2.set_character_kind("mage")
    p1.global_position = Vector2(110, 450)
    p2.global_position = Vector2(230, 450)
    bolt.initialize(p1)
    var hp_before := p2.health.hp
    var hit := bolt._hit_combat_target(garden, Vector2(138, 443), Vector2(235, 443))
    check(hit == "P2" and p2.health.hp == hp_before - 10,
        "actual Mage projectile hits the other player for ten HP")
    bolt.queue_free()

    p2.health._invuln_left = 0.0
    p2.health.take_damage(1000)
    check(manager.round_over and not manager.match_over and manager.p1_wins == 1,
        "first lethal hit ends round and awards P1 one win")
    check(manager.panel.visible and not p1.is_physics_processing(),
        "finished round shows winner overlay and freezes combat")
    check(p2.knocked_out and p2.sprite.rotation != 0.0 and p2.get_node("NameTag").text == "KO",
        "defeated fighter has a distinct KO pose before the result panel")
    manager.continue_after_round()
    check(not manager.round_over and p1.health.hp == p1.health.max_hp and p2.health.hp == p2.health.max_hp,
        "next round resets Eva's Health and both player positions")
    check(not p2.knocked_out and is_zero_approx(p2.sprite.rotation) and p2.get_node("NameTag").text == "P2",
        "new round restores normal character sprite and P2 name tag")
    check(manager.round_number == 2 and manager.p1_wins == 1,
        "round scores survive a round reset")
    p2.health.take_damage(1000)
    check(manager.match_over and manager.p1_wins == 2 and not manager.continue_button.visible,
        "second P1 win completes a best-of-three match")
    manager.new_match()
    check(not manager.round_over and not manager.match_over and manager.p1_wins == 0 and manager.p2_wins == 0,
        "rematch resets match scoring without reloading the scene")

    p1.set_character_kind("ninja")
    var shuriken := GameplayMagicBolt.new()
    garden.get_node("Projectiles").add_child(shuriken)
    shuriken.initialize(p1)
    check(shuriken.attack_kind == "ninja" and shuriken.speed > 395.0,
        "Ninja fires a faster shuriken profile instead of Mage fire")
    shuriken.queue_free()
    p1.set_character_kind("werewolf")
    var claw := GameplayMagicBolt.new()
    garden.get_node("Projectiles").add_child(claw)
    claw.initialize(p1)
    check(claw.attack_kind == "werewolf" and claw.lifetime < 0.2,
        "Werewolf uses documented provisional short-range claw")
    claw.queue_free()

    p1.set_character_kind("mage")
    p1.health._invuln_left = 0.0
    var bridge := garden.get_node("FireBridge") as GameplayFireBridge
    var cell := bridge.world_to_cell(p1.global_position + Vector2(0, 13))
    var original_cell_material := grid.get_cell_material(cell.x, cell.y)
    grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)
    grid.ignite(cell.x, cell.y)
    var before_fire := p1.health.hp
    p1.hazard._cooldown = 0.0
    p1.hazard.tick(1.0, bridge, p1)
    check(p1.health.hp == before_fire - 2,
        "real player contact with grid fire deals two HP per tick")
    p1.health._invuln_left = 0.0
    p1.fall_damage.hard_landing.emit(5)
    check(p1.health.hp == before_fire - 7,
        "Eva's fall-damage component is connected to the same Health")

    var rose := garden.get_node("GardenItems/Roses") as GameplayInteractableItem
    var original_attack := p1.attack_damage
    rose.take_damage(rose.hp, 1)
    check(rose.destroyed_item and p1.attack_damage > original_attack,
        "destroying Garden object increases attack damage by five percent")
    manager.new_match()
    check(not rose.destroyed_item and rose.hp == rose.max_hp and rose.global_position == Vector2(210, 243),
        "new match restores destroyed Garden items to their original HP and position")
    check(not grid.is_burning(cell.x, cell.y) and grid.get_cell_material(cell.x, cell.y) == original_cell_material,
        "new match restores actual Art Team mask material and clears old fire")
    garden.queue_free()
    await physics_frame

    var living := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(living)
    await physics_frame
    var room := living.get_node("GameplayMSD")
    var living_manager := room.get_node("MatchManager") as GameplayMatchManager
    var clock := room.get_node("WorldItems/Clock") as GameplayWorldItem
    var living_grid := room.get_node("MaterialGrid") as MaterialGrid
    var start_location := clock.global_position
    clock.take_damage(clock.hp, 1)
    living_grid.ignite(9, 29)
    check(clock.destroyed_item and living_grid.is_burning(9, 29),
        "Living Room has real destructible props and active Simulation fire")
    clock.global_position += Vector2(75, 0)
    living_manager.new_match()
    check(not clock.destroyed_item and clock.hp == clock.max_hp and clock.global_position == start_location,
        "Living Room rematch restores item HP and original world location")
    check(not living_grid.is_burning(9, 29),
        "Living Room rematch clears the previous round's fire")
    living.queue_free()

    print("COMPLETE_MATCH_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
