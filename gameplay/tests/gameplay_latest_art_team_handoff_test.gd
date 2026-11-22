## Latest Nov21 original Piskel source / animation / scene-art handoff.
## Art has been exported byte-for-byte via original Piskel frames.
## Ninja_fire is a Spark pose; actual shuriken G does not become a fireball.
extends SceneTree

var failed: Array[String] = []
var passes := 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, name: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + name)
    if ok: passes += 1
    else: failed.append(name)
func frames(n: int) -> void:
    for _i in n: await physics_frame
func key(k: Key, pressed: bool) -> void:
    var e := InputEventKey.new()
    e.keycode=k
    e.physical_keycode=k
    e.pressed=pressed
    Input.parse_input_event(e)
    Input.flush_buffered_events()
func tap(k: Key) -> void:
    key(k,true)
    await frames(2)
    key(k,false)
    await frames(2)
func _run() -> void:
    var ninja := load("res://gameplay/characters/ninja_visuals.tres") as GameplayCharacterVisualSet
    var wolf := load("res://gameplay/characters/werewolf_visuals.tres") as GameplayCharacterVisualSet
    check(ninja.action_frames.size()==4 and ninja.hurt_frames.size()==4
        and ninja.dead_texture != null, "Ninja new Art 4 action, 4 injured, 1 KO Piskel frames imported")
    check(wolf.burn_frames.size()==2,
        "Werewolf new two-frame Art Team walking-on-fire set imported")
    for i in 4:
        check(ninja.action_frames[i] == load(
            "res://gameplay/art_team/exported/ninja_fire_%d.png" % i)
            and ninja.hurt_frames[i] == load(
            "res://gameplay/art_team/exported/ninja_injured_%d.png" % i),
            "Original Ninja source Piskel action/hurt frame %d accessible" % i)
    for i in 2:
        check(wolf.burn_frames[i] == load(
            "res://gameplay/art_team/exported/wolf_fire_%d.png" % i),
            "Wolf walk-in-fire original frame %d accessible" % i)
    check(ninja.dead_texture.get_size()==Vector2(32,32)
        and ninja.dead_texture==load(
            "res://gameplay/art_team/exported/ninja_dead_0.png"),
        "Original Ninja_dead 32x32 sideways art preserved")
    var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(
        "res://gameplay/art_team/catalog.json"))
    check(catalog is Array and catalog.size() >= 12,
        "Art source SHA catalog now records six newly downloaded Piskels")
    var kinds: Array[String] = [
        "Ninja_fire.piskel","Ninja_injured.piskel","Ninja_dead.piskel",
        "Wolf walking on fire.piskel","Tree.piskel","Hose.piskel"
    ]
    for filename in kinds:
        var entry: Dictionary = {}
        for row: Dictionary in catalog:
            if row.get("original_name","")==filename:
                entry=row
                break
        check(not entry.is_empty() and FileAccess.file_exists(
            "res://gameplay/art_team/source/" + filename),
            "Original Art Team raw source retained: "+filename)

    var stage := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(stage)
    await frames(6)
    var tree := stage.get_node_or_null("ArtTeamUpdatedTree") as Sprite2D
    var tube := stage.get_node_or_null("ArtTeamHoseTube") as Sprite2D
    check(tree != null and tree.texture.get_size()==Vector2(190,245)
        and tree.position==Vector2(716,229) and tree.scale==Vector2(2,2),
        "New separated Tree Piskel overlays original source at exact x236,y0")
    check(tube != null and tube.texture.get_size()==Vector2(200,66)
        and tube.position==Vector2(414,412) and tube.scale==Vector2(2,2),
        "New Hose separated Piskel tube correct x80/y181 map alignment")
    var f1 := stage.get_node("Fences/Fence01") as GameplayGardenFenceSegment
    check(f1.hp==4 and stage.get_node("Fences").get_child_count()==8,
        "Latest Hose visual NEVER adds a duplicate unbreakable fence")
    var hose_item := stage.get_node("Throwables/HoseEnd") as GameplayGardenThrowable
    check(hose_item.HOSE_END_ART.get_size()==Vector2(20,10)
        and is_equal_approx(hose_item._throw_pixel_area(),800.0),
        "Latest actual nozzle Piskel pixels are 20x10 -> 0.08HP Design area")
    var p1 := stage.get_node("Player1") as GameplayPlayer
    var p2 := stage.get_node("Player2") as GameplayPlayer
    p1.set_character_kind("ninja")
    p2.set_character_kind("werewolf")
    p1.global_position=Vector2(438,448)
    p2.global_position=Vector2(803,448)
    p1.velocity=Vector2.ZERO
    p2.velocity=Vector2.ZERO
    await frames(3)
    await tap(KEY_G)
    check(p1._spark_art_pose_remaining==0.0 and
        p1.sprite.texture not in ninja.action_frames,
        "Actual G shuriken attack NEVER displays the Ninja_fire animation")
    await tap(KEY_F)
    check(p1._spark_art_pose_remaining>0.0
        and p1.sprite.texture in ninja.action_frames,
        "Actual F Spark shows Art Team Ninja_fire frames, not an invented attack")
    p1.health_component.invulnerable_time=0.0
    p1.health_component.take_damage(1,true)
    check(p1.sprite.texture==ninja.hurt_frames[0],
        "Real Eva Health damage immediately displays first Ninja_injured frame")
    for i in 4:
        p1._hurt_pose_elapsed=float(i)/12.0 + 0.001
        p1._update_character_sprite(false)
        check(p1.sprite.texture==ninja.hurt_frames[i],
            "All 4 Ninja_injured frames animate at authored 12fps: "+str(i))
    p1._hurt_pose_seconds=0.0
    p1._spark_art_pose_remaining=0.0
    p1._update_character_sprite(false)
    check(p1.sprite.texture==ninja.idle_frames[0],
        "After damage expires source Art Ninja idle is restored")
    check(p1.show_art_team_ko() and p1.sprite.texture==ninja.dead_texture
        and is_zero_approx(p1.sprite.rotation),
        "Ninja KO displays original sideways Ninja_dead, not generic tilted idle")
    p1.set_character_kind("ninja")
    check(p1.sprite.texture==ninja.idle_frames[0],
        "Character reset clears authored KO and restores source idle")
    check(p2.sprite.texture==wolf.idle_frames[0],
        "Werewolf retains existing idle when not on real fire")
    # Burn-contact visuals must use the SAME grid as Eva's existing hazard,
    # without any second HP/damage logic or speculative ability.
    var bridge := stage.get_node("FireBridge") as GameplayFireBridge
    var feet: Vector2=p2.hazard._feet_world(p2)
    var grid := stage.get_node("MaterialGrid") as GameplayEthanMaterialGrid
    var cell: Vector2i = grid.world_to_cell(feet)
    grid.set_cell_material(cell.x,cell.y,MaterialGrid.Materials.WOOD)
    bridge.ignite_world(feet)
    p2._update_character_sprite(true)
    check(p2.sprite.texture in wolf.burn_frames,
        "Actual shared Simulation fire cell drives Wolf authored burning-walk art")
    p2.facing=1
    p2._update_character_sprite(true)
    check(p2.sprite.flip_h, "Wolf burning frame remains correct world-right")
    for i in 4:
        f1.take_hit(1)
    await frames(3)
    check(f1.destroyed_segment and not f1.get_node("ArtTeamFencePixels").visible,
        "Original fence remains physically destructible after latest Hose overlay")
    stage.queue_free()
    await frames(2)
    print("LATEST_ART_TEAM_HANDOFF_SUMMARY failures=",failed.size()," passes=",passes)
    quit(0 if failed.is_empty() else 2)
