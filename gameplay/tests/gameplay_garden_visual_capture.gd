## Windowed Godot evidence, run manually (not a replacement for unit QA).
## The captures use ONLY the real game renderer and supplied Piskel assets.
extends SceneTree

const DIR := "res://gameplay/garden/evidence/2026-11-18-original-art/"

func _initialize() -> void:
    call_deferred("_run")


func _capture(file: String) -> bool:
    RenderingServer.force_draw(false)
    var image := root.get_texture().get_image()
    var err := image.save_png(DIR + file)
    print("GARDEN_ART_CAPTURE ", file," size=",image.get_size()," result=",err)
    return err == OK


func _frames(n: int = 3) -> void:
    for i in n:
        await process_frame


func _run() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("Run with actual Godot window, not headless.")
        quit(1)
        return
    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await _frames(8)
    var ctrl := stage.get_node("GardenMechanics")
    var p1 := stage.get_node("Player1") as GameplayPlayer
    var status := stage.get_node("HUD/Status") as Label
    status.text = "ART TEAM PISKEL • ORIGINAL GARDEN + ALL FENCES"
    await _frames(3)
    var ok := _capture("01_original_art.png")

    var fence := stage.get_node("Fences/Fence03") as GameplayGardenFenceSegment
    for i in 4:
        fence.take_hit(1)
    status.text = "FENCE 3 • 4 HITS • ORIGINAL PIXELS DISAPPEAR"
    await _frames(3)
    ok = _capture("02_fence_destroyed.png") and ok

    fence.restore()
    p1.global_position = ctrl.TREE_LOWER
    ctrl._on_player_interact(1,p1)
    status.text = "TREE HOLE • P1 MOVED TO UPPER BRANCH"
    await _frames(3)
    ok = _capture("03_tree_hole_travel.png") and ok

    p1.global_position = ctrl.HOSE_ART_ORIGIN
    ctrl._on_player_interact(1,p1)
    p1.global_position = Vector2(384,452)
    status.text = "10s WATER HOSE • ORIGINAL PISKEL NOZZLE IS PORTABLE"
    await _frames(4)
    ok = _capture("04_hose_stream.png") and ok

    stage.queue_free()
    quit(0 if ok else 1)
