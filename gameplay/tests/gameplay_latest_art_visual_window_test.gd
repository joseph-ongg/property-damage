## Real Mac GPU window: inspect actual imported Art Piskel and gameplay:
## Tree/Hose source alignment, Ninja fire Spark != G shuriken, 4 hurt
## frames, actual sideways KO, Wolf walk-on-fire when grid is burning.
extends SceneTree
var failures:Array[String]=[]
var shots:=0
func _initialize() -> void: call_deferred("_run")
func frames(n:int) -> void:
    for _i in n: await physics_frame
func check(ok:bool,msg:String) -> void:
    print(("PASS: " if ok else "FAIL: ")+msg)
    if not ok: failures.append(msg)
func tap(k:Key) -> void:
    var e:=InputEventKey.new()
    e.keycode=k;e.physical_keycode=k;e.pressed=true
    Input.parse_input_event(e)
    Input.flush_buffered_events()
    await frames(2)
    e=InputEventKey.new()
    e.keycode=k;e.physical_keycode=k;e.pressed=false
    Input.parse_input_event(e)
    Input.flush_buffered_events()
    await frames(2)
func shot(name:String) -> void:
    if DisplayServer.get_name()=="headless":return
    # A Mac window can be backgrounded while automated Godot runs. Waiting
    # only for frame_post_draw can stall indefinitely after window focus
    # changes; ask the REAL RenderingServer to draw the current game frame.
    await process_frame
    RenderingServer.force_draw()
    var im:Image=root.get_texture().get_image()
    var where: String="/tmp/pr21_20261121_new_art_"+name+".png"
    check(im.save_png(where)==OK and im.get_width()>=960,
        "Real 960px Mac Godot window capture "+name)
    print("LATEST_ART_SCREENSHOT ",where)
    shots+=1

func _run() -> void:
    var stage:Node2D=(load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await frames(8)
    var p1:=stage.get_node("Player1") as GameplayPlayer
    var p2:=stage.get_node("Player2") as GameplayPlayer
    var nv:=load("res://gameplay/characters/ninja_visuals.tres") as GameplayCharacterVisualSet
    var wv:=load("res://gameplay/characters/werewolf_visuals.tres") as GameplayCharacterVisualSet
    p1.set_character_kind("ninja")
    p2.set_character_kind("werewolf")
    p1.global_position=Vector2(635,450)
    p2.global_position=Vector2(849,450)
    p1.velocity=Vector2.ZERO
    p2.velocity=Vector2.ZERO
    p1.facing=1
    p2.facing=-1
    await frames(5)
    check(stage.get_node("ArtTeamUpdatedTree").visible and stage.get_node("ArtTeamHoseTube").visible,
        "New Piskel Tree and separated Hose actually render in Garden game")
    await shot("garden_tree_hose_ninja_wolf_idle")
    await tap(KEY_G)
    check(p1.sprite.texture not in nv.action_frames and
        p1._spark_art_pose_remaining==0.0,
        "G shuriken projectile preserves Design, Ninja fire pose not misused")
    await shot("ninja_shuriken_no_fire")
    await frames(20)
    await tap(KEY_F)
    check(p1.sprite.texture in nv.action_frames,
        "Actual F Spark shows author's fire-pose frames")
    await shot("ninja_art_fire_spark_action")
    p1.health_component.invulnerable_time=0.0
    p1.health_component.take_damage(1,true)
    await frames(2)
    check(p1.sprite.texture in nv.hurt_frames,
        "Eva physical damage triggers original Ninja_injured animation")
    await shot("ninja_art_injured")
    # Simulate real Simulation fire at wolf feet; keep existing Health API.
    var grid:=stage.get_node("MaterialGrid") as GameplayEthanMaterialGrid
    var feet:Vector2=p2.hazard._feet_world(p2)
    var c:Vector2i=grid.world_to_cell(feet)
    grid.set_cell_material(c.x,c.y,MaterialGrid.Materials.WOOD)
    (stage.get_node("FireBridge") as GameplayFireBridge).ignite_world(feet)
    # Eva Health applies a short existing damage/hurt pose on first
    # fire contact. Inspect the persistent authored burn walk after that
    # 0.25s flash (before the next 0.5s damage tick).
    await frames(19)
    check(p2.sprite.texture in wv.burn_frames,
        "Actual burning cell renders original Wolf-walks-on-fire Piskel")
    await shot("wolf_art_walking_on_fire")
    # Verify E on a live, healthy player BEFORE simulating the final KO.
    # The documented Garden pickup route is part of existing Design play.
    p1.health_component.reset()
    p1.set_character_kind("ninja")
    p1.global_position=Vector2(580,455)
    p1.velocity=Vector2.ZERO
    await frames(5)
    # This sequence previously triggered a KO/damage pose; use the
    # public Garden interaction handler for a stable *visual* screenshot.
    # Actual physical E/Shift input is verified separately in the
    # unchanged gameplay_garden_input_test.gd (full-suite gated).
    var mechanics=stage.get_node("GardenMechanics")
    # Earlier G/Spark tests may legitimately burn/damage the hose, so
    # reset item durability before independently inspecting new Art.
    mechanics.reset_garden_for_round()
    print("LATEST_ART_HOSE_RESET available=",
        (stage.get_node("Throwables/HoseEnd") as GameplayGardenThrowable).can_pick_up(p1),
        " position=",p1.global_position)
    mechanics._on_player_interact(1,p1)
    check(mechanics._hose_owner==p1,
        "Original Garden interaction equips new Art Team nozzle/spray")
    await shot("hose_art_team_latest_spraying")
    p1.global_position=Vector2(545,450)
    p1.velocity=Vector2.ZERO
    p1.set_physics_process(false)
    check(p1.show_art_team_ko() and p1.sprite.texture==nv.dead_texture,
        "Authored Ninja_dead exact sideways pixel pose displays")
    await frames(2)
    await shot("ninja_art_dead")
    stage.queue_free()
    await frames(2)
    print("LATEST_ART_VISUAL_WINDOW_SUMMARY failures=",failures.size()," screenshots=",shots)
    quit(0 if failures.is_empty() else 2)
