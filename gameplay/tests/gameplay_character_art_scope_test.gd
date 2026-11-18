## Small integration contract: Design-defined character stats and unmodified
## Art Team Piskel frames. No map, combat, Simulation or selection UI changes.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, msg: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + msg)
    if not ok:
        failures.append(msg)
        push_error("FAIL: " + msg)


func _run() -> void:
    var prefab := load("res://gameplay/prefabs/gameplay_player.tscn") as PackedScene
    var stage := Node2D.new()
    root.add_child(stage)
    var cases := [
        {"kind":"mage","hp":120,"move":1.0},
        {"kind":"ninja","hp":100,"move":1.2},
        {"kind":"werewolf","hp":160,"move":0.85},
    ]
    var players: Array[GameplayPlayer] = []
    for data in cases:
        var p := prefab.instantiate() as GameplayPlayer
        p.player_index = 1 if players.size() == 0 else 2
        p.character_kind = data["kind"]
        stage.add_child(p)
        p.set_physics_process(false)
        players.append(p)
        check(p.character_kind == data["kind"],
            "%s can be selected directly in Godot Inspector" % data["kind"])
        check(p.get_node("Health") is Health
            and p.health.max_hp == data["hp"] and p.health.hp == data["hp"],
            "%s uses Eva Health with Design-approved max HP" % data["kind"])
        check(is_equal_approx(p.motor.speed, 245.0 * float(data["move"])),
            "%s has Design-approved movement ratio" % data["kind"])
        check(is_equal_approx(p.motor.jump_speed, 460.0),
            "%s retains baseline jump until exact Ninja adjustment approved" % data["kind"])

    var ninja: GameplayPlayer = players[1]
    var wolf: GameplayPlayer = players[2]
    check(ninja.sprite.texture == load("res://gameplay/art_team/exported/ninja_side_0.png"),
        "Ninja idle uses original Art Team Piskel, not generated placeholder")
    ninja._animation_clock = 0.20
    ninja._update_character_sprite(true)
    check(ninja.sprite.texture == load("res://gameplay/art_team/exported/ninja_walk_2.png"),
        "Ninja movement animates Art Team's original 4 walking frames")

    check(wolf.sprite.texture == load("res://gameplay/art_team/exported/wolf_walk_0.png"),
        "Werewolf idle uses Art Team original walk frame")
    wolf._animation_clock = 0.20
    wolf._update_character_sprite(true)
    check(wolf.sprite.texture == load("res://gameplay/art_team/exported/wolf_walk_1.png"),
        "Werewolf movement uses supplied original walk animation")
    wolf.set_character_kind("werewolf")
    check(wolf.health.take_damage(1), "Eva's existing Health component handles damage")
    check(wolf.sprite.texture == load("res://gameplay/art_team/exported/wolf_damage_1.png"),
        "Werewolf reacts with actual Art Team damage frame")

    ninja.set_character_kind("werewolf")
    check(ninja.health.max_hp == 160 and ninja.health.hp == 160
        and is_equal_approx(ninja.motor.speed, 245.0 * 0.85),
        "future Angela selection can change kind using a single Gameplay API")
    ninja.set_character_kind("mage")
    check(ninja.health.max_hp == 120 and is_equal_approx(ninja.motor.speed, 245.0),
        "switching back to Mage restores baseline without stacking modifiers")
    check(ninja.sprite.texture == load("res://gameplay/art/mage_2.png"),
        "original Mage art remains the unchanged default for P2")

    var garden := (load("res://gameplay/garden/garden_art_preview.tscn") as PackedScene).instantiate()
    stage.add_child(garden)
    var background := garden.get_node("OriginalArtTeamGarden") as Sprite2D
    check(background.texture ==
        load("res://gameplay/art_team/exported/garden.png"),
        "Garden preview displays only real Art Team Piskel source")
    check(background.texture.get_size() == Vector2(426,286),
        "Garden preserves exact original 426x286 source pixels")
    check(garden.get_child_count() == 1 and
        not garden.has_node("GardenMechanics"),
        "Garden art preview does not invent or alter Design mechanics")
    check((load("res://gameplay/art_team/exported/bird_drop_0.png") as Texture2D)
        .get_size() == Vector2(32, 32),
        "real Art Team bird frames are available for approved apple mechanic")
    stage.queue_free()
    print("CHARACTER_ART_SCOPE_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
