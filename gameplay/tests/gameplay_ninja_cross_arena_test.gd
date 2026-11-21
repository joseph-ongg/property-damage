## Design Ninja shuriken must render on shared MagicBolt in BOTH arenas.
## Missing Art must use a '?' block; Werewolf's final "cloth?" attack is NOT Design approved.
extends SceneTree

var failures: Array[String] = []

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

func _test_projectiles(scene_path: String) -> void:
    var stage := (load(scene_path) as PackedScene).instantiate()
    root.add_child(stage)
    await _frames(4)
    var room: Node = stage.get_node("GameplayMSD") if stage.has_node("GameplayMSD") else stage
    var player: GameplayPlayer = room.get_node("Player1") as GameplayPlayer
    var projectiles: Node = room.get_node("Projectiles")
    player.set_character_kind("ninja")
    var shared_bolt := GameplayMagicBolt.new()
    projectiles.add_child(shared_bolt)
    shared_bolt.set_physics_process(false)
    shared_bolt.initialize(player)
    check(shared_bolt.projectile_kind == "shuriken",
        "%s: shared projectile selects Ninja shuriken visuals" % scene_path)
    check(player.motor.jump_speed > 460.0,
        "%s: Ninja keeps higher playtest jump" % scene_path)
    shared_bolt.queue_free()
    await _frames()

    player.set_character_kind("mage")
    var mage_bolt := GameplayMagicBolt.new()
    projectiles.add_child(mage_bolt)
    mage_bolt.set_physics_process(false)
    mage_bolt.initialize(player)
    check(mage_bolt.projectile_kind == "fireball",
        "%s: Wizard retains original hand-painted fireball frames" % scene_path)
    mage_bolt.queue_free()
    await _frames()

    player.set_character_kind("werewolf")
    var werewolf_bolt := GameplayMagicBolt.new()
    projectiles.add_child(werewolf_bolt)
    werewolf_bolt.set_physics_process(false)
    werewolf_bolt.initialize(player)
    check(werewolf_bolt.projectile_kind == "werewolf_unapproved",
        "%s: Werewolf now displays an explicit ? Art placeholder, never Wizard fire" % scene_path)
    werewolf_bolt.queue_free()
    stage.queue_free()
    await _frames(2)

func _run() -> void:
    await _test_projectiles("res://gameplay/playtest_main.tscn")
    await _test_projectiles("res://gameplay/garden/garden_level.tscn")
    print("NINJA_CROSS_ARENA_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
