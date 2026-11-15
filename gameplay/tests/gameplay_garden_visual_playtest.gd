## Windowed, pixel-accurate destructible Art Team garden visual acceptance.
extends SceneTree

var failures: Array[String] = []
const DIR := "/tmp/property_damage_garden_20261114_"


func _initialize() -> void:
    call_deferred("_run")


func assert_ok(ok: bool, message: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + message)
    if not ok:
        failures.append(message)


func snap(name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var path := DIR + name + ".png"
    var rc := image.save_png(path)
    assert_ok(rc == OK and image.get_size() == Vector2i(960, 540),
        "actual renderer saved " + name)
    print("SCREENSHOT ", path)


func _run() -> void:
    root.size = Vector2i(960, 540)
    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    current_scene = garden
    for _i in 6:
        await physics_frame
    var manager := garden.get_node("MatchManager") as GameplayMatchManager
    var tree := garden.get_node("GardenItems/Tree") as GameplayGardenProp
    await snap("01_tree_intact")
    tree.take_damage(tree.hp, 1)
    assert_ok(tree.destroyed_item, "tree HP reaches zero")
    await physics_frame
    await snap("02_tree_destroyed")
    manager.new_match()
    assert_ok(not tree.destroyed_item and tree.hp == tree.max_hp,
        "rematch reconstructs source art and full tree HP")
    await physics_frame
    await snap("03_tree_restored")
    print("GARDEN_VISUAL_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
