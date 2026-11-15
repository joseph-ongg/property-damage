## Stress-test repeated best-of-three matches across both arenas.
## Catches stale projectile, burned item, KO, timer or paused-grid state.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        push_error("FAIL: " + label)


func _play_matches(arena: Node, match_count: int) -> void:
    var manager := arena.get_node("MatchManager") as GameplayMatchManager
    var grid := arena.get_node("MaterialGrid") as MaterialGrid
    var p1 := arena.get_node("Player1") as GameplayPlayer
    var p2 := arena.get_node("Player2") as GameplayPlayer
    var prop: GameplayInteractableItem
    if arena.name == "GardenBattle":
        prop = arena.get_node("GardenItems/Roses") as GameplayInteractableItem
    else:
        prop = arena.get_node("WorldItems/Clock") as GameplayInteractableItem
    for match_index in match_count:
        for round_index in 2:
            check(not manager.round_over and prop.hp == prop.max_hp,
                "%s match%d round%d starts with fresh props" % [arena.name,match_index,round_index])
            prop.take_damage(prop.hp, 1)
            check(prop.destroyed_item and p1.attack_damage > 10.0,
                "%s match%d round%d applies destruction bonus" % [arena.name,match_index,round_index])
            p2.health._invuln_left = 0.0
            p2.health.take_damage(9999)
            check(manager.round_over and manager.p1_wins == round_index + 1,
                "%s match%d round%d completes" % [arena.name,match_index,round_index])
            check(grid.get_node("TickTimer").paused,
                "%s match%d round%d freezes grid on results" % [arena.name,match_index,round_index])
            if round_index == 0:
                manager.continue_after_round()
                check(not manager.round_over and not p2.knocked_out
                    and p2.health.hp == p2.health.max_hp,
                    "%s match%d continues with restored KO" % [arena.name,match_index])
        check(manager.match_over and manager.p1_wins == 2,
            "%s match%d final victory" % [arena.name,match_index])
        manager.new_match()
        check(not manager.match_over and not manager.round_over
            and manager.p1_wins == 0 and manager.p2_wins == 0,
            "%s match%d reset to fresh match" % [arena.name,match_index])
        check(prop.hp == prop.max_hp and not prop.destroyed_item
            and not grid.get_node("TickTimer").paused
            and is_equal_approx(p1.attack_damage, 10.0),
            "%s match%d fully restores items, grid and attack" % [arena.name,match_index])


func _run() -> void:
    var start := Time.get_ticks_msec()
    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    await process_frame
    _play_matches(garden, 10)
    garden.queue_free()
    await process_frame

    var living := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
    root.add_child(living)
    await process_frame
    _play_matches(living.get_node("GameplayMSD"), 6)
    living.queue_free()

    print("LONG_SESSION_SUMMARY failures=", failures.size(),
        " matches=16 rounds=32 elapsed_ms=", Time.get_ticks_msec() - start)
    quit(0 if failures.is_empty() else 1)
