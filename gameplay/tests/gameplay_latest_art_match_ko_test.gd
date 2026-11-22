## Both Design stages must show Art Team Ninja_dead on a real Eva Health KO.
## Other character KOs and the user-driven, non-final match rule are kept.
extends SceneTree

var failures: Array[String] = []
var passes := 0
func _initialize() -> void: call_deferred("_run")
func frames(n:int) -> void:
    for _i in n: await physics_frame
func check(ok:bool,msg:String) -> void:
    print(("PASS: " if ok else "FAIL: ")+msg)
    if ok: passes += 1
    else: failures.append(msg)

func _run() -> void:
    var paths := [
        "res://gameplay/garden/garden_level.tscn",
        "res://gameplay/playtest_main.tscn",
    ]
    var ninja_dead := load("res://gameplay/art_team/exported/ninja_dead_0.png")
    for path in paths:
        var map_tag := "Garden" if path.contains("garden") else "LivingRoom"
        for loser_index in [1,2]:
            var shell := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate()
            var selected: Array[String] = ["ninja","werewolf"]
            if loser_index==2:
                selected=["werewolf","ninja"]
            shell.selected_kinds = selected
            root.add_child(shell)
            await frames(6)
            shell._on_map_selected(path)
            await frames(9)
            var loser := shell.arena.get_node("Player%d" % loser_index) as GameplayPlayer
            var winner := shell.arena.get_node("Player%d" % (3-loser_index)) as GameplayPlayer
            loser.health_component.invulnerable_time=0.0
            loser.health_component.take_damage(loser.health_component.max_hp,true)
            await frames(2)
            check(shell.round_over and shell.scores[3-loser_index]==1
                and shell.screen_mode=="fight",
                map_tag+"/P"+str(loser_index)+" real Eva Health KO ends only a round")
            check(loser.sprite.texture==ninja_dead and
                is_zero_approx(loser.sprite.rotation) and
                loser.get_node("NameTag").text=="KO",
                map_tag+"/P"+str(loser_index)+" displays original sideways Ninja_dead Piskel")
            check(winner.sprite.texture!=ninja_dead,
                map_tag+" unrelated original Werewolf frame remains unchanged")
            shell._start_round()
            await frames(12)
            var fresh := shell.arena.get_node("Player%d" % loser_index) as GameplayPlayer
            check(not shell.round_over and fresh.character_kind=="ninja"
                and fresh.sprite.texture!=ninja_dead
                and fresh.health_component.hp==100,
                map_tag+" next round restores Ninja original idle and Design 100HP")
            shell.queue_free()
            await frames(3)
    print("LATEST_ART_MATCH_KO_SUMMARY failures=",failures.size()," passes=",passes)
    quit(0 if failures.is_empty() else 2)
