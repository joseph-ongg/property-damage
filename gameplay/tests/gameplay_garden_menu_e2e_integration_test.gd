## Integration-only: run in a combined QA worktree containing Angela's
## MapSelection, with her Garden destination patched to this PR's scene.
## This is not part of the standalone PR tests until Angela merges the map UI.
## Real Button.pressed -> SceneTree transition -> two 10-HP attack rounds ->
## Garden.prepare_new_round -> return to map selection.
extends SceneTree

var failures: Array[String] = []
var results: Array = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, description: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + description)
    if not ok:
        failures.append(description)
        push_error(description)

func _frames(n: int = 2) -> void:
    for _i in n:
        await physics_frame

func _shot(arena: Node2D, caster: GameplayPlayer, at: Vector2) -> void:
    var bolt := GameplayGardenMagicBolt.new()
    arena.get_node("Projectiles").add_child(bolt)
    bolt.set_physics_process(false)
    bolt.initialize(caster)
    bolt.global_position = at
    bolt._physics_process(0.50)

func _setup_combat(arena: Node2D) -> void:
    var p1: GameplayPlayer = arena.get_node("Player1")
    var p2: GameplayPlayer = arena.get_node("Player2")
    p1.set_physics_process(false)
    p2.set_physics_process(false)
    p1.global_position = Vector2(260, 455)
    p2.global_position = Vector2(375, 455)
    p1.facing = 1
    p2.facing = -1
    for fence in arena.get_node("Fences").get_children():
        (fence as GameplayGardenFenceSegment).collision_layer = 0
    for rose in arena.get_node("RoseThorns").get_children():
        (rose as Area2D).set_deferred("monitoring", false)
    await _frames(3)

func _play_round(arena: Node2D, caster_index: int) -> void:
    var attacker: GameplayPlayer = arena.get_node("Player%d" % caster_index)
    var defender: GameplayPlayer = arena.get_node("Player%d" % (3 - caster_index))
    var initial := defender.health_component.hp
    for shot in range(12):
        defender.health_component._process(1.0)  # honor Eva's i-frame interval
        var launch := Vector2(279,448) if caster_index == 1 else Vector2(356,448)
        _shot(arena, attacker, launch)
        await _frames(1)
        if shot == 0:
            check(defender.health_component.hp == initial - 10,
                "Round P%d: first actual projectile deals Design 10 HP" % caster_index)
    check(defender.health_component.hp == 0,
        "Round P%d: actual 12-shot fight reaches zero HP" % caster_index)
    check(arena._round_finished,
        "Round P%d: loser death freezes finished Garden" % caster_index)

func _run() -> void:
    var menu_path := "res://gameplay/MapSelection/map_select.tscn"
    check(ResourceLoader.exists(menu_path),
        "Angela's actual map-select PackedScene exists in combined checkout")
    if not ResourceLoader.exists(menu_path):
        print("GARDEN_MENU_E2E_SUMMARY failures=", failures.size())
        quit(1)
        return
    var menu := (load(menu_path) as PackedScene).instantiate() as Control
    root.add_child(menu)
    current_scene = menu
    await _frames(3)
    var options := menu.get_node("CenterContainer/VBoxContainer")
    var buttons: Array[Button] = []
    for item in options.get_children():
        if item is Button:
            buttons.append(item as Button)
    check(buttons.size() == 2,
        "Angela's original Living Room and Garden button layout is preserved")
    if buttons.size() != 2:
        quit(1)
        return
    check(buttons[1].text == "Garden", "Second actual menu button is Garden")
    # Use the real button signal; let Angela's own _load_map() transition.
    buttons[1].pressed.emit()
    await _frames(5)
    var garden := current_scene as Node2D
    check(is_instance_valid(garden) and garden.name == "Garden",
        "Real Angela menu button opens Suwen's Garden scene")
    if not is_instance_valid(garden) or garden.name != "Garden":
        print("GARDEN_MENU_E2E_SUMMARY failures=", failures.size())
        quit(1)
        return
    garden.player_defeated.connect(func(loser: int, winner: int) -> void:
        results.append([loser, winner]))

    await _setup_combat(garden)
    await _play_round(garden, 1)
    check(results == [[2,1]],
        "First Garden round emits P1 winner once to Angela's handoff")
    garden.prepare_new_round()
    await _frames(3)
    check(not garden._round_finished,
        "Scene-level handoff resets the complete arena between rounds")

    await _setup_combat(garden)
    await _play_round(garden, 2)
    check(results == [[2,1],[1,2]],
        "Second Garden round emits P2 winner once")
    garden.prepare_new_round()
    await _frames(3)
    check(garden.get_node("Player1").health_component.hp == 120
        and garden.get_node("Player2").health_component.hp == 120,
        "Next round restores both Eva Health components")
    var menu_change_error := change_scene_to_file(menu_path)
    check(menu_change_error == OK, "Garden can transition back to Angela map scene")
    await _frames(5)
    check(is_instance_valid(current_scene) and current_scene.name == "MapSelect",
        "Return to actual Angela map-select PackedScene works")
    print("GARDEN_MENU_E2E_SUMMARY failures=",failures.size())
    quit(0 if failures.is_empty() else 1)
