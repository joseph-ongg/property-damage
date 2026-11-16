## Integration acceptance: new pre-map two-fighter selection, Garden
## gnomes/hose/bird/tree cover, third arena crystals/beam and reused match HUD.
extends SceneTree

const Selection = preload("res://gameplay/characters/character_selection_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)
        push_error("FAIL: " + message)


func _run() -> void:
    # The new panel does not change Angela's map_select.gd; it hands character
    # choices to the existing GameplayCharacterSelectionState adapter.
    var select := (load("res://gameplay/presentation/fighter_select.tscn") as PackedScene).instantiate()
    root.add_child(select)
    current_scene = select
    await process_frame
    check(select.player_kinds == [0, 1] and select.start_button.disabled,
        "fight selection demands both players confirm")
    select._cycle(0, -1)
    check(select.player_kinds[0] == 2, "P1 can cycle to Werewolf")
    select._cycle(1, -1)
    check(select.player_kinds[1] == 0, "P2 can independently choose Mage")
    select.ready_buttons[0].button_pressed = true
    check(select.start_button.disabled, "one ready player cannot skip P2")
    select.ready_buttons[1].button_pressed = true
    check(not select.start_button.disabled, "two ready players unlock Angela's maps")
    select._continue_to_maps()
    await create_timer(0.17).timeout
    check(current_scene.name == "MapSelect", "selection continues to Angela's original map scene")
    check(Selection.for_player(1) == "werewolf" and Selection.for_player(2) == "mage",
        "existing state passes both independently chosen characters")
    check(current_scene.list.get_child_count() == 3,
        "Angela's map label and original two buttons remain untouched")
    check(current_scene.get_node("LobbyDecor") != null,
        "new third map button belongs to a separate cosmetic/deck extension")
    current_scene.queue_free()
    await process_frame

    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    await process_frame
    await process_frame
    var g: GameplayMatchManager = garden.get_node("MatchManager")
    var grid: MaterialGrid = garden.get_node("MaterialGrid")
    var mechanics: Node2D = garden.get_node("GardenMechanics")
    var p1: GameplayPlayer = garden.get_node("Player1")
    var p2: GameplayPlayer = garden.get_node("Player2")
    var tree: GameplayGardenProp = garden.get_node("GardenItems/Tree")
    var gnome1: GameplayGardenGnome = garden.get_node("GardenItems/Gnome1")
    var gnome2: GameplayGardenGnome = garden.get_node("GardenItems/Gnome2")
    check(p1.character_kind == "werewolf" and p2.character_kind == "mage",
        "Garden spawns the actual selected characters")
    check(gnome1.max_hp == 5.0 and gnome2.max_hp == 5.0,
        "two fragile programmatic gnome props present")
    var before_bonus := p1.attack_damage
    gnome1.take_damage(gnome1.hp, 1)
    check(gnome1.destroyed_item and p1.attack_damage > before_bonus,
        "destroying gnome grants player attack damage progression")
    check(mechanics.tree_prop == tree, "tree-hole cover is bound to actual Piskel tree")
    p1.global_position = Vector2(685, 441)
    Input.action_press("p1_down")
    mechanics._update_cover()
    Input.action_release("p1_down")
    check(p1.in_cover, "pressing Down inside original tree holes provides cover")
    var bolt := GameplayMagicBolt.new()
    garden.get_node("Projectiles").add_child(bolt)
    bolt.caster_index = 2
    check(bolt._hit_combat_target(garden, Vector2(610, 400), Vector2(740, 400)) != "P1",
        "tree cover prevents swept bolt from hitting concealed player")
    bolt.queue_free()
    mechanics.reset_mechanics()
    check(not p1.in_cover, "rematch/reset releases tree cover")
    var fuel: Vector2i = Vector2i(-1, -1)
    for x in range(10, 24):
        for y in range(23, 30):
            if grid.get_cell_material(x, y) == MaterialGrid.Materials.WOOD:
                fuel = Vector2i(x, y)
                break
        if fuel.x >= 0:
            break
    check(fuel.x >= 0, "Garden has locally burnable Art-pixel fuel")
    p1.global_position = mechanics.HOSE
    p1.facing = 1
    mechanics._on_interact(1, p1)
    check(mechanics.hose_time > 0.0 and mechanics.hose_cooldown > 0.0,
        "pressing Interact near Garden hose activates water and cooldown")
    # Actual physics runs at fixed 60 Hz. One artificial 3.5s delta would
    # teleport the freshly spawned drop offscreen before the next frame.
    for _i in 36:
        mechanics._physics_process(0.1)
    check(mechanics.bird_drops.size() >= 1,
        "flying birds periodically spawn falling environmental hazards")
    g.new_match()
    check(not gnome1.destroyed_item and gnome1.hp == gnome1.max_hp,
        "Garden new match restores both native Piskel and gnome breakables")
    check(mechanics.hose_time == 0.0 and mechanics.bird_drops.is_empty(),
        "Garden new match resets hose, birds and cover")
    garden.queue_free()
    await process_frame

    Selection.choose("ninja", "werewolf")
    var obs := (load("res://gameplay/observatory/observatory_level.tscn") as PackedScene).instantiate()
    root.add_child(obs)
    await process_frame
    await process_frame
    var o_manager: GameplayMatchManager = obs.get_node("MatchManager")
    var o_mechanics := obs.get_node("ObservatoryMechanics")
    var crystal: GameplayObservatoryCrystal = obs.get_node("ArcaneProps/Crystal1")
    var op1: GameplayPlayer = obs.get_node("Player1")
    var op2: GameplayPlayer = obs.get_node("Player2")
    check(op1.character_kind == "ninja" and op2.character_kind == "werewolf",
        "third arena inherits both selected fighters and Eva Health")
    check(obs.get_node("ArcaneProps").get_child_count() == 4,
        "Observatory has four destructible original crystal props")
    check(obs.get_node("ImpactJuice/HitCamera") is Camera2D,
        "third arena has reusable screen shake / hit feedback camera")
    var obs_bonus := op1.attack_damage
    crystal.take_damage(crystal.hp, 1)
    check(crystal.destroyed_item and op1.attack_damage > obs_bonus,
        "Observatory crystal destruction grants +5% attack")
    o_mechanics.cycle_age = 4.15
    op2.global_position = Vector2(680, 419)
    var pre_beam := op2.health.hp
    o_mechanics._physics_process(0.1)
    check(op2.health.hp < pre_beam, "telegraphed sweeping observatory beam deals Health damage")
    o_mechanics.meteor_age = 0.0
    o_mechanics._physics_process(0.06)
    check(o_mechanics.meteors.size() == 1,
        "third arena spawns meteor debris with independent timer")
    o_manager.new_match()
    check(not crystal.destroyed_item and crystal.hp == crystal.max_hp,
        "third arena rematch restores crystal and damage state")
    check(o_mechanics.meteors.is_empty() and o_mechanics.cycle_age == 0.0,
        "third arena rematch resets beams and meteors")
    obs.queue_free()
    Selection.clear()
    print("NOV15_DELIVERY_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
